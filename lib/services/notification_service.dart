// ============================================================
// NotificationService - Quản lý thông báo trong bộ nhớ.
//
// - Singleton, dùng ChangeNotifier để UI tự động rebuild khi
//   có thay đổi (đánh dấu đã đọc, thêm mới...).
// - Tách biệt với backend thật: dữ liệu hiện tại là MOCK.
// - Khi có Firestore listener / push notification thật, chỉ
//   cần thay thân hàm `_seedMock()` bằng stream từ backend.
//
// Theo yêu cầu: KHÔNG giả lập realtime/push. Service chỉ giữ
// state trong session, mất khi restart app.
// ============================================================

import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';

class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final List<NotificationItem> _items = [];

  /// Khởi tạo dữ liệu mẫu. An toàn gọi nhiều lần.
  void ensureSeeded() {
    if (_items.isNotEmpty) return;
    _items.addAll(_seedMock());
    // Sắp xếp mới nhất trước
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Reset state — chỉ dùng cho widget test. Trong production không
  /// nên gọi vì mất dữ liệu người dùng đã đọc.
  @visibleForTesting
  void resetForTest() {
    _items.clear();
    ensureSeeded();
  }

  /// Danh sách đã sắp xếp mới nhất trước.
  List<NotificationItem> get all {
    return List.unmodifiable(_items);
  }

  /// Lọc chưa đọc.
  List<NotificationItem> get unread {
    return _items.where((n) => !n.isRead).toList(growable: false);
  }

  int get unreadCount => _items.where((n) => !n.isRead).length;

  /// Đánh dấu 1 thông báo đã đọc.
  void markRead(String id) {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    if (_items[idx].isRead) return;
    _items[idx].isRead = true;
    notifyListeners();
  }

  /// Đánh dấu tất cả đã đọc.
  void markAllRead() {
    var changed = false;
    for (final n in _items) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// Thêm notification mới (dành cho tích hợp tương lai).
  void push(NotificationItem item) {
    _items.insert(0, item);
    notifyListeners();
  }

  // ----------------------------------------------------------------
  // Mock data — phủ 6 nhóm danh mục theo yêu cầu.
  // ----------------------------------------------------------------
  List<NotificationItem> _seedMock() {
    final now = DateTime.now();
    DateTime ago(int minutes) => now.subtract(Duration(minutes: minutes));

    return [
      // Cặp đôi
      NotificationItem(
        id: 'c1',
        type: NotificationType.couple,
        title: 'Người ấy gửi lời yêu thương 💕',
        message: 'Một lời nhắn ngọt ngào vừa được gửi đến bạn.',
        createdAt: ago(3),
        targetTabIndex: 3, // Tab 4 - Nhắn tin
        action: NotificationAction.switchTab,
      ),
      // Khoảnh khắc
      NotificationItem(
        id: 'm1',
        type: NotificationType.memory,
        title: 'Người ấy vừa đăng khoảnh khắc mới',
        message: 'Cùng xem kỷ niệm mới nhất của hai bạn nhé!',
        createdAt: ago(28),
        targetTabIndex: 2, // Tab 3 - Khoảnh khắc
        action: NotificationAction.switchTab,
      ),
      // Phần thưởng
      NotificationItem(
        id: 'r1',
        type: NotificationType.reward,
        title: 'Quà hằng ngày đã sẵn sàng 🎁',
        message: 'Điểm danh hôm nay để nhận xu MATE thưởng.',
        createdAt: ago(95),
        targetRouteName: 'dailyRewards',
        action: NotificationAction.pushRoute,
      ),
      // Pet
      NotificationItem(
        id: 'p1',
        type: NotificationType.pet,
        title: 'Pet đang đợi được chăm sóc',
        message: 'Bụng đói rồi — cho bé ăn nào!',
        createdAt: ago(180),
        targetTabIndex: 1, // Tab 2 - Pet
        action: NotificationAction.switchTab,
      ),
      // Tin nhắn
      NotificationItem(
        id: 'msg1',
        type: NotificationType.message,
        title: 'Bạn có tin nhắn mới',
        message: 'Người ấy vừa nhắn cho bạn trong cuộc trò chuyện.',
        createdAt: ago(260),
        targetTabIndex: 3, // Tab 4 - Nhắn tin
        action: NotificationAction.switchTab,
      ),
      // Phần thưởng
      NotificationItem(
        id: 'r2',
        type: NotificationType.reward,
        title: 'Lucky Box có thể mở 🎉',
        message: 'Bạn có một hộp quà may mắn đang chờ.',
        createdAt: ago(420),
        targetRouteName: 'luckyBox',
        action: NotificationAction.pushRoute,
      ),
      // Cặp đôi - kỷ niệm
      NotificationItem(
        id: 'c2',
        type: NotificationType.couple,
        title: 'Sắp đến ngày kỷ niệm của hai bạn',
        message: 'Chuẩn bị một điều bất ngờ cho người ấy thôi!',
        createdAt: ago(720),
      ),
      // Pet level up
      NotificationItem(
        id: 'p2',
        type: NotificationType.pet,
        title: 'Pet đạt cấp độ mới 🐾',
        message: 'Cấp độ của bé vừa tăng — ghé thăm bé ngay!',
        createdAt: ago(1320),
        targetTabIndex: 1,
        action: NotificationAction.switchTab,
      ),
      // Hệ thống
      NotificationItem(
        id: 's1',
        type: NotificationType.system,
        title: 'MATE đã có bản cập nhật mới',
        message: 'Trải nghiệm của bạn sẽ mượt mà hơn. Xem chi tiết trong Hồ sơ.',
        createdAt: ago(2400),
      ),
    ];
  }
}
