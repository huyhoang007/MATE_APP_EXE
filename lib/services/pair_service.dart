import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import 'user_id_service.dart';

/// ============================================================
/// PairService - Dịch vụ ghép đôi thời gian thực qua Firestore
///
/// LƯU Ý: KHÔNG dùng FirebaseAuth. Ứng dụng dùng userId thiết bị
/// (lưu SharedPreferences) + Firestore Rules `allow read, write: if true;`.
///
/// Cấu trúc document `couples/{code}`:
///   code: "ABC123"
///   status: "waiting" | "paired"
///   startDate: Timestamp
///   user1: { name, isOnline, batteryLevel, lastActive, deviceId }
///   user2: { name, isOnline, batteryLevel, lastActive, deviceId }
///   pet:    { name, level, exp, hunger, happiness }
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

  const PairSession({
    required this.code,
    required this.status,
    required this.creatorNickname,
    required this.startDate,
    this.partnerNickname,
  });

  bool get isPaired => status == PairStatus.paired;
}

class PairService {
  PairService._();
  static final PairService instance = PairService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'couples';
  static const String _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int _codeLength = 6;

  /// Timeout mặc định cho mọi call Firestore (tránh treo vô hạn).
  static const Duration _callTimeout = Duration(seconds: 10);

  String _generateCode() {
    final rng = Random.secure();
    return List.generate(
      _codeLength,
      (_) => _codeChars[rng.nextInt(_codeChars.length)],
    ).join();
  }

  /// Chuẩn hoá mã người dùng nhập -> "ABC123" (uppercase, bỏ space/dash).
  String normalizeCode(String raw) {
    final cleaned = raw
        .toUpperCase()
        .replaceAll(RegExp(r'[\s\-_]'), '')
        .trim();
    return cleaned;
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
    final deviceId = await UserIdService.instance.getOrCreate();
    String? lastError;
    for (int attempt = 0; attempt < 5; attempt++) {
      final code = _generateCode();
      try {
        await _db
            .collection(_collection)
            .doc(code)
            .set({
              'code': code,
              'status': 'waiting',
              'createdAt': FieldValue.serverTimestamp(),
              'startDate': Timestamp.fromDate(startDate),
              'user1': {
                'name': nickname,
                'isOnline': true,
                'batteryLevel': 100,
                'lastActive': FieldValue.serverTimestamp(),
                'deviceId': deviceId,
              },
              'user2': {
                'name': 'Đang chờ...',
                'isOnline': false,
                'batteryLevel': 0,
                'deviceId': null,
              },
              'pet': {
                'name': 'Mochi',
                'level': 1,
                'exp': 0,
                'hunger': 0.5,
                'happiness': 0.5,
              },
            })
            .timeout(_callTimeout);
        return code;
      } on FirebaseException catch (e) {
        lastError = e.message;
        // Lỗi trùng document -> thử lại; các lỗi khác -> ném PairException.
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
    // 1. Validate mã trước khi gọi Firestore.
    final validationError = validateCode(code);
    if (validationError != null) {
      throw PairException(validationError);
    }
    final normalized = normalizeCode(code);

    final deviceId = await UserIdService.instance.getOrCreate();
    final docRef = _db.collection(_collection).doc(normalized);

    try {
      // 2. Lấy document hiện tại với timeout.
      final snap = await docRef.get(const GetOptions(source: Source.server))
          .timeout(_callTimeout);

      if (!snap.exists) {
        throw const PairException(
          'Mã không tồn tại. Vui lòng kiểm tra lại!',
        );
      }

      final data = snap.data()!;
      final status = data['status'] as String?;

      if (status == 'paired') {
        throw const PairException('Phòng đã đủ 2 người rồi 🥺');
      }

      // 3. Update với timeout.
      await docRef.update({
        'status': 'paired',
        'user2': {
          'name': partnerNickname,
          'isOnline': true,
          'batteryLevel': 100,
          'lastActive': FieldValue.serverTimestamp(),
          'deviceId': deviceId,
        },
      }).timeout(_callTimeout);

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

  PairSession _toSession(
    String code,
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data() ?? {};
    final statusStr = data['status'] as String? ?? 'waiting';
    final status =
        statusStr == 'paired' ? PairStatus.paired : PairStatus.waiting;
    final user1 = data['user1'] as Map<String, dynamic>? ?? {};
    final user2 = data['user2'] as Map<String, dynamic>? ?? {};
    final startTs = data['startDate'] as Timestamp?;
    final partnerName = user2['name'] as String?;
    return PairSession(
      code: code,
      status: status,
      creatorNickname: (user1['name'] as String?) ?? '',
      startDate: startTs?.toDate() ?? DateTime.now(),
      partnerNickname: (partnerName != null && partnerName != 'Đang chờ...')
          ? partnerName
          : null,
    );
  }

  /// Chuyển mọi lỗi Firestore / Platform / khác thành PairException có message
  /// tiếng Việt thân thiện. TUYỆT ĐỐI KHÔNG để lỗ auth/network lọt ra ngoài.
  PairException _toPairException(Object e) {
    if (e is PairException) return e;

    String raw = e.toString();
    String message;

    if (e is FirebaseException) {
      // Một số mã lỗi thường gặp
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
      // Bắt riêng lỗi auth (App Check / token)
      message = 'Phiên xác thực hết hạn. Đang thử lại...';
    } else {
      message = 'Đã có lỗi xảy ra. Vui lòng thử lại!';
    }

    return PairException(message, cause: e);
  }
}