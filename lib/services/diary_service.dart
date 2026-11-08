import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';

/// ============================================================
/// DiaryService - Nhật ký cặp đôi hằng ngày qua Firestore.
///
/// Collection: couples/{code}/diaries/{dateKey}
///   dateKey = 'yyyy-MM-dd'
///   {
///     userId: String         (người viết)
///     dateKey: String        ('yyyy-MM-dd')
///     text: String           (nội dung nhật ký)
///     mood: String?          ('happy' | 'love' | 'sad' | 'angry' | 'neutral')
///     imageUrl: String?      (ảnh đính kèm, đã upload lên Storage)
///     createdAt: Timestamp
///     updatedAt: Timestamp
///   }
///
/// Mỗi ngày chỉ có 1 entry (dùng dateKey làm document ID).
/// Cả 2 người đều có thể đọc, nhưng chỉ người viết sửa/xóa được.
/// ============================================================

class DiaryEntry {
  final String dateKey;
  final String userId;
  final String text;
  final String? mood;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DiaryEntry({
    required this.dateKey,
    required this.userId,
    required this.text,
    this.mood,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiaryEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    return DiaryEntry(
      dateKey: snap.id,
      userId: (d['userId'] as String?) ?? '',
      text: (d['text'] as String?) ?? '',
      mood: d['mood'] as String?,
      imageUrl: d['imageUrl'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Kiểm tra xem diary có nội dung hay không.
  bool get isEmpty => text.trim().isEmpty && imageUrl == null;
}

class DiaryService {
  DiaryService._();
  static final DiaryService instance = DiaryService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const Duration _timeout = Duration(seconds: 12);

  CollectionReference<Map<String, dynamic>> _ref(String code) =>
      _db.collection('couples').doc(code).collection('diaries');

  /// Stream nhật ký gần đây, mới nhất đầu tiên.
  Stream<List<DiaryEntry>> watchDiaries(String code, {int limit = 30}) {
    return _ref(code)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(DiaryEntry.fromDoc).toList());
  }

  /// Lấy nhật ký 1 lần (không realtime).
  Future<List<DiaryEntry>> fetchDiaries(String code, {int limit = 30}) async {
    final snap = await _ref(code)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get()
        .timeout(_timeout);
    return snap.docs.map(DiaryEntry.fromDoc).toList();
  }

  /// Lấy nhật ký cho 1 ngày cụ thể.
  Future<DiaryEntry?> getDiaryForDate(String code, String dateKey) async {
    final snap = await _ref(code).doc(dateKey).get().timeout(_timeout);
    if (!snap.exists) return null;
    return DiaryEntry.fromDoc(snap);
  }

  /// Lưu/cập nhật nhật ký cho 1 ngày.
  ///
  /// Dùng dateKey làm document ID → mỗi ngày chỉ có 1 entry.
  Future<void> saveDiary(
    String code, {
    required String dateKey,
    required String text,
    String? mood,
    String? imageUrl,
  }) async {
    final uid = AuthService.instance.uid;
    if (uid == null) throw const DiaryException('Chưa đăng nhập.');

    final docRef = _ref(code).doc(dateKey);
    final existing = await docRef.get().timeout(_timeout);

    if (existing.exists) {
      // Cập nhật (chỉ người viết mới được sửa — theo Firestore rules).
      await docRef.update({
        'text': text.trim(),
        if (mood != null) 'mood': mood,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(_timeout);
    } else {
      // Tạo mới.
      await docRef.set({
        'userId': uid,
        'dateKey': dateKey,
        'text': text.trim(),
        'mood': mood ?? 'neutral',
        if (imageUrl != null) 'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(_timeout);
    }
  }

  /// Xóa nhật ký (chỉ người viết mới xóa được — theo Firestore rules).
  Future<void> deleteDiary(String code, String dateKey) {
    return _ref(code).doc(dateKey).delete().timeout(_timeout);
  }

  /// Ngày hôm nay dạng 'yyyy-MM-dd'.
  static String todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

class DiaryException implements Exception {
  final String message;
  const DiaryException(this.message);
  @override
  String toString() => message;
}
