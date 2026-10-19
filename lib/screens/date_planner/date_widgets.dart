// =====================================================================
// Date Planner - Shared widgets.
// =====================================================================

import 'package:flutter/material.dart';
import '../../constants/mate_theme.dart';

class DateHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const DateHeader({super.key, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFC1D3), Color(0xFFFFEBF1)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: MateColors.plum),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.7),
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: MateColors.plum,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (action != null) action!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 13,
                  color: MateColors.plum.withOpacity(0.7),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip chọn đơn (cho budget, mood, slot).
class SelectChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  const SelectChip({
    super.key,
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? MateColors.pink : Colors.white,
          borderRadius: BorderRadius.circular(MateRadius.pill),
          border: Border.all(
            color: selected ? MateColors.pink : MateColors.border,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected ? MateShadows.cta : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : MateColors.rose,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : MateColors.plum,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section title trong form.
class SectionTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  const SectionTitle(this.text, {super.key, this.icon});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: MateColors.pink, size: 18),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: MateColors.plum,
            ),
          ),
        ],
      ),
    );
  }
}

// Re-exports for screens in same package.
// (classes already public; nothing more to do)
