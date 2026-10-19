// ============================================================
// MapSettingsSheet - Popup cài đặt bản đồ (Tab 1).
//
// Cấu trúc:
//   - Header: tiêu đề "Cài đặt bản đồ" căn giữa toàn popup
//     (Stack + Center, overlay nút X ở phải — giống pattern
//     đã verify ở NotificationCenterSheet).
//   - 3 card dọc trong ListView cuộn được:
//       1) Hiển thị bản đồ: style sáng/tối + 3 toggle.
//       2) Vị trí & Chia sẻ: refresh / permission / pause.
//       3) Địa điểm & Cảnh báo: quản lý + geofencing.
//
// Tuân thủ yêu cầu backend:
//   - Cài đặt giao diện: bật/tắt có hiệu lực ngay.
//   - Chia sẻ vị trí + Tạm dừng + Saved places + Geofence:
//     CHƯA có backend, hiển thị "chưa khả dụng" trung thực.
//
// Giao tiếp với MapTab qua callback:
//   - onRefreshLocation: async; MapTab gọi Geolocator + Firestore.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../constants/mate_theme.dart';
import '../../services/map_preferences_service.dart';

class MapSettingsSheet extends StatefulWidget {
  /// Callback khi người dùng nhấn "Làm mới vị trí".
  /// Trả về Future để sheet biết khi nào loading xong (true = thành công).
  final Future<bool> Function()? onRefreshLocation;

  /// Trạng thái quyền truy cập vị trí hiện tại (do MapTab cung cấp).
  final geo.LocationPermission locationPermission;

  /// Service GPS có đang bật không.
  final bool locationServiceEnabled;

  const MapSettingsSheet({
    super.key,
    this.onRefreshLocation,
    this.locationPermission = geo.LocationPermission.denied,
    this.locationServiceEnabled = false,
  });

  /// Helper mở sheet.
  static Future<void> show(
    BuildContext context, {
    Future<bool> Function()? onRefreshLocation,
    geo.LocationPermission locationPermission = geo.LocationPermission.denied,
    bool locationServiceEnabled = false,
  }) {
    // Đảm bảo preferences đã load trước khi mở.
    MapPreferencesService.instance.ensureLoaded();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x59000000), // 35% black
      useSafeArea: true,
      builder: (_) => MapSettingsSheet(
        onRefreshLocation: onRefreshLocation,
        locationPermission: locationPermission,
        locationServiceEnabled: locationServiceEnabled,
      ),
    );
  }

  @override
  State<MapSettingsSheet> createState() => _MapSettingsSheetState();
}

class _MapSettingsSheetState extends State<MapSettingsSheet> {
  bool _refreshing = false;
  String? _refreshError;

  Future<void> _handleRefresh() async {
    final cb = widget.onRefreshLocation;
    if (cb == null || _refreshing) return;
    setState(() {
      _refreshing = true;
      _refreshError = null;
    });
    try {
      final ok = await cb();
      if (!mounted) return;
      if (!ok) {
        setState(() => _refreshError =
            'Không thể cập nhật vị trí. Kiểm tra GPS và quyền truy cập.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _refreshError = 'Đã xảy ra lỗi: $e');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxH = media.size.height * 0.80;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 24, 12, 0),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBF1), // gradientBottom pastel
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E000000), // 18% black
                blurRadius: 30,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Flexible(
                child: ListView(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    _buildMapDisplayCard(),
                    const SizedBox(height: 14),
                    _buildLocationCard(),
                    const SizedBox(height: 14),
                    _buildPlacesCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER — tiêu đề căn giữa toàn popup, nút X overlay bên phải
  // ============================================================
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Tiêu đề căn giữa TOÀN BỘ popup.
            const Center(
              child: Text(
                'Cài đặt bản đồ',
                style: TextStyle(
                  color: MateColors.plum,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
            // Nút X overlay ở phải.
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Đóng',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close, color: MateColors.plum),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARD 1 — Hiển thị bản đồ
  // ============================================================
  Widget _buildMapDisplayCard() {
    return _SectionCard(
      title: 'Hiển thị bản đồ',
      child: AnimatedBuilder(
        animation: MapPreferencesService.instance,
        builder: (context, _) {
          final p = MapPreferencesService.instance;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 4.1. Chế độ bản đồ — Segmented
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SettingLabel(text: 'Chế độ bản đồ'),
                    const SizedBox(height: 8),
                    _Segmented(
                      options: const [
                        _SegmentItem('Sáng', MapStyleMode.light),
                        _SegmentItem('Tối', MapStyleMode.dark),
                      ],
                      selected: p.mapStyle,
                      onSelect: (m) => p.setMapStyle(m),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: MateColors.border),
              _ToggleTile(
                title: 'Hiển thị vị trí hai người',
                value: p.showBothMarkers,
                onChanged: p.setShowBothMarkers,
              ),
              const Divider(height: 1, color: MateColors.border),
              _ToggleTile(
                title: 'Hiển thị đường kết nối',
                value: p.showConnectionLine,
                onChanged: p.setShowConnectionLine,
              ),
              const Divider(height: 1, color: MateColors.border),
              _ToggleTile(
                title: 'Hiển thị khoảng cách',
                value: p.showDistanceBadge,
                onChanged: p.setShowDistanceBadge,
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // CARD 2 — Vị trí & Chia sẻ
  // ============================================================
  Widget _buildLocationCard() {
    return _SectionCard(
      title: 'Vị trí & Chia sẻ',
      child: Column(
        children: [
          // 5.1 Chia sẻ vị trí — chưa có backend
          const _UnsupportedTile(
            title: 'Chia sẻ vị trí với người ấy',
            subtitle:
                'Cho phép người ấy xem vị trí của bạn. '
                'Tính năng dừng chia sẻ thực sự chưa khả dụng — đang chờ backend.',
            icon: Icons.share_location,
          ),
          const Divider(height: 1, color: MateColors.border),
          // 5.2 Làm mới vị trí
          ListTile(
            leading: _refreshing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: MateColors.pinkDeep,
                    ),
                  )
                : const Icon(Icons.refresh,
                    color: MateColors.pinkDeep),
            title: const Text(
              'Làm mới vị trí',
              style: TextStyle(
                color: MateColors.plum,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: _refreshError == null
                ? null
                : Text(
                    _refreshError!,
                    style: const TextStyle(
                        color: Color(0xFFB42318), fontSize: 12),
                  ),
            trailing: const Icon(
              Icons.chevron_right,
              color: MateColors.rose,
            ),
            onTap: _refreshing ? null : _handleRefresh,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(0),
              ),
            ),
          ),
          const Divider(height: 1, color: MateColors.border),
          // 5.3 Quyền truy cập vị trí
          ListTile(
            leading: const Icon(Icons.lock_outline,
                color: MateColors.pinkDeep),
            title: const Text(
              'Quyền truy cập vị trí',
              style: TextStyle(
                color: MateColors.plum,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              _permissionDescription(),
              style: TextStyle(
                color: _permissionColor(),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: MateColors.rose,
            ),
            onTap: _openAppSettings,
          ),
          const Divider(height: 1, color: MateColors.border),
          // 5.4 Tạm dừng chia sẻ — chưa có backend
          const _UnsupportedTile(
            title: 'Tạm dừng chia sẻ vị trí',
            subtitle:
                'Tạm dừng 15 phút / 1 giờ / Đến khi bật lại. '
                'Tính năng tự khôi phục theo thời hạn chưa khả dụng — đang chờ backend.',
            icon: Icons.timer_outlined,
          ),
        ],
      ),
    );
  }

  String _permissionDescription() {
    if (!widget.locationServiceEnabled) {
      return 'GPS đang tắt. Bật dịch vụ vị trí trên thiết bị để tiếp tục.';
    }
    switch (widget.locationPermission) {
      case geo.LocationPermission.always:
        return 'Đã cấp: Luôn truy cập vị trí.';
      case geo.LocationPermission.whileInUse:
        return 'Đã cấp: Truy cập khi dùng ứng dụng.';
      case geo.LocationPermission.denied:
        return 'Chưa cấp quyền. Nhấn để cấp lại.';
      case geo.LocationPermission.deniedForever:
        return 'Đã bị từ chối vĩnh viễn. Mở Cài đặt hệ thống để bật lại.';
      case geo.LocationPermission.unableToDetermine:
        return 'Không xác định được trạng thái quyền.';
    }
  }

  Color _permissionColor() {
    if (!widget.locationServiceEnabled) return const Color(0xFFB42318);
    switch (widget.locationPermission) {
      case geo.LocationPermission.always:
      case geo.LocationPermission.whileInUse:
        return const Color(0xFF0D9488);
      case geo.LocationPermission.denied:
      case geo.LocationPermission.unableToDetermine:
        return const Color(0xFFB45309);
      case geo.LocationPermission.deniedForever:
        return const Color(0xFFB42318);
    }
  }

  Future<void> _openAppSettings() async {
    try {
      await geo.Geolocator.openAppSettings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể mở Cài đặt hệ thống từ ứng dụng. '
            'Vui lòng mở thủ công.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFFB42318),
        ),
      );
    }
  }

  // ============================================================
  // CARD 3 — Địa điểm & Cảnh báo
  // ============================================================
  Widget _buildPlacesCard() {
    return _SectionCard(
      title: 'Địa điểm & Cảnh báo',
      child: const Column(
        children: [
          _UnsupportedTile(
            title: 'Địa điểm quan trọng',
            subtitle:
                'Nhà / Trường / Nơi làm việc / Địa điểm tùy chỉnh. '
                'Màn hình quản lý địa điểm chưa khả dụng — đang chờ backend.',
            icon: Icons.bookmark_outline,
          ),
          Divider(height: 1, color: MateColors.border),
          _UnsupportedTile(
            title: 'Thông báo đến / rời địa điểm',
            subtitle:
                'Geofencing cho phép nhận cảnh báo khi người ấy đến/rời '
                'một địa điểm. Tính năng chưa khả dụng — đang chờ backend.',
            icon: Icons.notifications_active_outlined,
          ),
        ],
      ),
    );
  }
}

// =============================================================
// _SectionCard — card trắng pastel có title đầu
// =============================================================
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      // Material ở đây vừa cung cấp background trắng vừa là nơi
      // ListTile / SwitchListTile paint ink splashes — tránh
      // warning "background color or ink splashes may be invisible"
      // khi wrap ListTile trong Container có decoration.
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MateColors.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5C8A).withAlpha(20), // ~8% pink
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title đầu card
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    color: MateColors.plum,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const Divider(height: 1, color: MateColors.border),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// _SettingLabel — label nhỏ phía trên SegmentedControl/Toggle
// =============================================================
class _SettingLabel extends StatelessWidget {
  final String text;
  const _SettingLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: MateColors.rose,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// =============================================================
// _Segmented — SegmentedControl đơn giản (custom) cho 2 lựa chọn
// =============================================================
class _SegmentItem<T> {
  final String label;
  final T value;
  const _SegmentItem(this.label, this.value);
}

class _Segmented<T> extends StatelessWidget {
  final List<_SegmentItem<T>> options;
  final T selected;
  final ValueChanged<T> onSelect;
  const _Segmented({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE0EA).withAlpha(77), // subtlePink ~30%
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: options.map((o) {
          final isSel = o.value == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(o.value),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSel
                      ? const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  o.label,
                  style: TextStyle(
                    color: isSel
                        ? MateColors.pinkDeep
                        : MateColors.plum.withAlpha(160),
                    fontWeight:
                        isSel ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================
// _ToggleTile — ListTile có switch
// =============================================================
class _ToggleTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: MateColors.plum,
          fontWeight: FontWeight.w700,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: MateColors.pinkDeep,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

// =============================================================
// _UnsupportedTile — ListTile hiển thị "chưa khả dụng" với badge
// =============================================================
class _UnsupportedTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _UnsupportedTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: MateColors.rose),
      title: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                color: MateColors.plum,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1B6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Sắp ra mắt',
              style: TextStyle(
                color: Color(0xFF8A6A00),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            color: MateColors.plum.withAlpha(170),
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ),
      isThreeLine: true,
    );
  }
}
