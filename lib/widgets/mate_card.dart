import 'package:flutter/material.dart';
import '../constants/mate_theme.dart';

/// ============================================================
/// MateCard - Thẻ giao diện dùng chung
/// Bo góc 24px, viền mảnh pastel, nền trắng mờ 95%, đổ bóng mềm.
/// ============================================================

class MateCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const MateCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: onTap != null ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: MateColors.cardBg,
          borderRadius: BorderRadius.circular(MateRadius.card),
          border: Border.all(color: MateColors.border),
          boxShadow: MateShadows.soft,
        ),
        child: child,
      ),
    );
  }
}