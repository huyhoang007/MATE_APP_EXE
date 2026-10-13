import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/mate_theme.dart';
import '../../models/couple_model.dart';

/// ============================================================
/// MemoriesTab - Tab 3: Khoảnh khắc & Camera
///
/// Giao diện:
///   - Segmented Switcher: "Chụp ảnh" / "Kỷ niệm"
///   - Chụp ảnh: Preview + Gallery picker + Caption + Gửi
///   - Kỷ niệm: Timeline Firestore + Thả tim + Premium banner
///
/// Firestore: couples/{coupleId}/moments/{momentId}
/// Storage: moments/{coupleId}/{momentId}.jpg
/// ============================================================

class MemoriesTab extends StatefulWidget {
  final String coupleId;
  final String currentUserId;
  final CoupleData? coupleData;

  const MemoriesTab({
    super.key,
    required this.coupleId,
    required this.currentUserId,
    this.coupleData,
  });

  @override
  State<MemoriesTab> createState() => _MemoriesTabState();
}

class _MemoriesTabState extends State<MemoriesTab> {
  int _subIndex = 0; // 0 = Chụp ảnh, 1 = Kỷ niệm

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── Top Header: Segmented Switcher ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _SegmentedSwitcher(
              selected: _subIndex,
              onChanged: (v) => setState(() => _subIndex = v),
            ),
          ),

          // ── Content ──
          Expanded(
            child: _subIndex == 0
                ? _CaptureView(
                    key: const ValueKey('capture'),
                    coupleId: widget.coupleId,
                    currentUserId: widget.currentUserId,
                  )
                : _TimelineView(
                    key: const ValueKey('timeline'),
                    coupleId: widget.coupleId,
                    currentUserId: widget.currentUserId,
                    isPremium: widget.coupleData?.isPremium ?? false,
                    user1Name: widget.coupleData?.user1.name ?? 'Bạn 1',
                    user2Name: widget.coupleData?.user2.name ?? 'Bạn 2',
                  ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// Segmented Switcher - Viên thuốc bo tròn
// =============================================================

class _SegmentedSwitcher extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _SegmentedSwitcher({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: MateColors.fieldBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: MateColors.border, width: 1.5),
      ),
      child: Row(children: [
        _Pill(label: 'Chụp ảnh', selected: selected == 0, onTap: () => onChanged(0)),
        const SizedBox(width: 4),
        _Pill(label: 'Kỷ niệm', selected: selected == 1, onTap: () => onChanged(1)),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: selected ? MateColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : MateColors.rose,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// View 1: Chụp ảnh
// =============================================================

class _CaptureView extends StatefulWidget {
  final String coupleId;
  final String currentUserId;

  const _CaptureView({super.key, required this.coupleId, required this.currentUserId});

  @override
  State<_CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<_CaptureView> {
  final _captionController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _image;
  bool _uploading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final img = await _picker.pickImage(source: source, imageQuality: 80);
      if (img != null) setState(() => _image = img);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chọn ảnh: $e')),
        );
      }
    }
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: MateColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Text('Chọn ảnh khoảnh khắc', style: TextStyle(
            color: MateColors.plum, fontSize: 18, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _SourceButton(
              icon: Icons.camera_alt_rounded,
              label: 'Chụp ảnh',
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            )),
            const SizedBox(width: 12),
            Expanded(child: _SourceButton(
              icon: Icons.photo_library_rounded,
              label: 'Thư viện',
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            )),
          ]),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ]),
      ),
    );
  }

  Future<void> _sendMoment() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn một bức ảnh trước nhé!')),
      );
      return;
    }

    setState(() => _uploading = true);

    try {
      final momentId = FirebaseFirestore.instance.collection('couples')
          .doc(widget.coupleId).collection('moments').doc().id;
      final storageRef = FirebaseStorage.instance
          .ref().child('moments/${widget.coupleId}/$momentId.jpg');

      // Upload ảnh
      await storageRef.putFile(File(_image!.path));
      final imageUrl = await storageRef.getDownloadURL();

      // Lưu document
      await FirebaseFirestore.instance
          .collection('couples').doc(widget.coupleId)
          .collection('moments').doc(momentId)
          .set({
        'imageUrl': imageUrl,
        'caption': _captionController.text.trim(),
        'senderId': widget.currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'hearts': [],
      });

      if (mounted) {
        setState(() {
          _image = null;
          _captionController.clear();
          _uploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('💕 Khoảnh khắc đã được lưu!'),
            backgroundColor: MateColors.pink,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi khoảnh khắc: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // ── Preview Ảnh ──
        GestureDetector(
          onTap: _showSourcePicker,
          child: Container(
            width: double.infinity,
            height: 320,
            decoration: BoxDecoration(
              color: MateColors.fieldBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: MateColors.border, width: 2),
              image: _image != null
                  ? DecorationImage(image: FileImage(File(_image!.path)), fit: BoxFit.cover)
                  : null,
            ),
            child: _image == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 64, color: MateColors.rose.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text('Nhấn để chọn ảnh',
                          style: TextStyle(color: MateColors.rose, fontSize: 15)),
                    ],
                  )
                : Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54, borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.edit, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text('Đổi ảnh', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ]),
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Caption ──
        TextField(
          controller: _captionController,
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'Viết gì đó về khoảnh khắc này...',
            hintStyle: TextStyle(color: MateColors.rose.withOpacity(0.6)),
            filled: true,
            fillColor: MateColors.fieldBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MateRadius.field),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MateRadius.field),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MateRadius.field),
              borderSide: BorderSide(color: MateColors.pink, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: TextStyle(color: MateColors.plum, fontSize: 15),
        ),

        const SizedBox(height: 16),

        // ── Nút Gửi ──
        SizedBox(
          width: double.infinity,
          height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: MateColors.primaryGradient,
              borderRadius: BorderRadius.circular(27),
              boxShadow: MateShadows.cta,
            ),
            child: ElevatedButton(
              onPressed: _uploading ? null : _sendMoment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
              ),
              child: _uploading
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text('Gửi khoảnh khắc',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: MateColors.cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MateColors.border),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: MateColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: MateColors.plum, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// =============================================================
// View 2: Kỷ niệm Timeline
// =============================================================

class _TimelineView extends StatelessWidget {
  final String coupleId;
  final String currentUserId;
  final bool isPremium;
  final String user1Name;
  final String user2Name;

  const _TimelineView({
    super.key,
    required this.coupleId,
    required this.currentUserId,
    required this.isPremium,
    required this.user1Name,
    required this.user2Name,
  });

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('couples').doc(coupleId)
        .collection('moments')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Column(children: [
      // ── Premium Banner ──
      if (!isPremium)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB1CB), Color(0xFFFFD8E4)],
              begin: Alignment.centerLeft, end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: MateShadows.soft,
          ),
          child: Row(children: [
            const Icon(Icons.play_circle_filled_rounded, color: MateColors.pink, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Video kỷ niệm trong ngày ',
                      style: TextStyle(color: MateColors.plum, fontSize: 14, fontWeight: FontWeight.w700)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: MateColors.pinkDeep, borderRadius: BorderRadius.circular(6)),
                    child: const Text('⭐ PREMIUM',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ]),
                const SizedBox(height: 2),
                Text('Nâng cấp để xem video kỷ niệm đặc biệt!',
                    style: TextStyle(color: MateColors.rose, fontSize: 12)),
              ]),
            ),
          ]),
        ),

      // ── Timeline ──
      Expanded(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: MateColors.pink));
            }
            if (snap.hasError) {
              return Center(child: Text('Lỗi: ${snap.error}', style: TextStyle(color: MateColors.rose)));
            }
            final moments = snap.data?.docs ?? [];
            if (moments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library_outlined, size: 72, color: MateColors.rose.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text('Chưa có kỷ niệm nào',
                        style: TextStyle(color: MateColors.rose, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Hãy gửi khoảnh khắc đầu tiên!',
                        style: TextStyle(color: MateColors.rose.withOpacity(0.6), fontSize: 13)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: moments.length,
              itemBuilder: (context, i) => _MomentCard(
                data: moments[i].data(),
                momentId: moments[i].id,
                coupleId: coupleId,
                currentUserId: currentUserId,
                user1Name: user1Name,
                user2Name: user2Name,
              ),
            );
          },
        ),
      ),
    ]);
  }
}

// =============================================================
// Moment Card
// =============================================================

class _MomentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String momentId;
  final String coupleId;
  final String currentUserId;
  final String user1Name;
  final String user2Name;

  const _MomentCard({
    required this.data,
    required this.momentId,
    required this.coupleId,
    required this.currentUserId,
    required this.user1Name,
    required this.user2Name,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl'] as String? ?? '';
    final caption = data['caption'] as String? ?? '';
    final senderId = data['senderId'] as String? ?? '';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final hearts = (data['hearts'] as List<dynamic>?)?.cast<String>() ?? [];
    final hasHearted = hearts.contains(currentUserId);

    // Xác định tên người gửi
    final isUser1 = senderId == currentUserId;
    final senderName = isUser1 ? user1Name : user2Name;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: MateColors.cardBg,
        borderRadius: BorderRadius.circular(MateRadius.cardLg),
        boxShadow: MateShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ảnh ──
          if (imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(imageUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: MateColors.fieldBg,
                  child: const Icon(Icons.broken_image, size: 48, color: MateColors.rose),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Avatar + Tên + Thời gian ──
                Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: MateColors.heroGradient,
                      shape: BoxShape.circle,
                      boxShadow: MateShadows.avatar,
                    ),
                    child: Center(
                      child: Text(
                        senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(senderName,
                          style: TextStyle(color: MateColors.plum, fontWeight: FontWeight.w700, fontSize: 14)),
                      if (timestamp != null)
                        Text(_timeAgo(timestamp),
                            style: TextStyle(color: MateColors.rose.withOpacity(0.7), fontSize: 11)),
                    ]),
                  ),
                ]),

                // ── Caption ──
                if (caption.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(caption,
                      style: TextStyle(color: MateColors.plum, fontSize: 14, height: 1.4)),
                ],

                // ── Nút thả tim ──
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _toggleHeart(context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: hasHearted
                          ? MateColors.pink.withOpacity(0.12)
                          : MateColors.subtlePink,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: hasHearted ? MateColors.pink : MateColors.border,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            hasHearted ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(hasHearted),
                            color: hasHearted ? MateColors.pinkDeep : MateColors.rose,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasHearted ? 'Đã thả tim' : 'Thả tim',
                          style: TextStyle(
                            color: hasHearted ? MateColors.pinkDeep : MateColors.rose,
                            fontSize: 13, fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (hearts.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text('${hearts.length}',
                              style: TextStyle(color: MateColors.rose, fontSize: 12)),
                        ],
                      ],
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

  Future<void> _toggleHeart(BuildContext context) async {
    final ref = FirebaseFirestore.instance
        .collection('couples').doc(coupleId)
        .collection('moments').doc(momentId);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final hearts = (snap.data()?['hearts'] as List<dynamic>?)?.cast<String>() ?? [];
        final uid = currentUserId;

        if (hearts.contains(uid)) {
          hearts.remove(uid);
          tx.update(ref, {'hearts': hearts});
          // Bớt 2 điểm intimacy
          tx.update(FirebaseFirestore.instance.collection('couples').doc(coupleId),
              {'intimacyScore': FieldValue.increment(-2)});
        } else {
          hearts.add(uid);
          tx.update(ref, {'hearts': hearts});
          // Thêm 2 điểm intimacy
          tx.update(FirebaseFirestore.instance.collection('couples').doc(coupleId),
              {'intimacyScore': FieldValue.increment(2)});
        }
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }
}
