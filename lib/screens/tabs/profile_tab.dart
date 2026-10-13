import 'package:flutter/material.dart';
import '../../widgets/placeholder_tab.dart';

/// ============================================================
/// ProfileTab - Tab 5: Hồ sơ cặp đôi (Màn hình chờ)
/// ============================================================

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderTab(
      title: 'Hồ sơ cặp đôi',
      subtitle: 'Thông tin & cài đặt của hai bạn',
      icon: Icons.person,
      placeholderTitle: 'Hồ sơ cá nhân',
      placeholderSubtitle: 'Sắp ra mắt trong phiên bản tiếp theo',
    );
  }
}
