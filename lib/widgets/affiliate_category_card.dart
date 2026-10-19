// =====================================================================
// AffiliateCategoryCard - Card độc lập cho section "Hẹn hò & Khám phá"
//
// Tách riêng hoàn toàn với ShopRewardCard. Style ảnh thật chiếm ~62%
// card, KHÔNG có gradient pastel phủ lên ảnh (giữ ảnh gốc nguyên vẹn),
// KHÔNG icon lớn che ảnh. Style chỉ phục vụ 4 mục Affiliate:
// Ăn uống / Đi chơi / Xem phim / Quà tặng.
// =====================================================================

import 'package:flutter/material.dart';
import '../../constants/mate_theme.dart';

class AffiliateCategoryCard extends StatelessWidget {
  /// Đường dẫn asset ảnh thumbnail.
  final String imageAsset;
  /// Tên danh mục.
  final String title;
  /// Mô tả ngắn.
  final String sub;
  /// Icon nhỏ ở badge góc trên-phải.
  final IconData icon;
  /// Màu icon.
  final Color color;
  /// Màu nền fallback (khi ảnh lỗi).
  final Color bg;
  final VoidCallback onTap;

  const AffiliateCategoryCard({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.sub,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

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
            // Ảnh thumbnail thật - ~62% card. KHÔNG gradient phủ,
            // KHÔNG icon lớn che ảnh.
            Expanded(
              flex: 13,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _thumbFallback(),
                  ),
                  // Badge icon nhỏ ở góc trên-phải.
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            // Text dưới - ~38% card.
            Expanded(
              flex: 8,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: MateColors.plum,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: MateColors.plum.withOpacity(0.65),
                        height: 1.3,
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

  /// Fallback khi ảnh lỗi: gradient nhẹ + icon ở giữa.
  /// KHÔNG phủ toàn bộ ảnh - chỉ dùng khi Image.asset error.
  Widget _thumbFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bg, bg.withOpacity(0.6)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color.withOpacity(0.7), size: 36),
    );
  }
}
