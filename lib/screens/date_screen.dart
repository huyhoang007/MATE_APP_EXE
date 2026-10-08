import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/mate_theme.dart';
import '../widgets/mate_card.dart';
import '../widgets/mate_cloud.dart';

/// ============================================================
/// DateScreen (placeholder) - Vòng quay chọn quán/món ăn
/// ============================================================

class DateScreen extends StatefulWidget {
  const DateScreen({super.key});

  @override
  State<DateScreen> createState() => _DateScreenState();
}

class _DateScreenState extends State<DateScreen> {
  double _rotation = 0;
  String _result = '';
  bool _spinning = false;

  final List<String> _options = [
    '🍕 Pizza',
    '🍜 Phở',
    '🍣 Sushi',
    '🍔 Burger',
    '🥗 Salad',
    '🍰 Bánh ngọt',
    '☕ Café',
    '🌮 Taco',
  ];

  Future<void> _spin() async {
    if (_spinning) return;
    setState(() {
      _spinning = true;
      _result = '';
    });

    final rand = math.Random();
    final turns = 5 + rand.nextInt(3); // 5-7 vòng
    final extra = rand.nextDouble() * 2 * math.pi;
    final target = _rotation + turns * 2 * math.pi + extra;

    // Chờ animation kết thúc (~1.6s)
    await Future.delayed(const Duration(milliseconds: 1600));

    if (!mounted) return;
    final index = ((target / (2 * math.pi)) * _options.length).round() % _options.length;
    setState(() {
      _rotation = target;
      _result = _options[index];
      _spinning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: MateColors.bgGradient),
      child: Stack(
        children: [
          const Positioned(left: -40, top: 100, child: MateCloud(size: 150)),
          const Positioned(right: -30, bottom: 140, child: MateCloud(size: 180)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hẹn hò',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: MateColors.plum,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Vòng quay chọn quán ăn cùng người yêu',
                    style: TextStyle(color: MateColors.rose, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: MateCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '🎯 Quay vòng chọn món',
                            style: TextStyle(
                              color: MateColors.plum,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: _rotation),
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return Transform.rotate(
                                angle: value,
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: MateColors.primaryGradient,
                                    boxShadow: MateShadows.cta,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.casino,
                                      color: Colors.white, size: 80),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _result.isNotEmpty
                                ? Container(
                                    key: ValueKey(_result),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: MateColors.subtlePink,
                                      borderRadius:
                                          BorderRadius.circular(MateRadius.pill),
                                    ),
                                    child: Text(
                                      'Hôm nay ăn: $_result',
                                      style: const TextStyle(
                                        color: MateColors.plum,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    key: ValueKey('hint'),
                                    'Nhấn nút bên dưới để quay',
                                    style: TextStyle(
                                        color: MateColors.rose, fontSize: 13),
                                  ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _spinning ? null : _spin,
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: Text(
                              _spinning ? 'Đang quay...' : 'Quay ngay',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MateColors.pinkDeep,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 14),
                              shape: const StadiumBorder(),
                              elevation: 6,
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