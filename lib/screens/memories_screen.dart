import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/mate_theme.dart';
import '../widgets/mate_card.dart';
import '../widgets/mate_cloud.dart';

/// ============================================================
/// MemoriesScreen (placeholder) - Timeline nhật ký ảnh
/// ============================================================

class MemoriesScreen extends StatelessWidget {
  const MemoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: MateColors.bgGradient),
      child: Stack(
        children: [
          const Positioned(right: -40, top: 120, child: MateCloud(size: 130)),
          const Positioned(left: -30, bottom: 120, child: MateCloud(size: 170)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kỷ niệm',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: MateColors.plum,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Nhật ký hành trình yêu thương của hai bạn',
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
                            child: const Icon(Icons.photo_library,
                                color: Colors.white, size: 60),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '📸 Sắp ra mắt',
                            style: TextStyle(
                              color: MateColors.plum,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Timeline ảnh & nhật ký chung sẽ có trong phiên bản tiếp theo',
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