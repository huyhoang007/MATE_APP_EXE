import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/mate_theme.dart';
import '../../models/couple_model.dart';
import '../../services/couple_service.dart';
import '../../widgets/mate_cloud.dart';

/// ============================================================
/// PetTab - Tab 2: Nhà của Pet
///
/// Kết nối realtime với Firestore qua CoupleService:
///   - Đọc pet state từ couples/{coupleId}.pet
///   - feedPet, playWithPet, renamePet trực tiếp Firestore.
/// ============================================================

class PetTab extends StatefulWidget {
  final String? coupleId;
  final String? currentUserId;
  final CoupleData? coupleData;

  const PetTab({
    super.key,
    this.coupleId,
    this.currentUserId,
    this.coupleData,
  });

  @override
  State<PetTab> createState() => _PetTabState();
}

class _PetTabState extends State<PetTab> with SingleTickerProviderStateMixin {
  bool _isFeeding = false;
  bool _isPlaying = false;
  late AnimationController _bounceCtrl;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  Future<void> _feed(PetState pet) async {
    if (_isFeeding || widget.coupleId == null) return;
    setState(() => _isFeeding = true);
    try {
      await CoupleService.instance.feedPet(widget.coupleId!, pet);
      _bounceCtrl.forward(from: 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🍖 Pet đã được ăn! Hunger +20, EXP +15'),
            backgroundColor: MateColors.pink,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: MateColors.rose),
        );
      }
    } finally {
      if (mounted) setState(() => _isFeeding = false);
    }
  }

  Future<void> _play(PetState pet) async {
    if (_isPlaying || widget.coupleId == null) return;
    setState(() => _isPlaying = true);
    try {
      await CoupleService.instance.playWithPet(widget.coupleId!, pet);
      _bounceCtrl.forward(from: 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎾 Pet rất vui! Happiness +25, EXP +10'),
            backgroundColor: MateColors.pink,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: MateColors.rose),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  Future<void> _rename() async {
    if (widget.coupleId == null) return;

    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Đổi tên Pet',
            style: GoogleFonts.beVietnamPro(
              fontWeight: FontWeight.w800,
              color: MateColors.plum,
            )),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(
            hintText: 'Nhập tên mới...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx, ctrl.text.trim());
              }
            },
            child: const Text('Đổi tên'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await CoupleService.instance.renamePet(widget.coupleId!, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✨ Pet đã được đổi tên thành "$result"!'),
              backgroundColor: MateColors.pink,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: MateColors.rose),
          );
        }
      }
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coupleId = widget.coupleId;
    if (coupleId == null) {
      return const Center(child: Text('Chưa kết nối phòng'));
    }

    return Container(
      decoration: const BoxDecoration(gradient: MateColors.bgGradient),
      child: Stack(
        children: [
          const Positioned(left: -40, top: 100, child: MateCloud(size: 140)),
          const Positioned(right: -50, top: 350, child: MateCloud(size: 120)),
          const Positioned(left: -30, bottom: 150, child: MateCloud(size: 150)),

          SafeArea(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('couples')
                  .doc(coupleId)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: MateColors.pink),
                  );
                }

                final data = snap.data!.data() ?? {};
                final pet =
                    PetState.fromMap(data['pet'] as Map<String, dynamic>?);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  child: Column(
                    children: [
                      _buildPetHeader(pet),
                      const SizedBox(height: 16),
                      _buildPetAvatar(pet),
                      const SizedBox(height: 20),
                      _buildStatsGrid(pet),
                      const SizedBox(height: 16),
                      _buildActionButtons(pet),
                      const SizedBox(height: 16),
                      _buildPetInfo(pet),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetHeader(PetState pet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: MateColors.cardBg,
        borderRadius: BorderRadius.circular(MateRadius.cardLg),
        border: Border.all(color: MateColors.border, width: 1.2),
        boxShadow: MateShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: MateColors.heroGradient,
            ),
            child: const Center(
              child: Text('🐱', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: GoogleFonts.beVietnamPro(
                    color: MateColors.plum,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Level ${pet.level} • EXP: ${pet.exp}/100',
                  style: const TextStyle(
                    color: MateColors.rose,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _rename,
            icon: const Icon(Icons.edit_rounded),
            color: MateColors.pink,
            tooltip: 'Đổi tên',
          ),
        ],
      ),
    );
  }

  Widget _buildPetAvatar(PetState pet) {
    final String mood;
    if (pet.happiness >= 0.7 && pet.hunger >= 0.5) {
      mood = '😻';
    } else if (pet.happiness >= 0.4) {
      mood = '🐱';
    } else if (pet.hunger < 0.3) {
      mood = '😿';
    } else {
      mood = '😾';
    }

    return AnimatedBuilder(
      animation: _bounceCtrl,
      builder: (_, child) {
        final scale = 1.0 + 0.1 * (1 - (_bounceCtrl.value * 2 - 1).abs());
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: MateColors.heroGradient,
          boxShadow: MateShadows.cta,
        ),
        child: Center(
          child: Text(mood, style: const TextStyle(fontSize: 72)),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(PetState pet) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            '🍖 Hunger',
            pet.hunger,
            pet.hunger >= 0.5 ? MateColors.online : MateColors.rose,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            '😊 Happiness',
            pet.happiness,
            pet.happiness >= 0.5 ? MateColors.pink : MateColors.rose,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, double value, Color barColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MateColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MateColors.border, width: 1),
        boxShadow: MateShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: MateColors.plum,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: MateColors.fieldBg,
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(value * 100).round()}%',
            style: TextStyle(
              color: barColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(PetState pet) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.restaurant_rounded,
            label: 'Cho ăn',
            isLoading: _isFeeding,
            onTap: () => _feed(pet),
            gradient: MateColors.primaryGradient,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            icon: Icons.sports_esports_rounded,
            label: 'Chơi cùng',
            isLoading: _isPlaying,
            onTap: () => _play(pet),
            gradient: MateColors.heroGradient,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
    required Gradient gradient,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedOpacity(
        opacity: isLoading ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: MateShadows.cta,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetInfo(PetState pet) {
    final lastFedStr = pet.lastFed != null
        ? '${pet.lastFed!.hour.toString().padLeft(2, '0')}:${pet.lastFed!.minute.toString().padLeft(2, '0')} - ${pet.lastFed!.day}/${pet.lastFed!.month}'
        : 'Chưa bao giờ';
    final lastPlayedStr = pet.lastPlayed != null
        ? '${pet.lastPlayed!.hour.toString().padLeft(2, '0')}:${pet.lastPlayed!.minute.toString().padLeft(2, '0')} - ${pet.lastPlayed!.day}/${pet.lastPlayed!.month}'
        : 'Chưa bao giờ';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MateColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MateColors.border, width: 1),
        boxShadow: MateShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin Pet',
            style: GoogleFonts.beVietnamPro(
              color: MateColors.plum,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _infoRow('🍽️ Ăn lần cuối', lastFedStr),
          _infoRow('🎮 Chơi lần cuối', lastPlayedStr),
          _infoRow('⭐ Level', 'Lv. ${pet.level}'),
          _infoRow('✨ EXP', '${pet.exp}/100'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: MateColors.rose,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: MateColors.plum,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
