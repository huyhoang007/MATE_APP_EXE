// ============================================================
// NotificationItem - Model thông báo dùng cho Notification Center.
//
// Tối thiểu theo yêu cầu:
//   - id, type, title, message, createdAt, isRead
//   - targetRoute / targetAction (optional)
//   - metadata (optional)
//
// Type dùng cho icon + nhóm danh mục. Không bắt buộc khớp backend
// thật — hiện tại toàn bộ dữ liệu là MOCK (in-memory).
// ============================================================

import 'package:flutter/material.dart';

enum NotificationType {
  couple,    // Cặp đôi: lời yêu thương, kỷ niệm, kết nối
  pet,       // Pet: cho ăn, vật phẩm, level up
  memory,    // Khoảnh khắc: đăng mới, chia sẻ
  message,   // Tin nhắn
  reward,    // Phần thưởng: quà hằng ngày, lucky box, xu
  system,    // Hệ thống: update, quyền, premium
}

/// Hành động điều hướng khi nhấn vào notification.
/// - switchTab: chuyển sang tab chỉ định (dùng cho Pet/Khoảnh khắc/Tin nhắn)
/// - pushRoute: đẩy sang route có sẵn (vd: DailyRewardsScreen trong Utilities)
/// - none: chỉ đánh dấu đã đọc
enum NotificationAction {
  none,
  switchTab,
  pushRoute,
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  bool isRead;
  final NotificationAction action;
  final int? targetTabIndex;       // dùng khi action == switchTab
  final String? targetRouteName;  // dùng khi action == pushRoute
  final Map<String, dynamic>? metadata;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.action = NotificationAction.none,
    this.targetTabIndex,
    this.targetRouteName,
    this.metadata,
  });

  /// Icon đại diện theo nhóm.
  IconData get icon {
    switch (type) {
      case NotificationType.couple:
        return Icons.favorite;
      case NotificationType.pet:
        return Icons.pets;
      case NotificationType.memory:
        return Icons.camera_alt;
      case NotificationType.message:
        return Icons.chat_bubble;
      case NotificationType.reward:
        return Icons.card_giftcard;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  /// Màu icon theo nhóm.
  Color get iconColor {
    switch (type) {
      case NotificationType.couple:
        return const Color(0xFFFF3B69);
      case NotificationType.pet:
        return const Color(0xFFFF8A4C);
      case NotificationType.memory:
        return const Color(0xFF9333EA);
      case NotificationType.message:
        return const Color(0xFF0D9488);
      case NotificationType.reward:
        return const Color(0xFFFFB347);
      case NotificationType.system:
        return const Color(0xFF7EC8E3);
    }
  }
}
