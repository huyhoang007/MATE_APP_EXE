// =====================================================================
// DatePlannerService
// =====================================================================
//
// - Lọc & sắp xếp mock data theo tiêu chí user.
// - Lưu kế hoạch đã tạo vào SharedPreferences (đã có sẵn trong project).
// - Không tạo backend mới.
// =====================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'date_models.dart';

class DatePlannerService {
  DatePlannerService._();
  static final DatePlannerService instance = DatePlannerService._();

  static const _kSavedKey = 'mate_date_plans_v1';

  // ----- Build a plan -----

  /// Lấy gợi ý lịch trình dựa trên tiêu chí đã chọn.
  ///
  /// Trả về danh sách stop. Có thể rỗng nếu không tìm được địa điểm phù hợp.
  List<ItineraryStop> buildItinerary({
    required String area,
    required BudgetRange budget,
    required DateMood mood,
    required Set<DateCategory> categories,
    required TimeSlot slot,
  }) {
    // 1. Lọc theo khu vực: nếu user chọn "Tất cả" (area rỗng hoặc '*')
    //    thì dùng toàn bộ mock data.
    Iterable<DatePlace> pool = allMockPlaces.where((p) {
      if (area.isEmpty || area == 'Tất cả' || area == '*') return true;
      return p.area.toLowerCase().contains(area.toLowerCase());
    });

    // 2. Lọc theo ngân sách.
    pool = pool.where((p) => budget.fits(p.pricePerTwo));

    // 3. Lọc theo khung giờ.
    pool = pool.where((p) => p.slots.contains(slot));

    // 4. Lọc theo phong cách.
    pool = pool.where((p) => p.moods.contains(mood));

    final list = pool.toList();

    // 5. Ưu tiên category user chọn, sau đó mở rộng nếu chưa đủ.
    final byCategory = <DateCategory, List<DatePlace>>{};
    for (final c in DateCategory.values) {
      byCategory[c] = [];
    }
    for (final p in list) {
      byCategory[p.category]!.add(p);
    }

    final selected = <DatePlace>[];

    // Helper: chọn 1 địa điểm từ 1 danh sách ưu tiên.
    void pickFrom(List<DatePlace> candidates) {
      if (candidates.isEmpty) return;
      // Sắp xếp theo: cùng area trước, rồi giá tăng dần.
      candidates.sort((a, b) {
        final areaMatchA = area.isEmpty ? 0 : (a.area == area ? 0 : 1);
        final areaMatchB = area.isEmpty ? 0 : (b.area == area ? 0 : 1);
        if (areaMatchA != areaMatchB) return areaMatchA - areaMatchB;
        return a.pricePerTwo.compareTo(b.pricePerTwo);
      });
      for (final c in candidates) {
        if (selected.any((s) => s.id == c.id)) continue;
        selected.add(c);
        break;
      }
    }

    // Ưu tiên 1 địa điểm từ mỗi category user chọn.
    for (final c in categories) {
      pickFrom(byCategory[c]!);
    }

    // Nếu user chọn quá ít category (hoặc rỗng), thêm từ các category khác.
    if (selected.length < 2) {
      for (final c in DateCategory.values) {
        if (categories.contains(c)) continue;
        pickFrom(byCategory[c]!);
        if (selected.length >= 3) break;
      }
    }

    // 6. Sắp xếp thời gian theo slot & category hợp lý.
    final ordered = _orderByTime(selected, slot);

    // 7. Tạo timeline với giờ bắt đầu tùy slot.
    return _toTimeline(ordered, slot);
  }

  /// Ghép các địa điểm thành timeline theo khung giờ.
  List<ItineraryStop> _toTimeline(List<DatePlace> ordered, TimeSlot slot) {
    int startHour;
    switch (slot) {
      case TimeSlot.morning:
        startHour = 8;
        break;
      case TimeSlot.afternoon:
        startHour = 14;
        break;
      case TimeSlot.evening:
        startHour = 18;
        break;
    }

    int cur = startHour * 60; // phút tính từ 00:00
    final result = <ItineraryStop>[];
    for (var i = 0; i < ordered.length; i++) {
      final p = ordered[i];
      final h = cur ~/ 60;
      final m = cur % 60;
      result.add(ItineraryStop(
        time: '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
        place: p,
        note: i == 0 ? 'Bắt đầu buổi hẹn' : '',
      ));
      // 15 phút di chuyển giữa các điểm.
      cur += p.durationMin + 15;
    }
    return result;
  }

  /// Sắp xếp thứ tự hợp lý theo loại hình cho từng slot.
  ///
  /// Ví dụ: buổi tối -> ăn tối -> xem phim -> cafe.
  List<DatePlace> _orderByTime(List<DatePlace> places, TimeSlot slot) {
    int priority(DatePlace p) {
      switch (slot) {
        case TimeSlot.morning:
          if (p.category == DateCategory.eat) return 0; // cafe sáng
          if (p.category == DateCategory.outdoor) return 1;
          if (p.category == DateCategory.play) return 2;
          if (p.category == DateCategory.gift) return 3;
          if (p.category == DateCategory.movie) return 4;
          break;
        case TimeSlot.afternoon:
          if (p.category == DateCategory.outdoor) return 0;
          if (p.category == DateCategory.play) return 1;
          if (p.category == DateCategory.eat) return 2;
          if (p.category == DateCategory.gift) return 3;
          if (p.category == DateCategory.movie) return 4;
          break;
        case TimeSlot.evening:
          if (p.category == DateCategory.eat) return 0; // ăn tối
          if (p.category == DateCategory.movie) return 1;
          if (p.category == DateCategory.gift) return 2;
          if (p.category == DateCategory.outdoor) return 3;
          if (p.category == DateCategory.play) return 4;
          break;
      }
      return 99;
    }

    final copy = List<DatePlace>.from(places);
    copy.sort((a, b) => priority(a).compareTo(priority(b)));
    return copy;
  }

  /// Gợi ý địa điểm thay thế cho 1 stop hiện tại.
  /// Trả về danh sách ứng viên cùng category + khu vực (nếu có thể).
  List<DatePlace> suggestAlternatives({
    required DatePlace current,
    required BudgetRange budget,
    required DateMood mood,
    required TimeSlot slot,
    required String area,
  }) {
    final all = allMockPlaces.where((p) {
      if (p.id == current.id) return false;
      if (p.category != current.category) return false;
      if (!budget.fits(p.pricePerTwo)) return false;
      if (!p.slots.contains(slot)) return false;
      if (!p.moods.contains(mood)) return false;
      return true;
    }).toList();

    // Ưu tiên cùng area trước.
    all.sort((a, b) {
      final aSame = a.area == current.area ? 0 : 1;
      final bSame = b.area == current.area ? 0 : 1;
      if (aSame != bSame) return aSame - bSame;
      return a.pricePerTwo.compareTo(b.pricePerTwo);
    });
    return all;
  }

  // ----- Persistence (lưu kế hoạch vào SharedPreferences) -----

  Future<List<DatePlan>> loadSavedPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kSavedKey) ?? <String>[];
    final out = <DatePlan>[];
    for (final s in raw) {
      try {
        out.add(DatePlan.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // Bỏ qua bản ghi lỗi.
      }
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  Future<void> savePlan(DatePlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kSavedKey) ?? <String>[];
    raw.add(jsonEncode(plan.toJson()));
    await prefs.setStringList(_kSavedKey, raw);
  }

  Future<void> deletePlan(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kSavedKey) ?? <String>[];
    raw.removeWhere((s) {
      try {
        return (jsonDecode(s) as Map<String, dynamic>)['id'] == id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_kSavedKey, raw);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSavedKey);
  }
}
