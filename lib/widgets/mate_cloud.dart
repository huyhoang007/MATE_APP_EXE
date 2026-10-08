import 'package:flutter/material.dart';

/// ============================================================
/// MateCloud - Widget mây trang trí nền
/// Dùng để trang trí cho các màn hình với tone hồng pastel.
/// ============================================================

class MateCloud extends StatelessWidget {
  final double size;
  final Color? color;

  const MateCloud({
    super.key,
    this.size = 160,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cloudColor = color ?? Colors.white.withOpacity(0.9);
    return SizedBox(
      width: size,
      height: size * 0.4,
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: size * 0.25,
              decoration: BoxDecoration(
                color: cloudColor,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.08,
            left: size * 0.15,
            child: CircleAvatar(
              radius: size * 0.17,
              backgroundColor: cloudColor,
            ),
          ),
          Positioned(
            bottom: size * 0.08,
            left: size * 0.4,
            child: CircleAvatar(
              radius: size * 0.2,
              backgroundColor: cloudColor,
            ),
          ),
        ],
      ),
    );
  }
}