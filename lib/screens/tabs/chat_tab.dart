import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/mate_theme.dart';
import '../../models/couple_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/mate_cloud.dart';

/// ============================================================
/// ChatTab - Tab 4: Nhắn tin (Couple Messenger UI)
///
/// Kết nối realtime với Firestore qua ChatService:
///   - Collection: couples/{coupleId}/messages/{messageId}
///   - Gửi / nhận tin nhắn văn bản, ảnh, activity realtime.
///   - Đánh dấu đã đọc qua ChatService.markAllRead().
/// ============================================================

class ChatTab extends StatefulWidget {
  final String? coupleId;
  final String? currentUserId;
  final CoupleData? coupleData;

  /// Callback khi người dùng nhấn nút Back trên Header.
  final VoidCallback? onBack;

  const ChatTab({
    super.key,
    this.coupleId,
    this.currentUserId,
    this.coupleData,
    this.onBack,
  });

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;

  static const double _inputBarHeight = 64;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  void _markRead() {
    if (widget.coupleId != null) {
      ChatService.instance.markAllRead(widget.coupleId!).catchError((e) {
        debugPrint('Error marking messages as read: $e');
      });
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onSend() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    final coupleId = widget.coupleId;
    if (coupleId == null) return;

    setState(() {
      _isSending = true;
      _msgCtrl.clear();
    });

    try {
      final myName = widget.coupleData?.user1.name ?? 'Tôi';
      await ChatService.instance.sendText(
        code: coupleId,
        text: text,
        senderName: myName,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi tin nhắn: $e'),
            backgroundColor: MateColors.rose,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (widget.onBack != null) {
          FocusScope.of(context).unfocus();
          widget.onBack!();
        }
      },
      child: Container(
        decoration: const BoxDecoration(gradient: MateColors.bgGradient),
        child: Stack(
          children: [
            // Mây trang trí nền
            const Positioned(left: -40, top: 110, child: MateCloud(size: 150)),
            const Positioned(right: -50, top: 380, child: MateCloud(size: 130)),
            const Positioned(left: -40, bottom: 200, child: MateCloud(size: 160)),

            // Vùng chat
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildMessagesStream(),
                  ),
                ],
              ),
            ),

            // Thanh nhập tin nhắn
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
  // Header: Partner info từ Firestore
  // ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final partner = widget.coupleData?.user2;
    final partnerName = partner?.name ?? 'Người yêu';
    final isOnline = partner?.isOnline ?? false;
    final battery = partner?.batteryLevel ?? 100;
    final initial = partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'M';

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
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
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
                    color: isOnline ? MateColors.online : Colors.grey,
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
                  partnerName,
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
                      decoration: BoxDecoration(
                        color: isOnline ? MateColors.online : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Đang hoạt động' : 'Vừa rời đi',
                      style: const TextStyle(
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
                Icon(
                  battery > 20
                      ? Icons.battery_full_rounded
                      : Icons.battery_alert_rounded,
                  color: battery > 20 ? MateColors.pink : MateColors.rose,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '$battery%',
                  style: const TextStyle(
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

  Widget _backButton() {
    return Tooltip(
      message: 'Quay lại',
      child: GestureDetector(
        onTap: () {
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
  // Messages Stream từ Firestore
  // ────────────────────────────────────────────────────────────
  Widget _buildMessagesStream() {
    final coupleId = widget.coupleId;
    if (coupleId == null) {
      return const Center(child: Text('Chưa kết nối phòng'));
    }

    return StreamBuilder<List<ChatMessage>>(
      stream: ChatService.instance.watchMessages(coupleId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Lỗi tải tin nhắn: ${snapshot.error}',
              style: const TextStyle(color: MateColors.rose),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: MateColors.pink),
          );
        }

        final messages = snapshot.data!;
        if (messages.isEmpty) {
          return _buildEmptyState();
        }

        // Tự động cuộn xuống tin nhắn mới nhất
        _scrollToBottom();

        // Nhóm tin nhắn theo ngày
        final grouped = _groupMessagesByDate(messages);
        final double bottomReserve = _inputBarHeight + 16;

        return SingleChildScrollView(
          controller: _scrollCtrl,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(12, 4, 12, bottomReserve),
          child: Column(
            children: [
              for (final group in grouped) ...[
                _buildDateSeparator(group.label),
                const SizedBox(height: 6),
                for (final msg in group.items) ...[
                  _buildMessageItem(msg),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 6),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MateColors.pink.withOpacity(0.12),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 36,
              color: MateColors.pink,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Chưa có tin nhắn nào',
            style: GoogleFonts.beVietnamPro(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: MateColors.plum,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hãy gửi tin nhắn đầu tiên cho người ấy 💕',
            style: TextStyle(
              fontSize: 13,
              color: MateColors.rose,
            ),
          ),
        ],
      ),
    );
  }

  List<_DateGroup> _groupMessagesByDate(List<ChatMessage> messages) {
    final groups = <_DateGroup>[];
    if (messages.isEmpty) return groups;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String currentLabel = '';
    List<ChatMessage> currentItems = [];

    for (final msg in messages) {
      final msgDate = DateTime(
        msg.createdAt.year,
        msg.createdAt.month,
        msg.createdAt.day,
      );

      String label;
      if (msgDate == today) {
        label = 'Hôm nay';
      } else if (msgDate == yesterday) {
        label = 'Hôm qua';
      } else {
        label =
            '${msgDate.day.toString().padLeft(2, '0')}/${msgDate.month.toString().padLeft(2, '0')}/${msgDate.year}';
      }

      if (label != currentLabel) {
        if (currentItems.isNotEmpty) {
          groups.add(_DateGroup(label: currentLabel, items: currentItems));
        }
        currentLabel = label;
        currentItems = [msg];
      } else {
        currentItems.add(msg);
      }
    }

    if (currentItems.isNotEmpty) {
      groups.add(_DateGroup(label: currentLabel, items: currentItems));
    }

    return groups;
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

  Widget _buildMessageItem(ChatMessage msg) {
    if (msg.isActivity) {
      return _buildActivityCard(msg);
    }
    return _buildBubble(msg);
  }

  Widget _buildBubble(ChatMessage msg) {
    final currentUid = widget.currentUserId ?? AuthService.instance.uid;
    final isMe = msg.senderId == currentUid;
    final bubbleColor = isMe ? null : Colors.white;
    final textColor = isMe ? Colors.white : MateColors.plum;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isMe ? 20 : 6),
      bottomRight: Radius.circular(isMe ? 6 : 20),
    );

    final timeStr =
        '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

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
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (msg.isImage && msg.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                msg.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_rounded,
                  color: MateColors.rose,
                ),
              ),
            ),
            if (msg.text.isNotEmpty) const SizedBox(height: 6),
          ],
          if (msg.text.isNotEmpty)
            Text(
              msg.text,
              style: TextStyle(
                color: textColor,
                fontSize: 14.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );

    final partnerName = widget.coupleData?.user2.name ?? 'M';
    final initialPartner =
        partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'M';
    final myName = widget.coupleData?.user1.name ?? 'B';
    final initialMe = myName.isNotEmpty ? myName[0].toUpperCase() : 'B';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _avatarMini(initialPartner),
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
                    timeStr,
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
          if (isMe) _avatarMini(initialMe),
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

  Widget _buildActivityCard(ChatMessage msg) {
    final meta = msg.meta;
    final title = (meta['title'] as String?) ?? msg.text;
    final subtitle = (meta['subtitle'] as String?) ?? '';
    final badge = (meta['badge'] as String?) ?? 'HOẠT ĐỘNG';
    final iconName = (meta['icon'] as String?) ?? 'favorite';

    IconData icon = Icons.favorite_rounded;
    Color iconColor = MateColors.pink;
    if (iconName == 'location' || iconName == 'location_on') {
      icon = Icons.location_on_rounded;
      iconColor = MateColors.info;
    } else if (iconName == 'pets') {
      icon = Icons.pets_rounded;
      iconColor = MateColors.pinkDeep;
    }

    final timeStr =
        '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

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
                    iconColor.withOpacity(0.2),
                    iconColor.withOpacity(0.45),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
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
                          color: iconColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: MateColors.rose,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: MateColors.plum,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: MateColors.rose.withOpacity(0.85),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Thanh nhập tin nhắn (Messenger-style)
  // ────────────────────────────────────────────────────────────
  Widget _buildInputBar(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final viewPaddingBottom = MediaQuery.viewPaddingOf(context).bottom;
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

            // Ô nhập pill ở giữa
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

            // Nút mic / send
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

class _DateGroup {
  final String label;
  final List<ChatMessage> items;
  const _DateGroup({required this.label, required this.items});
}
