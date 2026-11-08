import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import 'auth_service.dart';

/// ============================================================
/// PairService - Ghép đôi thời gian thực qua Firestore.
///
/// Dùng Firebase Anonymous Auth nên `request.auth.uid` là định danh
/// ổn định của thiết bị. Mỗi cặp đôi có:
///   couples/{code}                     -> document chính
///   couples/{code}/members/{uid}       -> 2 thành viên (nguồn sự thật)
///
/// Mã ghép đôi vẫn là 6 ký tự (A-Z, 2-9) để gửi qua Zalo/SMS cho
/// người yêu. Người nhận mã nhập vào → UID của họ được ghi vào
/// `members`, và họ tự động thấy cặp đôi trong `users/{uid}.coupleCode`.
/// ============================================================

enum PairStatus { waiting, paired, notFound, full }

/// Exception throw ra có message tiếng Việt thân thiện cho UI.
class PairException implements Exception {
  final String message;
  final Object? cause;
  const PairException(this.message, {this.cause});
  @override
  String toString() => message;
}

class PairSession {
  final String code;
  final PairStatus status;
  final String creatorNickname;
  final DateTime startDate;
  final String? partnerNickname;

  /// UID của người tạo phòng.
  final String? creatorUid;
  /// UID của người tham gia (null nếu chưa có).
  final String? partnerUid;
  /// UID của chính user hiện tại (nếu đã là thành viên).
  final String? myUid;

  const PairSession({
    required this.code,
    required this.status,
    required this.creatorNickname,
    required this.startDate,
    this.partnerNickname,
    this.creatorUid,
    this.partnerUid,
    this.myUid,
  });

  bool get isPaired => status == PairStatus.paired;
  bool get amIMember => myUid != null;
}

class PairService {
  PairService._();
  static final PairService instance = PairService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'couples';
  static const String _membersSub = 'members';
  static const String _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int _codeLength = 6;
  static const Duration _callTimeout = Duration(seconds: 12);

  String _generateCode() {
    final rng = Random.secure();
    return List.generate(
      _codeLength,
      (_) => _codeChars[rng.nextInt(_codeChars.length)],
    ).join();
  }

  /// Chuẩn hoá mã người dùng nhập -> "ABC123" (uppercase, bỏ space/dash).
  String normalizeCode(String raw) {
    return raw.toUpperCase().replaceAll(RegExp(r'[\s\-_]'), '').trim();
  }

  /// Validate mã 6 ký tự A-Z/2-9. Trả về null nếu OK, message lỗi nếu sai.
  String? validateCode(String raw) {
    final code = normalizeCode(raw);
    if (code.isEmpty) return 'Vui lòng nhập mã ghép đôi';
    if (code.length != _codeLength) {
      return 'Mã ghép đôi phải gồm $_codeLength ký tự (chữ và số)';
    }
    final validPattern = RegExp(r'^[A-HJ-NP-Z2-9]{6}$');
    if (!validPattern.hasMatch(code)) {
      return 'Mã chỉ gồm chữ cái A-Z và số 2-9';
    }
    return null;
  }

  /// Tạo phòng mới với mã ngẫu nhiên. Trả về mã đã tạo.
  Future<String> createRoom({
    required String nickname,
    required DateTime startDate,
  }) async {
    final uid = await _requireUid();
    String? lastError;

    if (AuthService.instance.isGuest) {
      final code = _generateCode();
      await AuthService.instance.linkCouple(code);
      return code;
    }

    for (int attempt = 0; attempt < 5; attempt++) {
      final code = _generateCode();
      try {
        final coupleRef = _db.collection(_collection).doc(code);

        // Tạo document cặp đôi + doc thành viên của tôi.
        await _db.runTransaction((txn) async {
          await txn.set(coupleRef, {
            'code': code,
            'status': 'waiting',
            'createdAt': FieldValue.serverTimestamp(),
            'startDate': Timestamp.fromDate(startDate),
            'isPremium': false,
            'streakDays': 0,
            'intimacyScore': 0,
            'daysLoved': 0,
            'coins': 100,
            'members': {uid: {'name': nickname, 'joinedAt': FieldValue.serverTimestamp()}},
            'creatorUid': uid,
            'partnerUid': null,
            'pet': {
              'name': 'Mochi',
              'level': 1,
              'exp': 0,
              'hunger': 0.5,
              'happiness': 0.5,
              'lastFed': null,
              'lastPlayed': null,
            },
          });

          await txn.set(coupleRef.collection(_membersSub).doc(uid), {
            'uid': uid,
            'name': nickname,
            'role': 'creator',
            'joinedAt': FieldValue.serverTimestamp(),
            'isOnline': true,
            'lastActive': FieldValue.serverTimestamp(),
          });
        }).timeout(_callTimeout);

        // Ghi nhớ cặp đôi vào hồ sơ user → mở app lại vẫn vào đúng cặp.
        await AuthService.instance.linkCouple(code);

        return code;
      } on FirebaseException catch (e) {
        lastError = e.message;
        if (e.code != 'aborted' && e.code != 'already-exists') {
          throw _toPairException(e);
        }
      } on TimeoutException {
        throw const PairException(
          'Kết nối Firestore quá chậm. Vui lòng thử lại nhé 💕',
        );
      } on PairException {
        rethrow;
      } catch (e) {
        throw _toPairException(e);
      }
    }
    throw PairException(
      'Không thể tạo mã phòng. Vui lòng thử lại!',
      cause: lastError,
    );
  }

  /// Stream lắng nghe thay đổi của 1 phòng theo mã.
  Stream<PairSession> watchRoom(String code) {
    final normalized = normalizeCode(code);
    if (AuthService.instance.isGuest) {
      return Stream.value(PairSession(
        code: normalized,
        status: PairStatus.waiting,
        creatorNickname: AuthService.instance.nickname,
        startDate: DateTime.now(),
        creatorUid: AuthService.instance.uid,
        myUid: AuthService.instance.uid,
      ));
    }
    final docRef = _db.collection(_collection).doc(normalized);
    return docRef.snapshots().map((snap) {
      if (!snap.exists) {
        return PairSession(
          code: normalized,
          status: PairStatus.notFound,
          creatorNickname: '',
          startDate: DateTime.now(),
        );
      }
      return _toSession(normalized, snap);
    });
  }

  /// Người thứ 2 tham gia phòng bằng mã.
  Future<PairSession> joinRoom({
    required String code,
    required String partnerNickname,
  }) async {
    final validationError = validateCode(code);
    if (validationError != null) {
      throw PairException(validationError);
    }
    final normalized = normalizeCode(code);
    final uid = await _requireUid();

    if (AuthService.instance.isGuest) {
      await AuthService.instance.linkCouple(normalized);
      return PairSession(
        code: normalized,
        status: PairStatus.paired,
        creatorNickname: 'Đối tác',
        startDate: DateTime.now(),
        partnerNickname: partnerNickname,
        creatorUid: 'guest_creator',
        partnerUid: uid,
        myUid: uid,
      );
    }

    final coupleRef = _db.collection(_collection).doc(normalized);
    final memberRef = coupleRef.collection(_membersSub).doc(uid);

    try {
      // Transaction: kiểm tra slot trống + ghi member atomically, tránh
      // race condition khi cả 2 người cùng nhập mã.
      await _db.runTransaction((txn) async {
        final coupleSnap = await txn.get(coupleRef);
        if (!coupleSnap.exists) {
          throw const PairException('Mã không tồn tại. Vui lòng kiểm tra lại!');
        }

        final memberSnap = await txn.get(memberRef);
        if (memberSnap.exists) {
          // Đã là thành viên → idempotent, coi như thành công.
          return;
        }

        final members = coupleSnap.data()?['members'];
        final memberCount = members is Map ? members.length : 0;
        if (memberCount >= 2) {
          throw const PairException('Phòng đã đủ 2 người rồi 🥺');
        }

        final creatorUid = coupleSnap.data()?['creatorUid'] as String?;
        final partnerUid = creatorUid == uid ? null : creatorUid;

        await txn.set(memberRef, {
          'uid': uid,
          'name': partnerNickname,
          'role': 'joiner',
          'joinedAt': FieldValue.serverTimestamp(),
          'isOnline': true,
          'lastActive': FieldValue.serverTimestamp(),
        });

        await txn.update(coupleRef, {
          'status': 'paired',
          'partnerUid': partnerUid,
          'members.$uid': {
            'name': partnerNickname,
            'joinedAt': FieldValue.serverTimestamp(),
          },
          'daysLoved': 0,
        });
      }).timeout(_callTimeout);

      // Ghi nhớ cặp đôi vào hồ sơ user.
      await AuthService.instance.linkCouple(normalized);

      final snap = await coupleRef.get();
      return _toSession(normalized, snap);
    } on PairException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _toPairException(e);
    } on TimeoutException {
      throw const PairException(
        'Kết nối quá chậm. Vui lòng thử lại nhé 💕',
      );
    } on PlatformException catch (e) {
      throw PairException(
        'Lỗi nền tảng: ${e.message ?? e.code}',
        cause: e,
      );
    } catch (e) {
      throw _toPairException(e);
    }
  }

  /// Lấy UID hiện tại, đảm bảo đã đăng nhập.
  Future<String> _requireUid() async {
    if (!AuthService.instance.isSignedIn) {
      try {
        await AuthService.instance.ensureSignedIn(force: true);
      } catch (e) {
        if (e is AuthException) {
          throw PairException(e.message, cause: e);
        }
      }
    }
    final uid = AuthService.instance.uid;
    if (uid == null) {
      throw const PairException('Chưa đăng nhập. Vui lòng kiểm tra kết nối hoặc bật Anonymous Auth trên Firebase Console!');
    }
    return uid;
  }

  PairSession _toSession(
    String code,
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data() ?? {};
    final statusStr = data['status'] as String? ?? 'waiting';
    final status =
        statusStr == 'paired' ? PairStatus.paired : PairStatus.waiting;

    final members = data['members'];
    final creatorUid = data['creatorUid'] as String?;
    final partnerUid = data['partnerUid'] as String?;

    String? creatorName;
    String? partnerName;
    if (members is Map) {
      for (final entry in members.entries) {
        final uid = entry.key as String;
        final name = (entry.value is Map)
            ? ((entry.value as Map)['name'] as String?)
            : null;
        if (uid == creatorUid) {
          creatorName = name;
        } else if (uid == partnerUid) {
          partnerName = name;
        } else if (partnerName == null && uid != creatorUid) {
          partnerName = name;
        }
      }
    }

    final startTs = data['startDate'] as Timestamp?;
    final myUid = AuthService.instance.uid;

    return PairSession(
      code: code,
      status: status,
      creatorNickname: creatorName ?? '',
      startDate: startTs?.toDate() ?? DateTime.now(),
      partnerNickname: (partnerName != null && partnerName.isNotEmpty)
          ? partnerName
          : null,
      creatorUid: creatorUid,
      partnerUid: partnerUid,
      myUid: myUid,
    );
  }

  /// Chuyển mọi lỗi Firestore / Platform / khác thành PairException có message
  /// tiếng Việt thân thiện. TUYỆT ĐỐI KHÔNG để lỗ auth/network lọt ra ngoài.
  PairException _toPairException(Object e) {
    if (e is PairException) return e;

    final raw = e.toString();
    String message;

    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          message = 'Bạn không có quyền truy cập. Hãy kiểm tra Firestore Rules.';
          break;
        case 'unauthenticated':
        case 'unavailable':
        case 'deadline-exceeded':
          message = 'Mất kết nối máy chủ. Vui lòng thử lại nhé 💕';
          break;
        case 'not-found':
          message = 'Mã không tồn tại. Vui lòng kiểm tra lại!';
          break;
        case 'already-exists':
        case 'aborted':
          message = 'Mã bị trùng, đang thử lại...';
          break;
        default:
          message = 'Lỗi Firestore (${e.code}). Vui lòng thử lại!';
      }
    } else if (raw.contains('SocketException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('Network is unreachable')) {
      message = 'Không có kết nối Internet. Vui lòng thử lại!';
    } else if (raw.contains('TimeoutException')) {
      message = 'Kết nối quá chậm. Vui lòng thử lại nhé 💕';
    } else if (raw.contains('authentication')) {
      message = 'Phiên xác thực hết hạn. Đang thử lại...';
    } else {
      message = 'Đã có lỗi xảy ra. Vui lòng thử lại!';
    }

    return PairException(message, cause: e);
  }
}
