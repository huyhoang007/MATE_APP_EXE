import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ============================================================
/// AuthService - Quản lý đăng nhập & hồ sơ người dùng.
///
/// VẤN ĐỀ ĐƯỢC GIẢI QUYẾT:
///   Trước đây app dùng `UserIdService` = random string lưu máy.
///   Hệ quả: mở app lại là mất hoàn toàn session, không "đăng nhập"
///   được, không thể khôi phục cặp đôi cũ.
///
/// GIẢI PHÁP:
///   Dùng Firebase Anonymous Authentication.
///   - UID do Firebase sinh & tự persist trên thiết bị (offline cũng OK).
///   - Mở app lại → `currentUser` vẫn còn → tự động vào thẳng cặp đôi cũ.
///   - Người B nhập mã → UID của B được ghi vào `couples/{code}/members`.
///   - Sau này nâng cấp sang email/Google qua `linkWithCredential`,
///     giữ nguyên UID & toàn bộ dữ liệu cặp đôi.
///
/// Firestore rules sẽ dựa vào `members` map để kiểm soát truy cập:
///   chỉ 2 thành viên trong `couples/{code}/members` mới đọc/ghi được cặp đôi.
/// ============================================================

enum AuthStatus { unknown, signedOut, signedIn }

class AuthUser {
  final String uid;
  final String nickname;
  final String? coupleCode;
  final DateTime createdAt;

  const AuthUser({
    required this.uid,
    required this.nickname,
    this.coupleCode,
    required this.createdAt,
  });

  bool get hasCouple => coupleCode != null && coupleCode!.isNotEmpty;
}

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _usersCollection = 'users';
  static const Duration _timeout = Duration(seconds: 12);

  User? _user;
  AuthUser? _profile;
  AuthStatus _status = AuthStatus.unknown;
  StreamSubscription<User?>? _authSub;
  bool _isGuest = false;
  String? _guestUid;

  /// Đã đăng nhập (anonymous hoặc guest dev mode).
  bool get isSignedIn => (_user != null) || _isGuest;
  String? get uid => _user?.uid ?? _guestUid;
  AuthStatus get status => _status;
  bool get isGuest => _isGuest;

  /// Hồ sơ người dùng hiện tại (đọc từ `users/{uid}`).
  AuthUser? get profile => _profile;
  String get nickname => _profile?.nickname ?? 'Bạn';
  String? get coupleCode => _profile?.coupleCode;

  /// Bật chế độ dùng thử Offline / Khách khi Firebase Auth chưa được cấu hình.
  void useGuestMode({String? customUid}) {
    _isGuest = true;
    _guestUid = customUid ?? 'guest_${DateTime.now().millisecondsSinceEpoch % 1000000}';
    _status = AuthStatus.signedIn;
    _profile = AuthUser(
      uid: _guestUid!,
      nickname: 'Bạn',
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Khởi tạo: đăng nhập anonymous (hoặc khôi phục session đã có) và
  /// load hồ sơ. Idempotent — gọi nhiều lần cũng chỉ đăng nhập 1 lần trừ khi force: true.
  Future<void> ensureSignedIn({bool force = false}) async {
    // Nếu đã đăng nhập thành công và có user, không cần đăng nhập lại trừ khi force: true
    if (!force && isSignedIn && _status == AuthStatus.signedIn) return;

    _status = AuthStatus.unknown;

    _authSub ??= _auth.authStateChanges().listen((u) {
      _user = u;
      if (u == null && !_isGuest && _status != AuthStatus.unknown) {
        _status = AuthStatus.signedOut;
        notifyListeners();
      }
    });

    try {
      // Ưu tiên session đã lưu (Firebase tự persist trên máy).
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously().timeout(_timeout);
      }
      _user = _auth.currentUser;
      _isGuest = false;
      _guestUid = null;
      _status = AuthStatus.signedIn;
      try {
        await _loadOrCreateProfile();
      } catch (err) {
        debugPrint('[AuthService] Không thể load profile Firestore: $err');
        _profile ??= AuthUser(
          uid: _user!.uid,
          nickname: 'Bạn',
          createdAt: DateTime.now(),
        );
      }
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.signedOut;
      notifyListeners();
      throw AuthException(_messageForAuthError(e), cause: e);
    } catch (e) {
      _status = AuthStatus.signedOut;
      notifyListeners();
      throw AuthException('Không thể đăng nhập. Vui lòng kiểm tra kết nối.', cause: e);
    }
  }

  /// Load `users/{uid}`, nếu chưa có thì tạo mới với nickname mặc định.
  Future<void> _loadOrCreateProfile() async {
    final uid = _user?.uid;
    if (uid == null) return;

    final ref = _db.collection(_usersCollection).doc(uid);
    final snap = await ref.get(const GetOptions(source: Source.server)).timeout(_timeout);

    if (!snap.exists) {
      final now = DateTime.now();
      await ref.set({
        'uid': uid,
        'nickname': 'Bạn',
        'coupleCode': null,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'isAnonymous': true,
      }).timeout(_timeout);
      _profile = AuthUser(uid: uid, nickname: 'Bạn', createdAt: now);
      return;
    }

    final data = snap.data() ?? {};
    final created = data['createdAt'];
    _profile = AuthUser(
      uid: uid,
      nickname: (data['nickname'] as String?) ?? 'Bạn',
      coupleCode: data['coupleCode'] as String?,
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
    );
  }

  /// Đổi biệt danh của user hiện tại (ghi cả vào hồ sơ Firestore).
  Future<void> updateNickname(String nickname) async {
    final currentUid = uid;
    final clean = nickname.trim();
    if (currentUid == null || clean.isEmpty) return;
    if (!_isGuest && _user != null) {
      try {
        await _db.collection(_usersCollection).doc(currentUid).update({
          'nickname': clean,
          'lastActive': FieldValue.serverTimestamp(),
        }).timeout(_timeout);
      } catch (e) {
        debugPrint('[AuthService] updateNickname Firestore non-fatal: $e');
      }
    }
    _profile = AuthUser(
      uid: currentUid,
      nickname: clean,
      coupleCode: _profile?.coupleCode,
      createdAt: _profile?.createdAt ?? DateTime.now(),
    );
    notifyListeners();
  }

  /// Ghi nhớ cặp đôi hiện tại vào hồ sơ user → dùng để tự vào lại
  /// cặp đôi cũ khi mở app lần sau.
  Future<void> linkCouple(String code) async {
    final currentUid = uid;
    if (currentUid == null) return;
    if (!_isGuest && _user != null) {
      try {
        await _db.collection(_usersCollection).doc(currentUid).update({
          'coupleCode': code,
          'lastActive': FieldValue.serverTimestamp(),
        }).timeout(_timeout);
      } catch (e) {
        debugPrint('[AuthService] linkCouple Firestore non-fatal: $e');
      }
    }
    _profile = AuthUser(
      uid: currentUid,
      nickname: _profile?.nickname ?? 'Bạn',
      coupleCode: code,
      createdAt: _profile?.createdAt ?? DateTime.now(),
    );
    notifyListeners();
  }

  /// Huỷ liên kết cặp đôi (dùng khi người dùng muốn bỏ cặp).
  Future<void> unlinkCouple() async {
    final currentUid = uid;
    if (currentUid == null) return;
    if (!_isGuest && _user != null) {
      try {
        await _db.collection(_usersCollection).doc(currentUid).update({
          'coupleCode': null,
          'lastActive': FieldValue.serverTimestamp(),
        }).timeout(_timeout);
      } catch (e) {
        debugPrint('[AuthService] unlinkCouple Firestore non-fatal: $e');
      }
    }
    _profile = AuthUser(
      uid: currentUid,
      nickname: _profile?.nickname ?? 'Bạn',
      coupleCode: null,
      createdAt: _profile?.createdAt ?? DateTime.now(),
    );
    notifyListeners();
  }

  /// Cập nhật trạng thái online + thời điểm active gần nhất.
  Future<void> touchActivity({bool online = true, int? batteryLevel}) async {
    final currentUid = uid;
    if (currentUid == null || _isGuest) return;
    final patch = <String, dynamic>{
      'isOnline': online,
      'lastActive': FieldValue.serverTimestamp(),
    };
    if (batteryLevel != null) patch['batteryLevel'] = batteryLevel;
    try {
      await _db.collection(_usersCollection).doc(currentUid).set(patch, SetOptions(merge: true)).timeout(_timeout);
    } catch (_) {
      // Không quan trọng — bỏ qua lỗi cập nhật trạng thái.
    }
  }

  /// Đăng xuất (xoá session trên máy). Dữ liệu cặp đôi vẫn còn trên server.
  Future<void> signOut() async {
    if (!_isGuest) {
      try {
        await _auth.signOut();
      } catch (_) {}
    }
    _user = null;
    _isGuest = false;
    _guestUid = null;
    _profile = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  /// Nâng cấp hồ sơ lên email (không mất UID, không mất dữ liệu cặp đôi).
  Future<void> linkEmail({required String email, required String password}) async {
    final u = _auth.currentUser;
    if (u == null) throw const AuthException('Chưa đăng nhập.');
    try {
      await u.linkWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
      await _db.collection(_usersCollection).doc(u.uid).update({
        'isAnonymous': false,
        'email': email,
      }).timeout(_timeout);
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageForAuthError(e), cause: e);
    }
  }

  String _messageForAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'Không có kết nối Internet. Vui lòng kiểm tra lại mạng!';
      case 'operation-not-allowed':
      case 'configuration-not-found':
        return 'Chưa bật tính năng đăng nhập Ẩn danh (Anonymous) trên Firebase Console.\n\n'
            'Vui lòng vào Firebase Console > Authentication > Sign-in method và Bật "Anonymous" (Ẩn danh).';
      case 'admin-restricted-operation':
        return 'Firebase đang chặn tạo người dùng (admin-restricted-operation).\n\n'
            '👉 Cách sửa: Vào Firebase Console > Authentication > tab Settings > mục User actions > Tích chọn "Enable create (sign-up)" để cho phép tạo tài khoản.';
      case 'invalid-api-key':
        return 'API Key không hợp lệ. Vui lòng kiểm tra firebase_options.dart.';
      case 'app-not-authorized':
        return 'Domain hiện tại chưa được uỷ quyền (Authorized domains) trong Firebase Authentication.';
      default:
        return 'Lỗi đăng nhập (${e.code}). Vui lòng kiểm tra Firebase Authentication!';
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

/// Exception chuẩn hoá lỗi auth với message tiếng Việt.
class AuthException implements Exception {
  final String message;
  final Object? cause;
  const AuthException(this.message, {this.cause});
  @override
  String toString() => message;
}
