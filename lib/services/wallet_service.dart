import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';

/// ============================================================
/// WalletService - Quản lý ví xu MATE qua Firestore.
///
/// Cấu trúc:
///   couples/{code}.coins            → số xu hiện tại (int)
///   couples/{code}/wallet/{txId}    → lịch sử giao dịch
///     {
///       userId: String (uid thực hiện)
///       type: 'earn' | 'spend'
///       amount: int (luôn dương)
///       reason: String
///       createdAt: Timestamp
///     }
/// ============================================================

enum TransactionType { earn, spend }

class WalletTransaction {
  final String id;
  final String userId;
  final TransactionType type;
  final int amount;
  final String reason;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.reason,
    required this.createdAt,
  });

  factory WalletTransaction.fromDoc(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    final typeStr = d['type'] as String? ?? 'earn';
    return WalletTransaction(
      id: snap.id,
      userId: (d['userId'] as String?) ?? '',
      type: typeStr == 'spend' ? TransactionType.spend : TransactionType.earn,
      amount: ((d['amount'] as num?)?.toInt()) ?? 0,
      reason: (d['reason'] as String?) ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  bool get isEarn => type == TransactionType.earn;
}

class WalletService {
  WalletService._();
  static final WalletService instance = WalletService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const Duration _timeout = Duration(seconds: 12);

  CollectionReference<Map<String, dynamic>> _walletRef(String code) =>
      _db.collection('couples').doc(code).collection('wallet');

  /// Stream số xu hiện tại từ field `coins` trong couple document.
  Stream<int> watchCoins(String code) {
    return _db.collection('couples').doc(code).snapshots().map((snap) {
      final data = snap.data();
      return ((data?['coins'] as num?)?.toInt()) ?? 0;
    });
  }

  /// Nhận xu (hoàn thành thử thách, quà hằng ngày, v.v.).
  Future<void> earnCoins(String code, int amount, String reason) async {
    final uid = AuthService.instance.uid;
    if (uid == null) throw const WalletException('Chưa đăng nhập.');
    if (amount <= 0) throw const WalletException('Số xu phải lớn hơn 0.');

    // Cộng xu vào couple doc + ghi lịch sử giao dịch.
    final batch = _db.batch();

    batch.update(_db.collection('couples').doc(code), {
      'coins': FieldValue.increment(amount),
    });

    final txRef = _walletRef(code).doc();
    batch.set(txRef, {
      'userId': uid,
      'type': 'earn',
      'amount': amount,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit().timeout(_timeout);
  }

  /// Chi tiêu xu (mua vật phẩm, mở Lucky Box, v.v.).
  ///
  /// Throw nếu không đủ xu. Dùng transaction để đảm bảo atomic.
  Future<void> spendCoins(String code, int amount, String reason) async {
    final uid = AuthService.instance.uid;
    if (uid == null) throw const WalletException('Chưa đăng nhập.');
    if (amount <= 0) throw const WalletException('Số xu phải lớn hơn 0.');

    final coupleRef = _db.collection('couples').doc(code);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(coupleRef);
      final currentCoins = ((snap.data()?['coins'] as num?)?.toInt()) ?? 0;

      if (currentCoins < amount) {
        throw const WalletException('Không đủ xu MATE.');
      }

      tx.update(coupleRef, {
        'coins': FieldValue.increment(-amount),
      });

      final txRef = _walletRef(code).doc();
      tx.set(txRef, {
        'userId': uid,
        'type': 'spend',
        'amount': amount,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }).timeout(_timeout);
  }

  /// Stream lịch sử giao dịch, mới nhất đầu tiên.
  Stream<List<WalletTransaction>> watchTransactions(String code) {
    return _walletRef(code)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(WalletTransaction.fromDoc).toList());
  }

  /// Lấy giao dịch gần đây (không realtime).
  Future<List<WalletTransaction>> fetchRecentTransactions(
    String code, {
    int limit = 20,
  }) async {
    final snap = await _walletRef(code)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get()
        .timeout(_timeout);
    return snap.docs.map(WalletTransaction.fromDoc).toList();
  }
}

class WalletException implements Exception {
  final String message;
  final Object? cause;
  const WalletException(this.message, {this.cause});
  @override
  String toString() => message;
}
