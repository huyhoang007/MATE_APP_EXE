import 'dart:math';
import 'package:flutter/material.dart';
import '../../constants/mate_theme.dart';
import '../../services/wallet_service.dart';
import '../../services/shop_service.dart';
import '../../services/inventory_service.dart';
import '../../services/daily_reward_service.dart';

// =====================================================================
// Shared header (gradient + nút Back + tiêu đề) cho mọi màn hình con.
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
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 18),
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
// PremiumScreen
// =====================================================================
//
// So sánh Free vs Premium + gói theo tháng/năm + VIP Daily Box.
// UI demo, không tạo giao dịch thanh toán thật.
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF1),
      body: SafeArea(
        child: Column(
          children: [
            const _SubHeader(
              title: 'MATE Premium 👑',
              subtitle: 'Đặc quyền dành riêng cho cặp đôi MATE',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  children: [
                    // So sánh Free / Premium.
                    _CompareCard(),
                    const SizedBox(height: 16),

                    // VIP Daily Box.
                    _DailyBoxCard(),
                    const SizedBox(height: 16),

                    // Các quyền lợi Premium.
                    const _SectionTitle2('Quyền lợi Premium'),
                    const SizedBox(height: 10),
                    ..._perks.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PerkRow(perk: p),
                        )),

                    const SizedBox(height: 16),

                    // Gói.
                    const _SectionTitle2('Chọn gói Premium'),
                    const SizedBox(height: 10),
                    _PlanCard(
                      title: 'Theo tháng',
                      price: '49.000đ',
                      per: '/ tháng',
                      highlight: false,
                    ),
                    const SizedBox(height: 10),
                    _PlanCard(
                      title: 'Theo năm',
                      price: '399.000đ',
                      per: '/ năm (tiết kiệm 32%)',
                      highlight: true,
                      badge: 'Tiết kiệm',
                    ),

                    const SizedBox(height: 16),

                    // Nút nâng cấp.
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Demo: chưa có hệ thống thanh toán thật.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Tính năng nâng cấp Premium sẽ sớm ra mắt 💕'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.workspace_premium_rounded),
                        label: const Text('Nâng cấp Premium'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MateColors.pink,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(MateRadius.pill),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Giao dịch chỉ mang tính minh họa. Tính năng thanh toán sẽ được tích hợp trong phiên bản sau.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: MateColors.plum.withOpacity(0.6),
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
}

class _CompareCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MateRadius.card),
        border: Border.all(color: MateColors.border),
        boxShadow: MateShadows.soft,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _PlanColumn(
                  title: 'Free',
                  color: MateColors.rose,
                  items: const [
                    'Vật phẩm cơ bản',
                    'Lucky Box thường',
                    'Theo dõi vị trí cơ bản',
                    'Nhật ký chuẩn HD',
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFB1CB), Color(0xFFFFD8E4)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _PlanColumn(
                    title: 'Premium',
                    color: Colors.white,
                    titleColor: Colors.white,
                    items: const [
                      'Tất cả vật phẩm hiếm',
                      'Lucky Box Premium',
                      'Vị trí thời gian thực',
                      'Nhật ký video chất lượng cao',
                    ],
                    textColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanColumn extends StatelessWidget {
  final String title;
  final Color color;
  final Color? titleColor;
  final Color? textColor;
  final List<String> items;
  const _PlanColumn({
    required this.title,
    required this.color,
    this.titleColor,
    this.textColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final tColor = titleColor ?? MateColors.plum;
    final bColor = textColor ?? MateColors.plum.withOpacity(0.75);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: tColor,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        ...items.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded, color: color, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s,
                    style: TextStyle(
                      color: bColor,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyBoxCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB1CB), Color(0xFFFFD8E4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(MateRadius.card),
        boxShadow: MateShadows.hero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.card_giftcard_rounded,
                  color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'VIP Daily Box',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _DailyRow(
            label: 'Free',
            coins: 'Khoảng 5 xu / ngày',
            color: Colors.white,
          ),
          const SizedBox(height: 4),
          _DailyRow(
            label: 'Premium',
            coins: '15 – 25 xu / ngày',
            color: Colors.white,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _DailyRow extends StatelessWidget {
  final String label;
  final String coins;
  final Color color;
  final bool bold;
  const _DailyRow({
    required this.label,
    required this.coins,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(MateRadius.pill),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          coins,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Perk {
  final IconData icon;
  final Color color;
  final String title;
  final String sub;
  const _Perk(this.icon, this.color, this.title, this.sub);
}

const _perks = [
  _Perk(Icons.pets_rounded, Color(0xFFE11D48), 'Vật phẩm Pet độc quyền',
      'Trang phục, phụ kiện chỉ dành cho Premium'),
  _Perk(Icons.location_on_rounded, Color(0xFF0D9488),
      'Theo dõi vị trí nâng cao', 'Trạng thái thời gian thực chi tiết hơn'),
  _Perk(Icons.videocam_rounded, Color(0xFF9333EA),
      'Nhật ký video chất lượng cao', 'Lưu giữ khoảnh khắc sắc nét hơn'),
  _Perk(Icons.workspace_premium_rounded, Color(0xFFD97706),
      'Huy hiệu Premium', 'Hiển thị đặc quyền trong cặp đôi'),
];

class _PerkRow extends StatelessWidget {
  final _Perk perk;
  const _PerkRow({required this.perk});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MateRadius.card),
        border: Border.all(color: MateColors.border),
        boxShadow: MateShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: perk.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(perk.icon, color: perk.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perk.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: MateColors.plum,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  perk.sub,
                  style: TextStyle(
                    fontSize: 12,
                    color: MateColors.plum.withOpacity(0.65),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String per;
  final bool highlight;
  final String? badge;
  const _PlanCard({
    required this.title,
    required this.price,
    required this.per,
    this.highlight = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFFEBF1) : Colors.white,
        borderRadius: BorderRadius.circular(MateRadius.card),
        border: Border.all(
          color: highlight ? MateColors.pink : MateColors.border,
          width: highlight ? 1.5 : 1,
        ),
        boxShadow: highlight ? MateShadows.cta : MateShadows.soft,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: MateColors.plum,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: MateColors.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(MateRadius.pill),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  per,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: MateColors.plum.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: MateColors.pink,
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w800,
          color: MateColors.plum,
        ),
      ),
    );
  }
}

// =====================================================================
// WalletScreen
// =====================================================================
//
// Kết nối realtime với Firestore qua WalletService:
//   - Số dư: watchCoins(coupleId)
//   - Lịch sử giao dịch: watchTransactions(coupleId)
class WalletScreen extends StatelessWidget {
  final String? coupleId;
  const WalletScreen({super.key, this.coupleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF1),
      body: SafeArea(
        child: Column(
          children: [
            const _SubHeader(
              title: 'Ví xu MATE',
              subtitle: 'Lịch sử giao dịch thời gian thực',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // Số dư lớn realtime
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB1CB), Color(0xFFFFD8E4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(MateRadius.card),
                      boxShadow: MateShadows.hero,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded,
                            color: Colors.white, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Số dư hiện tại',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  )),
                              const SizedBox(height: 2),
                              if (coupleId != null)
                                StreamBuilder<int>(
                                  stream: WalletService.instance.watchCoins(coupleId!),
                                  builder: (context, snap) {
                                    final coins = snap.data ?? 0;
                                    return Text(
                                      '$coins xu',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    );
                                  },
                                )
                              else
                                const Text(
                                  '0 xu',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle2('Giao dịch gần đây'),
                  const SizedBox(height: 8),
                  if (coupleId != null)
                    StreamBuilder<List<WalletTransaction>>(
                      stream: WalletService.instance.watchTransactions(coupleId!),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(color: MateColors.pink),
                            ),
                          );
                        }
                        final txs = snap.data!;
                        if (txs.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            child: const Text(
                              'Chưa có giao dịch nào',
                              style: TextStyle(color: MateColors.rose, fontSize: 13),
                            ),
                          );
                        }
                        return Column(
                          children: txs
                              .map((t) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _TxTileReal(tx: t),
                                  ))
                              .toList(),
                        );
                      },
                    )
                  else
                    const Center(child: Text('Chưa kết nối phòng')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TxTileReal extends StatelessWidget {
  final WalletTransaction tx;
  const _TxTileReal({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isPlus = tx.isEarn;
    final sign = isPlus ? '+' : '-';
    final icon = isPlus ? Icons.arrow_downward_rounded : Icons.shopping_bag_rounded;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MateRadius.card),
        border: Border.all(color: MateColors.border),
        boxShadow: MateShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isPlus ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isPlus ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.reason,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: MateColors.plum,
                  ),
                ),
                Text(
                  '${tx.createdAt.hour.toString().padLeft(2, '0')}:${tx.createdAt.minute.toString().padLeft(2, '0')} - ${tx.createdAt.day}/${tx.createdAt.month}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: MateColors.rose,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$sign${tx.amount}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: isPlus ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// ItemShopScreen
// =====================================================================
//
// Kết nối realtime với Firestore qua ShopService:
//   - Đọc shopItems collection
//   - Mua vật phẩm qua ShopService.purchaseItem (trừ xu + thêm inventory)
class ItemShopScreen extends StatelessWidget {
  final String? coupleId;
  const ItemShopScreen({super.key, this.coupleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF1),
      body: SafeArea(
        child: Column(
          children: [
            const _SubHeader(
              title: 'Shop vật phẩm',
              subtitle: 'Trang phục, phụ kiện và đồ trang trí cho cặp đôi',
            ),
            Expanded(
              child: StreamBuilder<List<ShopItem>>(
                stream: ShopService.instance.watchItems(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('Lỗi: ${snap.error}'));
                  }
                  if (!snap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: MateColors.pink),
                    );
                  }
                  final items = snap.data!;
                  if (items.isEmpty) {
                    return const Center(
                      child: Text('Cửa hàng đang chuẩn bị cập nhật...'),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: items.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (_, i) => _ShopItemCardReal(
                      item: items[i],
                      onTap: () => _confirmPurchase(context, items[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPurchase(BuildContext context, ShopItem item) async {
    if (coupleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa kết nối phòng')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận mua', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có muốn mua "${item.name}" với giá ${item.coins} xu MATE?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mua ngay'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await ShopService.instance.purchaseItem(coupleId!, item);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Mua thành công "${item.name}"! Vật phẩm đã vào Kho đồ.'),
              backgroundColor: MateColors.pink,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: MateColors.rose,
            ),
          );
        }
      }
    }
  }
}

class _ShopItemCardReal extends StatelessWidget {
  final ShopItem item;
  final VoidCallback onTap;
  const _ShopItemCardReal({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gradient = _getItemGradient(item.category, item.rarity);
    final icon = _getIconData(item.icon);
    final rarityColor = _getRarityColor(item.rarity);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(MateRadius.card)),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 44, color: Colors.white),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: MateColors.plum,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: MateColors.plum.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: rarityColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.rarity,
                          style: TextStyle(
                            color: rarityColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.monetization_on_rounded,
                          color: Color(0xFFEAB308), size: 14),
                      const SizedBox(width: 2),
                      Text(
                        '${item.coins}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// LuckyBoxScreen
// =====================================================================
//
// Mở hộp quà nhận xu MATE realtime, ghi nhận vào WalletService
class LuckyBoxScreen extends StatefulWidget {
  final String? coupleId;
  const LuckyBoxScreen({super.key, this.coupleId});
  @override
  State<LuckyBoxScreen> createState() => _LuckyBoxScreenState();
}

class _LuckyBoxScreenState extends State<LuckyBoxScreen> {
  final List<bool> _opened = [false, false, false, false, false, false];
  final Map<int, int> _rewards = {};
  bool _isOpening = false;

  Future<void> _openBox(int index, bool isPremium) async {
    if (_opened[index] || _isOpening) return;
    if (widget.coupleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa kết nối phòng')),
      );
      return;
    }

    setState(() => _isOpening = true);
    final random = Random();
    final coins = isPremium ? (50 + random.nextInt(151)) : (10 + random.nextInt(21));

    try {
      await WalletService.instance.earnCoins(
        widget.coupleId!,
        coins,
        'Mở Lucky Box ${isPremium ? "Premium" : "Thường"}',
      );
      setState(() {
        _opened[index] = true;
        _rewards[index] = coins;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎁 Chúc mừng! Bạn nhận được $coins xu MATE!'),
            backgroundColor: MateColors.pink,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: MateColors.rose),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final boxes = List.generate(6, (i) => i);
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF1),
      body: SafeArea(
        child: Column(
          children: [
            const _SubHeader(
              title: 'Lucky Box 🎁',
              subtitle: 'Mở hộp quà may mắn nhận xu mỗi ngày',
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: boxes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (_, i) {
                  final isPremium = i % 2 == 0;
                  final opened = _opened[i];
                  final reward = _rewards[i];
                  return _BoxCard(
                    title: isPremium ? 'Hộp Premium' : 'Hộp thường',
                    sub: opened ? '+$reward xu' : (isPremium ? '50 – 200 xu' : '10 – 30 xu'),
                    gradient: isPremium
                        ? const [Color(0xFFFF3B69), Color(0xFFFF8FB1)]
                        : const [Color(0xFFBAE6FD), Color(0xFFE0F2FE)],
                    opened: opened,
                    onTap: opened || _isOpening ? null : () => _openBox(i, isPremium),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoxCard extends StatelessWidget {
  final String title;
  final String sub;
  final List<Color> gradient;
  final bool opened;
  final VoidCallback? onTap;
  const _BoxCard({
    required this.title,
    required this.sub,
    required this.gradient,
    required this.opened,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: opened
                ? const [Color(0xFFE5E7EB), Color(0xFFF3F4F6)]
                : gradient,
          ),
          borderRadius: BorderRadius.circular(MateRadius.card),
          boxShadow: opened ? [] : MateShadows.cta,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  opened ? Icons.check_rounded : Icons.card_giftcard_rounded,
                  color: opened ? const Color(0xFF22C55E) : Colors.white,
                  size: 28,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: opened ? Colors.white : Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(MateRadius.pill),
                  ),
                  child: Text(
                    opened ? 'Đã nhận' : 'Mở',
                    style: TextStyle(
                      color: opened ? const Color(0xFF22C55E) : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: opened ? MateColors.plum : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: TextStyle(
                    color: opened ? MateColors.plum.withOpacity(0.65) : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// DailyRewardsScreen
// =====================================================================
//
// Kết nối với Firestore qua DailyRewardService (streak + claims)
class DailyRewardsScreen extends StatefulWidget {
  final String? coupleId;
  const DailyRewardsScreen({super.key, this.coupleId});
  @override
  State<DailyRewardsScreen> createState() => _DailyRewardsScreenState();
}

class _DailyRewardsScreenState extends State<DailyRewardsScreen> {
  int _streak = 0;
  bool _claimedToday = false;
  bool _isLoading = true;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    if (widget.coupleId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final claimed = await DailyRewardService.instance.hasClaimedToday(widget.coupleId!);
      final streak = await DailyRewardService.instance.getCurrentStreak(widget.coupleId!);
      if (mounted) {
        setState(() {
          _claimedToday = claimed;
          _streak = streak;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _claimReward() async {
    if (_claimedToday || _isClaiming || widget.coupleId == null) return;
    setState(() => _isClaiming = true);
    try {
      final coins = await DailyRewardService.instance.claimDailyReward(widget.coupleId!);
      final newStreak = await DailyRewardService.instance.getCurrentStreak(widget.coupleId!);
      if (mounted) {
        setState(() {
          _claimedToday = true;
          _streak = newStreak;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Nhận thành công $coins xu MATE! Chuỗi: $_streak ngày.'),
            backgroundColor: MateColors.pink,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: MateColors.rose),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rewards = [
      ('Ngày 1', 20),
      ('Ngày 2', 30),
      ('Ngày 3', 50),
      ('Ngày 4', 80),
      ('Ngày 5', 120),
      ('Ngày 6', 180),
      ('Ngày 7', 300),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF1),
      body: SafeArea(
        child: Column(
          children: [
            const _SubHeader(
              title: 'Quà hằng ngày',
              subtitle: 'Đăng nhập mỗi ngày để nhận xu thưởng',
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: MateColors.pink))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        // Chuỗi 7 ngày
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(MateRadius.card),
                            border: Border.all(color: MateColors.border),
                            boxShadow: MateShadows.soft,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Chuỗi đăng nhập hiện tại: $_streak ngày',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: MateColors.plum,
                                  )),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 84,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: rewards.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (_, i) {
                                    final dayIndex = i + 1;
                                    final claimed = dayIndex <= _streak;
                                    final today = dayIndex == _streak + 1 && !_claimedToday;
                                    return _DayChip(
                                      label: rewards[i].$1,
                                      coins: rewards[i].$2,
                                      claimed: claimed,
                                      today: today,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Quyền lợi Free vs Premium
                        const _SectionTitle2('Quyền lợi theo ngày'),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(MateRadius.card),
                            border: Border.all(color: MateColors.border),
                            boxShadow: MateShadows.soft,
                          ),
                          child: const Column(
                            children: [
                              _RewardRow('Free', '20 – 300 xu / ngày'),
                              Divider(color: MateColors.border, height: 18),
                              _RewardRow('Premium', 'x2 xu thưởng hằng ngày',
                                  highlight: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _claimedToday || _isClaiming
                                ? null
                                : _claimReward,
                            icon: Icon(
                                _claimedToday
                                    ? Icons.check_rounded
                                    : Icons.card_giftcard_rounded,
                                size: 18),
                            label: Text(_claimedToday
                                ? 'Đã nhận hôm nay'
                                : (_isClaiming ? 'Đang nhận...' : 'Nhận quà hôm nay')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _claimedToday
                                  ? MateColors.subtlePink
                                  : MateColors.pink,
                              foregroundColor: _claimedToday
                                  ? MateColors.rose
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(MateRadius.pill),
                              ),
                            ),
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
}

class _DayChip extends StatelessWidget {
  final String label;
  final int coins;
  final bool claimed;
  final bool today;
  const _DayChip({
    required this.label,
    required this.coins,
    required this.claimed,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.white;
    Color border = MateColors.border;
    Color textColor = MateColors.plum.withOpacity(0.6);
    IconData icon = Icons.lock_outline_rounded;
    Color iconColor = MateColors.rose;

    if (claimed) {
      bg = const Color(0xFFDCFCE7);
      border = const Color(0xFF22C55E);
      textColor = const Color(0xFF22C55E);
      icon = Icons.check_rounded;
      iconColor = const Color(0xFF22C55E);
    } else if (today) {
      bg = const Color(0xFFFFC1D3);
      border = MateColors.pink;
      textColor = MateColors.pink;
      icon = Icons.card_giftcard_rounded;
      iconColor = MateColors.pink;
    }

    return Container(
      width: 64,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: today ? 1.5 : 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor, size: 18),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on_rounded,
                  color: Color(0xFFEAB308), size: 12),
              const SizedBox(width: 1),
              Text(
                '$coins',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB45309),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _RewardRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 78,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: highlight ? MateColors.pink : MateColors.subtlePink,
            borderRadius: BorderRadius.circular(MateRadius.pill),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: highlight ? Colors.white : MateColors.plum,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: MateColors.plum,
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// InventoryScreen
// =====================================================================
//
// Kết nối realtime với Firestore qua InventoryService:
//   - Đọc couples/{coupleId}/inventory
//   - Toggle đang dùng với toggleUse(coupleId, itemId)
class InventoryScreen extends StatefulWidget {
  final String? coupleId;
  const InventoryScreen({super.key, this.coupleId});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _filter = 'Tất cả';

  static const Map<String, List<String>> _filterCategories = {
    'Tất cả': [],
    'Trang phục': ['outfit', 'trang phục'],
    'Phụ kiện': ['accessory', 'phụ kiện'],
    'Đồ trang trí': ['decoration', 'đồ trang trí'],
    'Thức ăn': ['food', 'thức ăn'],
  };

  @override
  Widget build(BuildContext context) {
    final cats = _filterCategories.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF1),
      body: SafeArea(
        child: Column(
          children: [
            const _SubHeader(
              title: 'Kho đồ',
              subtitle: 'Vật phẩm cặp đôi đang sở hữu',
            ),
            // Filter chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = cats[i];
                  final selected = _filter == c;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? MateColors.pink : Colors.white,
                        borderRadius: BorderRadius.circular(MateRadius.pill),
                        border: Border.all(
                          color: selected ? MateColors.pink : MateColors.border,
                        ),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          color: selected ? Colors.white : MateColors.plum,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: widget.coupleId == null
                  ? const Center(child: Text('Chưa kết nối phòng'))
                  : StreamBuilder<List<InventoryItem>>(
                      stream: InventoryService.instance.watchInventory(widget.coupleId!),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(color: MateColors.pink),
                          );
                        }
                        final allItems = snap.data!;
                        final allowed = _filterCategories[_filter] ?? [];
                        final list = allowed.isEmpty
                            ? allItems
                            : allItems.where((i) {
                                final cat = i.category.toLowerCase();
                                return allowed.any((a) => cat.contains(a));
                              }).toList();

                        if (list.isEmpty) {
                          return _empty();
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final it = list[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _InvTileReal(
                                item: it,
                                onUse: () async {
                                  try {
                                    await InventoryService.instance.toggleUse(
                                      widget.coupleId!,
                                      it.id,
                                      !it.inUse,
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Lỗi: $e'),
                                          backgroundColor: MateColors.rose,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
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
            const Icon(Icons.inventory_2_rounded,
                size: 56, color: MateColors.rose),
            const SizedBox(height: 8),
            const Text(
              'Chưa có vật phẩm nào',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: MateColors.plum,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hãy ghé Shop để sưu tập thêm nhé!',
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

class _InvTileReal extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onUse;
  const _InvTileReal({required this.item, required this.onUse});

  @override
  Widget build(BuildContext context) {
    final gradient = _getItemGradient(item.category, item.rarity);
    final icon = _getIconData(item.icon);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MateRadius.card),
        border: Border.all(
          color: item.inUse ? MateColors.pink : MateColors.border,
          width: item.inUse ? 1.5 : 1,
        ),
        boxShadow: MateShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: MateColors.plum,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatCategory(item.category),
                  style: TextStyle(
                    fontSize: 12,
                    color: MateColors.plum.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onUse,
            style: OutlinedButton.styleFrom(
              foregroundColor: item.inUse ? MateColors.rose : MateColors.pink,
              side: BorderSide(
                color: item.inUse ? MateColors.rose : MateColors.pink,
                width: 1.2,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MateRadius.pill),
              ),
            ),
            child: Text(
              item.inUse ? 'Đang dùng' : 'Dùng',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────

IconData _getIconData(String iconName) {
  switch (iconName) {
    case 'favorite':
      return Icons.favorite_rounded;
    case 'rocket':
    case 'rocket_launch':
      return Icons.rocket_launch_rounded;
    case 'lightbulb':
      return Icons.lightbulb_rounded;
    case 'ac_unit':
      return Icons.ac_unit_rounded;
    case 'icecream':
      return Icons.icecream_rounded;
    case 'bubble_chart':
      return Icons.bubble_chart_rounded;
    case 'checkroom':
      return Icons.checkroom_rounded;
    case 'chair':
      return Icons.chair_rounded;
    case 'pets':
      return Icons.pets_rounded;
    default:
      return Icons.card_giftcard_rounded;
  }
}

Color _getRarityColor(String rarity) {
  switch (rarity.toLowerCase()) {
    case 'rare':
    case 'hiếm':
      return const Color(0xFF9333EA);
    case 'legendary':
    case 'epic':
    case 'giới hạn':
      return const Color(0xFFE11D48);
    default:
      return const Color(0xFF6B7280);
  }
}

String _formatCategory(String cat) {
  switch (cat.toLowerCase()) {
    case 'outfit':
      return 'Trang phục';
    case 'accessory':
      return 'Phụ kiện';
    case 'decoration':
      return 'Đồ trang trí';
    case 'food':
      return 'Thức ăn';
    case 'limited':
      return 'Giới hạn';
    default:
      return cat;
  }
}

List<Color> _getItemGradient(String category, String rarity) {
  if (rarity.toLowerCase().contains('giới hạn') ||
      rarity.toLowerCase().contains('limited') ||
      rarity.toLowerCase().contains('legendary')) {
    return const [Color(0xFFA5F3FC), Color(0xFFE0F2FE)];
  }
  if (rarity.toLowerCase().contains('hiếm') ||
      rarity.toLowerCase().contains('rare')) {
    return const [Color(0xFFBAE6FD), Color(0xFFE0F2FE)];
  }
  if (category.toLowerCase().contains('trang phục') ||
      category.toLowerCase().contains('outfit')) {
    return const [Color(0xFFFFB1CB), Color(0xFFFFD8E4)];
  }
  return const [Color(0xFFFEF9C3), Color(0xFFFDE68A)];
}
