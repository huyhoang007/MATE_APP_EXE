import 'package:flutter/material.dart';
import '../../widgets/placeholder_tab.dart';

/// ============================================================
/// ChatTab - Tab 4: Dòng thời gian & Nhắn tin (Màn hình chờ)
/// ============================================================

class ChatTab extends StatelessWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderTab(
      title: 'Nhắn tin',
      subtitle: 'Tin nhắn riêng tư giữa hai bạn',
      icon: Icons.chat_bubble,
      placeholderTitle: 'Tin nhắn 1-1',
      placeholderSubtitle: 'Sắp ra mắt trong phiên bản tiếp theo',
    );
  }
}
