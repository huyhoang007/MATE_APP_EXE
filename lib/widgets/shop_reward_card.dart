// =====================================================================
// Shop Reward Card - Card độc lập cho section "Cửa hàng & Phần thưởng"
//
// Tách riêng hoàn toàn với AffiliateCategoryCard. KHÔNG chứa logic ảnh
// affiliate, KHÔNG share state nào với các card khác. Style chỉ phục
// vụ 4 mục: Shop vật phẩm / Lucky Box / Quà hằng ngày / Kho đồ.
// =====================================================================

import 'package:flutter/material.dart';
import '../../../constants/mate_theme.dart';

class ShopRewardItem {
  final IconData icon;
  final Color color;
  final Color bg;
  final String imageAsset;
  final String title;
  final String sub;
  final String badge;
  final VoidCallback onTap;

  const ShopRewardItem({
    required this.icon,
    required this.color,
    required this.bg,
    required this.imageAsset,
    required this.title,
    required this.sub,
    required this.badge,
    required this.onTap,
  });
}

/// Card 2x2 với:
/// - 55% ảnh pastel + icon đồ họa lớn ở giữa
/// - 45% tiêu đề + mô tả + mũi tên
/// - Bo góc đồng đều
class ShopRewardCard extends StatelessWidget {
  final ShopRewardItem item;
  const ShopRewardCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
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
            // Phần ảnh - 55% card
            Expanded(
              flex: 11,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Ảnh texture nền (BoxFit.cover + errorBuilder).
                  Image.asset(
                    item.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: item.bg,
                    ),
                  ),
                  // 2. Gradient pastel phủ - tạo tone MATE.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          item.bg.withOpacity(0.55),
                          item.bg.withOpacity(0.92),
                        ],
                      ),
                    ),
                  ),
                  // 3. Icon đồ họa lớn - minh họa rõ chủ đề.
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withOpacity(0.25),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(item.icon, color: item.color, size: 32),
                    ),
                  ),
                  // 4. Badge đặc điểm ở góc trên-trái.
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(MateRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.badge,
                            style: const TextStyle(
                              color: MateColors.plum,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Phần text - 45% card
            Expanded(
              flex: 9,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: MateColors.plum,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.sub,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: MateColors.plum.withOpacity(0.7),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: item.bg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: item.color,
                        size: 14,
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
}
