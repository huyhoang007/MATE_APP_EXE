import 'package:flutter/material.dart';

import '../constants/mate_theme.dart';
import '../models/couple_model.dart';
import '../services/couple_service.dart';
import '../widgets/home/anniversary_card.dart';
import '../widgets/home/header_card.dart';
import '../widgets/home/pet_card.dart';
import '../widgets/home/quick_actions.dart';
import '../widgets/mate_cloud.dart';

/// ============================================================
/// HomeDashboardScreen - Realtime Couple Home
/// StreamBuilder lắng nghe couples/{code} và rebuild toàn bộ UI.
/// ============================================================

class HomeDashboardScreen extends StatelessWidget {
  final String coupleCode;
  final String myNickname;
  final bool isUser1;

  const HomeDashboardScreen({
    super.key,
    required this.coupleCode,
    required this.myNickname,
    required this.isUser1,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CoupleData>(
      stream: CoupleService.instance.watchCouple(coupleCode),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }
        if (snap.hasError) {
          return _ErrorState(message: 'Lỗi kết nối: ${snap.error}');
        }
        final data = snap.data;
        if (data == null) {
          return const _ErrorState(message: 'Không tìm thấy dữ liệu cặp đôi');
        }
        return _HomeContent(
          data: data,
          myNickname: myNickname,
          isUser1: isUser1,
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  final CoupleData data;
  final String myNickname;
  final bool isUser1;

  const _HomeContent({
    required this.data,
    required this.myNickname,
    required this.isUser1,
  });

  @override
  Widget build(BuildContext context) {
    // Tự xác định mình là user1/user2 dựa trên nickname nếu flag sai.
    final me = (isUser1 || data.user1.name == myNickname)
        ? data.user1.copyWith(name: myNickname)
        : data.user1;
    final partner = isUser1 ? data.user2 : data.user1;

    return Container(
      decoration: const BoxDecoration(gradient: MateColors.bgGradient),
      child: Stack(
        children: [
          const Positioned(left: -40, top: 50, child: MateCloud(size: 140)),
          const Positioned(right: -30, top: 180, child: MateCloud(size: 110)),
          const Positioned(left: -20, bottom: 120, child: MateCloud(size: 180)),

          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeaderCard(
                    me: me,
                    partner: partner,
                    distanceKm: partner.distanceKm,
                  ),
                  const SizedBox(height: 16),
                  AnniversaryCard(
                    startDate: data.startDate,
                    onDateChanged: (d) => CoupleService.instance
                        .updateStartDate(data.code, d),
                  ),
                  const SizedBox(height: 16),
                  PetCard(
                    pet: data.pet,
                    isUser1: isUser1,
                    coupleCode: data.code,
                    onFeed: (p) =>
                        CoupleService.instance.updatePet(data.code, CoupleService.feedPet(p)),
                    onPlay: (p) => CoupleService.instance
                        .updatePet(data.code, CoupleService.playWithPet(p)),
                  ),
                  const SizedBox(height: 16),
                  QuickActions(
                    onFoodTap: () => _snack(context, 'Đang tìm quán ngon... 🍜'),
                    onGpsTap: () => _snack(context, 'Mở bản đồ 1-1... 📍'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: MateColors.pink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: MateColors.bgGradient),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(MateColors.pinkDeep),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: MateColors.bgGradient),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: MateColors.pinkDeep, size: 48),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: MateColors.plum,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}