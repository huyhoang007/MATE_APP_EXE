import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/couple_model.dart';

/// ============================================================
/// CoupleService - Quản lý dữ liệu cặp đôi realtime qua Firestore
/// Tất cả thay đổi đều sync 2 chiều giữa 2 người dùng.
/// ============================================================

class CoupleService {
  CoupleService._();
  static final CoupleService instance = CoupleService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'couples';
  static const Duration _callTimeout = Duration(seconds: 10);

  // ---------- READ ----------

  /// Stream document của cặp đôi. Phát `CoupleData` mỗi khi Firestore thay đổi.
  /// Nếu document chưa tồn tại → tự động tạo dữ liệu mẫu.
  Stream<CoupleData> watchCouple(String code) {
    return _db
        .collection(_collection)
        .doc(code)
        .snapshots()
        .asyncMap((snap) async {
          if (!snap.exists) {
            // Tạo document mẫu nếu chưa có
            await _ensureDocument(code);
            return CoupleData(
              code: code,
              startDate: DateTime.now().subtract(const Duration(days: 30)),
              user1: const UserInfo(name: 'Bạn'),
              user2: const UserInfo(name: 'Người yêu'),
              pet: const PetState(),
            );
          }
          // Nếu document có nhưng thiếu field → patch ngay
          final data = snap.data()!;
          if (_needsPatch(data)) {
            await _patchMissing(code, data);
          }
          return CoupleData.fromDoc(snap);
        });
  }

  Future<CoupleData?> getOnce(String code) async {
    final snap = await _db.collection(_collection).doc(code).get();
    if (!snap.exists) return null;
    final data = snap.data()!;
    if (_needsPatch(data)) {
      await _patchMissing(code, data);
    }
    return CoupleData.fromDoc(snap);
  }

  // ---------- WRITE: Date ----------

  /// Cập nhật ngày bắt đầu yêu.
  Future<void> updateStartDate(String code, DateTime date) {
    return _db.collection(_collection).doc(code).update({
      'startDate': Timestamp.fromDate(date),
    }).timeout(_callTimeout);
  }

  // ---------- WRITE: User ----------

  /// Cập nhật thông tin 1 user (user1 hoặc user2).
  Future<void> updateUser(String code, {required bool isUser1, required UserInfo user}) {
    return _db.collection(_collection).doc(code).update({
      isUser1 ? 'user1' : 'user2': user.toMap(),
    }).timeout(_callTimeout);
  }

  /// Cập nhật vị trí của 1 user.
  Future<void> updateLocation(String code, {required bool isUser1, required GeoLocation loc}) {
    return _db.collection(_collection).doc(code).update({
      '${isUser1 ? 'user1' : 'user2'}.location': loc.toMap(),
    }).timeout(_callTimeout);
  }

  /// Cập nhật vị trí bằng tên field trực tiếp (vd: 'user1', 'user2').
  /// Dùng cho trường hợp tên field lưu trong Firestore khác nickname.
  Future<void> pushLocation({
    required String code,
    required String field, // 'user1' | 'user2'
    required double lat,
    required double lng,
  }) {
    return _db.collection(_collection).doc(code).update({
      '$field.location': {'lat': lat, 'lng': lng},
      '$field.lastActive': FieldValue.serverTimestamp(),
    }).timeout(_callTimeout);
  }

  // ---------- WRITE: Pet ----------

  /// Cập nhật toàn bộ pet.
  Future<void> updatePet(String code, PetState pet) {
    return _db.collection(_collection).doc(code).update({
      'pet': pet.toMap(),
    }).timeout(_callTimeout);
  }

  /// Cho pet ăn: tăng hunger, +exp, auto level-up.
  Future<PetState> feedPet(String code, PetState pet) async {
    final updated = _feedPetLogic(pet);
    await updatePet(code, updated);
    return updated;
  }

  /// Chơi với pet: tăng happiness, +exp.
  Future<PetState> playWithPet(String code, PetState pet) async {
    final updated = _playPetLogic(pet);
    await updatePet(code, updated);
    return updated;
  }

  // ---------- WRITE: Premium & Gamification ----------

  /// Kích hoạt premium (test mode).
  Future<void> activatePremium(String code) {
    return _db.collection(_collection).doc(code).update({
      'isPremium': true,
    }).timeout(_callTimeout);
  }

  /// Làm thử thách thân mật: +5 intimacyScore, +1 streakDays.
  Future<void> doIntimacyChallenge(String code) {
    return _db.collection(_collection).doc(code).update({
      'intimacyScore': FieldValue.increment(5),
      'streakDays': FieldValue.increment(1),
    }).timeout(_callTimeout);
  }

  /// Love Touch: +5 intimacyScore.
  Future<void> doLoveTouch(String code) {
    return _db.collection(_collection).doc(code).update({
      'intimacyScore': FieldValue.increment(5),
    }).timeout(_callTimeout);
  }

  /// Xem video nhận thưởng: +10 intimacyScore.
  Future<void> doVideoReward(String code) {
    return _db.collection(_collection).doc(code).update({
      'intimacyScore': FieldValue.increment(10),
    }).timeout(_callTimeout);
  }

  /// Reset streak ngày mới (gọi 1 lần/ngày).
  Future<void> dailyStreakReset(String code) {
    return _db.collection(_collection).doc(code).update({
      'streakDays': FieldValue.increment(1),
    }).timeout(_callTimeout);
  }

  // ---------- WRITE: Couple ----------

  /// Patch 1 phần field của document.
  Future<void> patchCouple(String code, Map<String, dynamic> patch) {
    return _db.collection(_collection).doc(code).update(patch).timeout(_callTimeout);
  }

  // ---------- HELPERS ----------

  /// Kiểm tra document có thiếu field cần thiết không.
  bool _needsPatch(Map<String, dynamic> data) {
    return data['user1'] == null ||
        data['user2'] == null ||
        data['pet'] == null ||
        data['startDate'] == null;
  }

  /// Tự động patch những field còn thiếu.
  Future<void> _patchMissing(String code, Map<String, dynamic> data) async {
    final patch = <String, dynamic>{};
    if (data['user1'] == null) {
      patch['user1'] = const UserInfo(name: 'Bạn').toMap();
    }
    if (data['user2'] == null) {
      patch['user2'] = const UserInfo(name: 'Người yêu').toMap();
    }
    if (data['pet'] == null) {
      patch['pet'] = const PetState().toMap();
    }
    if (data['startDate'] == null) {
      patch['startDate'] = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 30)),
      );
    }
    if (patch.isNotEmpty) {
      await _db.collection(_collection).doc(code).update(patch).timeout(_callTimeout);
    }
  }

  /// Tạo document mẫu nếu chưa tồn tại.
  Future<void> _ensureDocument(String code) async {
    final snap = await _db.collection(_collection).doc(code).get();
    if (snap.exists) return;

    await _db.collection(_collection).doc(code).set({
      'code': code,
      'status': 'paired',
      'startDate': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 30)),
      ),
      'isPremium': false,
      'streakDays': 0,
      'intimacyScore': 0,
      'user1': const UserInfo(name: 'Bạn').toMap(),
      'user2': const UserInfo(name: 'Người yêu').toMap(),
      'pet': const PetState().toMap(),
    }).timeout(_callTimeout);
  }

  static PetState _feedPetLogic(PetState pet) {
    final newHunger = (pet.hunger + 0.20).clamp(0.0, 1.0);
    int newExp = pet.exp + 15;
    int newLevel = pet.level;
    while (newExp >= 100) {
      newExp -= 100;
      newLevel += 1;
    }
    return pet.copyWith(
      hunger: newHunger,
      exp: newExp,
      level: newLevel,
      lastFed: DateTime.now(),
    );
  }

  static PetState _playPetLogic(PetState pet) {
    final newHappy = (pet.happiness + 0.25).clamp(0.0, 1.0);
    int newExp = pet.exp + 10;
    int newLevel = pet.level;
    while (newExp >= 100) {
      newExp -= 100;
      newLevel += 1;
    }
    return pet.copyWith(
      happiness: newHappy,
      exp: newExp,
      level: newLevel,
      lastPlayed: DateTime.now(),
    );
  }
}
