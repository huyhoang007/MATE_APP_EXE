import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

/// ============================================================
/// Models cho Couple Home - Realtime Firestore
///
/// Cấu trúc `couples/{code}` (sau khi chuyển sang Firebase Anonymous Auth):
///   code: String
///   startDate: Timestamp
///   status: String "waiting" | "paired"
///   creatorUid: String          - UID người tạo phòng
///   partnerUid: String?         - UID người tham gia
///   members: { uid: { name, avatarUrl, isOnline, batteryLevel,
///                      lastActive, location: { lat, lng }, stayMinutes } }
///   isPremium: bool
///   streakDays: int
///   intimacyScore: int
///   pet: { name, level, exp, hunger, happiness, lastFed, lastPlayed }
//
///
/// Vì `members` là map theo UID nên 2 người có thể vào/ra bất kỳ lúc nào
/// mà vẫn giữ đúng dữ liệu của mình — không phụ thuộc thứ tự user1/user2.
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

  /// UID của user trong Firestore (null với dữ liệu legacy).
  final String? uid;
  final String? avatarUrl;
  final bool isOnline;
  final int batteryLevel; // 0..100
  final GeoLocation location;
  final DateTime? lastActive;
  final int? stayMinutes; // Phút ở lại (do client tự tính hoặc set từ server)

  const UserInfo({
    required this.name,
    this.uid,
    this.avatarUrl,
    this.isOnline = false,
    this.batteryLevel = 100,
    this.location = const GeoLocation(lat: 0, lng: 0),
    this.lastActive,
    this.stayMinutes,
  });

  factory UserInfo.fromMap(Map<String, dynamic>? data, {String? uid}) {
    if (data == null) {
      return UserInfo(name: 'Người yêu', uid: uid);
    }
    return UserInfo(
      name: (data['name'] as String?) ?? 'Người yêu',
      uid: (data['uid'] as String?) ?? uid,
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
        if (uid != null) 'uid': uid,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'isOnline': isOnline,
        'batteryLevel': batteryLevel,
        'location': location.toMap(),
        'lastActive': FieldValue.serverTimestamp(),
        if (stayMinutes != null) 'stayMinutes': stayMinutes,
      };

  UserInfo copyWith({
    String? name,
    String? uid,
    String? avatarUrl,
    bool? isOnline,
    int? batteryLevel,
    GeoLocation? location,
    DateTime? lastActive,
    int? stayMinutes,
  }) {
    return UserInfo(
      name: name ?? this.name,
      uid: uid ?? this.uid,
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

  /// Tất cả thành viên theo UID.
  final Map<String, UserInfo> members;

  /// UID của chính user đang xem (dùng để biết user1/user2 là ai).
  final String? currentUid;

  /// Số xu MATE hiện có của cặp đôi.
  final int coins;

  const CoupleData({
    required this.code,
    required this.startDate,
    required this.user1,
    required this.user2,
    required this.pet,
    this.isPremium = false,
    this.streakDays = 0,
    this.intimacyScore = 0,
    this.members = const {},
    this.currentUid,
    this.coins = 0,
  });

  factory CoupleData.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> snap, {
    String? currentUid,
  }) {
    final data = snap.data() ?? {};

    // ---- Đọc members map (cấu trúc mới) ----
    final members = <String, UserInfo>{};
    final rawMembers = data['members'];
    if (rawMembers is Map) {
      for (final entry in rawMembers.entries) {
        final uid = entry.key as String;
        final value = entry.value;
        if (value is Map) {
          members[uid] = UserInfo.fromMap(
            Map<String, dynamic>.from(value),
            uid: uid,
          );
        }
      }
    }

    // ---- Legacy fallback: user1 / user2 ----
    final legacyUser1 =
        UserInfo.fromMap(data['user1'] as Map<String, dynamic>?);
    final legacyUser2 =
        UserInfo.fromMap(data['user2'] as Map<String, dynamic>?);
    if (members.isEmpty && (legacyUser1.name != 'Người yêu' || legacyUser2.name != 'Người yêu')) {
      members['legacy_1'] = legacyUser1;
      members['legacy_2'] = legacyUser2;
    }

    final creatorUid = data['creatorUid'] as String?;

    // Sắp xếp: chính mình là user1, người kia là user2 (dễ cho UI).
    UserInfo me;
    UserInfo partner;
    if (currentUid != null && members.containsKey(currentUid)) {
      me = members[currentUid]!;
      partner = _otherThan(members, currentUid);
    } else if (creatorUid != null && members.containsKey(creatorUid)) {
      me = members[creatorUid]!;
      partner = _otherThan(members, creatorUid);
    } else if (members.isNotEmpty) {
      final list = members.values.toList();
      me = list.first;
      partner = list.length > 1 ? list[1] : const UserInfo(name: 'Người yêu');
    } else {
      me = legacyUser1;
      partner = legacyUser2;
    }

    return CoupleData(
      code: (data['code'] as String?) ?? snap.id,
      startDate:
          (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      user1: me,
      user2: partner,
      pet: PetState.fromMap(data['pet'] as Map<String, dynamic>?),
      isPremium: (data['isPremium'] as bool?) ?? false,
      streakDays: ((data['streakDays'] as num?)?.toInt()) ?? 0,
      intimacyScore: ((data['intimacyScore'] as num?)?.toInt()) ?? 0,
      members: members,
      currentUid: currentUid,
      coins: ((data['coins'] as num?)?.toInt()) ?? 0,
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

  /// UID của người kia (partner).
  String? get partnerUid => user2.uid;

  /// UID của chính mình.
  String? get myUid => user1.uid;

  /// Lấy thành viên khác (ngoài `uid`) trong map members.
  static UserInfo _otherThan(Map<String, UserInfo> members, String uid) {
    for (final entry in members.entries) {
      if (entry.key != uid) return entry.value;
    }
    return const UserInfo(name: 'Người yêu');
  }
}
