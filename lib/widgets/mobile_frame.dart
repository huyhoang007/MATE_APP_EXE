import 'package:flutter/material.dart';
import '../constants/mate_theme.dart';

/// ============================================================
/// MobileFrame - Responsive wrapper giới hạn max-width 430px
/// Khi chạy trên web/desktop, canh giữa và bo góc nhẹ như khung iPhone.
/// Khi chạy trên mobile, chiếm trọn màn hình.
/// ============================================================

class MobileFrame extends StatelessWidget {
  final Widget child;
  final Color? background;

  const MobileFrame({
    super.key,
    required this.child,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > kMobileMaxWidth + 32;

    if (!isWide) {
      return child;
    }

    return Container(
      color: background ?? const Color(0xFFFCE4EC),
      alignment: Alignment.center,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMobileMaxWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}