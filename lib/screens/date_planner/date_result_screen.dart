// =====================================================================
// Date Result Screen - Màn hình 2: Lịch trình gợi ý
// =====================================================================

import 'package:flutter/material.dart';
import '../../constants/mate_theme.dart';
import 'date_models.dart';
import 'date_planner_service.dart';
import 'date_widgets.dart';
import 'date_place_detail_screen.dart';

class DateResultScreen extends StatefulWidget {
  final String area;
  final DateTime date;
  final BudgetRange budget;
  final DateMood mood;
  final TimeSlot slot;
  final List<ItineraryStop> initialStops;

  const DateResultScreen({
    super.key,
    required this.area,
    required this.date,
    required this.budget,
    required this.mood,
    required this.slot,
    required this.initialStops,
  });

  @override
  State<DateResultScreen> createState() => _DateResultScreenState();
}

class _DateResultScreenState extends State<DateResultScreen> {
  late List<ItineraryStop> _stops;

  @override
  void initState() {
    super.initState();
    _stops = List.from(widget.initialStops);
  }

  int get _totalCost =>
      _stops.fold<int>(0, (sum, s) => sum + s.place.pricePerTwo);

  int get _totalMinutes =>
      _stops.fold<int>(0, (sum, s) => sum + s.place.durationMin);

  /// Gợi ý 1 lịch trình khác: xáo trộn category ưu tiên.
  void _regenerate() {
    // Tạm thời loại các stop đang dùng để gợi ý ưu tiên các điểm khác.
    final usedIds = _stops.map((s) => s.place.id).toSet();
    final oldCats = _stops.map((s) => s.place.category).toSet();

    // Bỏ chọn 1 category ngẫu nhiên và thêm 1 category khác.
    final allCats = DateCategory.values.toList();
    final newCats = Set<DateCategory>.from(oldCats);
    if (oldCats.length > 1) {
      newCats.remove(oldCats.first);
    }
    final others = allCats.where((c) => !newCats.contains(c)).toList();
    if (others.isNotEmpty) {
      newCats.add(others.first);
    }

    final next = DatePlannerService.instance.buildItinerary(
      area: widget.area,
      budget: widget.budget,
      mood: widget.mood,
      categories: newCats,
      slot: widget.slot,
    ).where((s) => !usedIds.contains(s.place.id)).toList();

    if (next.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hết phương án khác trong khu vực này. '
              'Hãy thử đổi khu vực hoặc nới rộng ngân sách.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _stops = next;
    });
  }

  Future<void> _savePlan() async {
    final plan = DatePlan(
      id: 'dp_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      dateLabel: _dateLabel(widget.date),
      area: widget.area,
      budgetLabel: widget.budget.label,
      moodLabel: widget.mood.label,
      categoryLabels: _stops.map((s) => s.place.category.label).toSet().toList(),
      stops: _stops,
      totalCost: _totalCost,
      totalMinutes: _totalMinutes,
    );
    await DatePlannerService.instance.savePlan(plan);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu kế hoạch vào thiết bị 💕'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _replaceStop(int index) async {
    final cur = _stops[index];
    final alts = DatePlannerService.instance.suggestAlternatives(
      current: cur.place,
      budget: widget.budget,
      mood: widget.mood,
      slot: widget.slot,
      area: widget.area,
    );
    if (!mounted) return;

    final picked = await showModalBottomSheet<DatePlace>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AlternativesSheet(
        title: 'Thay "${cur.place.name}"',
        options: alts,
        slot: widget.slot,
      ),
    );
    if (picked == null) return;
    setState(() {
      _stops[index] = ItineraryStop(
        time: cur.time,
        place: picked,
        note: cur.note,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_stops.isEmpty) return _empty();
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF1),
      body: SafeArea(
        child: Column(
          children: [
            DateHeader(
              title: 'Lịch hẹn của chúng mình 💕',
              subtitle:
                  '${_dateLabel(widget.date)} • ${widget.area} • ${widget.slot.label}',
            ),
            // Tóm tắt
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB1CB), Color(0xFFFFD8E4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(MateRadius.card),
                boxShadow: MateShadows.hero,
              ),
              child: Row(
                children: [
                  const Icon(Icons.timeline_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tổng ngân sách dự kiến',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatVnd(_totalCost),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _summaryChip('${_stops.length} điểm'),
                  const SizedBox(width: 6),
                  _summaryChip(_formatDuration(_totalMinutes)),
                ],
              ),
            ),

            // Banner "Dữ liệu demo"
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(MateRadius.pill),
                border: Border.all(color: MateColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: MateColors.rose, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Dữ liệu demo • Lịch trình chỉ mang tính gợi ý',
                    style: TextStyle(
                      color: MateColors.plum.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // Timeline
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: _stops.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StopCard(
                    index: i,
                    isFirst: i == 0,
                    isLast: i == _stops.length - 1,
                    stop: _stops[i],
                    onDetail: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DatePlaceDetailScreen(
                            place: _stops[i].place,
                          ),
                        ),
                      );
                    },
                    onReplace: () => _replaceStop(i),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _regenerate,
                      icon: const Icon(Icons.shuffle_rounded, size: 18),
                      label: const Text('Phương án khác'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MateColors.pink,
                        side: const BorderSide(
                            color: MateColors.pink, width: 1.4),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(MateRadius.pill),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('Chỉnh tiêu chí'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MateColors.rose,
                        side: const BorderSide(color: MateColors.border),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(MateRadius.pill),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _savePlan,
                  icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                  label: const Text('Lưu kế hoạch'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MateColors.pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MateRadius.pill),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF1),
      body: SafeArea(
        child: Column(
          children: [
            DateHeader(title: 'Lịch hẹn của chúng mình 💕'),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off_rounded,
                          size: 56, color: MateColors.rose),
                      const SizedBox(height: 8),
                      const Text(
                        'Chưa tìm được địa điểm phù hợp',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: MateColors.plum,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Thử nới rộng ngân sách, đổi khu vực hoặc bớt một sở thích nhé.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: MateColors.plum.withOpacity(0.65),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Chỉnh tiêu chí'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MateColors.pink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(MateRadius.pill),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(MateRadius.pill),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  final int index;
  final bool isFirst;
  final bool isLast;
  final ItineraryStop stop;
  final VoidCallback onDetail;
  final VoidCallback onReplace;
  const _StopCard({
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.stop,
    required this.onDetail,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MateRadius.card),
        border: Border.all(color: MateColors.border),
        boxShadow: MateShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail + time overlay
          Stack(
            children: [
              Container(
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      stop.place.category == DateCategory.eat
                          ? const Color(0xFFFFB1CB)
                          : stop.place.category == DateCategory.movie
                              ? const Color(0xFFA78BFA)
                              : stop.place.category == DateCategory.play
                                  ? const Color(0xFF5EEAD4)
                                  : stop.place.category ==
                                          DateCategory.outdoor
                                      ? const Color(0xFF86EFAC)
                                      : const Color(0xFFFCD34D),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Image.asset(
                  stop.place.imageAsset,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(
                      stop.place.category.icon,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(MateRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: MateColors.pink, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        stop.time,
                        style: const TextStyle(
                          color: MateColors.plum,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius:
                        BorderRadius.circular(MateRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(stop.place.category.icon,
                          color: MateColors.pink, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        stop.place.category.label,
                        style: const TextStyle(
                          color: MateColors.plum,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (stop.place.isPartner)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: MateColors.primaryGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.handshake_rounded,
                            color: Colors.white, size: 10),
                        SizedBox(width: 2),
                        Text(
                          'Đối tác',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: MateColors.plum,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: MateColors.rose, size: 13),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        stop.place.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: MateColors.plum.withOpacity(0.65),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: MateColors.rose, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      '${stop.place.durationMin} phút',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: MateColors.plum.withOpacity(0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.payments_rounded,
                        color: MateColors.rose, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      _formatVnd(stop.place.pricePerTwo),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: MateColors.pink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDetail,
                        icon: const Icon(Icons.info_outline_rounded,
                            size: 15),
                        label: const Text('Chi tiết'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MateColors.pink,
                          side: const BorderSide(color: MateColors.border),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(MateRadius.pill),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReplace,
                        icon:
                            const Icon(Icons.swap_horiz_rounded, size: 15),
                        label: const Text('Thay'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MateColors.rose,
                          side: const BorderSide(color: MateColors.border),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(MateRadius.pill),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
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
      ),
    );
  }
}

class _AlternativesSheet extends StatelessWidget {
  final String title;
  final List<DatePlace> options;
  final TimeSlot slot;
  const _AlternativesSheet({
    required this.title,
    required this.options,
    required this.slot,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, scrollCtl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFEBF1),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: MateColors.rose.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: MateColors.plum,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        color: MateColors.rose),
                  ),
                ],
              ),
            ),
            if (options.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.sentiment_dissatisfied_rounded,
                        size: 48, color: MateColors.rose),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có lựa chọn thay thế phù hợp.\n'
                      'Hãy thử nới rộng ngân sách hoặc đổi khu vực.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: MateColors.plum.withOpacity(0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollCtl,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final p = options[i];
                    return GestureDetector(
                      onTap: () => Navigator.of(context).pop(p),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(MateRadius.card),
                          border: Border.all(color: MateColors.border),
                          boxShadow: MateShadows.soft,
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                p.imageAsset,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 56,
                                  height: 56,
                                  color: MateColors.subtlePink,
                                  child: Icon(p.category.icon,
                                      color: MateColors.pink),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: MateColors.plum,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${p.area} • ${_formatVnd(p.pricePerTwo)} • ${p.durationMin} phút',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color:
                                          MateColors.plum.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: MateColors.rose),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ----- Shared helpers (dùng nội bộ file) -----

String _formatVnd(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${buf.toString()}đ';
}

String _formatDuration(int min) {
  if (min < 60) return '$min phút';
  final h = min ~/ 60;
  final m = min % 60;
  if (m == 0) return '$h giờ';
  return '$h giờ $m phút';
}

String _dateLabel(DateTime d) {
  const weekdays = [
    'Thứ 2',
    'Thứ 3',
    'Thứ 4',
    'Thứ 5',
    'Thứ 6',
    'Thứ 7',
    'Chủ nhật',
  ];
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '${weekdays[d.weekday - 1]}, $dd/$mm/${d.year}';
}
