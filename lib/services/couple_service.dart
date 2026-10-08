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

  // ---------------- READ (Realtime) ----------------

  /// Stream document của cặp đôi. Phát `CoupleData` mỗi khi Firestore thay đổi.
  Stream<CoupleData> watchCouple(String code) {
    return _db
        .collection(_collection)
        .doc(code)
        .snapshots()
        .map(CoupleData.fromDoc);
  }

  Future<CoupleData?> getOnce(String code) async {
    final snap = await _db.collection(_collection).doc(code).get();
    if (!snap.exists) return null;
    return CoupleData.fromDoc(snap);
  }

  // ---------------- WRITE ----------------

  /// Cập nhật ngày bắt đầu yêu.
  Future<void> updateStartDate(String code, DateTime date) {
    return _db.collection(_collection).doc(code).update({
      'startDate': Timestamp.fromDate(date),
    });
  }

  /// Cập nhật thông tin 1 user (user1 hoặc user2).
  Future<void> updateUser(String code, {required bool isUser1, required UserInfo user}) {
    return _db.collection(_collection).doc(code).update({
      isUser1 ? 'user1' : 'user2': user.toMap(),
    });
  }

  /// Cập nhật pet (dùng cho mọi tương tác: cho ăn, xoa đầu, v.v.).
  Future<void> updatePet(String code, PetState pet) {
    return _db.collection(_collection).doc(code).update({
      'pet': pet.toMap(),
    });
  }

  /// Patch pet 1 phần: merge với pet hiện tại rồi ghi lại.
  Future<void> patchPet(String code, Map<String, dynamic> patch) {
    return _db.collection(_collection).doc(code).update({
      'pet': patch,
    });
  }

  // ---------------- HELPER: Pet interactions ----------------

  /// Cho pet ăn: tăng hunger, +exp.
  static PetState feedPet(PetState pet) {
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

  /// Xoa đầu / chơi đùa: tăng happiness, +exp.
  static PetState playWithPet(PetState pet) {
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