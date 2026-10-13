import 'package:flutter/material.dart';
import '../../widgets/placeholder_tab.dart';

/// ============================================================
/// MemoriesTab - Tab 3: Camera / Khoảnh khắc (Màn hình chờ)
/// ============================================================

class MemoriesTab extends StatelessWidget {
  const MemoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderTab(
      title: 'Khoảnh khắc',
      subtitle: 'Lưu giữ kỷ niệm đẹp của hai bạn',
      icon: Icons.camera_alt,
      placeholderTitle: 'Camera & Timeline',
      placeholderSubtitle: 'Sắp ra mắt trong phiên bản tiếp theo',
    );
  }
}
