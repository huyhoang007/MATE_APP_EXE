import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/mate_theme.dart';
import '../../models/couple_model.dart';
import '../mate_card.dart';

/// ============================================================
/// HeaderCard - Hiển thị 2 avatar lồng ghép + heart beat.
/// Status, pin, khoảng cách của 2 người.
/// ============================================================

class HeaderCard extends StatefulWidget {
  final UserInfo me;
  final UserInfo partner;
  final double? distanceKm;
  final VoidCallback? onEdit;

  const HeaderCard({
    super.key,
    required this.me,
    required this.partner,
    this.distanceKm,
    this.onEdit,
  });

  @override
  State<HeaderCard> createState() => _HeaderCardState();
}

class _HeaderCardState extends State<HeaderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartCtrl;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MateCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _UserColumn(user: widget.me, align: CrossAxisAlignment.end)),
              const SizedBox(width: 8),
              _HeartBeat(ctrl: _heartCtrl),
              const SizedBox(width: 8),
              Expanded(
                child: _UserColumn(user: widget.partner, align: CrossAxisAlignment.start),
              ),
            ],
          ),
          if (widget.distanceKm != null) ...[
            const SizedBox(height: 10),
            _DistancePill(km: widget.distanceKm!),
          ],
        ],
      ),
    );
  }
}

class _UserColumn extends StatelessWidget {
  final UserInfo user;
  final CrossAxisAlignment align;
  const _UserColumn({required this.user, required this.align});

  @override
  Widget build(BuildContext context) {
    final isRight = align == CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        Stack(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [MateColors.pink, MateColors.pinkDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: MateShadows.avatar,
              ),
              alignment: Alignment.center,
              child: Text(
                _initial(user.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: user.isOnline ? MateColors.online : MateColors.offline,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 80,
          child: Text(
            user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: isRight ? TextAlign.start : TextAlign.end,
            style: TextStyle(
              color: MateColors.plum,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: GoogleFonts.poppins().fontFamily,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRight) const Spacer(),
            Icon(
              user.isOnline ? Icons.bolt : Icons.power_settings_new,
              size: 12,
              color: user.isOnline ? MateColors.warning : MateColors.rose,
            ),
            const SizedBox(width: 2),
            Text(
              user.isOnline ? '${user.batteryLevel}%' : 'off',
              style: TextStyle(
                fontSize: 10,
                color: MateColors.rose,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isRight) const Spacer(),
          ],
        ),
      ],
    );
  }

  String _initial(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }
}

class _HeartBeat extends StatelessWidget {
  final AnimationController ctrl;
  const _HeartBeat({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        final scale = 1.0 + (ctrl.value - 0.5).abs() * 0.18;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: MateColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: MateColors.pink.withOpacity(0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.favorite, color: Colors.white, size: 18),
          ),
        );
      },
    );
  }
}

class _DistancePill extends StatelessWidget {
  final double km;
  const _DistancePill({required this.km});

  @override
  Widget build(BuildContext context) {
    final txt = km < 1
        ? '${(km * 1000).round()} m'
        : '${km.toStringAsFixed(1)} km';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: MateColors.subtlePink,
        borderRadius: BorderRadius.circular(MateRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, size: 12, color: MateColors.pinkDeep),
          const SizedBox(width: 4),
          Text(
            'Cách nhau $txt',
            style: const TextStyle(
              color: MateColors.pinkDeep,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}