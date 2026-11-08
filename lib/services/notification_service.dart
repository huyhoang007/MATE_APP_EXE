// ============================================================
// NotificationService - Thông báo realtime qua Firestore.
//
// Dữ liệu được lưu trữ và đồng bộ qua Firestore subcollection:
//   couples/{coupleCode}/notifications/{notifId}
//
// API giữ nguyên tương thích ngược:
//   - .all, .unread, .unreadCount
//   - .markRead(id), .markAllRead(), .push(item)
//   - .ensureSeeded() → no-op (backward compat)
//
// Thêm mới:
//   - .init(coupleCode) → bắt đầu stream Firestore
//   - .dispose() → hủy stream
// ============================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';
import 'auth_service.dart';

class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const Duration _timeout = Duration(seconds: 12);

  final List<NotificationItem> _items = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _coupleCode;

  /// Khởi tạo stream từ Firestore.
  ///
  /// Gọi 1 lần khi vào MainWrapperScreen (sau khi có coupleCode).
  /// Idempotent — gọi lại với cùng code sẽ không tạo stream mới.
  void init(String coupleCode) {
    if (_coupleCode == coupleCode && _sub != null) return;

    // Hủy stream cũ nếu có.
    _sub?.cancel();
    _coupleCode = coupleCode;

    _sub = _db
        .collection('couples')
        .doc(coupleCode)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
      (snap) {
        _items.clear();
        for (final doc in snap.docs) {
          _items.add(_fromFirestore(doc));
        }
        notifyListeners();
      },
      onError: (e) {
        debugPrint('NotificationService stream error: $e');
      },
    );
  }

  /// Backward compatibility.
  /// Bây giờ là no-op vì dữ liệu đến từ Firestore stream.
  void ensureSeeded() {
    // no-op: dữ liệu realtime từ Firestore.
  }

  /// Reset — chỉ dùng cho widget test.
  @visibleForTesting
  void resetForTest() {
    _sub?.cancel();
    _sub = null;
    _coupleCode = null;
    _items.clear();
    notifyListeners();
  }

  // ---------- Getters (tương thích ngược) ----------

  /// Danh sách đã sắp xếp mới nhất trước.
  List<NotificationItem> get all => List.unmodifiable(_items);

  /// Lọc chưa đọc.
  List<NotificationItem> get unread =>
      _items.where((n) => !n.isRead).toList(growable: false);

  int get unreadCount => _items.where((n) => !n.isRead).length;

  // ---------- Actions ----------

  /// Đánh dấu 1 thông báo đã đọc.
  void markRead(String id) {
    if (_coupleCode == null) return;

    // Cập nhật local ngay (optimistic update).
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx != -1 && !_items[idx].isRead) {
      _items[idx].isRead = true;
      notifyListeners();
    }

    // Cập nhật Firestore.
    _db
        .collection('couples')
        .doc(_coupleCode!)
        .collection('notifications')
        .doc(id)
        .update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    }).timeout(_timeout).catchError((e) {
      debugPrint('NotificationService markRead error: $e');
    });
  }

  /// Đánh dấu tất cả đã đọc.
  void markAllRead() {
    if (_coupleCode == null) return;

    // Optimistic update local.
    bool changed = false;
    for (final n in _items) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();

    // Batch update Firestore.
    _batchMarkAllRead();
  }

  Future<void> _batchMarkAllRead() async {
    try {
      final snap = await _db
          .collection('couples')
          .doc(_coupleCode!)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .limit(100)
          .get()
          .timeout(_timeout);

      if (snap.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit().timeout(_timeout);
    } catch (e) {
      debugPrint('NotificationService markAllRead batch error: $e');
    }
  }

  /// Thêm notification mới vào Firestore.
  void push(NotificationItem item) {
    if (_coupleCode == null) return;

    // Optimistic update local.
    _items.insert(0, item);
    notifyListeners();

    // Ghi vào Firestore.
    _db
        .collection('couples')
        .doc(_coupleCode!)
        .collection('notifications')
        .doc(item.id.startsWith('local_') ? null : item.id)
        .set(_toFirestore(item))
        .timeout(_timeout)
        .catchError((e) {
      debugPrint('NotificationService push error: $e');
    });
  }

  /// Gửi notification từ bên ngoài (vd: từ game, từ chat).
  Future<void> sendNotification({
    required String coupleCode,
    required NotificationType type,
    required String title,
    required String message,
    NotificationAction action = NotificationAction.none,
    int? targetTabIndex,
    String? targetRouteName,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = AuthService.instance.uid;
    await _db
        .collection('couples')
        .doc(coupleCode)
        .collection('notifications')
        .doc()
        .set({
      'type': type.name,
      'title': title,
      'message': message,
      'isRead': false,
      'action': action.name,
      if (targetTabIndex != null) 'targetTabIndex': targetTabIndex,
      if (targetRouteName != null) 'targetRouteName': targetRouteName,
      if (metadata != null) 'metadata': metadata,
      'senderId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    }).timeout(_timeout);
  }

  /// Xóa 1 notification.
  Future<void> deleteNotification(String id) async {
    if (_coupleCode == null) return;

    _items.removeWhere((n) => n.id == id);
    notifyListeners();

    await _db
        .collection('couples')
        .doc(_coupleCode!)
        .collection('notifications')
        .doc(id)
        .delete()
        .timeout(_timeout);
  }

  // ---------- Conversion ----------

  NotificationItem _fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    final typeStr = d['type'] as String? ?? 'system';
    final actionStr = d['action'] as String? ?? 'none';

    return NotificationItem(
      id: snap.id,
      type: NotificationType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => NotificationType.system,
      ),
      title: (d['title'] as String?) ?? '',
      message: (d['message'] as String?) ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: (d['isRead'] as bool?) ?? false,
      action: NotificationAction.values.firstWhere(
        (a) => a.name == actionStr,
        orElse: () => NotificationAction.none,
      ),
      targetTabIndex: (d['targetTabIndex'] as num?)?.toInt(),
      targetRouteName: d['targetRouteName'] as String?,
      metadata: d['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> _toFirestore(NotificationItem item) {
    return {
      'type': item.type.name,
      'title': item.title,
      'message': item.message,
      'isRead': item.isRead,
      'action': item.action.name,
      if (item.targetTabIndex != null) 'targetTabIndex': item.targetTabIndex,
      if (item.targetRouteName != null) 'targetRouteName': item.targetRouteName,
      if (item.metadata != null) 'metadata': item.metadata,
      'senderId': AuthService.instance.uid,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // ---------- Lifecycle ----------

  @override
  void dispose() {
    _sub?.cancel();
    _sub = null;
    super.dispose();
  }
}
