// ============================================================
// NotificationCenterSheet - Trung tâm thông báo dạng modal.
//
// Hiển thị như bottom sheet, overlay mờ nhẹ, drag handle,
// header (chuông + tiêu đề + badge số chưa đọc + nút X), tabs
// "Tất cả" / "Chưa đọc", nút "Đánh dấu tất cả đã đọc", danh
// sách card cuộn được, empty state khi không có thông báo.
//
// Tương thích Mobile Wrapper:
//   - Chiều cao tối đa ~78% chiều cao màn hình khả dụng.
//   - Width full-width nhưng do MobileFrame đã giới hạn 430px
//     (xem main.dart + widgets/mobile_frame.dart), popup nằm
//     gọn bên trong khung.
//   - SafeArea bottom để không bị Bottom Navigation che.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/mate_theme.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';
import '../screens/utilities/utilities_screens.dart';

class NotificationCenterSheet extends StatefulWidget {
  /// Callback để yêu cầu MainWrapper chuyển tab (Pet=1, Memories=2,
  /// Chat=3, Profile=4). Tùy chọn — nếu null thì chỉ đánh dấu đã đọc.
  final ValueChanged<int>? onChangeTab;

  const NotificationCenterSheet({super.key, this.onChangeTab});

  /// Helper mở sheet với style đồng bộ (bo góc trên, animation trượt).
  static Future<void> show(BuildContext context, {ValueChanged<int>? onChangeTab}) {
    NotificationService.instance.ensureSeeded();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x59000000), // 35% black
      useSafeArea: true,
      builder: (_) => NotificationCenterSheet(onChangeTab: onChangeTab),
    );
  }

  @override
  State<NotificationCenterSheet> createState() => _NotificationCenterSheetState();
}

class _NotificationCenterSheetState extends State<NotificationCenterSheet> {
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.ensureSeeded();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxH = media.size.height * 0.78;

    return AnimatedPadding(
      // Tự co giãn theo bàn phím — mặc dù sheet không có input,
      // giữ để SafeArea inset bottom được tôn trọng.
      duration: const Duration(milliseconds: 120),
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 24, 12, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: const Color(0x2E000000), // 18% black
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              _buildTabs(),
              _buildMarkAllRow(context),
              _buildList(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  // Cấu trúc:
  //   - Stack alignment.center: titleGroup được Center căn giữa theo
  //     CHIỀU NGANG TOÀN BỘ popup (không phải vùng trừ nút X).
  //   - titleGroup có mainAxisSize: min nên chỉ rộng bằng nội dung,
  //     Center sẽ đặt nhóm ở chính giữa popup.
  //   - Nút X là overlay (Align centerRight) nằm đè lên vùng của
  //     Stack, không chiếm layout space.
  //   - Khi màn hình rất hẹp, title Text có Flexible + ellipsis
  //     sẽ tự co lại để không đè nút X.
  Widget _buildHeader(BuildContext context) {
    return AnimatedBuilder(
      animation: NotificationService.instance,
      builder: (context, _) {
        final unread = NotificationService.instance.unreadCount;

        // Nhóm icon + title + badge: chỉ rộng bằng nội dung.
        final titleGroup = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_active, color: MateColors.pinkDeep, size: 24),
            const SizedBox(width: 10),
            // Flexible để title có thể co lại + ellipsis nếu
            // tổng width vượt quá vùng khả dụng.
            Flexible(
              child: Text(
                'Thông báo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.beVietnamPro(
                  color: MateColors.plum,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                key: const ValueKey('notif_badge'),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: MateColors.pinkDeep,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        );

        return Padding(
          // Padding top/bottom giữ khoảng cách với tab bên dưới.
          // Padding left/right = 0 để Center căn giữa toàn popup.
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
          // SizedBox giữ chiều cao header ổn định, giống Row cũ.
          child: SizedBox(
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Nhóm tiêu đề — Center sẽ căn giữa theo CHIỀU NGANG
                // TOÀN BỘ popup. Vì titleGroup có mainAxisSize: min
                // (chỉ rộng bằng nội dung), Center đặt nó ở chính giữa
                // popup. Khi màn hình rất hẹp, title Text có Flexible +
                // ellipsis sẽ tự co lại để không đè nút X.
                Center(child: titleGroup),
                // Nút đóng X — overlay ở mép phải, căn giữa dọc.
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, color: MateColors.plum),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- "Đánh dấu tất cả đã đọc" ----------------
  // Đặt thành hàng riêng (không nằm chung với header) để chuỗi
  // dài không đẩy icon/badge/nút X ra khỏi popup trên màn hình nhỏ.
  Widget _buildMarkAllRow(BuildContext context) {
    return AnimatedBuilder(
      animation: NotificationService.instance,
      builder: (context, _) {
        final unread = NotificationService.instance.unreadCount;
        if (unread == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 12, 6),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => NotificationService.instance.markAllRead(),
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text(
                'Đánh dấu tất cả đã đọc',
                overflow: TextOverflow.ellipsis,
              ),
              style: TextButton.styleFrom(
                foregroundColor: MateColors.pinkDeep,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- TABS ----------------
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _TabChip(
            label: 'Tất cả',
            selected: !_showUnreadOnly,
            onTap: () => setState(() => _showUnreadOnly = false),
          ),
          const SizedBox(width: 8),
          _TabChip(
            label: 'Chưa đọc',
            selected: _showUnreadOnly,
            onTap: () => setState(() => _showUnreadOnly = true),
          ),
        ],
      ),
    );
  }

  // ---------------- LIST ----------------
  Widget _buildList() {
    return Flexible(
      child: AnimatedBuilder(
        animation: NotificationService.instance,
        builder: (context, _) {
          final items = _showUnreadOnly
              ? NotificationService.instance.unread
              : NotificationService.instance.all;

          if (items.isEmpty) {
            return _EmptyState(filtering: _showUnreadOnly);
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _NotificationCard(
              item: items[i],
              onTap: () => _onTapItem(items[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onTapItem(NotificationItem item) async {
    NotificationService.instance.markRead(item.id);
    if (!mounted) return;

    // Capture navigator TRƯỚC khi pop sheet (sau pop, context bị dispose).
    final outerNavigator = Navigator.of(context, rootNavigator: true);

    // Đóng popup.
    Navigator.of(context).pop();

    if (item.action == NotificationAction.switchTab) {
      final tab = item.targetTabIndex;
      if (tab != null && widget.onChangeTab != null) {
        // Đợi sheet đóng xong hẳn rồi mới chuyển tab để tránh
        // conflict giữa 2 animation.
        await Future<void>.delayed(const Duration(milliseconds: 80));
        if (!mounted) return;
        widget.onChangeTab!(tab);
      }
    } else if (item.action == NotificationAction.pushRoute) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      Widget? target;
      switch (item.targetRouteName) {
        case 'dailyRewards':
          target = const DailyRewardsScreen();
          break;
        case 'luckyBox':
          target = const LuckyBoxScreen();
          break;
      }
      if (target != null && outerNavigator.mounted) {
        outerNavigator.push(
          MaterialPageRoute(
            builder: (_) => target!,
            settings: RouteSettings(name: item.targetRouteName),
          ),
        );
      }
    }
  }
}

// =============================================================
// _TabChip - Tab con "Tất cả" / "Chưa đọc"
// =============================================================
class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? MateColors.pinkDeep : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? MateColors.pinkDeep : MateColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : MateColors.plum,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// =============================================================
// _NotificationCard - 1 card thông báo
// =============================================================
class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = item.isRead
        ? Colors.white
        : const Color(0xFFFFF0F5); // hồng pastel nhẹ cho chưa đọc
    final border = item.isRead ? MateColors.border : const Color(0xFFFFB6CE);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: 1.4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.iconColor.withAlpha(31), // 12% alpha
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              // Nội dung
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: MateColors.plum,
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Time text có thể bị dài trong tương lai
                        // (vd "30 phút trước"). Đặt Flexible + ellipsis
                        // để không bao giờ đẩy nội dung khác ra ngoài.
                        Flexible(
                          child: Text(
                            _formatTimeAgo(item.createdAt),
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: MateColors.rose.withAlpha(204), // 80%
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: TextStyle(
                        color: MateColors.plum.withAlpha(191), // 75%
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Chấm hồng chưa đọc
              if (!item.isRead)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: MateColors.pinkDeep,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    return '${dt.day}/${dt.month}';
  }
}

// =============================================================
// _EmptyState - Khi không có thông báo
// =============================================================
class _EmptyState extends StatelessWidget {
  final bool filtering;
  const _EmptyState({required this.filtering});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: MateColors.subtlePink,
              borderRadius: BorderRadius.circular(36),
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: MateColors.rose,
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            filtering ? 'Không có thông báo chưa đọc' : 'Chưa có thông báo nào',
            style: const TextStyle(
              color: MateColors.plum,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            filtering
                ? 'Bạn đã đọc hết rồi — quay lại sau nhé.'
                : 'Khi có thông báo mới, chúng sẽ xuất hiện ở đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MateColors.rose.withAlpha(230), // 90%
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
