import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/mate_theme.dart';
import '../../models/couple_model.dart';
import '../mate_card.dart';

/// ============================================================
/// PetCard - Pet chibi + 2 chỉ số chính (hunger, happiness) + level/exp.
/// Bấm nút "Cho ăn" / "Xoa đầu" để tương tác (haptic + animation).
/// Pet có thể được tạo nhanh bằng Container thuần (tránh phụ thuộc asset).
/// ============================================================

class PetCard extends StatefulWidget {
  final PetState pet;
  final bool isUser1;
  final String coupleCode;
  final ValueChanged<PetState> onFeed;
  final ValueChanged<PetState> onPlay;

  const PetCard({
    super.key,
    required this.pet,
    required this.isUser1,
    required this.coupleCode,
    required this.onFeed,
    required this.onPlay,
  });

  @override
  State<PetCard> createState() => _PetCardState();
}

class _PetCardState extends State<PetCard> with TickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounce;
  final List<_HeartParticle> _particles = [];
  int _particleId = 0;
  String _message = 'Chào cậu chủ! 💕';

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounce = CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _spawnParticle({required bool isFood}) {
    final id = _particleId++;
    setState(() => _particles.add(_HeartParticle(id: id, isFood: isFood)));
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _particles.removeWhere((p) => p.id == id));
    });
  }

  void _feed() {
    HapticFeedback.lightImpact();
    setState(() => _message = 'Ăn ngon quá! Cảm ơn cậu 🍔');
    _spawnParticle(isFood: true);
    _bounceCtrl.forward(from: 0);
    widget.onFeed(widget.pet);
  }

  void _play() {
    HapticFeedback.lightImpact();
    setState(() => _message = 'Vui quá đi! Chơi nữa nha 🎮');
    _spawnParticle(isFood: false);
    _bounceCtrl.forward(from: 0);
    widget.onPlay(widget.pet);
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    return MateCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              // Pet name + level
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🐾', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    pet.name,
                    style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      color: MateColors.plum,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: MateColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Lv.${pet.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Pet chibi với animation
              _buildPet(pet: pet),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: MateColors.subtlePink,
                  borderRadius: BorderRadius.circular(MateRadius.pill),
                ),
                child: Text(
                  _message,
                  style: const TextStyle(
                    color: MateColors.plum,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // EXP bar
              _ExpBar(level: pet.level, exp: pet.exp),
              const SizedBox(height: 14),

              // 2 chỉ số: hunger, happiness
              _StatBar(
                icon: Icons.restaurant,
                label: 'Độ no bụng',
                value: pet.hunger,
                color: const Color(0xFFFFB347),
              ),
              const SizedBox(height: 10),
              _StatBar(
                icon: Icons.favorite,
                label: 'Hạnh phúc',
                value: pet.happiness,
                color: MateColors.pink,
              ),
              const SizedBox(height: 16),

              // 2 nút tương tác
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.restaurant_menu,
                    label: 'Cho ăn',
                    onTap: _feed,
                  ),
                  _ActionButton(
                    icon: Icons.pets,
                    label: 'Xoa đầu',
                    onTap: _play,
                  ),
                ],
              ),
            ],
          ),

          // Floating particles overlay
          ..._particles.map((p) => _Particle(
                key: ValueKey(p.id),
                isFood: p.isFood,
              )),
        ],
      ),
    );
  }

  Widget _buildPet({required PetState pet}) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) {
        final scale = 1 + _bounce.value * 0.18;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Colors.white, MateColors.subtlePink],
          ),
          border: Border.all(color: MateColors.border, width: 3),
          boxShadow: [
            BoxShadow(
              color: MateColors.pink.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 14,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.rotate(
                    angle: -0.4,
                    child: Container(
                      width: 24,
                      height: 30,
                      decoration: BoxDecoration(
                        color: MateColors.pink,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(4),
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Transform.rotate(
                    angle: 0.4,
                    child: Container(
                      width: 24,
                      height: 30,
                      decoration: BoxDecoration(
                        color: MateColors.pink,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: MateColors.border, width: 2),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _eye(),
                      const SizedBox(width: 14),
                      _eye(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 6,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: MateColors.plum,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(left: 18, bottom: 32, child: _Cheek()),
            const Positioned(right: 18, bottom: 32, child: _Cheek()),
          ],
        ),
      ),
    );
  }

  Widget _eye() => Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: MateColors.plum,
          shape: BoxShape.circle,
        ),
      );
}

class _ExpBar extends StatelessWidget {
  final int level;
  final int exp;
  const _ExpBar({required this.level, required this.exp});

  @override
  Widget build(BuildContext context) {
    final pct = (exp / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '⭐ EXP',
              style: TextStyle(
                color: MateColors.plum,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$exp / 100',
              style: const TextStyle(
                color: MateColors.rose,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: MateColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (context, v, _) => FractionallySizedBox(
                widthFactor: v,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [MateColors.pink, MateColors.pinkDeep],
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;
  const _StatBar({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: MateColors.plum,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: const TextStyle(
                      color: MateColors.rose,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: MateColors.border,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: value),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, v, _) => FractionallySizedBox(
                      widthFactor: v,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: MateColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: MateColors.pink.withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: MateColors.plum,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Cheek extends StatelessWidget {
  const _Cheek();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 8,
      decoration: BoxDecoration(
        color: MateColors.pink.withOpacity(0.4),
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}

class _HeartParticle {
  final int id;
  final bool isFood;
  _HeartParticle({required this.id, required this.isFood});
}

class _Particle extends StatefulWidget {
  final bool isFood;
  const _Particle({super.key, required this.isFood});

  @override
  State<_Particle> createState() => _ParticleState();
}

class _ParticleState extends State<_Particle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final t = _anim.value;
        final dx = math.sin(t * math.pi * 2) * 30;
        return Positioned(
          left: MediaQuery.of(context).size.width * 0.5 - 14 + dx,
          top: 140 - t * 100,
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.5 + t * 0.7,
              child: Icon(
                widget.isFood ? Icons.restaurant : Icons.favorite,
                color: widget.isFood
                    ? const Color(0xFFFFB347)
                    : MateColors.pinkDeep,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }
}