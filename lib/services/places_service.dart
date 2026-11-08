import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/date_planner/date_models.dart';

/// ============================================================
/// PlacesService - Danh mục địa điểm thật trên Firestore.
///
/// Collection: `places/{placeId}`  (dùng chung cho Date Planner + Affiliate)
///   {
///     name: String
///     category: 'eat' | 'movie' | 'play' | 'outdoor' | 'gift'
///     area: String            (vd: "Quận 1")
///     address: String
///     lat, lng: double        (để mở bản đồ điều hướng)
///     imageUrl: String?       (ảnh trên Storage/CDN)
///     imageAsset: String?     (fallback asset nội bộ)
///     pricePerTwo: int        (VNĐ cho 2 người)
///     priceText: String       (vd: "45K - 90K / người")
///     durationMin: int
///     moods: [String]         (id của DateMood)
///     slots: [String]         ('Sáng' | 'Chiều' | 'Tối')
///     hours: String?
///     description: String
///     rating: double          (0..5)
///     reviewCount: int
///     isPartner: bool
///     affiliateUrl: String?
///     active: bool
///   }
///
/// Nếu collection rỗng (chưa seed) → service dùng fallback tĩnh để app
/// không trống, nhưng ghi rõ nguồn `fromCache = true` để UI hiển thị
/// "dữ liệu chưa xác minh" thay vì bịa số liệu.
/// ============================================================

class PlacesService {
  PlacesService._();
  static final PlacesService instance = PlacesService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'places';
  static const Duration _timeout = Duration(seconds: 12);

  List<DatePlace>? _cache;
  bool _fromCache = false;

  /// True nếu dữ liệu hiện tại đến từ fallback tĩnh (chưa seed Firestore).
  bool get isFallback => _fromCache;

  /// Stream danh mục địa điểm realtime (dùng cho cả Date Planner & Affiliate).
  Stream<List<DatePlace>> watchPlaces() {
    return _db.collection(_collection).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => _toPlace(d.id, d.data() ?? {}))
          .where((p) => p.name.isNotEmpty)
          .toList();
      if (list.isNotEmpty) {
        _cache = list;
        _fromCache = false;
        return list;
      }
      // Firestore chưa seed → dùng fallback tĩnh (dữ liệu địa điểm thật).
      _fromCache = true;
      return _cache ?? fallbackPlaces;
    });
  }

  /// Lấy 1 lần (dùng khi cần dữ liệu không realtime).
  Future<List<DatePlace>> fetchPlaces() async {
    try {
      final snap = await _db
          .collection(_collection)
          .where('active', isEqualTo: true)
          .get()
          .timeout(_timeout);
      final list = snap.docs
          .map((d) => _toPlace(d.id, d.data() ?? {}))
          .where((p) => p.name.isNotEmpty)
          .toList();
      if (list.isNotEmpty) {
        _cache = list;
        _fromCache = false;
        return list;
      }
    } catch (_) {
      // Lỗi mạng / rules → dùng cache hoặc fallback.
    }
    _fromCache = true;
    return _cache ?? fallbackPlaces;
  }

  /// Lấy theo category (cho tab Affiliate).
  Future<List<DatePlace>> fetchByCategory(String categoryId) async {
    final all = await fetchPlaces();
    return all.where((p) => p.category.id == categoryId).toList();
  }

  DatePlace _toPlace(String id, Map<String, dynamic> d) {
    DateCategory cat(DateCategory fallback) {
      final raw = d['category'] as String?;
      if (raw == null) return fallback;
      return DateCategory.values.firstWhere(
        (c) => c.id == raw,
        orElse: () => fallback,
      );
    }

    final moods = (d['moods'] as List?)
            ?.map((e) => DateMood.values.firstWhere(
                  (m) => m.id == e,
                  orElse: () => DateMood.chill,
                ))
            .toList() ??
        const <DateMood>[DateMood.chill];

    final slots = (d['slots'] as List?)
            ?.map((e) => TimeSlot.values.firstWhere(
                  (s) => s.label == e,
                  orElse: () => TimeSlot.afternoon,
                ))
            .toList() ??
        const <TimeSlot>[TimeSlot.afternoon];

    return DatePlace(
      id: id,
      name: (d['name'] as String?) ?? '',
      category: cat(DateCategory.eat),
      area: (d['area'] as String?) ?? '',
      address: (d['address'] as String?) ?? '',
      imageAsset: (d['imageAsset'] as String?) ?? 'assets/images/affiliate/eat.jpg',
      imageUrl: d['imageUrl'] as String?,
      pricePerTwo: ((d['pricePerTwo'] as num?)?.toInt()) ?? 0,
      priceText: (d['priceText'] as String?) ?? '',
      durationMin: ((d['durationMin'] as num?)?.toInt()) ?? 60,
      moods: moods,
      slots: slots,
      description: (d['description'] as String?) ?? '',
      hours: d['hours'] as String?,
      isPartner: (d['isPartner'] as bool?) ?? false,
      affiliateUrl: d['affiliateUrl'] as String?,
      rating: ((d['rating'] as num?)?.toDouble()) ?? 0,
      reviewCount: ((d['reviewCount'] as num?)?.toInt()) ?? 0,
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
    );
  }
}
