// ============================================================
// MapPreferencesService - Quản lý tùy chọn hiển thị bản đồ.
//
// Cài đặt giao diện (lưu vào SharedPreferences để giữ qua session):
//   - mapStyle: 'light' | 'dark'           (mặc định: 'dark')
//   - showBothMarkers: bool                (mặc định: true)
//   - showConnectionLine: bool             (mặc định: true)
//   - showDistanceBadge: bool              (mặc định: true)
//
// Cài đặt quyền riêng tư (KHÔNG có backend, hiển thị trung thực):
//   - isSharingLocation: bool              (mặc định: true, do service
//     GPS của MapTab tự push; chưa có cơ chế tắt thật sự)
//   - sharingPausedUntil: DateTime?        (chưa có scheduler tự resume)
//
// Tuân thủ yêu cầu:
//   - Cài đặt giao diện: thay đổi ngay, persist, rebuild UI.
//   - Cài đặt quyền riêng tư: chỉ thay đổi khi backend xác nhận.
//     Vì project CHƯA có backend cho pause/stop sharing, các toggle
//     liên quan hiển thị trạng thái "chưa khả dụng" trong UI.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MapStyleMode {
  light,
  dark;

  String get id => name;
  static MapStyleMode fromId(String? id) =>
      id == 'light' ? light : dark;
}

class MapPreferencesService extends ChangeNotifier {
  MapPreferencesService._();
  static final MapPreferencesService instance = MapPreferencesService._();

  // ---------- keys ----------
  static const _kMapStyle = 'map_pref.style';
  static const _kShowMarkers = 'map_pref.showMarkers';
  static const _kShowLine = 'map_pref.showLine';
  static const _kShowDistance = 'map_pref.showDistance';

  // ---------- state ----------
  MapStyleMode _mapStyle = MapStyleMode.dark;
  bool _showBothMarkers = true;
  bool _showConnectionLine = true;
  bool _showDistanceBadge = true;

  // Cờ đánh dấu đã load từ disk xong (tránh emit khi chưa sẵn sàng).
  bool _ready = false;
  bool get isReady => _ready;

  // ---------- getters ----------
  MapStyleMode get mapStyle => _mapStyle;
  bool get showBothMarkers => _showBothMarkers;
  bool get showConnectionLine => _showConnectionLine;
  bool get showDistanceBadge => _showDistanceBadge;

  /// Tile URL cho Stadia Maps theo style hiện tại.
  /// - light: alidade_smooth (nền sáng, dễ đọc ban ngày)
  /// - dark : alidade_smooth_dark (hiện tại của MATE)
  String get tileUrl {
    switch (_mapStyle) {
      case MapStyleMode.light:
        return 'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png';
      case MapStyleMode.dark:
        return 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png';
    }
  }

  // ---------- lifecycle ----------
  /// Load preferences từ SharedPreferences. Idempotent — gọi nhiều lần
  /// vẫn chỉ load 1 lần.
  Future<void> ensureLoaded() async {
    if (_ready) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _mapStyle = MapStyleMode.fromId(prefs.getString(_kMapStyle));
      _showBothMarkers = prefs.getBool(_kShowMarkers) ?? true;
      _showConnectionLine = prefs.getBool(_kShowLine) ?? true;
      _showDistanceBadge = prefs.getBool(_kShowDistance) ?? true;
    } catch (e) {
      // SharedPreferences có thể chưa sẵn sàng trên web lần đầu —
      // fallback về defaults. Không throw để UI vẫn chạy.
      debugPrint('MapPreferencesService load error: $e');
    }
    _ready = true;
    notifyListeners();
  }

  /// Reset tất cả preferences — chỉ dùng cho test.
  @visibleForTesting
  Future<void> resetForTest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kMapStyle);
      await prefs.remove(_kShowMarkers);
      await prefs.remove(_kShowLine);
      await prefs.remove(_kShowDistance);
    } catch (_) {}
    _mapStyle = MapStyleMode.dark;
    _showBothMarkers = true;
    _showConnectionLine = true;
    _showDistanceBadge = true;
    _ready = true;
    notifyListeners();
  }

  // ---------- setters ----------
  Future<void> setMapStyle(MapStyleMode mode) async {
    if (_mapStyle == mode) return;
    _mapStyle = mode;
    notifyListeners();
    await _persistString(_kMapStyle, mode.id);
  }

  Future<void> setShowBothMarkers(bool v) async {
    if (_showBothMarkers == v) return;
    _showBothMarkers = v;
    notifyListeners();
    await _persistBool(_kShowMarkers, v);
  }

  Future<void> setShowConnectionLine(bool v) async {
    if (_showConnectionLine == v) return;
    _showConnectionLine = v;
    notifyListeners();
    await _persistBool(_kShowLine, v);
  }

  Future<void> setShowDistanceBadge(bool v) async {
    if (_showDistanceBadge == v) return;
    _showDistanceBadge = v;
    notifyListeners();
    await _persistBool(_kShowDistance, v);
  }

  Future<void> _persistString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('MapPreferencesService persist $key error: $e');
    }
  }

  Future<void> _persistBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('MapPreferencesService persist $key error: $e');
    }
  }
}
