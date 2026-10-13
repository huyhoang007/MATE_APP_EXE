import 'package:flutter/material.dart';
import '../../widgets/placeholder_tab.dart';

/// ============================================================
/// PetTab - Tab 2: Nhà của Pet (Màn hình chờ)
/// ============================================================

class PetTab extends StatelessWidget {
  const PetTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderTab(
      title: 'Nhà của Pet',
      subtitle: 'Không gian riêng cho thú cưng của hai bạn',
      icon: Icons.pets,
      placeholderTitle: 'Đang phát triển theo thiết kế',
      placeholderSubtitle: 'Tính năng nhà Pet sẽ sớm ra mắt',
    );
  }
}
