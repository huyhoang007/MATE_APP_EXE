import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants/mate_theme.dart';
import '../models/couple_model.dart';
import 'tabs/map_tab.dart';
import 'tabs/pet_tab.dart';
import 'tabs/memories_tab.dart';
import 'tabs/chat_tab.dart';
import 'tabs/profile_tab.dart';

/// ============================================================
/// MainWrapperScreen - App Shell chính của MATE
///
/// Nhận:
///   - coupleId: ID document Firestore (vd: "ABC123")
///   - currentUserId: ID thiết bị của user hiện tại
///
/// - Responsive: max-width 430px, canh giữa trên web/desktop.
/// - 5 tab: Bản đồ / Pet / Khoảnh khắc / Nhắn tin / Hồ sơ.
/// ============================================================

class MainWrapperScreen extends StatefulWidget {
  final String coupleId;
  final String currentUserId;

  const MainWrapperScreen({
    super.key,
    required this.coupleId,
    required this.currentUserId,
  });

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('couples')
          .doc(widget.coupleId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final coupleDoc = snap.data!;
        final data = coupleDoc.data() ?? <String, dynamic>{};

        int daysTogether = 0;
        final sd = data['startDate'];
        if (sd != null) {
          final start = (sd as dynamic).toDate();
          if (start is DateTime) {
            daysTogether = DateTime.now().difference(start).inDays.clamp(0, 99999);
          }
        }
        final coupleData = CoupleData.fromDoc(coupleDoc);

        final tabs = <Widget>[
          MapTab(
            coupleId: widget.coupleId,
            currentUserId: widget.currentUserId,
            coupleData: coupleData,
            // Tien ich "Khoanh khac" tren Map se goi callback nay de
            // chuyen sang Tab 3 (index 2) qua cung co che setState(_index).
            onChangeTab: (i) {
              if (!mounted) return;
              setState(() => _index = i);
            },
          ),
          const PetTab(),
          MemoriesTab(
            coupleId: widget.coupleId,
            currentUserId: widget.currentUserId,
            coupleData: coupleData,
          ),
          // Tab 4 (Nhắn tin): khi được chọn, Bottom Navigation sẽ
          // được ẩn hoàn toàn để Message Input Bar chiếm vị trí đó.
          // Nhấn Back (trên Header hoặc Android system back) sẽ
          // quay về Tab 1 – Bản đồ.
          ChatTab(
            onBack: () {
              if (!mounted) return;
              setState(() => _index = 0);
            },
          ),
          // Tab 5: Hồ sơ cặp đôi — truyền cùng dữ liệu với MapTab/MemoriesTab
          // để hiển thị 2 avatar, thống kê và dòng thời gian thực tế.
          ProfileTab(
            coupleId: widget.coupleId,
            currentUserId: widget.currentUserId,
            coupleData: coupleData,
          ),
        ];

        // Ẩn Bottom Navigation khi đang ở Tab Nhắn tin (index == 3).
        final bool showDock = _index != 3;

        // MobileFrame đã bọc ở MaterialApp.builder (main.dart), nên ở đây
        // chỉ cần Scaffold thường — mọi tab và mọi route push (Games, ...)
        // đều nằm trong cùng khung mobile 430px.
        return Scaffold(
          backgroundColor: const Color(0xFFFCE4EC),
          extendBody: true,
          body: IndexedStack(index: _index, children: tabs),
          // Truyền null khi ở tab Chat để Scaffold không render dock,
          // đồng thời tự động dồn body lên tận đáy (vẫn giữ
          // resizeToAvoidBottomInset mặc định = true).
          bottomNavigationBar: showDock
              ? _FloatingDock(
                  currentIndex: _index,
                  onTap: (i) => setState(() => _index = i),
                )
              : null,
        );
      },
    );
  }
}


// =============================================================
// Floating Dock — 5 icon bottom nav
// =============================================================

class _FloatingDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _FloatingDock({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(MateRadius.dock),
            border: Border.all(color: MateColors.border, width: 1.5),
            boxShadow: MateShadows.dock,
          ),
          child: Row(
            children: [
              _DockItem(
                icon: Icons.explore_outlined,
                selectedIcon: Icons.explore,
                label: 'Bản đồ',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _DockItem(
                icon: Icons.pets_outlined,
                selectedIcon: Icons.pets,
                label: 'Pet',
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _DockItem(
                icon: Icons.camera_alt_outlined,
                selectedIcon: Icons.camera_alt,
                label: 'Khoảnh khắc',
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _DockItem(
                icon: Icons.chat_bubble_outline,
                selectedIcon: Icons.chat_bubble,
                label: 'Nhắn tin',
                selected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _DockItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Hồ sơ',
                selected: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DockItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            gradient: selected ? MateColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                color: selected ? Colors.white : MateColors.rose,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : MateColors.rose,
                  fontSize: 9,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
