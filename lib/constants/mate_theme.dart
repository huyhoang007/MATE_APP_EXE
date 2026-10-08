import 'package:flutter/material.dart';

/// ============================================================
/// MATE - Design System Constants
/// Pastel Pink theme cho cặp đôi Gen Z - Modern Romantic style.
/// ============================================================

class MateColors {
  MateColors._();

  // Gradient nền chính (Top/Bottom)
  static const Color gradientTop = Color(0xFFFFC1D3);
  static const Color gradientBottom = Color(0xFFFFEBF1);
  static const Color cream = Color(0xFFFFF7FA);

  // Text
  static const Color plum = Color(0xFF5C1D2E);
  static const Color rose = Color(0xFFA86E7E);

  // Borders & accents
  static const Color border = Color(0xFFFFE0EA);
  static const Color pink = Color(0xFFFF5C8A);
  static const Color pinkDeep = Color(0xFFFF3B69);

  // Status colors
  static const Color online = Color(0xFF4CD964);
  static const Color offline = Color(0xFFB7B7B7);
  static const Color warning = Color(0xFFFFB347);
  static const Color info = Color(0xFF7EC8E3);

  // Background helpers
  static Color get cardBg => Colors.white.withOpacity(0.95);
  static Color get fieldBg => const Color(0xFFFFE0EA).withOpacity(0.4);
  static Color get subtlePink => const Color(0xFFFFE0EA).withOpacity(0.3);

  // Gradient CTA chính
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [pink, pinkDeep],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Gradient nền màn hình
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientTop, gradientBottom],
  );

  // Gradient hero cho Anniversary card
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB1CB), Color(0xFFFFD8E4)],
  );
}

class MateShadows {
  MateShadows._();

  // Shadow mềm cho card thường
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: const Color(0xFFFF5C8A).withOpacity(0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // Shadow nổi bật cho hero card
  static List<BoxShadow> get hero => [
        BoxShadow(
          color: const Color(0xFFFF3B69).withOpacity(0.22),
          blurRadius: 32,
          offset: const Offset(0, 14),
        ),
      ];

  // Shadow mạnh cho CTA
  static List<BoxShadow> get cta => [
        BoxShadow(
          color: const Color(0xFFFF3B69).withOpacity(0.45),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];

  // Shadow cho floating dock
  static List<BoxShadow> get dock => [
        BoxShadow(
          color: const Color(0xFFFF5C8A).withOpacity(0.22),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  // Shadow mảnh cho header avatar
  static List<BoxShadow> get avatar => [
        BoxShadow(
          color: const Color(0xFFFF3B69).withOpacity(0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

class MateRadius {
  MateRadius._();
  static const double card = 24;
  static const double cardLg = 28;
  static const double field = 16;
  static const double pill = 100;
  static const double dock = 32;
}

/// Max-width cho mobile frame. Web sẽ hiển thị như iPhone 14 Pro Max.
const double kMobileMaxWidth = 430;
