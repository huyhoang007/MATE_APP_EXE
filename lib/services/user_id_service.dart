import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================
/// UserIdService - Quản lý userId thiết bị qua SharedPreferences
///
/// Mỗi lần cài/reset app sẽ có 1 userId ngẫu nhiên (UUID-like).
/// Dùng để Firestore biết ai là người dùng mà KHÔNG cần FirebaseAuth.
/// ============================================================

class UserIdService {
  UserIdService._();
  static final UserIdService instance = UserIdService._();

  static const String _key = 'mate_user_id';
  String? _cached;

  static const String _chars = 'abcdefghijklmnopqrstuvwxyz0123456789';

  String _generate() {
    final rng = Random.secure();
    return List.generate(
      24,
      (_) => _chars[rng.nextInt(_chars.length)],
    ).join();
  }

  /// Lấy userId hiện tại; nếu chưa có sẽ tự sinh & lưu.
  Future<String> getOrCreate() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null || id.isEmpty) {
      id = _generate();
      await prefs.setString(_key, id);
    }
    _cached = id;
    return id;
  }

  /// Xoá userId hiện tại (dùng khi cần reset).
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _cached = null;
  }
}