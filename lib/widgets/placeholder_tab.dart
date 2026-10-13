import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/mate_theme.dart';
import 'mate_card.dart';
import 'mate_cloud.dart';

/// ============================================================
/// PlaceholderTab - UI dùng chung cho các tab đang phát triển.
/// ============================================================

class PlaceholderTab extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String placeholderTitle;
  final String placeholderSubtitle;

  const PlaceholderTab({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.placeholderTitle,
    required this.placeholderSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: MateColors.bgGradient),
      child: Stack(
        children: [
          const Positioned(left: -30, top: 80, child: MateCloud(size: 140)),
          const Positioned(right: -40, bottom: 100, child: MateCloud(size: 160)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      color: MateColors.plum,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: MateColors.rose, fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: MateCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120, height: 120,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: MateColors.primaryGradient,
                            ),
                            alignment: Alignment.center,
                            child: Icon(icon, color: Colors.white, size: 60),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            placeholderTitle,
                            style: const TextStyle(
                              color: MateColors.plum, fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            placeholderSubtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: MateColors.rose, fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
