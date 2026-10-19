import 'package:flutter/material.dart';

import '../../constants/mate_theme.dart';

import 'utilities_screens.dart';

import 'affiliate_screens.dart';

import '../date_planner/date_preferences_screen.dart';

import '../../widgets/shop_reward_card.dart';

import '../../widgets/affiliate_category_card.dart';



/// =============================================================

// UtilitiesHomeScreen - Trung tâm tiện ích cho cặp đôi.

//

// Mở từ tiện ích "Tiện ích" ở Tab 1 - Bản đồ.

// Đây là route push, không phải tab mới trong Bottom Navigation.

// Nằm trong MobileFrame (max-width 430) đã bọc ở MaterialApp.builder.

//

// Bố cục:

//   - Header gradient + nút Back

//   - Premium Banner (gradient hồng đậm, icon vương miện)

//   - Ví xu MATE (card số dư + nút xem lịch sử)

//   - Grid 2 cột Shop & Rewards (4 mục)

//   - Section Hẹn hò & Khám phá

//   - Card gợi ý hẹn hò

// =============================================================



class UtilitiesHomeScreen extends StatelessWidget {

  const UtilitiesHomeScreen({super.key});



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFFFEBF1),

      body: SafeArea(

        child: CustomScrollView(

          slivers: [

            // Header gradient.

            SliverToBoxAdapter(

              child: Container(

                decoration: const BoxDecoration(

                  gradient: LinearGradient(

                    begin: Alignment.topCenter,

                    end: Alignment.bottomCenter,

                    colors: [Color(0xFFFFC1D3), Color(0xFFFFEBF1)],

                  ),

                ),

                padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),

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

                        const Expanded(

                          child: Text(

                            'Tiện ích của chúng mình 💕',

                            style: TextStyle(

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

                    const SizedBox(height: 8),

                    Padding(

                      padding: const EdgeInsets.only(left: 12),

                      child: Text(

                        'Khám phá đặc quyền và những trải nghiệm dành cho hai bạn',

                        style: TextStyle(

                          fontSize: 13.5,

                          color: MateColors.plum.withOpacity(0.7),

                          fontWeight: FontWeight.w500,

                          height: 1.35,

                        ),

                      ),

                    ),

                  ],

                ),

              ),

            ),



            // Nội dung các section.

            SliverPadding(

              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),

              sliver: SliverList(

                delegate: SliverChildListDelegate.fixed([

                  // Premium Banner.

                  _PremiumBanner(

                    onTap: () {

                      Navigator.of(context).push(

                        MaterialPageRoute(

                          builder: (_) => const PremiumScreen(),

                        ),

                      );

                    },

                  ),

                  const SizedBox(height: 14),



                  // Ví xu MATE.

                  _WalletCard(

                    onTapHistory: () {

                      Navigator.of(context).push(

                        MaterialPageRoute(

                          builder: (_) => const WalletScreen(),

                        ),

                      );

                    },

                  ),

                  const SizedBox(height: 18),



                  // Section Shop & Rewards - dùng ShopRewardCard độc lập.

                  const _SectionTitle('🛍️ Cửa hàng & Phần thưởng'),

                  const SizedBox(height: 10),

                  GridView.builder(

                    shrinkWrap: true,

                    physics: const NeverScrollableScrollPhysics(),

                    itemCount: 4,

                    gridDelegate:

                        const SliverGridDelegateWithFixedCrossAxisCount(

                      crossAxisCount: 2,

                      mainAxisSpacing: 12,

                      crossAxisSpacing: 12,

                      childAspectRatio: 0.85,

                    ),

                    itemBuilder: (_, i) {

                      void goTo(Widget Function() builder) {

                        Navigator.of(context).push(

                          MaterialPageRoute(builder: (_) => builder()),

                        );

                      }



                      late final ShopRewardItem item;

                      switch (i) {

                        case 0:

                          item = ShopRewardItem(

                            icon: Icons.checkroom_rounded,

                            color: const Color(0xFFE11D48),

                            bg: const Color(0xFFFCE7F3),

                            imageAsset: 'assets/images/shop/shop.jpg',

                            title: 'Shop vật phẩm',

                            sub: 'Trang phục & phụ kiện Pet',

                            badge: 'Mua bằng xu',

                            onTap: () => goTo(() => const ItemShopScreen()),

                          );

                          break;

                        case 1:

                          item = ShopRewardItem(

                            icon: Icons.card_giftcard_rounded,

                            color: const Color(0xFF9333EA),

                            bg: const Color(0xFFF3E8FF),

                            imageAsset: 'assets/images/shop/lucky.jpg',

                            title: 'Lucky Box',

                            sub: 'Mở hộp quà bất ngờ',

                            badge: 'Quà may mắn',

                            onTap: () => goTo(() => const LuckyBoxScreen()),

                          );

                          break;

                        case 2:

                          item = ShopRewardItem(

                            icon: Icons.calendar_month_rounded,

                            color: const Color(0xFFD97706),

                            bg: const Color(0xFFFEF9C3),

                            imageAsset: 'assets/images/shop/daily.jpg',

                            title: 'Quà hằng ngày',

                            sub: 'Điểm danh nhận xu',

                            badge: 'Mỗi ngày',

                            onTap: () =>

                                goTo(() => const DailyRewardsScreen()),

                          );

                          break;

                        default:

                          item = ShopRewardItem(

                            icon: Icons.inventory_2_rounded,

                            color: const Color(0xFF0D9488),

                            bg: const Color(0xFFCCFBF1),

                            imageAsset: 'assets/images/shop/inventory.jpg',

                            title: 'Kho đồ',

                            sub: 'Bộ sưu tập của bạn',

                            badge: 'Vật phẩm',

                            onTap: () => goTo(() => const InventoryScreen()),

                          );

                      }

                      return ShopRewardCard(item: item);

                    },

                  ),

                  const SizedBox(height: 20),



                  // Section Hẹn hò & Khám phá - dùng AffiliateCategoryCard

                  // độc lập, KHÔNG share state với ShopRewardCard.

                  const _SectionTitle('💕 Hẹn hò & Khám phá'),

                  const SizedBox(height: 6),

                  Padding(

                    padding: const EdgeInsets.only(bottom: 10),

                    child: Text(

                      'Cùng người ấy tạo thêm kỷ niệm tại những địa điểm thú vị',

                      style: TextStyle(

                        fontSize: 12.5,

                        color: MateColors.plum.withOpacity(0.65),

                        height: 1.4,

                      ),

                    ),

                  ),

                  GridView.builder(

                    shrinkWrap: true,

                    physics: const NeverScrollableScrollPhysics(),

                    itemCount: 4,

                    gridDelegate:

                        const SliverGridDelegateWithFixedCrossAxisCount(

                      crossAxisCount: 2,

                      mainAxisSpacing: 12,

                      crossAxisSpacing: 12,

                      childAspectRatio: 0.78,

                    ),

                    itemBuilder: (_, i) {

                      late final AffiliateCategory c;

                      switch (i) {

                        case 0:

                          c = AffiliateCategory(

                            id: 'eat',

                            title: 'Ăn uống',

                            sub: 'Cafe, nhà hàng cho cặp đôi',

                            icon: Icons.restaurant_rounded,

                            color: const Color(0xFFE11D48),

                            bg: const Color(0xFFFCE7F3),

                            emoji: '🍽️',

                            imageAsset: 'assets/images/affiliate/eat.jpg',

                          );

                          break;

                        case 1:

                          c = AffiliateCategory(

                            id: 'play',

                            title: 'Đi chơi',

                            sub: 'Khu vui chơi, tham quan',

                            icon: Icons.attractions_rounded,

                            color: const Color(0xFF0D9488),

                            bg: const Color(0xFFCCFBF1),

                            emoji: '🎡',

                            imageAsset: 'assets/images/affiliate/play.jpg',

                          );

                          break;

                        case 2:

                          c = AffiliateCategory(

                            id: 'movie',

                            title: 'Xem phim',

                            sub: 'Rạp chiếu phim, suất chiếu',

                            icon: Icons.movie_rounded,

                            color: const Color(0xFF9333EA),

                            bg: const Color(0xFFF3E8FF),

                            emoji: '🎬',

                            imageAsset: 'assets/images/affiliate/movie.jpg',

                          );

                          break;

                        default:

                          c = AffiliateCategory(

                            id: 'gift',

                            title: 'Quà tặng',

                            sub: 'Hoa, quà lưu niệm cho người ấy',

                            icon: Icons.local_florist_rounded,

                            color: const Color(0xFFD97706),

                            bg: const Color(0xFFFEF9C3),

                            emoji: '🎁',

                            imageAsset: 'assets/images/affiliate/gift.jpg',

                          );

                      }

                      return AffiliateCategoryCard(

                        imageAsset: c.imageAsset!,

                        title: c.title,

                        sub: c.sub,

                        icon: c.icon,

                        color: c.color,

                        bg: c.bg,

                        onTap: () {

                          Navigator.of(context).push(

                            MaterialPageRoute(

                              builder: (_) =>

                                  AffiliateListScreen(category: c),

                            ),

                          );

                        },

                      );

                    },

                  ),

                  const SizedBox(height: 18),



                  // Gợi ý hẹn hò.

                  const _DatingSuggestionCard(),

                ]),

              ),

            ),

          ],

        ),

      ),

    );

  }

}



// =====================================================================

// Premium Banner

// =====================================================================



class _PremiumBanner extends StatelessWidget {

  final VoidCallback onTap;

  const _PremiumBanner({required this.onTap});



  @override

  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: onTap,

      behavior: HitTestBehavior.opaque,

      child: Container(

        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(

          gradient: const LinearGradient(

            begin: Alignment.topLeft,

            end: Alignment.bottomRight,

            colors: [Color(0xFFFF3B69), Color(0xFFFF8FB1)],

          ),

          borderRadius: BorderRadius.circular(MateRadius.card),

          boxShadow: MateShadows.cta,

        ),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Row(

              children: [

                Container(

                  padding: const EdgeInsets.symmetric(

                      horizontal: 10, vertical: 4),

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius: BorderRadius.circular(MateRadius.pill),

                  ),

                  child: const Row(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      Icon(Icons.workspace_premium_rounded,

                          color: MateColors.pink, size: 14),

                      SizedBox(width: 4),

                      Text(

                        'MATE PREMIUM',

                        style: TextStyle(

                          fontSize: 10.5,

                          fontWeight: FontWeight.w900,

                          color: MateColors.pink,

                          letterSpacing: 0.5,

                        ),

                      ),

                    ],

                  ),

                ),

              ],

            ),

            const SizedBox(height: 14),

            Row(

              children: [

                Container(

                  width: 52,

                  height: 52,

                  alignment: Alignment.center,

                  decoration: BoxDecoration(

                    color: Colors.white.withOpacity(0.25),

                    shape: BoxShape.circle,

                  ),

                  child: const Icon(Icons.workspace_premium_rounded,

                      color: Colors.white, size: 30),

                ),

                const SizedBox(width: 12),

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: const [

                      Text(

                        'Đặc quyền dành cho hai bạn',

                        style: TextStyle(

                          color: Colors.white,

                          fontSize: 16,

                          fontWeight: FontWeight.w800,

                          height: 1.25,

                        ),

                      ),

                      SizedBox(height: 2),

                      Text(

                        'Mở khóa quà VIP, vật phẩm hiếm và nhiều trải nghiệm đặc biệt',

                        style: TextStyle(

                          color: Colors.white,

                          fontSize: 12,

                          height: 1.35,

                        ),

                      ),

                    ],

                  ),

                ),

              ],

            ),

            const SizedBox(height: 14),

            Row(

              mainAxisAlignment: MainAxisAlignment.end,

              children: [

                Container(

                  padding: const EdgeInsets.symmetric(

                      horizontal: 14, vertical: 8),

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius: BorderRadius.circular(MateRadius.pill),

                  ),

                  child: const Row(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      Text(

                        'Khám phá Premium',

                        style: TextStyle(

                          color: MateColors.pink,

                          fontSize: 12.5,

                          fontWeight: FontWeight.w800,

                        ),

                      ),

                      SizedBox(width: 4),

                      Icon(Icons.arrow_forward_rounded,

                          color: MateColors.pink, size: 14),

                    ],

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

// Wallet card

// =====================================================================



class _WalletCard extends StatelessWidget {

  final VoidCallback onTapHistory;

  const _WalletCard({required this.onTapHistory});



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

      child: Row(

        children: [

          Container(

            width: 52,

            height: 52,

            alignment: Alignment.center,

            decoration: BoxDecoration(

              color: const Color(0xFFFEF9C3),

              borderRadius: BorderRadius.circular(16),

            ),

            child: const Icon(Icons.monetization_on_rounded,

                color: Color(0xFFEAB308), size: 30),

          ),

          const SizedBox(width: 14),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  'Ví xu MATE',

                  style: TextStyle(

                    fontSize: 12,

                    fontWeight: FontWeight.w600,

                    color: MateColors.plum.withOpacity(0.65),

                  ),

                ),

                const SizedBox(height: 2),

                const Text(

                  '1.250 xu',

                  style: TextStyle(

                    fontSize: 22,

                    fontWeight: FontWeight.w900,

                    color: MateColors.plum,

                    height: 1.1,

                  ),

                ),

              ],

            ),

          ),

          TextButton.icon(

            onPressed: onTapHistory,

            icon: const Icon(Icons.history_rounded, size: 16),

            label: const Text('Lịch sử'),

            style: TextButton.styleFrom(

              foregroundColor: MateColors.pink,

              padding:

                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

              shape: RoundedRectangleBorder(

                borderRadius: BorderRadius.circular(MateRadius.pill),

                side: const BorderSide(color: MateColors.border),

              ),

            ),

          ),

        ],

      ),

    );

  }

}



// =====================================================================

// Section title

// =====================================================================



class _SectionTitle extends StatelessWidget {

  final String text;

  const _SectionTitle(this.text);



  @override

  Widget build(BuildContext context) {

    return Text(

      text,

      style: const TextStyle(

        fontSize: 15,

        fontWeight: FontWeight.w800,

        color: MateColors.plum,

      ),

    );

  }

}



// =====================================================================

// Gợi ý hẹn hò

// =====================================================================



class _DatingSuggestionCard extends StatelessWidget {

  const _DatingSuggestionCard();



  @override

  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: () {

        Navigator.of(context).push(

          MaterialPageRoute(

            builder: (_) => const DatePreferencesScreen(),

          ),

        );

      },

      behavior: HitTestBehavior.opaque,

      child: Container(

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(

          gradient: const LinearGradient(

            begin: Alignment.topLeft,

            end: Alignment.bottomRight,

            colors: [Color(0xFFFFB1CB), Color(0xFFFFD8E4)],

          ),

          borderRadius: BorderRadius.circular(MateRadius.card),

          boxShadow: MateShadows.hero,

        ),

        child: Row(

          children: [

            Container(

              width: 56,

              height: 56,

              alignment: Alignment.center,

              decoration: BoxDecoration(

                color: Colors.white.withOpacity(0.25),

                shape: BoxShape.circle,

              ),

              child: const Text('💗', style: TextStyle(fontSize: 28)),

            ),

            const SizedBox(width: 14),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: const [

                  Text(

                    'Gợi ý hẹn hò cho hai bạn',

                    style: TextStyle(

                      color: Colors.white,

                      fontSize: 15,

                      fontWeight: FontWeight.w800,

                    ),

                  ),

                  SizedBox(height: 4),

                  Text(

                    'Khám phá những địa điểm thú vị để tạo thêm kỷ niệm cùng người ấy.',

                    style: TextStyle(

                      color: Colors.white,

                      fontSize: 12,

                      height: 1.35,

                    ),

                  ),

                ],

              ),

            ),

            // Mũi tên hint hành động.

            Container(

              width: 32,

              height: 32,

              alignment: Alignment.center,

              decoration: BoxDecoration(

                color: Colors.white.withOpacity(0.25),

                shape: BoxShape.circle,

              ),

              child: const Icon(Icons.arrow_forward_rounded,

                  color: Colors.white, size: 18),

            ),

          ],

        ),

      ),

    );

  }

}

