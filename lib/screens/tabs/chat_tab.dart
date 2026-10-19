import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/mate_theme.dart';
import '../../widgets/mate_cloud.dart';

/// ============================================================
/// ChatTab - Tab 4: Nhắn tin (Couple Messenger UI)
///
/// Bố cục gồm:
///   - Header: avatar người yêu, tên, online, % pin, menu.
///   - Chat area: bubble 2 phía, ngày, thời gian. Mình = hồng,
///     người yêu = trắng.
///   - Activity notifications: card vị trí / check-in nằm giữa
///     cuộc trò chuyện.
///   - Message Input Bar: pill style (Messenger-like) với
///     + / ảnh / sticker ở trái, ô nhập pill ở giữa có icon
///     emoji bên trong, nút mic / send ở phải — luôn cố định
///     ở cuối màn hình, ngay trên Bottom Navigation.
///   - Bottom nav: giữ ở main_wrapper (không chỉnh sửa).
///
/// CHÚ Ý:
///   - Dữ liệu trong đây là SAMPLE để hiển thị giao diện.
///   - Chỉ thay đổi phần UI; KHÔNG đụng backend / Firestore / nav.
/// ============================================================

class ChatTab extends StatefulWidget {
  /// Callback khi người dùng nhấn nút Back trên Header hoặc
  /// thao tác Android system back. Thường dùng để chuyển về Tab 1.
  final VoidCallback? onBack;

  const ChatTab({super.key, this.onBack});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Mock data các tin nhắn theo cấu trúc ngày (read-only showcase).
  final List<_DaySection> _days = const [
    _DaySection(
      label: 'Hôm nay',
      items: [
        _Bubble(
          side: _BubbleSide.them,
          text: 'Dậy chưa em? Anh nhớ em quá 💕',
          time: '09:12',
        ),
        _Bubble(
          side: _BubbleSide.me,
          text: 'Mới dậy nè, vừa đánh răng xong á 😴',
          time: '09:14',
        ),
        _Bubble(
          side: _BubbleSide.them,
          text: 'Hôm nay anh đi công tác về sớm nha, 5h có mặt ở nhà 🥰',
          time: '09:16',
        ),
        _ActivityCard(
          icon: Icons.favorite_rounded,
          iconColor: MateColors.pink,
          badge: 'CHECK-IN',
          title: 'Anh yêu đã check-in "Vừa thức dậy"',
          subtitle: 'Điểm thân mật +5',
          time: '09:18',
        ),
        _Bubble(
          side: _BubbleSide.me,
          text: 'Okii anh, em chờ nhé. Hôm nay em nấu cơm chiều cho anh nè 🍚',
          time: '09:20',
        ),
        _Bubble(
          side: _BubbleSide.them,
          text: 'Hôm nay ăn gì đặc biệt không em?',
          time: '09:22',
        ),
        _Bubble(
          side: _BubbleSide.me,
          text: 'Em làm bún bò cho anh, thơm phức luôn 😘',
          time: '09:25',
        ),
        _ActivityCard(
          icon: Icons.location_on_rounded,
          iconColor: MateColors.info,
          badge: 'VỊ TRÍ',
          title: 'Em yêu vừa đến "Chợ Bến Thành"',
          subtitle: 'Cách anh 4.2 km',
          time: '10:42',
        ),
        _Bubble(
          side: _BubbleSide.them,
          text: 'Em mua gì vậy? Mua cho anh ổ bánh mì nha 😂',
          time: '10:45',
        ),
        _Bubble(
          side: _BubbleSide.me,
          text: 'Mua rồi nè, anh muốn ăn pate hay xíu mại? 🥖',
          time: '10:48',
        ),
        _Bubble(
          side: _BubbleSide.them,
          text: 'Pate đi em, nhớ mua thêm ổ nữa nha 😋',
          time: '10:50',
        ),
        _Bubble(
          side: _BubbleSide.me,
          text: 'Ok anh, em mua 2 ổ luôn. Yêu anh nhiều 🥰',
          time: '10:52',
        ),
      ],
    ),
    _DaySection(
      label: 'Hôm qua',
      items: [
        _Bubble(
          side: _BubbleSide.them,
          text: 'Ngủ ngon em nhé, mai mình cùng đi cafe ☕',
          time: '23:05',
        ),
        _Bubble(
          side: _BubbleSide.me,
          text: 'Dạ, anh cũng ngủ sớm nha. Yêu anh 🌙',
          time: '23:08',
        ),
      ],
    ),
  ];

  // Khoảng đệm dưới cho vùng chat cuộn: chỉ cần chừa chỗ cho
  // Message Input Bar (đã được Positioned ở đáy Stack). Bottom
  // Navigation đã được ẩn hoàn toàn khi ở Tab Nhắn tin, nên không
  // cần trừ thêm chiều cao dock ở đây.
  static const double _inputBarHeight = 64;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSend() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    // Demo UI: chỉ clear input, không đẩy lên state/backend.
    setState(() => _msgCtrl.clear());
  }

  // ────────────────────────────────────────────────────────────
  // Build chính
  // ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // PopScope: chặn hành vi back mặc định (pop Navigator / thoát
    // app) và gọi onBack để MainWrapper chuyển về Tab 1 – Bản đồ.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (widget.onBack != null) {
          // Ẩn bàn phím trước khi chuyển tab để tránh giật layout.
          FocusScope.of(context).unfocus();
          widget.onBack!();
        }
      },
      child: Container(
        decoration: const BoxDecoration(gradient: MateColors.bgGradient),
        child: Stack(
          children: [
            // Mây trang trí nền — đồng bộ style MATE.
            const Positioned(left: -40, top: 110, child: MateCloud(size: 150)),
            const Positioned(right: -50, top: 380, child: MateCloud(size: 130)),
            const Positioned(left: -40, bottom: 200, child: MateCloud(size: 160)),

            // ── Vùng chat: Column với header cố định + body cuộn được ──
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildBody(),
                  ),
                ],
              ),
            ),

            // ── Thanh nhập tin nhắn: cố định ở đáy (thay thế vị trí
            //    của Bottom Navigation khi ở Tab Nhắn tin) ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildInputBar(context),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Header: Back → Avatar → Tên/Online → Pin → Menu
  // ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: MateColors.cardBg,
        borderRadius: BorderRadius.circular(MateRadius.cardLg),
        border: Border.all(color: MateColors.border, width: 1.2),
        boxShadow: MateShadows.soft,
      ),
      child: Row(
        children: [
          // ── Nút Back (chỉ hiển thị khi có onBack) ──
          if (widget.onBack != null) ...[
            _backButton(),
            const SizedBox(width: 8),
          ],

          // Avatar người yêu + chấm online
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: MateColors.heroGradient,
                  boxShadow: MateShadows.avatar,
                ),
                child: const Center(
                  child: Text(
                    'M',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: MateColors.online,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Tên + trạng thái
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Minh Anh',
                  style: GoogleFonts.beVietnamPro(
                    color: MateColors.plum,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: MateColors.online,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Đang hoạt động',
                      style: TextStyle(
                        color: MateColors.rose,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // % pin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: MateColors.fieldBg,
              borderRadius: BorderRadius.circular(MateRadius.pill),
              border: Border.all(color: MateColors.border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.battery_full_rounded,
                  color: MateColors.pink,
                  size: 16,
                ),
                const SizedBox(width: 4),
                const Text(
                  '78%',
                  style: TextStyle(
                    color: MateColors.plum,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Menu (3 chấm)
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded),
            color: MateColors.plum,
            iconSize: 22,
            tooltip: 'Tùy chọn',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  // Nút Back phong cách MATE — nền hồng pastel, mũi tên hồng đậm.
  Widget _backButton() {
    return Tooltip(
      message: 'Quay lại',
      child: GestureDetector(
        onTap: () {
          // Ẩn bàn phím trước khi back để tránh giật layout.
          FocusScope.of(context).unfocus();
          widget.onBack?.call();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: MateColors.fieldBg,
            shape: BoxShape.circle,
            border: Border.all(color: MateColors.border, width: 1.2),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.arrow_back_rounded,
            color: MateColors.pinkDeep,
            size: 20,
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Body: cuộn các tin nhắn + activity
  // Padding dưới = chiều cao input bar + khoảng cách + dock,
  // để nội dung cuối không bị thanh nhập / bottom nav che.
  // ────────────────────────────────────────────────────────────
  Widget _buildBody() {
    // Padding dưới = chiều cao input bar + khoảng đệm, để nội dung
    // cuối không bị thanh nhập che. Bottom Navigation đã ẩn nên
    // không cộng thêm chiều cao dock ở đây.
    final double bottomReserve = _inputBarHeight + 16;

    return SingleChildScrollView(
      controller: _scrollCtrl,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(12, 4, 12, bottomReserve),
      child: Column(
        children: [
          for (final day in _days) ...[
            _buildDateSeparator(day.label),
            const SizedBox(height: 6),
            for (final item in day.items) ...[
              _buildItem(item),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildDateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(MateRadius.pill),
            border: Border.all(color: MateColors.border, width: 1),
            boxShadow: MateShadows.soft,
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: MateColors.rose,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(dynamic item) {
    if (item is _Bubble) {
      return _buildBubble(item);
    } else if (item is _ActivityCard) {
      return _buildActivityCard(item);
    }
    return const SizedBox.shrink();
  }

  // ────────────────────────────────────────────────────────────
  // Bong bóng tin nhắn
  // ────────────────────────────────────────────────────────────
  Widget _buildBubble(_Bubble b) {
    final isMe = b.side == _BubbleSide.me;
    final bubbleColor = isMe ? null : Colors.white;
    final textColor = isMe ? Colors.white : MateColors.plum;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isMe ? 20 : 6),
      bottomRight: Radius.circular(isMe ? 6 : 20),
    );

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 270),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isMe ? MateColors.primaryGradient : null,
        color: bubbleColor,
        borderRadius: radius,
        border: isMe ? null : Border.all(color: MateColors.border, width: 1),
        boxShadow: isMe
            ? MateShadows.cta
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Text(
        b.text,
        style: TextStyle(
          color: textColor,
          fontSize: 14.5,
          height: 1.35,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _avatarMini('M'),
          if (!isMe) const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                bubble,
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    b.time,
                    style: const TextStyle(
                      color: MateColors.rose,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 6),
          if (isMe) _avatarMini('B'),
        ],
      ),
    );
  }

  Widget _avatarMini(String initial) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: MateColors.heroGradient,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: MateShadows.avatar,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Activity notification (card nằm giữa cuộc trò chuyện)
  // ────────────────────────────────────────────────────────────
  Widget _buildActivityCard(_ActivityCard a) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MateColors.border, width: 1),
          boxShadow: MateShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    a.iconColor.withOpacity(0.2),
                    a.iconColor.withOpacity(0.45),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(a.icon, color: a.iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: a.iconColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          a.badge,
                          style: TextStyle(
                            color: a.iconColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        a.time,
                        style: const TextStyle(
                          color: MateColors.rose,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a.title,
                    style: const TextStyle(
                      color: MateColors.plum,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    a.subtitle,
                    style: TextStyle(
                      color: MateColors.rose.withOpacity(0.85),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Thanh nhập tin nhắn (Messenger-style) — cố định dưới cùng
  //
  // Bố cục:
  //   [+]  [🖼]  [GIF]  ( ━ pill nhập + emoji ━ )  [mic / send]
  //
  // - Tự né bàn phím qua MediaQuery.viewInsetsOf(context).bottom
  // - Tự chừa khoảng Bottom Navigation (Floating Dock) bằng
  //   _dockReservedHeight — vì Scaffold.extendBody:true nên
  //   main_wrapper không tự padding cho body.
  // ────────────────────────────────────────────────────────────
  Widget _buildInputBar(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final viewPaddingBottom = MediaQuery.viewPaddingOf(context).bottom;
    // Bottom Navigation đã được ẩn hoàn toàn khi ở Tab Nhắn tin.
    // Thanh nhập đặt sát đáy viewport, chỉ cần né system safe area
    // (gesture bar / home indicator) và bàn phím.
    final bottomPadding = viewInsets + viewPaddingBottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          border: const Border(
            top: BorderSide(color: MateColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Cụm icon bên trái: +, ảnh, sticker/gif ──
            _circleIcon(
              icon: Icons.add_rounded,
              tooltip: 'Thêm',
              onTap: () {},
            ),
            const SizedBox(width: 6),
            _circleIcon(
              icon: Icons.photo_camera_outlined,
              tooltip: 'Hình ảnh',
              onTap: () {},
            ),
            const SizedBox(width: 6),
            _circleIcon(
              icon: Icons.auto_awesome_motion_rounded,
              tooltip: 'Sticker / GIF',
              onTap: () {},
            ),
            const SizedBox(width: 8),

            // ── Ô nhập pill ở giữa, có icon emoji bên trong ──
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: MateColors.fieldBg,
                  borderRadius: BorderRadius.circular(MateRadius.pill),
                  border: Border.all(color: MateColors.border, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // TextField — placeholder "Aa" / "Nhắn cho người yêu..."
                    Expanded(
                      child: TextField(
                        controller: _msgCtrl,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _onSend(),
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          color: MateColors.plum,
                          fontSize: 14.5,
                        ),
                        cursorColor: MateColors.pink,
                        decoration: const InputDecoration(
                          hintText: 'Aa  Nhắn cho người yêu...',
                          hintStyle: TextStyle(
                            color: MateColors.rose,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),

                    // Icon emoji bên trong pill, phía bên phải
                    _iconInsidePill(
                      icon: Icons.emoji_emotions_outlined,
                      tooltip: 'Emoji',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // ── Nút mic / send bên phải ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: _msgCtrl.text.trim().isEmpty
                  ? _primaryCircleIcon(
                      icon: Icons.mic_none_rounded,
                      tooltip: 'Ghi âm',
                      key: const ValueKey('mic'),
                      onTap: () {},
                    )
                  : _primaryCircleIcon(
                      icon: Icons.send_rounded,
                      tooltip: 'Gửi',
                      key: const ValueKey('send'),
                      onTap: _onSend,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Icon vòng tròn nhỏ (nền hồng pastel) cho + / ảnh / sticker
  Widget _circleIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: MateColors.fieldBg,
            shape: BoxShape.circle,
            border: Border.all(color: MateColors.border, width: 1),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: MateColors.pink, size: 20),
        ),
      ),
    );
  }

  // Icon bên trong pill (emoji) — nền trong suốt để giữ cảm giác "nằm trong ô"
  Widget _iconInsidePill({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Icon(icon, color: MateColors.pink, size: 22),
        ),
      ),
    );
  }

  // Nút hành động chính (mic / send) — gradient hồng, nổi bật
  Widget _primaryCircleIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Key? key,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        key: key,
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: MateColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: MateShadows.cta,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// =============================================================
// Models dữ liệu cục bộ cho UI — không gắn backend.
// =============================================================

enum _BubbleSide { me, them }

class _Bubble {
  final _BubbleSide side;
  final String text;
  final String time;
  const _Bubble({
    required this.side,
    required this.text,
    required this.time,
  });
}

class _ActivityCard {
  final IconData icon;
  final Color iconColor;
  final String badge;
  final String title;
  final String subtitle;
  final String time;
  const _ActivityCard({
    required this.icon,
    required this.iconColor,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

class _DaySection {
  final String label;
  final List<dynamic> items;
  const _DaySection({required this.label, required this.items});
}
