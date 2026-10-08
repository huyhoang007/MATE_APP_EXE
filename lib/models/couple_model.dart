import 'package:cloud_firestore/cloud_firestore.dart';

/// ============================================================
/// Models cho Couple Home - Realtime Firestore
///
/// Cấu trúc `couples/{code}`:
///   startDate: Timestamp
///   user1: { name, avatarUrl, isOnline, batteryLevel, lastActive }
///   user2: { name, avatarUrl, isOnline, batteryLevel, lastActive }
///   pet:    { name, level, exp, hunger, happiness, lastFed, lastPlayed }
/// ============================================================

class UserInfo {
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final int batteryLevel; // 0..100
  final double? distanceKm;
  final DateTime? lastActive;

  const UserInfo({
    required this.name,
    this.avatarUrl,
    this.isOnline = false,
    this.batteryLevel = 100,
    this.distanceKm,
    this.lastActive,
  });

  factory UserInfo.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const UserInfo(name: 'Người yêu');
    return UserInfo(
      name: (data['name'] as String?) ?? 'Người yêu',
      avatarUrl: data['avatarUrl'] as String?,
      isOnline: (data['isOnline'] as bool?) ?? false,
      batteryLevel: ((data['batteryLevel'] as num?)?.toInt()) ?? 100,
      distanceKm: (data['distanceKm'] as num?)?.toDouble(),
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'isOnline': isOnline,
        'batteryLevel': batteryLevel,
        if (distanceKm != null) 'distanceKm': distanceKm,
        'lastActive': FieldValue.serverTimestamp(),
      };

  UserInfo copyWith({
    String? name,
    String? avatarUrl,
    bool? isOnline,
    int? batteryLevel,
    double? distanceKm,
  }) {
    return UserInfo(
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      distanceKm: distanceKm ?? this.distanceKm,
      lastActive: lastActive,
    );
  }
}

class PetState {
  final String name;
  final int level;
  final int exp; // 0..100 (reset khi lên level)
  final double hunger; // 0..1, 1 = no
  final double happiness; // 0..1, 1 = vui
  final DateTime? lastFed;
  final DateTime? lastPlayed;

  const PetState({
    this.name = 'Mochi',
    this.level = 1,
    this.exp = 0,
    this.hunger = 0.5,
    this.happiness = 0.5,
    this.lastFed,
    this.lastPlayed,
  });

  factory PetState.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const PetState();
    return PetState(
      name: (data['name'] as String?) ?? 'Mochi',
      level: ((data['level'] as num?)?.toInt()) ?? 1,
      exp: ((data['exp'] as num?)?.toInt()) ?? 0,
      hunger: ((data['hunger'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
      happiness:
          ((data['happiness'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
      lastFed: (data['lastFed'] as Timestamp?)?.toDate(),
      lastPlayed: (data['lastPlayed'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'level': level,
        'exp': exp,
        'hunger': hunger,
        'happiness': happiness,
        if (lastFed != null) 'lastFed': Timestamp.fromDate(lastFed!),
        if (lastPlayed != null) 'lastPlayed': Timestamp.fromDate(lastPlayed!),
      };

  PetState copyWith({
    String? name,
    int? level,
    int? exp,
    double? hunger,
    double? happiness,
    DateTime? lastFed,
    DateTime? lastPlayed,
  }) {
    return PetState(
      name: name ?? this.name,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      hunger: hunger ?? this.hunger,
      happiness: happiness ?? this.happiness,
      lastFed: lastFed ?? this.lastFed,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }
}

class CoupleData {
  final String code;
  final DateTime startDate;
  final UserInfo user1;
  final UserInfo user2;
  final PetState pet;

  const CoupleData({
    required this.code,
    required this.startDate,
    required this.user1,
    required this.user2,
    required this.pet,
  });

  factory CoupleData.fromDoc(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? {};
    return CoupleData(
      code: (data['code'] as String?) ?? snap.id,
      startDate:
          (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      user1: UserInfo.fromMap(data['user1'] as Map<String, dynamic>?),
      user2: UserInfo.fromMap(data['user2'] as Map<String, dynamic>?),
      pet: PetState.fromMap(data['pet'] as Map<String, dynamic>?),
    );
  }

  int get daysLoved {
    final now = DateTime.now();
    return now.difference(startDate).inDays.abs();
  }
}