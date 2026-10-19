import 'package:flutter/material.dart';
import '../../constants/mate_theme.dart';
import 'game_screens.dart';

/// =============================================================
// GamesListScreen - Màn hình danh sách 4 trò chơi cặp đôi.
//
// Mở từ tiện ích "Chơi" ở Tab 1 - Bản đồ.
// Đây là một route push lên stack Navigator của MapTab, KHÔNG phải
// tab mới trong Bottom Navigation, nên:
//   - Quay lại bằng nút Back hoặc swipe back.
//   - Trạng thái Tab 1 (bản đồ, vị trí) được IndexedStack giữ nguyên.
//
// Bố cục: danh sách card 1 cột dọc (SliverList) để tối ưu chiều rộng
// mobile 430px — tránh card bị kéo giãn như grid 2 cột trên web.
// =============================================================

class GamesListScreen extends StatelessWidget {
  const GamesListScreen({super.key});

  // Định nghĩa 4 game. Mỗi mục gồm icon, màu nền, mô tả, và một builder
  // trả về widget nội dung game (dùng cho GameDetailScreen).
  static final List<_GameItem> _games = [
    _GameItem(
      title: 'Hiểu nhau bao nhiêu?',
      emoji: '💕',
      icon: Icons.favorite_rounded,
      bgColor: const Color(0xFFFCE7F3),
      iconColor: const Color(0xFFE11D48),
      description: 'Thử xem hai bạn hiểu nhau đến mức nào!',
      builder: (_) => const QuizGame(),
    ),
    _GameItem(
      title: 'Caro tình yêu',
      emoji: '❌⭕',
      icon: Icons.grid_3x3_rounded,
      bgColor: const Color(0xFFF3E8FF),
      iconColor: const Color(0xFF9333EA),
      description: 'Cùng người ấy thử tài chiến thuật.',
      builder: (_) => const TicTacToeGame(),
    ),
    _GameItem(
      title: 'Đoán ý người yêu',
      emoji: '💭',
      icon: Icons.psychology_rounded,
      bgColor: const Color(0xFFE0F2FE),
      iconColor: const Color(0xFF0284C7),
      description: 'Hai người có đang nghĩ giống nhau?',
      builder: (_) => const MindReadGame(),
    ),
    _GameItem(
      title: 'Thử thách cặp đôi',
      emoji: '🏆',
      icon: Icons.emoji_events_rounded,
      bgColor: const Color(0xFFFEF9C3),
      iconColor: const Color(0xFFD97706),
      description: 'Cùng nhau hoàn thành những thử thách thú vị.',
      builder: (_) => const DailyChallengeGame(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF1),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header gradient
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
                            '🎮 Trò chơi của chúng mình',
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
                        'Cùng chơi, cùng hiểu nhau hơn 💕',
                        style: TextStyle(
                          fontSize: 14,
                          color: MateColors.plum.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Danh sách card 1 cột dọc - tối ưu cho chiều rộng mobile.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: EdgeInsets.only(
                      bottom: i == _games.length - 1 ? 0 : 12,
                    ),
                    child: _GameCard(
                      item: _games[i],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GameDetailScreen(
                              title: _games[i].title,
                              emoji: _games[i].emoji,
                              icon: _games[i].icon,
                              iconColor: _games[i].iconColor,
                              child: _games[i].builder(context),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  childCount: _games.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mô tả 1 trò chơi trong danh sách.
class _GameItem {
  final String title;
  final String emoji;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final String description;
  final WidgetBuilder builder;

  const _GameItem({
    required this.title,
    required this.emoji,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.description,
    required this.builder,
  });
}

/// Card hiển thị 1 trò chơi trong grid.
class _GameCard extends StatelessWidget {
  final _GameItem item;
  final VoidCallback onTap;
  const _GameCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(MateRadius.card),
          border: Border.all(color: MateColors.border),
          boxShadow: MateShadows.soft,
        ),
        // Bố cục ngang: icon trái - nội dung phải - nút CTA.
        child: Row(
          children: [
            // Icon vuông bo góc.
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: item.bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(item.icon, color: item.iconColor, size: 30),
            ),
            const SizedBox(width: 14),
            // Cột tên + mô tả.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: MateColors.plum,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: MateColors.plum.withOpacity(0.65),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Nút "Chơi ngay" pill gradient.
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: MateColors.primaryGradient,
                borderRadius: BorderRadius.circular(MateRadius.pill),
                boxShadow: MateShadows.cta,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Chơi ngay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
