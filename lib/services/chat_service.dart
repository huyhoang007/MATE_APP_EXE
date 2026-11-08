import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';

/// ============================================================
/// ChatService - Nhắn tin thời gian thực giữa 2 người yêu.
///
/// Firestore: couples/{code}/messages/{messageId}
///   {
///     text: String
///     senderId: String (uid)
///     senderName: String
///     type: 'text' | 'image' | 'activity'
///     imageUrl: String?
///     createdAt: Timestamp
///     readAt: Timestamp?
///     readBy: [uid]
///     meta: {...}   // cho activity card (check-in, vị trí...)
///   }
/// ============================================================

enum MessageType { text, image, activity }

class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final MessageType type;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? readAt;
  final List<String> readBy;
  final Map<String, dynamic> meta;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    this.type = MessageType.text,
    this.imageUrl,
    required this.createdAt,
    this.readAt,
    this.readBy = const [],
    this.meta = const {},
  });

  bool get isImage => type == MessageType.image;
  bool get isActivity => type == MessageType.activity;

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    final typeStr = d['type'] as String? ?? 'text';
    return ChatMessage(
      id: snap.id,
      text: (d['text'] as String?) ?? '',
      senderId: (d['senderId'] as String?) ?? '',
      senderName: (d['senderName'] as String?) ?? '',
      type: MessageType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => MessageType.text,
      ),
      imageUrl: d['imageUrl'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (d['readAt'] as Timestamp?)?.toDate(),
      readBy: (d['readBy'] as List?)?.map((e) => e as String).toList() ?? const [],
      meta: (d['meta'] as Map<String, dynamic>?) ?? const {},
    );
  }

  /// Tin nhắn đã được người kia đọc chưa.
  bool isReadBy(String uid) => readBy.contains(uid);
}

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _messages = 'messages';
  static const Duration _timeout = Duration(seconds: 12);

  CollectionReference<Map<String, dynamic>> _ref(String code) =>
      _db.collection('couples').doc(code).collection(_messages);

  /// Stream tin nhắn, mới nhất cuối cùng (Firestore tự sắp theo createdAt).
  Stream<List<ChatMessage>> watchMessages(String code) {
    return _ref(code)
        .orderBy('createdAt', descending: false)
        .limitToLast(300)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  /// Gửi tin nhắn text.
  Future<String> sendText({
    required String code,
    required String text,
    required String senderName,
  }) async {
    final uid = AuthService.instance.uid;
    if (uid == null) throw const ChatException('Chưa đăng nhập.');
    final clean = text.trim();
    if (clean.isEmpty) throw const ChatException('Nội dung trống.');

    final ref = _ref(code).doc();
    await ref.set({
      'text': clean,
      'senderId': uid,
      'senderName': senderName,
      'type': 'text',
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [uid],
    }).timeout(_timeout);

    return ref.id;
  }

  /// Gửi tin nhắn kèm ảnh (đã upload lên Storage trước).
  Future<String> sendImage({
    required String code,
    required String imageUrl,
    required String senderName,
    String caption = '',
  }) async {
    final uid = AuthService.instance.uid;
    if (uid == null) throw const ChatException('Chưa đăng nhập.');

    final ref = _ref(code).doc();
    await ref.set({
      'text': caption.trim(),
      'senderId': uid,
      'senderName': senderName,
      'type': 'image',
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [uid],
    }).timeout(_timeout);

    return ref.id;
  }

  /// Gửi "activity card" — vd: check-in, đến vị trí, hoàn thành thử thách.
  Future<String> sendActivity({
    required String code,
    required String senderName,
    required String title,
    required String subtitle,
    required String badge,
    String icon = 'favorite',
  }) async {
    final uid = AuthService.instance.uid;
    if (uid == null) throw const ChatException('Chưa đăng nhập.');

    final ref = _ref(code).doc();
    await ref.set({
      'text': title,
      'senderId': uid,
      'senderName': senderName,
      'type': 'activity',
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [uid],
      'meta': {
        'title': title,
        'subtitle': subtitle,
        'badge': badge,
        'icon': icon,
      },
    }).timeout(_timeout);

    return ref.id;
  }

  /// Đánh dấu đã đọc tất cả tin nhắn của người kia.
  ///
  /// Firestore Dart SDK không hỗ trợ `arrayNotContains`; dùng cách lấy
  /// tất cả tin nhắn của người kia rồi lọc client-side theo `readBy`.
  Future<void> markAllRead(String code) async {
    final uid = AuthService.instance.uid;
    if (uid == null) return;

    final msgs = await _ref(code)
        .where('senderId', isNotEqualTo: uid)
        .limit(100)
        .get();

    final unread = msgs.docs
        .where((d) => !((d.data()['readBy'] as List?)?.contains(uid) ?? false))
        .toList();

    if (unread.isEmpty) return;

    final batch = _db.batch();
    for (final doc in unread) {
      batch.update(doc.reference, {
        'readBy': FieldValue.arrayUnion([uid]),
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit().timeout(_timeout);
  }

  /// Số tin nhắn chưa đọc.
  Stream<int> watchUnreadCount(String code) {
    final uid = AuthService.instance.uid;
    if (uid == null) return Stream.value(0);
    return _ref(code)
        .where('senderId', isNotEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs
            .where((d) => !((d.data()['readBy'] as List?)?.contains(uid) ?? false))
            .length);
  }
}

class ChatException implements Exception {
  final String message;
  final Object? cause;
  const ChatException(this.message, {this.cause});
  @override
  String toString() => message;
}
