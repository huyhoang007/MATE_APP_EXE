// =====================================================================
// Date Preferences Screen - Màn hình 1
// =====================================================================
//
// Form chọn: khu vực, ngân sách, ngày giờ, sở thích, phong cách.
// Bấm "Lên lịch hẹn cho chúng mình" -> sang Màn hình 2.

import 'package:flutter/material.dart';
import '../../constants/mate_theme.dart';
import 'date_models.dart';
import 'date_planner_service.dart';
import 'date_widgets.dart';
import 'date_result_screen.dart';
import 'date_saved_screen.dart';

/// Format ngày kiểu "Thứ 7, 18/10/2026" — không cần package intl.
String _formatViDate(DateTime d) {
  const weekdays = [
    'Thứ 2',
    'Thứ 3',
    'Thứ 4',
    'Thứ 5',
    'Thứ 6',
    'Thứ 7',
    'Chủ nhật',
  ];
  final wd = weekdays[d.weekday - 1];
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$wd, $dd/$mm/${d.year}';
}

class DatePreferencesScreen extends StatefulWidget {
  const DatePreferencesScreen({super.key});

  @override
  State<DatePreferencesScreen> createState() => _DatePreferencesScreenState();
}

class _DatePreferencesScreenState extends State<DatePreferencesScreen> {
  // Mặc định chọn sẵn để demo nhanh.
  final _areaCtl = TextEditingController(text: 'Quận 1');
  BudgetRange _budget = BudgetRange.ranges[1]; // 200-500K
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeSlot _slot = TimeSlot.evening;
  final Set<DateCategory> _categories = {
    DateCategory.eat,
    DateCategory.movie,
  };
  DateMood _mood = DateMood.romantic;

  @override
  void dispose() {
    _areaCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: MateColors.pink,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: MateColors.plum,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final stops = DatePlannerService.instance.buildItinerary(
      area: _areaCtl.text.trim(),
      budget: _budget,
      mood: _mood,
      categories: _categories,
      slot: _slot,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DateResultScreen(
          area: _areaCtl.text.trim().isEmpty ? 'Khu vực của bạn' : _areaCtl.text.trim(),
          date: _date,
          budget: _budget,
          mood: _mood,
          slot: _slot,
          initialStops: stops,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatViDate(_date);
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF1),
      body: SafeArea(
        child: Column(
          children: [
            DateHeader(
              title: '💕 Hôm nay chúng mình đi đâu?',
              subtitle:
                  'Chọn một vài điều bạn thích, MATE sẽ giúp hai bạn lên kế hoạch hẹn hò.',
              action: IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DateSavedScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bookmark_rounded,
                    color: MateColors.pink),
                tooltip: 'Kế hoạch đã lưu',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.7),
                  shape: const CircleBorder(),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ----- Khu vực -----
                    const SectionTitle('Khu vực hẹn hò',
                        icon: Icons.location_on_rounded),
                    TextField(
                      controller: _areaCtl,
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: Quận 1, Quận 3, Thủ Đức…',
                        hintStyle: TextStyle(
                          color: MateColors.plum.withOpacity(0.5),
                          fontSize: 13.5,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: MateColors.rose),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(MateRadius.field),
                          borderSide: const BorderSide(
                              color: MateColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(MateRadius.field),
                          borderSide: const BorderSide(
                              color: MateColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(MateRadius.field),
                          borderSide: const BorderSide(
                              color: MateColors.pink, width: 1.4),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: const [
                        'Tất cả',
                        'Quận 1',
                        'Quận 3',
                        'Quận 7',
                        'Thủ Đức',
                        'Quận 9',
                      ]
                          .map((s) => GestureDetector(
                                onTap: () =>
                                    setState(() => _areaCtl.text = s),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: MateColors.subtlePink,
                                    borderRadius: BorderRadius.circular(
                                        MateRadius.pill),
                                  ),
                                  child: Text(
                                    s,
                                    style: const TextStyle(
                                      color: MateColors.rose,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),

                    const SizedBox(height: 16),

                    // ----- Ngân sách -----
                    const SectionTitle('Ngân sách',
                        icon: Icons.payments_rounded),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: BudgetRange.ranges
                          .map(
                            (b) => SelectChip(
                              label: b.label,
                              selected: _budget.id == b.id,
                              onTap: () => setState(() => _budget = b),
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: 16),

                    // ----- Ngày & khung giờ -----
                    const SectionTitle('Ngày & khung giờ',
                        icon: Icons.event_rounded),
                    GestureDetector(
                      onTap: _pickDate,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(MateRadius.field),
                          border: Border.all(color: MateColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: MateColors.rose, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                dateLabel,
                                style: const TextStyle(
                                  color: MateColors.plum,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(Icons.edit_calendar_rounded,
                                color: MateColors.rose, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TimeSlot.values
                          .map(
                            (s) => SelectChip(
                              label: s.label,
                              icon: s.icon,
                              selected: _slot == s,
                              onTap: () => setState(() => _slot = s),
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: 16),

                    // ----- Sở thích (multi) -----
                    const SectionTitle('Sở thích',
                        icon: Icons.favorite_rounded),
                    Text(
                      'Có thể chọn nhiều',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: MateColors.plum.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: DateCategory.values
                          .map(
                            (c) => SelectChip(
                              label: c.label,
                              icon: c.icon,
                              selected: _categories.contains(c),
                              onTap: () => setState(() {
                                if (_categories.contains(c)) {
                                  _categories.remove(c);
                                } else {
                                  _categories.add(c);
                                }
                              }),
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: 16),

                    // ----- Phong cách (single) -----
                    const SectionTitle('Phong cách hẹn hò',
                        icon: Icons.auto_awesome_rounded),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: DateMood.values
                          .map(
                            (m) => SelectChip(
                              label: m.label,
                              icon: m.icon,
                              selected: _mood == m,
                              onTap: () => setState(() => _mood = m),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('Lên lịch hẹn cho chúng mình'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MateColors.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MateRadius.pill),
                ),
                textStyle: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
