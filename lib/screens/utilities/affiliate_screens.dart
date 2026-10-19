import 'package:flutter/material.dart';
import '../../constants/mate_theme.dart';

// =====================================================================
// AffiliateCategory - mô tả 1 danh mục (Ăn uống / Đi chơi / ...)
// =====================================================================

class AffiliateCategory {
  final String id;
  final String title;
  final String sub;
  final IconData icon;
  final Color color;
  final Color bg;
  final String emoji;
  /// Đường dẫn asset cho thumbnail card. Nếu null sẽ dùng emoji + bg.
  final String? imageAsset;
  const AffiliateCategory({
    required this.id,
    required this.title,
    required this.sub,
    required this.icon,
    required this.color,
    required this.bg,
    required this.emoji,
    this.imageAsset,
  });
}

// =====================================================================
// Shared sub-header.
// =====================================================================

class _SubHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SubHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFC1D3), Color(0xFFFFEBF1)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: MateColors.plum),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.7),
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: MateColors.plum,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 13,
                  color: MateColors.plum.withOpacity(0.7),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =====================================================================
// AffiliateListScreen - danh sách địa điểm trong 1 danh mục.
// =====================================================================
//
// Search + filter chips + list card.
// Mock data rõ ràng; đánh dấu "Đối tác" để minh họa affiliate.

class AffiliatePlace {
  final String name;
  final String address;
  final String priceRange;
  final IconData icon;
  final List<Color> gradient;
  final bool isPartner;
  const AffiliatePlace({
    required this.name,
    required this.address,
    required this.priceRange,
    required this.icon,
    required this.gradient,
    this.isPartner = false,
  });
}

class AffiliateListScreen extends StatefulWidget {
  final AffiliateCategory category;
  const AffiliateListScreen({super.key, required this.category});

  @override
  State<AffiliateListScreen> createState() => _AffiliateListScreenState();
}

class _AffiliateListScreenState extends State<AffiliateListScreen> {
  String _search = '';
  String _area = 'Tất cả';
  String _price = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    final all = _mockData(widget.category.id);
    final filtered = all.where((p) {
      if (_search.isNotEmpty &&
          !p.name.toLowerCase().contains(_search.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF1),
      body: SafeArea(
        child: Column(
          children: [
            _SubHeader(
              title: '${widget.category.emoji} ${widget.category.title}',
              subtitle: widget.category.sub,
            ),
            // Search bar.
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(MateRadius.field),
                  border: Border.all(color: MateColors.border),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm địa điểm…',
                    hintStyle: TextStyle(
                      color: MateColors.plum.withOpacity(0.5),
                      fontSize: 13.5,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: MateColors.rose),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ),
            // Filter chips.
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _filterChip('Khu vực', _area, [
                    'Tất cả',
                    'Quận 1',
                    'Quận 3',
                    'Quận 7',
                  ], (v) => setState(() => _area = v)),
                  const SizedBox(width: 8),
                  _filterChip('Mức giá', _price, [
                    'Tất cả',
                    'Dưới 200K',
                    '200K - 500K',
                    'Trên 500K',
                  ], (v) => setState(() => _price = v)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: filtered.isEmpty
                  ? _empty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PlaceCard(
                          place: filtered[i],
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AffiliateDetailScreen(
                                  place: filtered[i],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (_) => options
          .map((o) => PopupMenuItem(value: o, child: Text(o)))
          .toList(),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MateRadius.pill),
          border: Border.all(color: MateColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $value',
              style: const TextStyle(
                color: MateColors.plum,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: MateColors.rose, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 56, color: MateColors.rose),
            const SizedBox(height: 8),
            const Text(
              'Không tìm thấy địa điểm nào',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: MateColors.plum,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Thử thay đổi từ khóa hoặc bộ lọc nhé!',
              style: TextStyle(
                fontSize: 12,
                color: MateColors.plum.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final AffiliatePlace place;
  final VoidCallback onTap;
  const _PlaceCard({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MateRadius.card),
          border: Border.all(color: MateColors.border),
          boxShadow: MateShadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail gradient.
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: place.gradient,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(place.icon, color: Colors.white, size: 36),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: MateColors.plum,
                          ),
                        ),
                      ),
                      if (place.isPartner) _partnerBadge(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: MateColors.rose, size: 14),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          place.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: MateColors.plum.withOpacity(0.65),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.priceRange,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MateColors.pink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _partnerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: MateColors.primaryGradient,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.handshake_rounded, color: Colors.white, size: 10),
          SizedBox(width: 2),
          Text(
            'Đối tác',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// AffiliateDetailScreen
// =====================================================================

class AffiliateDetailScreen extends StatelessWidget {
  final AffiliatePlace place;
  const AffiliateDetailScreen({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF1),
      body: SafeArea(
        child: Column(
          children: [
            _SubHeader(title: place.name),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero image
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: place.gradient,
                        ),
                        borderRadius: BorderRadius.circular(MateRadius.card),
                        boxShadow: MateShadows.hero,
                      ),
                      alignment: Alignment.center,
                      child: Icon(place.icon,
                          color: Colors.white, size: 64),
                    ),
                    const SizedBox(height: 16),
                    // Tên + danh mục
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: MateColors.plum,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (place.isPartner) _badgePartner(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _infoRow(Icons.location_on_rounded, place.address),
                    const SizedBox(height: 8),
                    _infoRow(Icons.access_time_rounded, 'Giờ mở cửa: 09:00 – 22:00'),
                    const SizedBox(height: 8),
                    _infoRow(Icons.payments_rounded, 'Khoảng giá: ${place.priceRange}'),
                    const SizedBox(height: 16),
                    const _SectionTitle2('Mô tả'),
                    const SizedBox(height: 6),
                    Text(
                      'Đây là địa điểm được gợi ý dành cho các cặp đôi. '
                      'Không gian lãng mạn, phù hợp cho những buổi hẹn hò đáng nhớ. '
                      'Thông tin chi tiết sẽ được cập nhật từ đối tác trong thời gian tới.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: MateColors.plum.withOpacity(0.75),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Tính năng mở bản đồ sẽ dùng Tab 1 khi tích hợp.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map_rounded, size: 18),
                        label: const Text('Xem trên bản đồ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MateColors.pink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(MateRadius.pill),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Đã lưu vào danh sách yêu thích 💕'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(
                                Icons.favorite_border_rounded,
                                size: 18),
                            label: const Text('Lưu yêu thích'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: MateColors.pink,
                              side: const BorderSide(
                                  color: MateColors.pink, width: 1.5),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(MateRadius.pill),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: place.isPartner
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Liên kết Affiliate sẽ được cấu hình khi tích hợp.'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(
                                Icons.local_offer_rounded,
                                size: 18),
                            label: const Text('Đặt qua đối tác'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: place.isPartner
                                  ? MateColors.pink
                                  : MateColors.subtlePink,
                              foregroundColor: place.isPartner
                                  ? Colors.white
                                  : MateColors.rose,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(MateRadius.pill),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Liên kết Affiliate và thông tin đối tác sẽ được cập nhật khi có hợp đồng chính thức. '
                      'Ứng dụng không tự ý tạo URL giả.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: MateColors.plum.withOpacity(0.55),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: MateColors.rose, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              color: MateColors.plum,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _badgePartner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: MateColors.primaryGradient,
        borderRadius: BorderRadius.circular(MateRadius.pill),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.handshake_rounded, color: Colors.white, size: 12),
          SizedBox(width: 3),
          Text(
            'Đối tác',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle2 extends StatelessWidget {
  final String text;
  const _SectionTitle2(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: MateColors.plum,
      ),
    );
  }
}

// =====================================================================
// Mock data theo category id.
// =====================================================================

List<AffiliatePlace> _mockData(String id) {
  switch (id) {
    case 'eat':
      return [
        AffiliatePlace(
          name: 'The Coffee House',
          address: '123 Nguyễn Huệ, Quận 1',
          priceRange: '45K - 90K / người',
          icon: Icons.local_cafe_rounded,
          gradient: const [Color(0xFF92400E), Color(0xFFD97706)],
          isPartner: true,
        ),
        AffiliatePlace(
          name: 'Pizza 4P\'s',
          address: '8 Đông Du, Quận 1',
          priceRange: '250K - 500K / 2 người',
          icon: Icons.local_pizza_rounded,
          gradient: const [Color(0xFFB91C1C), Color(0xFFEF4444)],
        ),
        AffiliatePlace(
          name: 'Quán ăn Cô Ba',
          address: '45 Lê Lợi, Quận 3',
          priceRange: '100K - 200K / 2 người',
          icon: Icons.ramen_dining_rounded,
          gradient: const [Color(0xFFB45309), Color(0xFFFBBF24)],
          isPartner: true,
        ),
        AffiliatePlace(
          name: 'Góc Hà Nội - Phở Bò',
          address: '12 Trần Hưng Đạo',
          priceRange: '60K - 100K / người',
          icon: Icons.soup_kitchen_rounded,
          gradient: const [Color(0xFF065F46), Color(0xFF10B981)],
        ),
      ];
    case 'play':
      return [
        AffiliatePlace(
          name: 'Suối Tiên Theme Park',
          address: 'Xa lộ Hà Nội, Quận 9',
          priceRange: '200K - 400K / vé',
          icon: Icons.attractions_rounded,
          gradient: const [Color(0xFF0D9488), Color(0xFF14B8A6)],
          isPartner: true,
        ),
        AffiliatePlace(
          name: 'Đầm Sen Park',
          address: '3 Hòa Bình, Quận 11',
          priceRange: '150K - 300K / vé',
          icon: Icons.local_florist_rounded,
          gradient: const [Color(0xFF16A34A), Color(0xFF22C55E)],
        ),
        AffiliatePlace(
          name: 'Bảo tàng Mỹ thuật',
          address: '97A Phó Đức Chính, Quận 1',
          priceRange: '30K / vé',
          icon: Icons.museum_rounded,
          gradient: const [Color(0xFF7C3AED), Color(0xFFA78BFA)],
        ),
        AffiliatePlace(
          name: 'Vịnh Hạ Long tour',
          address: 'Quảng Ninh',
          priceRange: '1.200K - 2.500K / 2 người',
          icon: Icons.directions_boat_rounded,
          gradient: const [Color(0xFF1E40AF), Color(0xFF3B82F6)],
          isPartner: true,
        ),
      ];
    case 'movie':
      return [
        AffiliatePlace(
          name: 'CGV Vincom Đồng Khởi',
          address: '72 Lê Thánh Tôn, Quận 1',
          priceRange: '90K - 200K / vé',
          icon: Icons.theaters_rounded,
          gradient: const [Color(0xFFDC2626), Color(0xFFEF4444)],
          isPartner: true,
        ),
        AffiliatePlace(
          name: 'Lotte Cinema Gò Vấp',
          address: '242 Nguyễn Văn Lượng',
          priceRange: '85K - 180K / vé',
          icon: Icons.movie_rounded,
          gradient: const [Color(0xFFB91C1C), Color(0xFFF87171)],
        ),
        AffiliatePlace(
          name: 'Galaxy Cinema Phạm Văn Đồng',
          address: '819 Phạm Văn Đồng',
          priceRange: '80K - 170K / vé',
          icon: Icons.local_movies_rounded,
          gradient: const [Color(0xFF7C3AED), Color(0xFFC084FC)],
          isPartner: true,
        ),
      ];
    case 'gift':
      return [
        AffiliatePlace(
          name: 'Flower Shop Hồng Tươi',
          address: '15 Pasteur, Quận 1',
          priceRange: '150K - 500K / bó',
          icon: Icons.local_florist_rounded,
          gradient: const [Color(0xFFEC4899), Color(0xFFF9A8D4)],
          isPartner: true,
        ),
        AffiliatePlace(
          name: 'Mộc Mây Handmade',
          address: '32 Phan Đình Phùng',
          priceRange: '100K - 350K',
          icon: Icons.card_giftcard_rounded,
          gradient: const [Color(0xFF0D9488), Color(0xFF5EEAD4)],
        ),
        AffiliatePlace(
          name: 'Mochi Bakery',
          address: '78 Hai Bà Trưng, Quận 1',
          priceRange: '80K - 200K / hộp',
          icon: Icons.cake_rounded,
          gradient: const [Color(0xFFFBBF24), Color(0xFFFDE68A)],
        ),
        AffiliatePlace(
          name: 'Nến Thơm Sài Gòn',
          address: '102 Nguyễn Đình Chiểu',
          priceRange: '120K - 280K',
          icon: Icons.local_fire_department_rounded,
          gradient: const [Color(0xFFB45309), Color(0xFFF59E0B)],
        ),
      ];
    default:
      return [];
  }
}
