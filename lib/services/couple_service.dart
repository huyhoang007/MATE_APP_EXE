import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/couple_model.dart';
import 'auth_service.dart';

/// ============================================================
/// CoupleService - Quản lý dữ liệu cặp đôi realtime qua Firestore.
///
/// Tất cả thay đổi đều sync 2 chiều giữa 2 người dùng.
///
/// Cấu trúc:
///   couples/{code}                      -> document chính
///   couples/{code}/members/{uid}        -> thành viên
///   couples/{code}/moments/{id}         -> khoảnh khắc
///   couples/{code}/messages/{id}        -> tin nhắn
///   couples/{code}/notifications/{id}   -> thông báo
///   couples/{code}/wallet/{id}          -> giao dịch xu
///   couples/{code}/quests/{id}          -> thử thách
///   couples/{code}/inventory/{id}       -> vật phẩm
///   couples/{code}/diaries/{dateKey}    -> nhật ký
///   couples/{code}/checkins/{id}        -> check-in
///   couples/{code}/games/{id}           -> kết quả mini-game
/// ============================================================

class CoupleService {
  CoupleService._();
  static final CoupleService instance = CoupleService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'couples';
  static const Duration _callTimeout = Duration(seconds: 12);

  DocumentReference<Map<String, dynamic>> _coupleRef(String code) =>
      _db.collection(_collection).doc(code);

  // ---------- READ ----------

  /// Stream document của cặp đôi. Phát `CoupleData` mỗi khi Firestore thay đổi.
  Stream<CoupleData> watchCouple(String code) {
    return _coupleRef(code).snapshots().map((snap) {
      if (!snap.exists) {
        return CoupleData(
          code: code,
          startDate: DateTime.now(),
          user1: const UserInfo(name: 'Bạn'),
          user2: const UserInfo(name: 'Người yêu'),
          pet: const PetState(),
          currentUid: AuthService.instance.uid,
        );
      }
      return CoupleData.fromDoc(snap, currentUid: AuthService.instance.uid);
    });
  }

  Future<CoupleData?> getOnce(String code) async {
    final snap = await _coupleRef(code).get();
    if (!snap.exists) return null;
    return CoupleData.fromDoc(snap, currentUid: AuthService.instance.uid);
  }

  // ---------- WRITE: Date ----------

  /// Cập nhật ngày bắt đầu yêu.
  Future<void> updateStartDate(String code, DateTime date) {
    return _coupleRef(code).update({
      'startDate': Timestamp.fromDate(date),
    }).timeout(_callTimeout);
  }

  // ---------- WRITE: User ----------

  /// Cập nhật thông tin 1 user theo UID.
  Future<void> updateUser(String code, {required String uid, required UserInfo user}) {
    return _coupleRef(code).update({
      'members.$uid': {
        ...user.toMap(),
        'uid': uid,
      },
    }).timeout(_callTimeout);
  }

  /// Cập nhật tên hiển thị của 1 user.
  Future<void> updateDisplayName(String code, String uid, String name) {
    return _coupleRef(code).update({
      'members.$uid.name': name,
    }).timeout(_callTimeout);
  }

  /// Cập nhật avatar của 1 user.
  Future<void> updateAvatar(String code, String uid, String avatarUrl) {
    return _coupleRef(code).update({
      'members.$uid.avatarUrl': avatarUrl,
    }).timeout(_callTimeout);
  }

  /// Cập nhật vị trí của 1 user (theo UID).
  Future<void> updateLocation(String code, {required String uid, required GeoLocation loc}) {
    return _coupleRef(code).update({
      'members.$uid.location': loc.toMap(),
      'members.$uid.lastActive': FieldValue.serverTimestamp(),
    }).timeout(_callTimeout);
  }

  /// Push vị trí bằng tên field trực tiếp (vd: 'members.abc123').
  /// Dùng cho trường hợp tên field lưu trong Firestore khác nickname.
  Future<void> pushLocation({
    required String code,
    required String field, // 'members.{uid}'
    required double lat,
    required double lng,
  }) {
    return _coupleRef(code).update({
      '$field.location': {'lat': lat, 'lng': lng},
      '$field.lastActive': FieldValue.serverTimestamp(),
    }).timeout(_callTimeout);
  }

  /// Cập nhật trạng thái online + pin của 1 user.
  Future<void> updatePresence(
    String code, {
    required String uid,
    required bool isOnline,
    int? batteryLevel,
    int? stayMinutes,
  }) {
    final patch = <String, dynamic>{
      'members.$uid.isOnline': isOnline,
      'members.$uid.lastActive': FieldValue.serverTimestamp(),
    };
    if (batteryLevel != null) patch['members.$uid.batteryLevel'] = batteryLevel;
    if (stayMinutes != null) patch['members.$uid.stayMinutes'] = stayMinutes;
    return _coupleRef(code).update(patch).timeout(_callTimeout);
  }

  // ---------- WRITE: Pet ----------

  /// Cập nhật toàn bộ pet.
  Future<void> updatePet(String code, PetState pet) {
    return _coupleRef(code).update({
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

  /// Đổi tên pet.
  Future<void> renamePet(String code, String name) {
    return _coupleRef(code).update({
      'pet.name': name,
    }).timeout(_callTimeout);
  }

  // ---------- WRITE: Premium & Gamification ----------

  /// Kích hoạt premium.
  Future<void> activatePremium(String code) {
    return _coupleRef(code).update({
      'isPremium': true,
    }).timeout(_callTimeout);
  }

  /// Làm thử thách thân mật: +5 intimacyScore, +1 streakDays.
  Future<void> doIntimacyChallenge(String code) {
    return _coupleRef(code).update({
      'intimacyScore': FieldValue.increment(5),
      'streakDays': FieldValue.increment(1),
    }).timeout(_callTimeout);
  }

  /// Love Touch: +5 intimacyScore.
  Future<void> doLoveTouch(String code) {
    return _coupleRef(code).update({
      'intimacyScore': FieldValue.increment(5),
    }).timeout(_callTimeout);
  }

  /// Xem video nhận thưởng: +10 intimacyScore.
  Future<void> doVideoReward(String code) {
    return _coupleRef(code).update({
      'intimacyScore': FieldValue.increment(10),
    }).timeout(_callTimeout);
  }

  /// Reset streak ngày mới (gọi 1 lần/ngày).
  Future<void> dailyStreakReset(String code) {
    return _coupleRef(code).update({
      'streakDays': FieldValue.increment(1),
    }).timeout(_callTimeout);
  }

  /// Cộng/trừ xu MATE (dùng FieldValue.increment để atomic).
  Future<void> addCoins(String code, int amount) {
    return _coupleRef(code).update({
      'coins': FieldValue.increment(amount),
    }).timeout(_callTimeout);
  }

  // ---------- WRITE: Couple ----------

  /// Patch 1 phần field của document.
  Future<void> patchCouple(String code, Map<String, dynamic> patch) {
    return _coupleRef(code).update(patch).timeout(_callTimeout);
  }

  // ---------- HELPERS ----------

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
