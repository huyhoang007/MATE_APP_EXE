import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants/mate_theme.dart';
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
        final data = snap.data?.data() ?? <String, dynamic>{};

        // Tính số ngày bên nhau từ startDate.
        int daysTogether = 0;
        final sd = data['startDate'];
        if (sd != null) {
          final start = (sd as dynamic).toDate();
          if (start is DateTime) {
            daysTogether = DateTime.now().difference(start).inDays.clamp(0, 99999);
          }
        }
        final coupleData = <String, dynamic>{
          'user1': data['user1'],
          'user2': data['user2'],
          'daysTogether': daysTogether,
          'isPremium': data['isPremium'] ?? false,
        };

        final tabs = <Widget>[
          MapTab(
            coupleId: widget.coupleId,
            currentUserId: widget.currentUserId,
            coupleData: coupleData,
          ),
          const PetTab(),
          const MemoriesTab(),
          const ChatTab(),
          const ProfileTab(),
        ];

        return _ResponsiveFrame(
          background: const Color(0xFFFCE4EC),
          child: Scaffold(
            extendBody: true,
            body: IndexedStack(index: _index, children: tabs),
            bottomNavigationBar: _FloatingDock(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================
// Responsive Frame — max-width 430px, canh giữa trên web
// =============================================================

class _ResponsiveFrame extends StatelessWidget {
  final Widget child;
  final Color background;
  const _ResponsiveFrame({required this.child, required this.background});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > kMobileMaxWidth + 32;

    if (!isWide) {
      return Container(color: background, child: child);
    }

    return Container(
      color: background,
      alignment: Alignment.center,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMobileMaxWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
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
