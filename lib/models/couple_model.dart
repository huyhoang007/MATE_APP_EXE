import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

/// ============================================================
/// Models cho Couple Home - Realtime Firestore
///
/// Cấu trúc `couples/{code}`:
///   code: String
///   startDate: Timestamp
///   status: String "waiting" | "paired"
///   isPremium: bool
///   streakDays: int
///   intimacyScore: int
///   user1: { name, avatarUrl, isOnline, batteryLevel, lastActive,
///             deviceId, location: { lat, lng } }
///   user2: { name, avatarUrl, isOnline, batteryLevel, lastActive,
///             deviceId, location: { lat, lng } }
///   pet:    { name, level, exp, hunger, happiness, lastFed, lastPlayed }
/// ============================================================

// ---------- Location ----------

class GeoLocation {
  final double lat;
  final double lng;

  const GeoLocation({required this.lat, required this.lng});

  factory GeoLocation.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const GeoLocation(lat: 0, lng: 0);
    return GeoLocation(
      lat: (data['lat'] as num?)?.toDouble() ?? 0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {'lat': lat, 'lng': lng};

  LatLng toLatLng() => LatLng(lat, lng);

  bool get isValid => lat != 0 && lng != 0;

  /// Khoảng cách Haversine (km) từ điểm này tới điểm khác.
  double distanceKmTo(GeoLocation other) {
    const R = 6371.0; // Bán kính trái đất km
    final dLat = _toRad(other.lat - lat);
    final dLng = _toRad(other.lng - lng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat)) *
            math.cos(_toRad(other.lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}

// ---------- UserInfo ----------

class UserInfo {
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final int batteryLevel; // 0..100
  final GeoLocation location;
  final DateTime? lastActive;
  final int? stayMinutes; // Phút ở lại (do client tự tính hoặc set từ server)

  const UserInfo({
    required this.name,
    this.avatarUrl,
    this.isOnline = false,
    this.batteryLevel = 100,
    this.location = const GeoLocation(lat: 0, lng: 0),
    this.lastActive,
    this.stayMinutes,
  });

  factory UserInfo.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const UserInfo(name: 'Người yêu');
    return UserInfo(
      name: (data['name'] as String?) ?? 'Người yêu',
      avatarUrl: data['avatarUrl'] as String?,
      isOnline: (data['isOnline'] as bool?) ?? false,
      batteryLevel: ((data['batteryLevel'] as num?)?.toInt()) ?? 100,
      location: GeoLocation.fromMap(data['location'] as Map<String, dynamic>?),
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      stayMinutes: (data['stayMinutes'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'isOnline': isOnline,
        'batteryLevel': batteryLevel,
        'location': location.toMap(),
        'lastActive': FieldValue.serverTimestamp(),
        if (stayMinutes != null) 'stayMinutes': stayMinutes,
      };

  UserInfo copyWith({
    String? name,
    String? avatarUrl,
    bool? isOnline,
    int? batteryLevel,
    GeoLocation? location,
    DateTime? lastActive,
    int? stayMinutes,
  }) {
    return UserInfo(
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      location: location ?? this.location,
      lastActive: lastActive ?? this.lastActive,
      stayMinutes: stayMinutes ?? this.stayMinutes,
    );
  }

  /// Phút online gần đây. Ưu tiên `stayMinutes` (server set), fallback `lastActive`.
  int get minutesAgo {
    if (stayMinutes != null) return stayMinutes!;
    if (lastActive == null) return 0;
    return DateTime.now().difference(lastActive!).inMinutes;
  }
}

// ---------- PetState ----------

class PetState {
  final String name;
  final int level;
  final int exp; // 0..99 (reset khi lên level)
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

// ---------- CoupleData ----------

class CoupleData {
  final String code;
  final DateTime startDate;
  final UserInfo user1;
  final UserInfo user2;
  final PetState pet;
  final bool isPremium;
  final int streakDays;
  final int intimacyScore;

  const CoupleData({
    required this.code,
    required this.startDate,
    required this.user1,
    required this.user2,
    required this.pet,
    this.isPremium = false,
    this.streakDays = 0,
    this.intimacyScore = 0,
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
      isPremium: (data['isPremium'] as bool?) ?? false,
      streakDays: ((data['streakDays'] as num?)?.toInt()) ?? 0,
      intimacyScore: ((data['intimacyScore'] as num?)?.toInt()) ?? 0,
    );
  }

  int get daysLoved {
    return DateTime.now().difference(startDate).inDays.abs();
  }

  /// Khoảng cách 2 người (km). Trả về null nếu chưa có vị trí.
  double? get distanceKm {
    if (!user1.location.isValid || !user2.location.isValid) return null;
    return user1.location.distanceKmTo(user2.location);
  }
}
