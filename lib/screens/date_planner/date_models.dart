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

/// Một địa điểm trong mock data.
class DatePlace {
  final String id;
  final String name;
  final DateCategory category;
  final String area;
  final String address;
  final String imageAsset;
  final int pricePerTwo; // ước tính cho 2 người
  final int durationMin;
  final List<DateMood> moods;
  final List<TimeSlot> slots;
  final String? hours;
  final String description;
  final bool isPartner;
  final String? affiliateUrl;

  const DatePlace({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.address,
    required this.imageAsset,
    required this.pricePerTwo,
    required this.durationMin,
    required this.moods,
    required this.slots,
    required this.description,
    this.hours,
    this.isPartner = false,
    this.affiliateUrl,
  });
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
                    'pricePerTwo': s.place.pricePerTwo,
                    'durationMin': s.place.durationMin,
                    'moodIds': s.place.moods.map((m) => m.id).toList(),
                    'slotLabels': s.place.slots.map((t) => t.label).toList(),
                    'hours': s.place.hours,
                    'description': s.place.description,
                    'isPartner': s.place.isPartner,
                    'affiliateUrl': s.place.affiliateUrl,
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
          pricePerTwo: p['pricePerTwo'] as int,
          durationMin: p['durationMin'] as int,
          moods: moods,
          slots: slots,
          description: p['description'] as String,
          hours: p['hours'] as String?,
          isPartner: (p['isPartner'] as bool?) ?? false,
          affiliateUrl: p['affiliateUrl'] as String?,
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
// Mock data - 12 địa điểm trải đều 4 khu vực × 5 danh mục.
// Tất cả ảnh dùng asset đã khai báo trong pubspec.yaml; một số dùng
// lại asset sẵn có (eat/play/movie/gift) cho gọn.
// =====================================================================

const _mockPlaces = <DatePlace>[
  // ----- Quận 1: trung tâm, lãng mạn -----
  DatePlace(
    id: 'p01',
    name: 'The Coffee House',
    category: DateCategory.eat,
    area: 'Quận 1',
    address: '123 Nguyễn Huệ',
    imageAsset: 'assets/images/affiliate/eat.jpg',
    pricePerTwo: 180000,
    durationMin: 60,
    moods: [DateMood.romantic, DateMood.chill, DateMood.budget],
    slots: [TimeSlot.morning, TimeSlot.afternoon],
    hours: '07:00 – 22:00',
    description:
        'Quán cafe yên tĩnh, ánh sáng tự nhiên, thích hợp cho buổi hẹn nhẹ nhàng buổi sáng hoặc chiều.',
  ),
  DatePlace(
    id: 'p02',
    name: 'Pizza 4P\'s',
    category: DateCategory.eat,
    area: 'Quận 1',
    address: '8 Đông Du',
    imageAsset: 'assets/images/affiliate/eat.jpg',
    pricePerTwo: 380000,
    durationMin: 90,
    moods: [DateMood.romantic, DateMood.active],
    slots: [TimeSlot.evening],
    hours: '11:00 – 23:00',
    description:
        'Nhà hàng pizza kiểu Ý, không gian ấm cúng, thường kín chỗ vào cuối tuần.',
    isPartner: true,
    affiliateUrl: 'https://example.com/partner/pizza4ps',
  ),
  DatePlace(
    id: 'p03',
    name: 'CGV Vincom Đồng Khởi',
    category: DateCategory.movie,
    area: 'Quận 1',
    address: '72 Lê Thánh Tôn',
    imageAsset: 'assets/images/affiliate/movie.jpg',
    pricePerTwo: 220000,
    durationMin: 150,
    moods: [DateMood.romantic, DateMood.chill, DateMood.surprise],
    slots: [TimeSlot.evening],
    hours: '09:00 – 24:00',
    description:
        'Rạp chiếu phim trung tâm, nhiều suất, có phòng đôi cho cặp đôi.',
    isPartner: true,
    affiliateUrl: 'https://example.com/partner/cgv',
  ),

  // ----- Quận 3: cổ điển, thư giãn -----
  DatePlace(
    id: 'p04',
    name: 'Công viên Tao Đàn',
    category: DateCategory.outdoor,
    area: 'Quận 3',
    address: 'Hai Bà Trưng / Trương Định',
    imageAsset: 'assets/images/affiliate/play.jpg',
    pricePerTwo: 30000,
    durationMin: 60,
    moods: [DateMood.chill, DateMood.budget],
    slots: [TimeSlot.morning, TimeSlot.afternoon],
    hours: '05:00 – 22:00',
    description:
        'Công viên trung tâm có nhiều cây xanh, thích hợp đi bộ buổi sáng hoặc ngồi ghế đá buổi chiều.',
  ),
  DatePlace(
    id: 'p05',
    name: 'Mochi Bakery',
    category: DateCategory.gift,
    area: 'Quận 3',
    address: '78 Hai Bà Trưng',
    imageAsset: 'assets/images/affiliate/gift.jpg',
    pricePerTwo: 160000,
    durationMin: 30,
    moods: [DateMood.budget, DateMood.chill],
    slots: [TimeSlot.afternoon],
    hours: '08:00 – 21:00',
    description:
        'Tiệm bánh mochi nhỏ xinh, nhiều vị, thích hợp mua về làm quà.',
  ),
  DatePlace(
    id: 'p06',
    name: 'Lotte Cinema Nam Sài Gòn',
    category: DateCategory.movie,
    area: 'Quận 7',
    address: 'Lotte Mart, Nguyễn Hữu Thọ',
    imageAsset: 'assets/images/affiliate/movie.jpg',
    pricePerTwo: 200000,
    durationMin: 150,
    moods: [DateMood.chill, DateMood.surprise],
    slots: [TimeSlot.afternoon, TimeSlot.evening],
    hours: '09:00 – 24:00',
    description: 'Rạp phim trong Lotte, ghế rộng, có bắp rang bơ.',
  ),

  // ----- Quận 7: hiện đại, hoạt động -----
  DatePlace(
    id: 'p07',
    name: 'Suối Tiên Theme Park',
    category: DateCategory.play,
    area: 'Quận 9',
    address: 'Xa lộ Hà Nội',
    imageAsset: 'assets/images/affiliate/play.jpg',
    pricePerTwo: 600000,
    durationMin: 240,
    moods: [DateMood.active, DateMood.surprise],
    slots: [TimeSlot.afternoon, TimeSlot.evening],
    hours: '08:00 – 22:00',
    description:
        'Khu vui chơi lớn với nhiều trò chơi cảm giác mạnh, công viên nước và các show diễn.',
    isPartner: true,
    affiliateUrl: 'https://example.com/partner/suoitien',
  ),
  DatePlace(
    id: 'p08',
    name: 'Đầm Sen Park',
    category: DateCategory.play,
    area: 'Quận 11',
    address: '3 Hòa Bình',
    imageAsset: 'assets/images/affiliate/play.jpg',
    pricePerTwo: 400000,
    durationMin: 180,
    moods: [DateMood.active, DateMood.budget],
    slots: [TimeSlot.afternoon],
    hours: '08:00 – 21:00',
    description:
        'Công viên giải trí có hồ bơi, khu vui chơi trẻ em, thích hợp buổi chiều.',
  ),

  // ----- Thủ Đức: ngoài trời, bất ngờ -----
  DatePlace(
    id: 'p09',
    name: 'Bảo tàng Mỹ thuật',
    category: DateCategory.outdoor,
    area: 'Quận 1',
    address: '97A Phó Đức Chính',
    imageAsset: 'assets/images/affiliate/eat.jpg',
    pricePerTwo: 60000,
    durationMin: 90,
    moods: [DateMood.chill, DateMood.budget, DateMood.surprise],
    slots: [TimeSlot.morning, TimeSlot.afternoon],
    hours: '09:00 – 17:00',
    description:
        'Bảo tàng trưng bày các tác phẩm hội họa và điêu khắc Việt Nam hiện đại và truyền thống.',
  ),
  DatePlace(
    id: 'p10',
    name: 'Flower Shop Hồng Tươi',
    category: DateCategory.gift,
    area: 'Quận 1',
    address: '15 Pasteur',
    imageAsset: 'assets/images/affiliate/gift.jpg',
    pricePerTwo: 350000,
    durationMin: 25,
    moods: [DateMood.romantic, DateMood.surprise],
    slots: [TimeSlot.afternoon, TimeSlot.evening],
    hours: '08:00 – 22:00',
    description:
        'Shop hoa tươi các loại, có set hoa cắm sẵn theo phong cách Hàn Quốc.',
    isPartner: true,
    affiliateUrl: 'https://example.com/partner/hoa',
  ),
  DatePlace(
    id: 'p11',
    name: 'Cà phê Acoustic Chill',
    category: DateCategory.eat,
    area: 'Quận 3',
    address: '25 Võ Văn Tần',
    imageAsset: 'assets/images/affiliate/eat.jpg',
    pricePerTwo: 150000,
    durationMin: 60,
    moods: [DateMood.romantic, DateMood.chill],
    slots: [TimeSlot.evening],
    hours: '17:00 – 24:00',
    description:
        'Quán cà phê nhạc sống nhẹ, thích hợp cho buổi hẹn tối lãng mạn.',
  ),
  DatePlace(
    id: 'p12',
    name: 'Vịnh Hạ Long tour',
    category: DateCategory.outdoor,
    area: 'Quảng Ninh',
    address: 'Bãi Cháy, Hạ Long',
    imageAsset: 'assets/images/affiliate/play.jpg',
    pricePerTwo: 2400000,
    durationMin: 480,
    moods: [DateMood.surprise, DateMood.romantic],
    slots: [TimeSlot.morning, TimeSlot.afternoon],
    hours: '07:00 – 20:00',
    description:
        'Tour du thuyền Vịnh Hạ Long 1 ngày, bao gồm ăn trưa và tham quan hang động.',
  ),
];

/// Exposed read-only list.
List<DatePlace> get allMockPlaces => List.unmodifiable(_mockPlaces);
