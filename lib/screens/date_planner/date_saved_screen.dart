// =====================================================================
// Date Saved Screen - Kế hoạch đã lưu
// =====================================================================

import 'package:flutter/material.dart';
import '../../constants/mate_theme.dart';
import 'date_models.dart';
import 'date_planner_service.dart';
import 'date_widgets.dart';
import 'date_result_screen.dart';

class DateSavedScreen extends StatefulWidget {
  const DateSavedScreen({super.key});

  @override
  State<DateSavedScreen> createState() => _DateSavedScreenState();
}

class _DateSavedScreenState extends State<DateSavedScreen> {
  late Future<List<DatePlan>> _future;

  @override
  void initState() {
    super.initState();
    _future = DatePlannerService.instance.loadSavedPlans();
  }

  void _reload() {
    setState(() {
      _future = DatePlannerService.instance.loadSavedPlans();
    });
  }

  Future<void> _delete(DatePlan plan) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Xóa kế hoạch?'),
        content: Text('"${plan.dateLabel}" sẽ bị xóa khỏi thiết bị.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DatePlannerService.instance.deletePlan(plan.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF1),
      body: SafeArea(
        child: Column(
          children: [
            const DateHeader(
              title: 'Kế hoạch đã lưu',
              subtitle: 'Mở lại hoặc xóa các buổi hẹn bạn đã lên lịch',
            ),
            Expanded(
              child: FutureBuilder<List<DatePlan>>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: MateColors.pink),
                    );
                  }
                  final list = snap.data ?? [];
                  if (list.isEmpty) return _empty();
                  return ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final p = list[i];
                      return _PlanCard(
                        plan: p,
                        onOpen: () async {
                          // Mở lại bằng cách dựng lại DateResultScreen
                          // với stops đã lưu. mood/slot/budget ở đây chỉ
                          // là default để hợp lệ tham số - UI hiển thị
                          // lại đúng stops từ plan đã lưu.
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DateResultScreen(
                                area: p.area,
                                date: p.createdAt,
                                budget: BudgetRange.ranges[1],
                                mood: DateMood.romantic,
                                slot: TimeSlot.evening,
                                initialStops: p.stops,
                              ),
                            ),
                          );
                          _reload();
                        },
                        onDelete: () => _delete(p),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_border_rounded,
                size: 56, color: MateColors.rose),
            const SizedBox(height: 8),
            const Text(
              'Chưa có kế hoạch nào',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: MateColors.plum,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hãy tạo lịch hẹn và bấm "Lưu kế hoạch" để xem lại ở đây nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: MateColors.plum.withOpacity(0.6),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final DatePlan plan;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  const _PlanCard({
    required this.plan,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MateRadius.card),
          border: Border.all(color: MateColors.border),
          boxShadow: MateShadows.soft,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB1CB), Color(0xFFFFD8E4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_month_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.dateLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: MateColors.plum,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${plan.area} • ${plan.moodLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: MateColors.plum.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: MateColors.rose, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _tag(plan.budgetLabel),
                ...plan.categoryLabels.map(_tag),
                _tag('${plan.stops.length} điểm'),
                _tag(_formatVnd(plan.totalCost)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Mở lại'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MateColors.pink,
                  side: const BorderSide(color: MateColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MateRadius.pill),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: MateColors.subtlePink,
        borderRadius: BorderRadius.circular(MateRadius.pill),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: MateColors.rose,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _formatVnd(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${buf.toString()}đ';
}
