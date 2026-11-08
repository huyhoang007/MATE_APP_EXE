import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';
import 'wallet_service.dart';

/// ============================================================
/// DailyRewardService - Quà hằng ngày & chuỗi đăng nhập.
///
/// Collection: couples/{code}/checkins/{checkinId}
///   {
///     userId: String
///     date: String ('yyyy-MM-dd')
///     coinsEarned: int
///     streakDay: int (ngày thứ mấy trong chuỗi 7 ngày)
///     createdAt: Timestamp
///   }
///
/// Logic:
///   - Mỗi ngày mỗi user chỉ claim 1 lần.
///   - Chuỗi đăng nhập 7 ngày: ngày 1→20xu, 2→30xu, 3→50xu, 4→80xu,
///     5→120xu, 6→180xu, 7→300xu. Premium ×2.
///   - Sau ngày 7, reset về ngày 1.
///   - Nếu bỏ 1 ngày, reset chuỗi về 1.
/// ============================================================

class DailyCheckin {
  final String id;
  final String userId;
  final String date;
  final int coinsEarned;
  final int streakDay;
  final DateTime createdAt;

  const DailyCheckin({
    required this.id,
    required this.userId,
    required this.date,
    required this.coinsEarned,
    required this.streakDay,
    required this.createdAt,
  });

  factory DailyCheckin.fromDoc(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    return DailyCheckin(
      id: snap.id,
      userId: (d['userId'] as String?) ?? '',
      date: (d['date'] as String?) ?? '',
      coinsEarned: ((d['coinsEarned'] as num?)?.toInt()) ?? 0,
      streakDay: ((d['streakDay'] as num?)?.toInt()) ?? 1,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class DailyRewardService {
  DailyRewardService._();
  static final DailyRewardService instance = DailyRewardService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const Duration _timeout = Duration(seconds: 12);

  /// Xu thưởng theo ngày trong chuỗi (1-indexed).
  static const List<int> _rewardsByDay = [0, 20, 30, 50, 80, 120, 180, 300];

  CollectionReference<Map<String, dynamic>> _ref(String code) =>
      _db.collection('couples').doc(code).collection('checkins');

  /// Ngày hôm nay dạng 'yyyy-MM-dd'.
  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Ngày hôm qua dạng 'yyyy-MM-dd'.
  static String _yesterday() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
  }

  /// Kiểm tra hôm nay đã claim chưa.
  Future<bool> hasClaimedToday(String code) async {
    final uid = AuthService.instance.uid;
    if (uid == null) return false;

    final snap = await _ref(code)
        .where('userId', isEqualTo: uid)
        .where('date', isEqualTo: _today())
        .limit(1)
        .get()
        .timeout(_timeout);

    return snap.docs.isNotEmpty;
  }

  /// Tính streak hiện tại (dựa trên checkin gần nhất).
  Future<int> getCurrentStreak(String code) async {
    final uid = AuthService.instance.uid;
    if (uid == null) return 0;

    final snap = await _ref(code)
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get()
        .timeout(_timeout);

    if (snap.docs.isEmpty) return 0;

    final last = DailyCheckin.fromDoc(snap.docs.first);

    // Nếu checkin cuối cùng là hôm nay → streak hiện tại.
    if (last.date == _today()) return last.streakDay;

    // Nếu checkin cuối cùng là hôm qua → streak tiếp tục.
    if (last.date == _yesterday()) return last.streakDay;

    // Bỏ ngày → reset.
    return 0;
  }

  /// Claim quà hằng ngày. Trả về số xu đã nhận.
  ///
  /// Throw nếu đã claim hôm nay.
  Future<int> claimDailyReward(String code, {bool isPremium = false}) async {
    final uid = AuthService.instance.uid;
    if (uid == null) throw const DailyRewardException('Chưa đăng nhập.');

    // Kiểm tra đã claim chưa.
    final alreadyClaimed = await hasClaimedToday(code);
    if (alreadyClaimed) {
      throw const DailyRewardException('Bạn đã nhận quà hôm nay rồi.');
    }

    // Tính streak.
    int streakDay = 1;
    final currentStreak = await getCurrentStreak(code);
    if (currentStreak > 0) {
      // Tiếp tục chuỗi, reset sau ngày 7.
      streakDay = (currentStreak % 7) + 1;
    }

    // Tính xu thưởng.
    int coins = _rewardsByDay[streakDay.clamp(1, 7)];
    if (isPremium) coins *= 2;

    // Ghi checkin.
    await _ref(code).doc().set({
      'userId': uid,
      'date': _today(),
      'coinsEarned': coins,
      'streakDay': streakDay,
      'createdAt': FieldValue.serverTimestamp(),
    }).timeout(_timeout);

    // Cộng xu.
    await WalletService.instance.earnCoins(code, coins, 'Quà hằng ngày (ngày $streakDay)');

    return coins;
  }

  /// Stream checkins gần đây.
  Stream<List<DailyCheckin>> watchCheckins(String code, {int limit = 7}) {
    return _ref(code)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(DailyCheckin.fromDoc).toList());
  }
}

class DailyRewardException implements Exception {
  final String message;
  const DailyRewardException(this.message);
  @override
  String toString() => message;
}
