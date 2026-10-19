// =====================================================================
// Date Place Detail - Màn hình 3
// =====================================================================

import 'package:flutter/material.dart';
import '../../constants/mate_theme.dart';
import 'date_models.dart';
import 'date_widgets.dart';

class DatePlaceDetailScreen extends StatelessWidget {
  final DatePlace place;
  const DatePlaceDetailScreen({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF1),
      body: SafeArea(
        child: Column(
          children: [
            const _BackOnlyHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(MateRadius.card),
                      child: Stack(
                        children: [
                          Container(
                            height: 180,
                            width: double.infinity,
                            color: MateColors.subtlePink,
                            child: Image.asset(
                              place.imageAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(place.category.icon,
                                    color: MateColors.pink, size: 60),
                              ),
                            ),
                          ),
                          if (place.isPartner)
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: MateColors.primaryGradient,
                                  borderRadius:
                                      BorderRadius.circular(MateRadius.pill),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.handshake_rounded,
                                        color: Colors.white, size: 12),
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
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Tên + category
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: MateColors.subtlePink,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(place.category.icon,
                              color: MateColors.pink, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: MateColors.plum,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                place.category.label,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: MateColors.plum.withOpacity(0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _infoRow(Icons.location_on_rounded, place.address),
                    const SizedBox(height: 6),
                    if (place.hours != null)
                      _infoRow(Icons.access_time_rounded,
                          'Giờ mở cửa: ${place.hours}'),
                    const SizedBox(height: 6),
                    _infoRow(Icons.payments_rounded,
                        'Khoảng giá: ${_formatVnd(place.pricePerTwo)} (2 người)'),
                    const SizedBox(height: 6),
                    _infoRow(Icons.timer_outlined,
                        'Thời lượng gợi ý: ${place.durationMin} phút'),
                    const SizedBox(height: 14),
                    const SectionTitle('Mô tả'),
                    const SizedBox(height: 6),
                    Text(
                      place.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: MateColors.plum.withOpacity(0.75),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Nhãn demo
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(MateRadius.pill),
                        border: Border.all(color: MateColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: MateColors.rose, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            'Dữ liệu demo — chưa xác minh',
                            style: TextStyle(
                              color: MateColors.plum.withOpacity(0.7),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Action buttons
                    SizedBox(
                      width: double.infinity,
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
                        icon: const Icon(Icons.favorite_border_rounded,
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
                          textStyle: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(MateRadius.pill),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    if (place.affiliateUrl != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: Colors.white,
                                title: const Text('Ưu đãi đối tác'),
                                content: Text(
                                  'Liên kết Affiliate sẽ mở khi có hợp đồng thật.\n\nURL cấu hình: ${place.affiliateUrl}',
                                  style: TextStyle(
                                    color: MateColors.plum
                                        .withOpacity(0.8),
                                    height: 1.4,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Đóng'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.local_offer_rounded,
                              size: 18),
                          label: const Text('Xem ưu đãi đối tác'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: MateColors.pink,
                            side: const BorderSide(
                                color: MateColors.pink, width: 1.5),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(MateRadius.pill),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Liên kết Affiliate sẽ được kích hoạt khi có hợp đồng thật. '
                      'Ứng dụng không tự tạo URL giả.',
                      style: TextStyle(
                        fontSize: 11,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: MateColors.rose, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: MateColors.plum,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _BackOnlyHeader extends StatelessWidget {
  const _BackOnlyHeader();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFEBF1),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded,
                color: MateColors.plum),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: const CircleBorder(),
              side: const BorderSide(color: MateColors.border),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatVnd(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${buf.toString()}đ';
}
