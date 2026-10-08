import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/mate_theme.dart';

/// ============================================================
/// AnniversaryCard - Đếm ngày yêu, font số lớn nổi bật.
/// Bấm vào ngày để mở DatePicker chỉnh sửa.
/// ============================================================

class AnniversaryCard extends StatelessWidget {
  final DateTime startDate;
  final ValueChanged<DateTime>? onDateChanged;

  const AnniversaryCard({
    super.key,
    required this.startDate,
    this.onDateChanged,
  });

  int get _days {
    return DateTime.now().difference(startDate).inDays.abs();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        gradient: MateColors.heroGradient,
        borderRadius: BorderRadius.circular(MateRadius.cardLg),
        boxShadow: MateShadows.hero,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.favorite, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(
                'Đã yêu nhau',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.favorite, color: Colors.white, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_days.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.w800,
              height: 1,
              shadows: const [
                Shadow(
                  color: Color(0x55000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ngày',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _editDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(MateRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event,
                      size: 14, color: MateColors.pinkDeep),
                  const SizedBox(width: 6),
                  Text(
                    'Từ ${_formatDate(startDate)}',
                    style: const TextStyle(
                      color: MateColors.pinkDeep,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit,
                      size: 12, color: MateColors.pinkDeep),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MateColors.pinkDeep,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: MateColors.plum,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && onDateChanged != null) {
      onDateChanged!(picked);
    }
  }
}