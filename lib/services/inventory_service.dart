import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';

/// ============================================================
/// InventoryService - Quản lý kho vật phẩm cặp đôi qua Firestore.
///
/// Collection: couples/{code}/inventory/{itemId}
///   {
///     itemId: String          (ID gốc từ shopItems)
///     name: String
///     category: String
///     icon: String
///     rarity: String
///     inUse: bool             (đang sử dụng hay không)
///     acquiredAt: Timestamp
///   }
/// ============================================================

class InventoryItem {
  final String id;
  final String itemId;
  final String name;
  final String category;
  final String icon;
  final String rarity;
  final bool inUse;
  final DateTime acquiredAt;

  const InventoryItem({
    required this.id,
    required this.itemId,
    required this.name,
    required this.category,
    required this.icon,
    required this.rarity,
    this.inUse = false,
    required this.acquiredAt,
  });

  factory InventoryItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    return InventoryItem(
      id: snap.id,
      itemId: (d['itemId'] as String?) ?? snap.id,
      name: (d['name'] as String?) ?? '',
      category: (d['category'] as String?) ?? '',
      icon: (d['icon'] as String?) ?? 'card_giftcard',
      rarity: (d['rarity'] as String?) ?? 'common',
      inUse: (d['inUse'] as bool?) ?? false,
      acquiredAt: (d['acquiredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class InventoryService {
  InventoryService._();
  static final InventoryService instance = InventoryService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const Duration _timeout = Duration(seconds: 12);

  CollectionReference<Map<String, dynamic>> _ref(String code) =>
      _db.collection('couples').doc(code).collection('inventory');

  /// Stream toàn bộ kho đồ, sắp xếp theo thời gian mua mới nhất.
  Stream<List<InventoryItem>> watchInventory(String code) {
    return _ref(code)
        .orderBy('acquiredAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(InventoryItem.fromDoc).toList());
  }

  /// Lấy kho đồ 1 lần.
  Future<List<InventoryItem>> fetchInventory(String code) async {
    final snap = await _ref(code)
        .orderBy('acquiredAt', descending: true)
        .get()
        .timeout(_timeout);
    return snap.docs.map(InventoryItem.fromDoc).toList();
  }

  /// Bật/tắt sử dụng 1 vật phẩm.
  Future<void> toggleUse(String code, String docId, bool inUse) {
    return _ref(code).doc(docId).update({
      'inUse': inUse,
    }).timeout(_timeout);
  }

  /// Thêm 1 vật phẩm vào kho (thường gọi từ ShopService.purchaseItem).
  Future<String> addItem(
    String code, {
    required String itemId,
    required String name,
    required String category,
    required String icon,
    String rarity = 'common',
  }) async {
    final ref = _ref(code).doc();
    await ref.set({
      'itemId': itemId,
      'name': name,
      'category': category,
      'icon': icon,
      'rarity': rarity,
      'inUse': false,
      'acquiredAt': FieldValue.serverTimestamp(),
    }).timeout(_timeout);
    return ref.id;
  }

  /// Số lượng vật phẩm trong kho.
  Stream<int> watchCount(String code) {
    return _ref(code).snapshots().map((snap) => snap.docs.length);
  }
}
