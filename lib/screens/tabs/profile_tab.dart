import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/mate_theme.dart';
import '../../models/couple_model.dart';
import '../../widgets/vietqr_sheet.dart';

/// ============================================================
/// ProfileTab - Tab 5: Hồ sơ cặp đôi
///
/// Bố cục (cuộn dọc):
///   1. Couple Header: 2 avatar + trái tim giữa + settings
///   2. Ngày yêu nhau + số ngày
///   3. Lưới thống kê 3×2 (Bên nhau, Kỷ niệm, Thú cưng, Tương tác, Thân mật, Chuỗi)
///   4. MATE Premium banner
///   5. Kết nối / Quyền riêng tư / FAQ
///   6. Dòng thời gian tình yêu (startDate + moments từ Firestore)
///   7. Settings & tài khoản
///
/// Dữ liệu thực: Firestore `couples/{id}/moments` cho Kỷ niệm & Timeline.
/// Các chỉ số khác lấy từ `CoupleData` (startDate, intimacyScore, streakDays, pet...).
/// Các phần Premium/FAQ/Settings dùng UI mock — nút bấm mở bottom sheet
/// hoặc hiển thị snackbar.
/// ============================================================

class ProfileTab extends StatelessWidget {
  final String coupleId;
  final String currentUserId;
  final CoupleData? coupleData;

  const ProfileTab({
    super.key,
    required this.coupleId,
    required this.currentUserId,
    this.coupleData,
  });

  @override
  Widget build(BuildContext context) {
    final data = coupleData;
    if (data == null) {
      return _LoadingState();
    }

    return Container(
      decoration: const BoxDecoration(gradient: MateColors.bgGradient),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _CoupleHeader(
              coupleId: coupleId,
              user1: data.user1,
              user2: data.user2,
            ),
            const SizedBox(height: 14),
            _LovedSince(startDate: data.startDate, daysLoved: data.daysLoved),
            const SizedBox(height: 18),
            _StatsGrid(
              daysLoved: data.daysLoved,
              isPremium: data.isPremium,
              streakDays: data.streakDays,
              intimacyScore: data.intimacyScore,
              pet: data.pet,
              coupleId: coupleId,
            ),
            const SizedBox(height: 18),
            _PremiumBanner(
              isPremium: data.isPremium,
              coupleId: coupleId,
            ),
            const SizedBox(height: 18),
            _ConnectionPrivacySection(
              coupleId: coupleId,
              code: data.code,
              isPaired: data.user2.name.isNotEmpty,
            ),
            const SizedBox(height: 18),
            _CoupleTimelineSection(
              coupleId: coupleId,
              startDate: data.startDate,
              user1Name: data.user1.name,
              user2Name: data.user2.name,
            ),
            const SizedBox(height: 24),
            _AppFooter(),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// Loading state
// =============================================================

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: MateColors.bgGradient),
      child: const Center(
        child: CircularProgressIndicator(color: MateColors.pink),
      ),
    );
  }
}

// =============================================================
// 1. Couple Header
// =============================================================

class _CoupleHeader extends StatelessWidget {
  final String coupleId;
  final UserInfo user1;
  final UserInfo user2;

  const _CoupleHeader({
    required this.coupleId,
    required this.user1,
    required this.user2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: MateColors.cardBg,
        borderRadius: BorderRadius.circular(MateRadius.cardLg),
        border: Border.all(color: MateColors.border, width: 1.2),
        boxShadow: MateShadows.soft,
      ),
      child: Column(
        children: [
          // Hàng trên: nút Settings
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: MateColors.fieldBg,
                  borderRadius: BorderRadius.circular(MateRadius.pill),
                  border: Border.all(color: MateColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.favorite_rounded,
                        color: MateColors.pink, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Cặp đôi của MATE',
                      style: TextStyle(
                        color: MateColors.plum,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _openSettings(context),
                icon: const Icon(Icons.settings_rounded),
                color: MateColors.plum,
                tooltip: 'Cài đặt',
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Hàng avatar + tim
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _PartnerAvatar(
                  name: user1.name,
                  isOnline: user1.isOnline,
                  align: CrossAxisAlignment.center,
                ),
              ),
                Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: MateColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: MateShadows.cta,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.favorite_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
              Expanded(
                child: _PartnerAvatar(
                  name: user2.name.isEmpty ? 'Người yêu' : user2.name,
                  isOnline: user2.isOnline,
                  align: CrossAxisAlignment.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SettingsSheet(coupleId: coupleId),
    );
  }
}

class _PartnerAvatar extends StatelessWidget {
  final String name;
  final bool isOnline;
  final CrossAxisAlignment align;

  const _PartnerAvatar({
    required this.name,
    required this.isOnline,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Column(
      crossAxisAlignment: align,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: MateColors.heroGradient,
                boxShadow: MateShadows.avatar,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isOnline ? MateColors.online : MateColors.offline,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 96),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              color: MateColors.plum,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================
// 2. Loved since / số ngày
// =============================================================

class _LovedSince extends StatelessWidget {
  final DateTime startDate;
  final int daysLoved;

  const _LovedSince({required this.startDate, required this.daysLoved});

  @override
  Widget build(BuildContext context) {
    final m = startDate.month.toString().padLeft(2, '0');
    final d = startDate.day.toString().padLeft(2, '0');
    final y = startDate.year;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB1CB), Color(0xFFFFD8E4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(MateRadius.cardLg),
        boxShadow: MateShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded,
                color: MateColors.pinkDeep, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bên nhau $daysLoved ngày',
                  style: const TextStyle(
                    color: MateColors.plum,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Yêu nhau từ $d/$m/$y',
                  style: TextStyle(
                    color: MateColors.plum.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// 3. Stats Grid 3×2
// =============================================================

class _StatsGrid extends StatelessWidget {
  final int daysLoved;
  final bool isPremium;
  final int streakDays;
  final int intimacyScore;
  final PetState pet;
  final String coupleId;

  const _StatsGrid({
    required this.daysLoved,
    required this.isPremium,
    required this.streakDays,
    required this.intimacyScore,
    required this.pet,
    required this.coupleId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // Số khoảnh khắm thực từ Firestore
      stream: FirebaseFirestore.instance
          .collection('couples')
          .doc(coupleId)
          .collection('moments')
          .snapshots(),
      builder: (context, snap) {
        final momentsCount = snap.data?.docs.length ?? 0;
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          children: [
            _StatCard(
              emoji: '💕',
              label: 'Bên nhau',
              value: '$daysLoved',
              unit: 'ngày',
            ),
            _StatCard(
              emoji: '📸',
              label: 'Kỷ niệm',
              value: '$momentsCount',
              unit: 'ảnh',
            ),
            _StatCard(
              emoji: '🐾',
              label: 'Thú cưng',
              value: 'Lv.${pet.level}',
              unit: pet.name,
            ),
            _StatCard(
              emoji: '💌',
              label: 'Tương tác',
              // Số tim tổng = ước lượng từ intimacyScore (mỗi tim ±2 điểm).
              value: '${(intimacyScore / 2).abs()}',
              unit: 'lượt',
            ),
            _StatCard(
              emoji: '💗',
              label: 'Thân mật',
              value: '$intimacyScore',
              unit: 'điểm',
              highlight: true,
            ),
            _StatCard(
              emoji: '🔥',
              label: 'Chuỗi ngày',
              value: '$streakDays',
              unit: streakDays > 0 ? 'đang cháy' : 'ngày',
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String unit;
  final bool highlight;
  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.unit,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: highlight ? MateColors.subtlePink : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight ? MateColors.pink : MateColors.border,
          width: highlight ? 1.5 : 1,
        ),
        boxShadow: highlight ? MateShadows.soft : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: MateColors.plum,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            unit,
            style: TextStyle(
              color: MateColors.rose.withOpacity(0.85),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: MateColors.plum,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =============================================================
// 4. Premium banner
// =============================================================

class _PremiumBanner extends StatelessWidget {
  final bool isPremium;
  final String coupleId;
  const _PremiumBanner({required this.isPremium, required this.coupleId});

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return _PremiumActiveCard();
    }
    return _PremiumPromoCard(coupleId: coupleId);
  }
}

class _PremiumActiveCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MateRadius.cardLg),
        border: Border.all(color: MateColors.online, width: 1.5),
        boxShadow: MateShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: MateColors.online,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.verified_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'MATE Premium đang kích hoạt',
                  style: TextStyle(
                    color: MateColors.plum,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Cảm ơn bạn đã đồng hành cùng người yêu 💕',
                  style: TextStyle(color: MateColors.rose, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumPromoCard extends StatelessWidget {
  final String coupleId;
  const _PremiumPromoCard({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF3B69), Color(0xFFFFB1CB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(MateRadius.cardLg),
        boxShadow: MateShadows.hero,
      ),
      child: Stack(
        children: [
          // Vòng tròn trang trí
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text('👑', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 6),
                    Text(
                      'MATE Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Một người đăng ký – Cả hai cùng tận hưởng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _premiumBenefit('✨', 'VIP Daily Box: 15–25 xu/ngày'),
                _premiumBenefit('🎁', 'Vật phẩm Pet hiếm & phụ kiện độc quyền'),
                _premiumBenefit('📍', 'Theo dõi vị trí & trạng thái nâng cao'),
                _premiumBenefit('🎬', 'Nhật ký video kỷ niệm chất lượng cao'),
                _premiumBenefit('💞', 'Quyền lợi mở rộng dành cho cặp đôi'),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => VietQRSheet(coupleId: coupleId),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: MateColors.pinkDeep,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Khám phá Premium',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumBenefit(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// 5. Kết nối / Quyền riêng tư / FAQ
// =============================================================

class _ConnectionPrivacySection extends StatelessWidget {
  final String coupleId;
  final String code;
  final bool isPaired;

  const _ConnectionPrivacySection({
    required this.coupleId,
    required this.code,
    required this.isPaired,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(icon: Icons.handshake_rounded, title: 'Kết nối cặp đôi'),
        const SizedBox(height: 8),
        _CardGroup(
          children: [
            _SettingTile(
              icon: Icons.qr_code_2_rounded,
              title: 'Unique Match Code',
              subtitle: code,
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: MateColors.rose, size: 20),
                color: Colors.white,
                onSelected: (v) {
                  if (v == 'copy') {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép mã ghép đôi 💕'),
                        backgroundColor: MateColors.pink,
                      ),
                    );
                  } else if (v == 'share') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Chia sẻ mã: $code'),
                        backgroundColor: MateColors.pink,
                      ),
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'copy',
                    child: Row(children: [
                      Icon(Icons.copy, size: 18, color: MateColors.plum),
                      SizedBox(width: 8),
                      Text('Sao chép mã'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(children: [
                      Icon(Icons.share, size: 18, color: MateColors.plum),
                      SizedBox(width: 8),
                      Text('Chia sẻ'),
                    ]),
                  ),
                ],
              ),
            ),
            _SettingTile(
              icon: Icons.favorite_rounded,
              title: isPaired ? 'Đã ghép đôi' : 'Chưa kết nối',
              subtitle: isPaired
                  ? 'Hai bạn đang kết nối trên MATE'
                  : 'Chia sẻ mã để người yêu tham gia',
              valueColor: isPaired ? MateColors.online : MateColors.pinkDeep,
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _SectionTitle(
            icon: Icons.shield_outlined, title: 'Quyền riêng tư & truy cập'),
        const SizedBox(height: 8),
        _CardGroup(
          children: [
            _SettingTile(
              icon: Icons.location_on_outlined,
              title: 'Chia sẻ vị trí',
              subtitle: 'Cả hai đang chia sẻ vị trí thời gian thực',
              trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeColor: MateColors.pink,
              ),
            ),
            _SettingTile(
              icon: Icons.notifications_active_outlined,
              title: 'Thông báo',
              subtitle: 'Nhận thông báo khi người yêu online',
              trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeColor: MateColors.pink,
              ),
            ),
            _SettingTile(
              icon: Icons.photo_camera_outlined,
              title: 'Quyền Camera & Thư viện',
              subtitle: 'Dùng cho Album kỷ niệm & Nhật ký',
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: MateColors.rose),
              onTap: () => _showInfoSheet(
                context,
                title: 'Camera & Thư viện',
                content:
                    'MATE chỉ sử dụng Camera và Thư viện ảnh khi bạn chủ động chụp hoặc đăng khoảnh khắc. Ảnh của bạn chỉ chia sẻ với người yêu trong cặp đôi.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _SectionTitle(icon: Icons.help_outline_rounded, title: 'FAQ & Hỗ trợ'),
        const SizedBox(height: 8),
        _CardGroup(
          children: [
            _SettingTile(
              icon: Icons.book_outlined,
              title: 'Câu hỏi thường gặp',
              subtitle: 'Cách dùng MATE, ghép đôi, Premium...',
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: MateColors.rose),
              onTap: () => _openFaqSheet(context),
            ),
            _SettingTile(
              icon: Icons.support_agent_rounded,
              title: 'Liên hệ hỗ trợ',
              subtitle: 'Gửi phản hồi cho đội ngũ MATE',
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: MateColors.rose),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng hỗ trợ sẽ sớm sẵn sàng 💌'),
                    backgroundColor: MateColors.pink,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showInfoSheet(BuildContext context,
      {required String title, required String content}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _InfoSheet(title: title, content: content),
    );
  }

  void _openFaqSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _FaqSheet(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: MateColors.pinkDeep),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: MateColors.plum,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardGroup extends StatelessWidget {
  final List<Widget> children;
  const _CardGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final list = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      list.add(children[i]);
      if (i != children.length - 1) {
        list.add(Divider(
          height: 1,
          color: MateColors.border.withOpacity(0.7),
          indent: 52,
        ));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MateColors.border, width: 1.2),
        boxShadow: MateShadows.soft,
      ),
      child: Column(children: list),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? valueColor;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: MateColors.fieldBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: MateColors.pink, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: valueColor ?? MateColors.plum,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: MateColors.rose,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  final String title;
  final String content;
  const _InfoSheet({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return _SheetWrap(
      title: title,
      child: Text(
        content,
        style: const TextStyle(
            color: MateColors.plum, fontSize: 14, height: 1.5),
      ),
    );
  }
}

class _FaqSheet extends StatelessWidget {
  const _FaqSheet();

  static const _items = [
    (
      'MATE hoạt động như thế nào?',
      'MATE kết nối hai người yêu nhau qua một mã ghép đôi duy nhất. '
          'Sau khi kết nối, cả hai có thể chia sẻ vị trí, gửi khoảnh khắc và nuôi thú cưng ảo chung.'
    ),
    (
      'Tôi có thể hủy ghép đôi không?',
      'Tính năng quản lý kết nối đang được phát triển. Vui lòng liên hệ hỗ trợ nếu bạn cần thao tác ngay.'
    ),
    (
      'MATE Premium có những quyền lợi gì?',
      'VIP Daily Box 15–25 xu/ngày, vật phẩm Pet hiếm, theo dõi vị trí nâng cao, video kỷ niệm chất lượng cao và nhiều quyền lợi khác.'
    ),
    (
      'Dữ liệu của tôi có an toàn không?',
      'MATE chỉ chia sẻ dữ liệu giữa hai người trong cặp đôi. Mọi thông tin vị trí và ảnh đều được mã hóa và lưu trên Firebase.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _SheetWrap(
      title: 'Câu hỏi thường gặp',
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            _FaqItem(question: _items[i].$1, answer: _items[i].$2),
            if (i != _items.length - 1)
              Divider(
                height: 1,
                color: MateColors.border.withOpacity(0.7),
                indent: 16,
                endIndent: 16,
              ),
          ],
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Bỏ splash + gạch chân
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        iconColor: MateColors.pinkDeep,
        collapsedIconColor: MateColors.rose,
        title: Text(
          question,
          style: const TextStyle(
            color: MateColors.plum,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: const TextStyle(
                color: MateColors.rose,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetWrap extends StatelessWidget {
  final String title;
  final Widget child;
  const _SheetWrap({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: MateColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: MateColors.plum,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: MateColors.fieldBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: MateColors.plum, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// 6. Couple Timeline
// =============================================================

class _CoupleTimelineSection extends StatelessWidget {
  final String coupleId;
  final DateTime startDate;
  final String user1Name;
  final String user2Name;

  const _CoupleTimelineSection({
    required this.coupleId,
    required this.startDate,
    required this.user1Name,
    required this.user2Name,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
            icon: Icons.timeline_rounded, title: 'Dòng thời gian của chúng mình'),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('couples')
              .doc(coupleId)
              .collection('moments')
              .orderBy('timestamp', descending: true)
              .limit(15)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _LoadingTimeline();
            }
            if (snap.hasError) {
              return _TimelineError(error: snap.error.toString());
            }
            final moments = snap.data?.docs ?? [];
            if (moments.isEmpty) {
              return const _EmptyTimeline();
            }

            final items = <_TimelineItem>[];
            // Mốc đầu tiên: ngày yêu
            items.add(_TimelineItem(
              date: startDate,
              icon: Icons.favorite_rounded,
              iconColor: MateColors.pinkDeep,
              title: 'Bắt đầu yêu nhau',
              description: 'Hành trình của chúng mình bắt đầu từ đây 💕',
              imageUrl: '',
            ));
            // Các khoảnh khắc
            for (final m in moments) {
              final data = m.data();
              final ts = (data['timestamp'] as Timestamp?)?.toDate();
              if (ts == null) continue;
              final senderId = data['senderId'] as String? ?? '';
              final caption = (data['caption'] as String? ?? '').trim();
              final imageUrl = data['imageUrl'] as String? ?? '';
              final isVideo = (data['type'] as String?) == 'video' ||
                  (data['videoUrl'] as String? ?? '').isNotEmpty;
              final senderName = senderId.isEmpty
                  ? '—'
                  : (senderId == m.reference.parent.parent?.id
                      ? user1Name
                      : user2Name);
              items.add(_TimelineItem(
                date: ts,
                icon: isVideo ? Icons.videocam_rounded : Icons.image_rounded,
                iconColor: MateColors.pink,
                title: senderName,
                description: caption.isEmpty
                    ? (isVideo ? 'Đã chia sẻ video' : 'Đã chia sẻ khoảnh khắc')
                    : caption,
                imageUrl: imageUrl,
                isVideo: isVideo,
              ));
            }

            return _TimelineList(items: items);
          },
        ),
      ],
    );
  }
}

class _TimelineItem {
  final DateTime date;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String imageUrl;
  final bool isVideo;
  const _TimelineItem({
    required this.date,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.isVideo = false,
  });
}

class _TimelineList extends StatelessWidget {
  final List<_TimelineItem> items;
  const _TimelineList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _TimelineRow(
            item: items[i],
            isFirst: i == 0,
            isLast: i == items.length - 1,
          ),
        ],
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final _TimelineItem item;
  final bool isFirst;
  final bool isLast;
  const _TimelineRow({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột timeline
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: item.iconColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: MateShadows.soft,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: MateColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: _TimelineCard(item: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final _TimelineItem item;
  const _TimelineCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MateColors.border, width: 1),
        boxShadow: MateShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(item.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                            color: MateColors.fieldBg,
                            child: const Icon(Icons.broken_image,
                                color: MateColors.rose, size: 32),
                          )),
                  if (item.isVideo)
                    Container(
                      color: Colors.black26,
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: MateColors.pinkDeep, size: 26),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(item.icon, size: 14, color: item.iconColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: MateColors.plum,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(item.date),
                      style: TextStyle(
                        color: MateColors.rose.withOpacity(0.85),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: MateColors.plum,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final today = DateTime.now();
    if (dt.year == today.year && dt.month == today.month && dt.day == today.day) {
      return 'Hôm nay';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _LoadingTimeline extends StatelessWidget {
  const _LoadingTimeline();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: MateColors.pink),
    );
  }
}

class _TimelineError extends StatelessWidget {
  final String error;
  const _TimelineError({required this.error});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MateColors.border),
      ),
      child: Text(
        'Không thể tải dòng thời gian: $error',
        style: const TextStyle(color: MateColors.rose, fontSize: 12),
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MateColors.border),
      ),
      child: Column(
        children: [
          const Text('💕', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text(
            'Hành trình của chúng mình đang chờ những kỷ niệm đầu tiên 💕',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MateColors.plum,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hãy gửi khoảnh khắc đầu tiên trong Tab Khoảnh khắc nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: MateColors.rose.withOpacity(0.85), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// 7. Settings Sheet (mở từ icon ⚙ ở Header)
// =============================================================

class _AppFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.favorite_rounded, color: MateColors.pink, size: 24),
        const SizedBox(height: 4),
        Text(
          'MATE',
          style: GoogleFonts.beVietnamPro(
            color: MateColors.plum,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Dành cho những người yêu nhau 💕',
          style: TextStyle(
              color: MateColors.rose.withOpacity(0.7), fontSize: 11),
        ),
      ],
    );
  }
}

// =============================================================
// Settings Sheet (mở từ icon ⚙ ở Header)
// =============================================================

class _SettingsSheet extends StatelessWidget {
  final String coupleId;
  const _SettingsSheet({required this.coupleId});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: MateColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Cài đặt hồ sơ',
                  style: TextStyle(
                    color: MateColors.plum,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _CardGroup(children: [
                    _SettingTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Thông tin cá nhân',
                      subtitle: 'Tên, avatar, trạng thái',
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: MateColors.rose),
                      onTap: () => Navigator.pop(context),
                    ),
                    _SettingTile(
                      icon: Icons.favorite_border_rounded,
                      title: 'Thông tin cặp đôi',
                      subtitle: 'Ngày bắt đầu, mã ghép đôi',
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: MateColors.rose),
                      onTap: () => Navigator.pop(context),
                    ),
                    _SettingTile(
                      icon: Icons.handshake_rounded,
                      title: 'Quản lý kết nối',
                      subtitle: 'Mã ghép đôi, trạng thái cặp',
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: MateColors.rose),
                      onTap: () => Navigator.pop(context),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _CardGroup(children: [
                    _SettingTile(
                      icon: Icons.shield_moon_outlined,
                      title: 'Quyền riêng tư & chia sẻ vị trí',
                      subtitle: 'Quản lý quyền chia sẻ dữ liệu',
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: MateColors.rose),
                      onTap: () => Navigator.pop(context),
                    ),
                    _SettingTile(
                      icon: Icons.notifications_outlined,
                      title: 'Thông báo',
                      subtitle: 'Push, trong ứng dụng',
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: MateColors.rose),
                      onTap: () => Navigator.pop(context),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _CardGroup(children: [
                    _SettingTile(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Quản lý Premium',
                      subtitle: 'Gói, thanh toán, lịch sử',
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: MateColors.rose),
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => VietQRSheet(coupleId: coupleId),
                        );
                      },
                    ),
                    _SettingTile(
                      icon: Icons.help_outline_rounded,
                      title: 'FAQ và hỗ trợ',
                      subtitle: 'Câu hỏi thường gặp, liên hệ',
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: MateColors.rose),
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => const _FaqSheet(),
                        );
                      },
                    ),
                    _SettingTile(
                      icon: Icons.info_outline_rounded,
                      title: 'Về MATE',
                      subtitle: 'Phiên bản 1.0.0',
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: MateColors.rose),
                      onTap: () => Navigator.pop(context),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
