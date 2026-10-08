import 'package:flutter/material.dart';

import '../widgets/home/custom_bottom_nav.dart';
import '../widgets/mobile_frame.dart';
import 'home_dashboard_screen.dart';
import 'map_screen.dart';
import 'memories_screen.dart';
import 'date_screen.dart';

/// ============================================================
/// MainWrapper - Responsive frame + Floating dock + 4 tab.
/// ============================================================

class MainWrapper extends StatefulWidget {
  final String coupleCode;
  final String myNickname;
  final bool isUser1;

  const MainWrapper({
    super.key,
    required this.coupleCode,
    required this.myNickname,
    required this.isUser1,
  });

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _index = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeDashboardScreen(
        coupleCode: widget.coupleCode,
        myNickname: widget.myNickname,
        isUser1: widget.isUser1,
      ),
      const MapScreen(),
      const MemoriesScreen(),
      const DateScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MobileFrame(
      background: const Color(0xFFFCE4EC),
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}