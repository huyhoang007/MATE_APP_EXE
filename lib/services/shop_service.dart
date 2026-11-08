import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';
import 'wallet_service.dart';

/// ============================================================
/// ShopService - Đọc vật phẩm & danh mục từ Firestore (read-only).
///
/// Collections (seed từ Admin, client chỉ đọc):
///   shopItems/{itemId}
///     {
///       name, category, coins, rarity, icon, description, active
///     }
///   shopCategories/{categoryId}
///     {
///       id, name, icon, order, active
///     }
///
/// Mua vật phẩm → ghi vào inventory + trừ xu qua WalletService.
/// ============================================================

class ShopItem {
  final String id;
  final String name;
  final String category;
  final int coins;
  final String rarity;
  final String icon;
  final String description;
  final bool active;

  const ShopItem({
    required this.id,
    required this.name,
    required this.category,
    required this.coins,
    required this.rarity,
    required this.icon,
    required this.description,
    this.active = true,
  });

  factory ShopItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    return ShopItem(
      id: snap.id,
      name: (d['name'] as String?) ?? '',
      category: (d['category'] as String?) ?? '',
      coins: ((d['coins'] as num?)?.toInt()) ?? 0,
      rarity: (d['rarity'] as String?) ?? 'common',
      icon: (d['icon'] as String?) ?? 'card_giftcard',
      description: (d['description'] as String?) ?? '',
      active: (d['active'] as bool?) ?? true,
    );
  }
}

class ShopCategory {
  final String id;
  final String name;
  final String icon;
  final int order;
  final bool active;

  const ShopCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.order,
    this.active = true,
  });

  factory ShopCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    return ShopCategory(
      id: snap.id,
      name: (d['name'] as String?) ?? '',
      icon: (d['icon'] as String?) ?? '',
      order: ((d['order'] as num?)?.toInt()) ?? 0,
      active: (d['active'] as bool?) ?? true,
    );
  }
}

class ShopService {
  ShopService._();
  static final ShopService instance = ShopService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const Duration _timeout = Duration(seconds: 12);

  static const List<ShopItem> defaultItems = [
    ShopItem(
      id: 'item_hat_pink',
      name: 'Mũ Rơm Trái Tim',
      category: 'pet',
      coins: 50,
      rarity: 'rare',
      icon: 'pets',
      description: 'Chiếc mũ xinh xắn làm tăng 20% điểm vui vẻ cho Mochi.',
    ),
    ShopItem(
      id: 'item_bell_gold',
      name: 'Vòng Cổ Chuông Vàng',
      category: 'pet',
      coins: 80,
      rarity: 'epic',
      icon: 'notifications_active',
      description: 'Lắc chuông lanh lảnh mỗi khi Mochi chạy nhảy.',
    ),
    ShopItem(
      id: 'item_theme_sunset',
      name: 'Theme Hoàng Hôn Tình Yêu',
      category: 'theme',
      coins: 120,
      rarity: 'epic',
      icon: 'palette',
      description: 'Tông màu cam hồng ấm áp cho toàn bộ giao diện app.',
    ),
    ShopItem(
      id: 'item_sticker_pack_cat',
      name: 'Gói Sticker Mèo Đôi',
      category: 'sticker',
      coins: 30,
      rarity: 'common',
      icon: 'emoji_emotions',
      description: '12 biểu cảm siêu đáng yêu cho khung chat hai bạn.',
    ),
    ShopItem(
      id: 'item_milk_bottle',
      name: 'Bình Sữa Thú Cưng Siêu Cấp',
      category: 'pet',
      coins: 40,
      rarity: 'common',
      icon: 'local_cafe',
      description: 'Hồi phục 100% độ no cho thú cưng ngay lập tức.',
    ),
    ShopItem(
      id: 'item_couple_badge_star',
      name: 'Huy Hiệu Ngôi Sao Đôi',
      category: 'badge',
      coins: 150,
      rarity: 'legendary',
      icon: 'military_tech',
      description: 'Huy hiệu phát sáng lấp lánh trên trang cá nhân.',
    ),
  ];

  /// Stream danh sách vật phẩm (active).
  Stream<List<ShopItem>> watchItems() {
    return _db
        .collection('shopItems')
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snap) {
      if (snap.docs.isNotEmpty) {
        return snap.docs.map(ShopItem.fromDoc).toList();
      }
      return defaultItems;
    });
  }

  /// Lấy danh sách vật phẩm 1 lần.
  Future<List<ShopItem>> fetchItems() async {
    try {
      final snap = await _db
          .collection('shopItems')
          .where('active', isEqualTo: true)
          .get()
          .timeout(_timeout);
      if (snap.docs.isNotEmpty) {
        return snap.docs.map(ShopItem.fromDoc).toList();
      }
    } catch (_) {}
    return defaultItems;
  }

  /// Stream danh mục, sắp xếp theo order.
  Stream<List<ShopCategory>> watchCategories() {
    return _db
        .collection('shopCategories')
        .where('active', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map(ShopCategory.fromDoc).toList());
  }

  /// Lấy danh mục 1 lần.
  Future<List<ShopCategory>> fetchCategories() async {
    final snap = await _db
        .collection('shopCategories')
        .where('active', isEqualTo: true)
        .orderBy('order')
        .get()
        .timeout(_timeout);
    return snap.docs.map(ShopCategory.fromDoc).toList();
  }

  /// Mua vật phẩm: trừ xu + thêm vào inventory.
  ///
  /// Throw [ShopException] nếu không đủ xu hoặc chưa đăng nhập.
  Future<void> purchaseItem(String code, ShopItem item) async {
    final uid = AuthService.instance.uid;
    if (uid == null) throw const ShopException('Chưa đăng nhập.');

    // Trừ xu qua WalletService (đã có transaction atomic).
    await WalletService.instance.spendCoins(
      code,
      item.coins,
      'Mua ${item.name}',
    );

    // Thêm vào inventory.
    await _db
        .collection('couples')
        .doc(code)
        .collection('inventory')
        .doc()
        .set({
      'itemId': item.id,
      'name': item.name,
      'category': item.category,
      'icon': item.icon,
      'rarity': item.rarity,
      'inUse': false,
      'acquiredAt': FieldValue.serverTimestamp(),
    }).timeout(_timeout);
  }
}

class ShopException implements Exception {
  final String message;
  final Object? cause;
  const ShopException(this.message, {this.cause});
  @override
  String toString() => message;
}
