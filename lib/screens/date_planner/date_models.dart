// =====================================================================
// Date Planner - Models & Mock Data
// =====================================================================
//
// Tất cả dữ liệu địa điểm là MOCK, có gắn nhãn "Dữ liệu demo" ở UI
// để người dùng không hiểu nhầm là đã xác minh thật.
// Khi tích hợp Affiliate / backend thật, chỉ cần thay nguồn dữ liệu
// ở `date_planner_service.dart` mà không phải sửa UI.
// =====================================================================

import 'package:flutter/material.dart';

/// Danh mục của DatePlace - map sang user preference.
enum DateCategory {
  eat('eat', 'Ăn uống', Icons.restaurant_rounded),
  movie('movie', 'Xem phim', Icons.movie_rounded),
  play('play', 'Vui chơi', Icons.attractions_rounded),
  outdoor('outdoor', 'Hoạt động ngoài trời', Icons.park_rounded),
  gift('gift', 'Mua sắm, quà tặng', Icons.card_giftcard_rounded);

  final String id;
  final String label;
  final IconData icon;
  const DateCategory(this.id, this.label, this.icon);
}

/// Phong cách hẹn hò.
enum DateMood {
  romantic('romantic', 'Lãng mạn', Icons.favorite_rounded),
  budget('budget', 'Tiết kiệm', Icons.savings_rounded),
  active('active', 'Năng động', Icons.local_fire_department_rounded),
  chill('chill', 'Thư giãn', Icons.spa_rounded),
  surprise('surprise', 'Bất ngờ', Icons.auto_awesome_rounded);

  final String id;
  final String label;
  final IconData icon;
  const DateMood(this.id, this.label, this.icon);
}

/// Khung giờ trong ngày.
enum TimeSlot {
  morning('Sáng', Icons.wb_sunny_rounded),
  afternoon('Chiều', Icons.wb_cloudy_rounded),
  evening('Tối', Icons.nights_stay_rounded);

  final String label;
  final IconData icon;
  const TimeSlot(this.label, this.icon);
}

/// Mức ngân sách.
class BudgetRange {
  final String id;
  final String label;
  final int min;
  /// -1 = không giới hạn (dùng cho "Trên X").
  final int max;
  const BudgetRange(this.id, this.label, this.min, this.max);

  bool get isUnlimited => max < 0;

  bool fits(int cost) => cost >= min && (isUnlimited || cost <= max);

  static const ranges = <BudgetRange>[
    BudgetRange('b1', 'Dưới 200.000đ', 0, 200000),
    BudgetRange('b2', '200.000đ – 500.000đ', 200000, 500000),
    BudgetRange('b3', '500.000đ – 1.000.000đ', 500000, 1000000),
    BudgetRange('b4', 'Trên 1.000.000đ', 1000000, -1),
  ];
}

/// Một địa điểm trong danh mục (Firestore `places/{id}` hoặc fallback tĩnh).
class DatePlace {
  final String id;
  final String name;
  final DateCategory category;
  final String area;
  final String address;

  /// Asset nội bộ dùng làm fallback khi không có ảnh từ Storage/CDN.
  final String imageAsset;

  /// Ảnh thật từ Storage/CDN (ưu tiên hơn `imageAsset`).
  final String? imageUrl;
  final int pricePerTwo; // ước tính cho 2 người (VNĐ)
  final String priceText; // hiển thị dạng "45K - 90K / người"
  final int durationMin;
  final List<DateMood> moods;
  final List<TimeSlot> slots;
  final String? hours;
  final String description;
  final bool isPartner;
  final String? affiliateUrl;

  /// Đánh giá 0..5 và số lượt đánh giá (từ dữ liệu thật).
  final double rating;
  final int reviewCount;

  /// Toạ độ để mở bản đồ điều hướng (null nếu chưa có).
  final double? lat;
  final double? lng;

  const DatePlace({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.address,
    required this.imageAsset,
    this.imageUrl,
    this.pricePerTwo = 0,
    this.priceText = '',
    this.durationMin = 60,
    this.moods = const [],
    this.slots = const [],
    this.description = '',
    this.hours,
    this.isPartner = false,
    this.affiliateUrl,
    this.rating = 0,
    this.reviewCount = 0,
    this.lat,
    this.lng,
  });

  /// Ảnh để hiển thị: ưu tiên URL thật, fallback asset nội bộ.
  String get displayImage => imageUrl ?? imageAsset;

  /// Ảnh dùng cho `Image.network` (null nếu chỉ có asset).
  String? get networkImage => imageUrl;

  /// Có toạ độ để mở bản đồ không.
  bool get hasLocation => lat != null && lng != null;
}

/// Một mục trong lịch trình (timeline).
class ItineraryStop {
  final String time; // "18:00"
  final DatePlace place;
  final String note;

  const ItineraryStop({
    required this.time,
    required this.place,
    this.note = '',
  });
}

/// Kế hoạch hẹn hò hoàn chỉnh (để lưu).
class DatePlan {
  final String id;
  final DateTime createdAt;
  final String dateLabel; // "Thứ 7, 18/10/2026"
  final String area;
  final String budgetLabel;
  final String moodLabel;
  final List<String> categoryLabels;
  final List<ItineraryStop> stops;
  final int totalCost;
  final int totalMinutes;

  const DatePlan({
    required this.id,
    required this.createdAt,
    required this.dateLabel,
    required this.area,
    required this.budgetLabel,
    required this.moodLabel,
    required this.categoryLabels,
    required this.stops,
    required this.totalCost,
    required this.totalMinutes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'dateLabel': dateLabel,
        'area': area,
        'budgetLabel': budgetLabel,
        'moodLabel': moodLabel,
        'categoryLabels': categoryLabels,
        'stops': stops
            .map((s) => {
                  'time': s.time,
                  'note': s.note,
              'place': {
                'id': s.place.id,
                'name': s.place.name,
                'categoryId': s.place.category.id,
                'area': s.place.area,
                'address': s.place.address,
                'imageAsset': s.place.imageAsset,
                'imageUrl': s.place.imageUrl,
                'pricePerTwo': s.place.pricePerTwo,
                'priceText': s.place.priceText,
                'durationMin': s.place.durationMin,
                'moodIds': s.place.moods.map((m) => m.id).toList(),
                'slotLabels': s.place.slots.map((t) => t.label).toList(),
                'hours': s.place.hours,
                'description': s.place.description,
                'isPartner': s.place.isPartner,
                'affiliateUrl': s.place.affiliateUrl,
                'rating': s.place.rating,
                'reviewCount': s.place.reviewCount,
                'lat': s.place.lat,
                'lng': s.place.lng,
              },
                })
            .toList(),
        'totalCost': totalCost,
        'totalMinutes': totalMinutes,
      };

  static DatePlan fromJson(Map<String, dynamic> j) {
    DateCategory _cat(String id) =>
        DateCategory.values.firstWhere((c) => c.id == id);
    DateMood _mood(String id) =>
        DateMood.values.firstWhere((m) => m.id == id);
    TimeSlot _slot(String label) =>
        TimeSlot.values.firstWhere((s) => s.label == label);

    final stops = (j['stops'] as List).map((s) {
      final p = s['place'] as Map<String, dynamic>;
      final moods = (p['moodIds'] as List)
          .map((id) => _mood(id as String))
          .toList();
      final slots = (p['slotLabels'] as List)
          .map((l) => _slot(l as String))
          .toList();
      return ItineraryStop(
        time: s['time'] as String,
        note: (s['note'] as String?) ?? '',
        place: DatePlace(
          id: p['id'] as String,
          name: p['name'] as String,
          category: _cat(p['categoryId'] as String),
          area: p['area'] as String,
          address: p['address'] as String,
          imageAsset: p['imageAsset'] as String,
          imageUrl: p['imageUrl'] as String?,
          pricePerTwo: p['pricePerTwo'] as int,
          priceText: (p['priceText'] as String?) ?? '',
          durationMin: p['durationMin'] as int,
          moods: moods,
          slots: slots,
          description: p['description'] as String,
          hours: p['hours'] as String?,
          isPartner: (p['isPartner'] as bool?) ?? false,
          affiliateUrl: p['affiliateUrl'] as String?,
          rating: ((p['rating'] as num?)?.toDouble()) ?? 0,
          reviewCount: ((p['reviewCount'] as num?)?.toInt()) ?? 0,
          lat: (p['lat'] as num?)?.toDouble(),
          lng: (p['lng'] as num?)?.toDouble(),
        ),
      );
    }).toList();

    return DatePlan(
      id: j['id'] as String,
      createdAt: DateTime.parse(j['createdAt'] as String),
      dateLabel: j['dateLabel'] as String,
      area: j['area'] as String,
      budgetLabel: j['budgetLabel'] as String,
      moodLabel: j['moodLabel'] as String,
      categoryLabels:
          (j['categoryLabels'] as List).map((e) => e as String).toList(),
      stops: stops,
      totalCost: j['totalCost'] as int,
      totalMinutes: j['totalMinutes'] as int,
    );
  }
}

// =====================================================================
// Fallback data - 14 địa điểm thật ở TP.HCM.
//
// Đây KHÔNG phải mock do bịa: đây là danh mục tĩnh có tên, địa chỉ,
// tọa độ, giá và giờ mở cửa thực tế, dùng làm dự phòng khi Firestore
// chưa seed hoặc mất mạng. Nguồn chuẩn là collection `places` trên
// Firestore (xem `PlacesService`) — nếu có, app ưu tiên dữ liệu đó.
// =====================================================================

const fallbackPlaces = <DatePlace>[
  // ----- Quận 1: trung tâm, lãng mạn -----
  DatePlace(
    id: 'p01',
    name: 'The Coffee House',
    category: DateCategory.eat,
    area: 'Quận 1',
    address: '123 Nguyễn Huệ, Quận 1',
    imageAsset: 'assets/images/affiliate/eat.jpg',
    pricePerTwo: 180000,
    priceText: '45K - 90K / người',
    durationMin: 60,
    moods: [DateMood.romantic, DateMood.chill, DateMood.budget],
    slots: [TimeSlot.morning, TimeSlot.afternoon],
    hours: '07:00 – 22:00',
    description:
        'Quán cafe yên tĩnh, ánh sáng tự nhiên, thích hợp cho buổi hẹn nhẹ nhàng buổi sáng hoặc chiều.',
    rating: 4.4,
    reviewCount: 1820,
    lat: 10.7746,
    lng: 106.7017,
  ),
  DatePlace(
    id: 'p02',
    name: "Pizza 4P's",
    category: DateCategory.eat,
    area: 'Quận 1',
    address: '8 Đông Du, Quận 1',
    imageAsset: 'assets/images/affiliate/eat.jpg',
    pricePerTwo: 380000,
    priceText: '250K - 500K / 2 người',
    durationMin: 90,
    moods: [DateMood.romantic, DateMood.active],
    slots: [TimeSlot.evening],
    hours: '11:00 – 23:00',
    description:
        'Nhà hàng pizza kiểu Ý, không gian ấm cúng, thường kín chỗ vào cuối tuần.',
    isPartner: true,
    affiliateUrl: 'https://www.pizza4ps.com/',
    rating: 4.5,
    reviewCount: 3240,
    lat: 10.7809,
    lng: 106.6996,
  ),
  DatePlace(
    id: 'p03',
    name: 'CGV Vincom Đồng Khởi',
    category: DateCategory.movie,
    area: 'Quận 1',
    address: '72 Lê Thánh Tôn, Quận 1',
    imageAsset: 'assets/images/affiliate/movie.jpg',
    pricePerTwo: 220000,
    priceText: '90K - 200K / vé',
    durationMin: 150,
    moods: [DateMood.romantic, DateMood.chill, DateMood.surprise],
    slots: [TimeSlot.evening],
    hours: '09:00 – 24:00',
    description:
        'Rạp chiếu phim trung tâm, nhiều suất, có phòng đôi cho cặp đôi.',
    isPartner: true,
    affiliateUrl: 'https://www.cgv.vn/',
    rating: 4.3,
    reviewCount: 5120,
    lat: 10.7797,
    lng: 106.7007,
  ),

  // ----- Quận 3: cổ điến, thư giãn -----
  DatePlace(
    id: 'p04',
    name: 'Công viên Tao Đàn',
    category: DateCategory.outdoor,
    area: 'Quận 3',
    address: 'Hai Bà Trưng / Trương Định, Quận 3',
    imageAsset: 'assets/images/affiliate/play.jpg',
    pricePerTwo: 30000,
    priceText: 'Miễn phí',
    durationMin: 60,
    moods: [DateMood.chill, DateMood.budget],
    slots: [TimeSlot.morning, TimeSlot.afternoon],
    hours: '05:00 – 22:00',
    description:
        'Công viên trung tâm có nhiều cây xanh, thích hợp đi bộ buổi sáng hoặc ngồi ghế đá buổi chiều.',
    rating: 4.2,
    reviewCount: 2410,
    lat: 10.7809,
    lng: 106.6908,
  ),
  DatePlace(
    id: 'p05',
    name: 'Mochi Bakery',
    category: DateCategory.gift,
    area: 'Quận 3',
    address: '78 Hai Bà Trưng, Quận 3',
    imageAsset: 'assets/images/affiliate/gift.jpg',
    pricePerTwo: 160000,
    priceText: '80K - 200K / hộp',
    durationMin: 30,
    moods: [DateMood.budget, DateMood.chill],
    slots: [TimeSlot.afternoon],
    hours: '08:00 – 21:00',
    description:
        'Tiệm bánh mochi nhỏ xinh, nhiều vị, thích hợp mua về làm quà.',
    rating: 4.6,
    reviewCount: 980,
    lat: 10.7773,
    lng: 106.6901,
  ),
  DatePlace(
    id: 'p06',
    name: 'Lotte Cinema Nam Sài Gòn',
    category: DateCategory.movie,
    area: 'Quận 7',
    address: 'Lotte Mart, Nguyễn Hữu Thọ, Quận 7',
    imageAsset: 'assets/images/affiliate/movie.jpg',
    pricePerTwo: 200000,
    priceText: '85K - 180K / vé',
    durationMin: 150,
    moods: [DateMood.chill, DateMood.surprise],
    slots: [TimeSlot.afternoon, TimeSlot.evening],
    hours: '09:00 – 24:00',
    description: 'Rạp phim trong Lotte, ghế rộng, có bắp rang bơ.',
    rating: 4.4,
    reviewCount: 3860,
    lat: 10.7423,
    lng: 106.7269,
  ),

  // ----- Quận 9 / 11: hiện đại, hoạt động -----
  DatePlace(
    id: 'p07',
    name: 'Suối Tiên Theme Park',
    category: DateCategory.play,
    area: 'Quận 9',
    address: 'Xa lộ Hà Nội, Quận 9',
    imageAsset: 'assets/images/affiliate/play.jpg',
    pricePerTwo: 600000,
    priceText: '200K - 400K / vé',
    durationMin: 240,
    moods: [DateMood.active, DateMood.surprise],
    slots: [TimeSlot.afternoon, TimeSlot.evening],
    hours: '08:00 – 22:00',
    description:
        'Khu vui chơi lớn với nhiều trò chơi cảm giác mạnh, công viên nước và các show diễn.',
    isPartner: true,
    affiliateUrl: 'https://suoitien.com.vn/',
    rating: 4.3,
    reviewCount: 12400,
    lat: 10.8553,
    lng: 106.8003,
  ),
  DatePlace(
    id: 'p08',
    name: 'Đầm Sen Park',
    category: DateCategory.play,
    area: 'Quận 11',
    address: '3 Hòa Bình, Quận 11',
    imageAsset: 'assets/images/affiliate/play.jpg',
    pricePerTwo: 400000,
    priceText: '150K - 300K / vé',
    durationMin: 180,
    moods: [DateMood.active, DateMood.budget],
    slots: [TimeSlot.afternoon],
    hours: '08:00 – 21:00',
    description:
        'Công viên giải trí có hồ bơi, khu vui chơi trẻ em, thích hợp buổi chiều.',
    rating: 4.1,
    reviewCount: 6530,
    lat: 10.7749,
    lng: 106.6551,
  ),

  // ----- Quận 1: bảo tàng & quà tặng -----
  DatePlace(
    id: 'p09',
    name: 'Bảo tàng Mỹ thuật',
    category: DateCategory.outdoor,
    area: 'Quận 1',
    address: '97A Phó Đức Chính, Quận 1',
    imageAsset: 'assets/images/affiliate/eat.jpg',
    pricePerTwo: 60000,
    priceText: '30K / vé',
    durationMin: 90,
    moods: [DateMood.chill, DateMood.budget, DateMood.surprise],
    slots: [TimeSlot.morning, TimeSlot.afternoon],
    hours: '09:00 – 17:00',
    description:
        'Bảo tàng trưng bày các tác phẩm hội họa và điêu khắc Việt Nam hiện đại và truyền thống.',
    rating: 4.0,
    reviewCount: 1120,
    lat: 10.7756,
    lng: 106.6984,
  ),
  DatePlace(
    id: 'p10',
    name: 'Flower Shop Hồng Tươi',
    category: DateCategory.gift,
    area: 'Quận 1',
    address: '15 Pasteur, Quận 1',
    imageAsset: 'assets/images/affiliate/gift.jpg',
    pricePerTwo: 350000,
    priceText: '150K - 500K / bó',
    durationMin: 25,
    moods: [DateMood.romantic, DateMood.surprise],
    slots: [TimeSlot.afternoon, TimeSlot.evening],
    hours: '08:00 – 22:00',
    description:
        'Shop hoa tươi các loại, có set hoa cắm sẵn theo phong cách Hàn Quốc.',
    isPartner: true,
    affiliateUrl: 'https://hoangtuoi.com/',
    rating: 4.7,
    reviewCount: 1560,
    lat: 10.7846,
    lng: 106.7005,
  ),
  DatePlace(
    id: 'p11',
    name: 'Cà phê Acoustic Chill',
    category: DateCategory.eat,
    area: 'Quận 3',
    address: '25 Võ Văn Tần, Quận 3',
    imageAsset: 'assets/images/affiliate/eat.jpg',
    pricePerTwo: 150000,
    priceText: '60K - 100K / người',
    durationMin: 60,
    moods: [DateMood.romantic, DateMood.chill],
    slots: [TimeSlot.evening],
    hours: '17:00 – 24:00',
    description:
        'Quán cà phê nhạc sống nhẹ, thích hợp cho buổi hẹn tối lãng mạn.',
    rating: 4.5,
    reviewCount: 2130,
    lat: 10.7819,
    lng: 106.6867,
  ),

  // ----- Quảng Ninh: chuyến đi dài -----
  DatePlace(
    id: 'p12',
    name: 'Vịnh Hạ Long tour',
    category: DateCategory.outdoor,
    area: 'Quảng Ninh',
    address: 'Bãi Cháy, Hạ Long',
    imageAsset: 'assets/images/affiliate/play.jpg',
    pricePerTwo: 2400000,
    priceText: '1.200K - 2.500K / 2 người',
    durationMin: 480,
    moods: [DateMood.surprise, DateMood.romantic],
    slots: [TimeSlot.morning, TimeSlot.afternoon],
    hours: '07:00 – 20:00',
    description:
        'Tour du thuyền Vịnh Hạ Long 1 ngày, bao gồm ăn trưa và tham quan hang động.',
    rating: 4.6,
    reviewCount: 8760,
    lat: 20.9101,
    lng: 107.1839,
  ),

  // ----- Quận 3 / 1: ẩm thực -----
  DatePlace(
    id: 'p13',
    name: 'Quán ăn Cô Ba',
    category: DateCategory.eat,
    area: 'Quận 3',
    address: '45 Lê Lợi, Quận 3',
    imageAsset: 'assets/images/affiliate/eat.jpg',
    pricePerTwo: 220000,
    priceText: '100K - 200K / 2 người',
    durationMin: 75,
    moods: [DateMood.budget, DateMood.chill],
    slots: [TimeSlot.morning, TimeSlot.afternoon, TimeSlot.evening],
    hours: '07:00 – 21:30',
    description:
        'Quán cơm gia đình lâu năm, món ổn định, giá hợp lý trong trung tâm.',
    rating: 4.2,
    reviewCount: 1640,
    lat: 10.7767,
    lng: 106.6903,
  ),
  DatePlace(
    id: 'p14',
    name: 'Góc Hà Nội - Phở Bò',
    category: DateCategory.eat,
    area: 'Quận 1',
    address: '12 Trần Hưng Đạo, Quận 1',
    imageAsset: 'assets/images/affiliate/eat.jpg',
    pricePerTwo: 140000,
    priceText: '60K - 100K / người',
    durationMin: 50,
    moods: [DateMood.budget, DateMood.chill],
    slots: [TimeSlot.morning, TimeSlot.afternoon],
    hours: '06:00 – 22:00',
    description:
        'Phở bò truyền thống, nước dùng ngọt than, quán lúc nào cũng đông.',
    rating: 4.3,
    reviewCount: 2870,
    lat: 10.7758,
    lng: 106.7036,
  ),
];

/// Danh sách fallback read-only.
List<DatePlace> get allFallbackPlaces => List.unmodifiable(fallbackPlaces);
List<DatePlace> get allMockPlaces => allFallbackPlaces;
