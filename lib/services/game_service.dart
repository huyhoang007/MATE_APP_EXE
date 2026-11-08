import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';

/// ============================================================
/// GameService - Mini-game câu hỏi & lưu kết quả qua Firestore.
///
/// Collections:
///   gameQuestions/{questionId}         → câu hỏi (read-only, seed từ Admin)
///     {
///       game: 'quiz' | 'mindread' | 'daily_challenge'
///       question: String
///       options: [String]             (dùng cho quiz)
///       correctIndex: int             (0-based, -1 nếu không có đáp án)
///       category: String
///       difficulty: 'easy' | 'medium' | 'hard'
///       active: bool
///     }
///
///   couples/{code}/games/{gameId}     → kết quả chơi
///     {
///       userId: String
///       game: String
///       score: int
///       meta: Map                     (chi tiết tùy game)
///       createdAt: Timestamp
///     }
/// ============================================================

class GameQuestion {
  final String id;
  final String game;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String category;
  final String difficulty;

  const GameQuestion({
    required this.id,
    required this.game,
    required this.question,
    this.options = const [],
    this.correctIndex = -1,
    this.category = '',
    this.difficulty = 'easy',
  });

  factory GameQuestion.fromDoc(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    return GameQuestion(
      id: snap.id,
      game: (d['game'] as String?) ?? '',
      question: (d['question'] as String?) ?? '',
      options: (d['options'] as List?)?.map((e) => e as String).toList() ?? const [],
      correctIndex: ((d['correctIndex'] as num?)?.toInt()) ?? -1,
      category: (d['category'] as String?) ?? '',
      difficulty: (d['difficulty'] as String?) ?? 'easy',
    );
  }

  bool get hasCorrectAnswer => correctIndex >= 0 && correctIndex < options.length;
}

class GameResult {
  final String id;
  final String userId;
  final String game;
  final int score;
  final Map<String, dynamic> meta;
  final DateTime createdAt;

  const GameResult({
    required this.id,
    required this.userId,
    required this.game,
    required this.score,
    this.meta = const {},
    required this.createdAt,
  });

  factory GameResult.fromDoc(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    return GameResult(
      id: snap.id,
      userId: (d['userId'] as String?) ?? '',
      game: (d['game'] as String?) ?? '',
      score: ((d['score'] as num?)?.toInt()) ?? 0,
      meta: (d['meta'] as Map<String, dynamic>?) ?? const {},
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class GameService {
  GameService._();
  static final GameService instance = GameService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const Duration _timeout = Duration(seconds: 12);

  /// Cache câu hỏi đã tải (tránh gọi Firestore liên tục).
  final Map<String, List<GameQuestion>> _cache = {};

  /// Lấy câu hỏi theo loại game.
  ///
  /// [game] = 'quiz' | 'mindread' | 'daily_challenge'
  /// [limit] = số câu hỏi tối đa (mặc định 10).
  /// [shuffle] = xáo trộn thứ tự (mặc định true).
  Future<List<GameQuestion>> fetchQuestions(
    String game, {
    int limit = 10,
    bool shuffle = true,
  }) async {
    // Kiểm tra cache.
    if (_cache.containsKey(game) && _cache[game]!.isNotEmpty) {
      final cached = List<GameQuestion>.from(_cache[game]!);
      if (shuffle) cached.shuffle();
      return cached.take(limit).toList();
    }

    try {
      final snap = await _db
          .collection('gameQuestions')
          .where('game', isEqualTo: game)
          .where('active', isEqualTo: true)
          .get()
          .timeout(_timeout);

      final questions = snap.docs.map(GameQuestion.fromDoc).toList();
      _cache[game] = questions;

      final result = List<GameQuestion>.from(questions);
      if (shuffle) result.shuffle();
      return result.take(limit).toList();
    } catch (_) {
      // Fallback: trả về cache hoặc rỗng nếu Firestore lỗi.
      return _cache[game] ?? const [];
    }
  }

  /// Xóa cache (để reload câu hỏi mới).
  void clearCache() => _cache.clear();

  /// Lưu kết quả mini-game vào Firestore.
  Future<String> saveGameResult(
    String code, {
    required String game,
    required int score,
    Map<String, dynamic>? meta,
  }) async {
    final uid = AuthService.instance.uid;
    if (uid == null) throw const GameException('Chưa đăng nhập.');

    final ref = _db
        .collection('couples')
        .doc(code)
        .collection('games')
        .doc();

    await ref.set({
      'userId': uid,
      'game': game,
      'score': score,
      'meta': meta ?? {},
      'createdAt': FieldValue.serverTimestamp(),
    }).timeout(_timeout);

    return ref.id;
  }

  /// Stream lịch sử chơi game, mới nhất đầu tiên.
  Stream<List<GameResult>> watchGameHistory(String code) {
    return _db
        .collection('couples')
        .doc(code)
        .collection('games')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(GameResult.fromDoc).toList());
  }

  /// Lấy lịch sử theo loại game cụ thể.
  Future<List<GameResult>> fetchGameHistory(
    String code, {
    required String game,
    int limit = 20,
  }) async {
    final snap = await _db
        .collection('couples')
        .doc(code)
        .collection('games')
        .where('game', isEqualTo: game)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get()
        .timeout(_timeout);
    return snap.docs.map(GameResult.fromDoc).toList();
  }
}

class GameException implements Exception {
  final String message;
  final Object? cause;
  const GameException(this.message, {this.cause});
  @override
  String toString() => message;
}
