import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/mate_theme.dart';
import '../widgets/mate_card.dart';
import '../widgets/mate_cloud.dart';

/// ============================================================
/// MapScreen (placeholder) - Bản đồ GPS 1-1
/// ============================================================

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

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
                    'Bản đồ đôi',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: MateColors.plum,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Chia sẻ vị trí 1-1 với người yêu',
                    style: TextStyle(color: MateColors.rose, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: MateCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: MateColors.primaryGradient,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.location_on,
                                color: Colors.white, size: 60),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '📍 Đang phát triển',
                            style: TextStyle(
                              color: MateColors.plum,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tính năng bản đồ thời gian thực sẽ sớm ra mắt',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: MateColors.rose, fontSize: 13),
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