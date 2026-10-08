import 'package:flutter/material.dart';

import '../../constants/mate_theme.dart';
import '../mate_card.dart';

/// ============================================================
/// QuickActions - 2 lối tắt tiện ích: Hôm nay ăn gì? / Vị trí GPS.
/// ============================================================

class QuickActions extends StatelessWidget {
  final VoidCallback onFoodTap;
  final VoidCallback onGpsTap;

  const QuickActions({
    super.key,
    required this.onFoodTap,
    required this.onGpsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Action(
            icon: Icons.restaurant_menu,
            label: 'Hôm nay ăn gì?',
            color: const Color(0xFFFFB347),
            onTap: onFoodTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Action(
            icon: Icons.location_on,
            label: 'Vị trí GPS',
            color: const Color(0xFF7EC8E3),
            onTap: onGpsTap,
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MateCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: MateColors.plum,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}