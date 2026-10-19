import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/mate_theme.dart';
import '../../models/couple_model.dart';
import '../../widgets/vietqr_sheet.dart';

/// ============================================================
/// MemoriesTab - Tab 3: Khoảnh khắc & Album
///
/// Bố cục mới:
///   - Segmented Switcher: "Chụp ảnh" / "Kỷ niệm"
///   - "Chụp ảnh": Ảnh + Video + Caption + Gửi
///       · Hỗ trợ chọn/quay ảnh (Free + Premium)
///       · Hỗ trợ chọn/quay video ngắn (Free: 15s, Premium: 60s+)
///   - "Kỷ niệm":
///       · 🎬 Card "Nhật ký trong ngày" (Premium) / Banner Free
///       · 💕 Album kỷ niệm: Timeline phân nhóm theo ngày,
///         lưới ảnh trong ngày, click để xem full screen.
///
/// Firestore: couples/{coupleId}/moments/{momentId}
/// Storage : moments/{coupleId}/{momentId}.{jpg|mp4}
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

  bool get _isPremium => widget.coupleData?.isPremium ?? false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: MateColors.bgGradient),
      child: SafeArea(
        bottom: false,
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
                      isPremium: _isPremium,
                    )
                  : _TimelineView(
                      key: const ValueKey('timeline'),
                      coupleId: widget.coupleId,
                      currentUserId: widget.currentUserId,
                      isPremium: _isPremium,
                      user1Name: widget.coupleData?.user1.name ?? 'Bạn 1',
                      user2Name: widget.coupleData?.user2.name ?? 'Bạn 2',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// Segmented Switcher
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
// View 1: Chụp ảnh / Video
// =============================================================

class _CaptureView extends StatefulWidget {
  final String coupleId;
  final String currentUserId;
  final bool isPremium;

  const _CaptureView({
    super.key,
    required this.coupleId,
    required this.currentUserId,
    required this.isPremium,
  });

  @override
  State<_CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<_CaptureView> {
  final _captionController = TextEditingController();
  final _picker = ImagePicker();

  XFile? _image;
  XFile? _video;
  bool _uploading = false;

  // Caption counter
  static const int _maxCaption = 200;
  // Giới hạn video
  static const int _freeVideoSeconds = 15;
  static const int _premiumVideoSeconds = 60;

  @override
  void initState() {
    super.initState();
    _captionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // ---- Source picker (ảnh / video) ----
  void _showSourcePicker({required bool isVideo}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: MateColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Text(
            isVideo ? 'Chọn video kỷ niệm' : 'Chọn ảnh khoảnh khắc',
            style: const TextStyle(
              color: MateColors.plum, fontSize: 18, fontWeight: FontWeight.w700,
            ),
          ),
          if (isVideo)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.isPremium
                    ? 'Premium: tối đa $_premiumVideoSeconds giây, chất lượng cao'
                    : 'Free: tối đa $_freeVideoSeconds giây. Nâng cấp Premium để quay dài hơn!',
                style: TextStyle(
                  color: widget.isPremium ? MateColors.online : MateColors.rose,
                  fontSize: 11.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: _SourceButton(
                icon: isVideo ? Icons.videocam_rounded : Icons.camera_alt_rounded,
                label: isVideo ? 'Quay video' : 'Chụp ảnh',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMedia(
                    isVideo: true,
                    source: ImageSource.camera,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SourceButton(
                icon: isVideo
                    ? Icons.video_library_rounded
                    : Icons.photo_library_rounded,
                label: 'Thư viện',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMedia(isVideo: isVideo, source: ImageSource.gallery);
                },
              ),
            ),
          ]),
          SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
        ]),
      ),
    );
  }

  Future<void> _pickMedia({
    required bool isVideo,
    required ImageSource source,
  }) async {
    try {
      final maxSeconds =
          widget.isPremium ? _premiumVideoSeconds : _freeVideoSeconds;
      if (isVideo) {
        final v = await _picker.pickVideo(
          source: source,
          maxDuration: Duration(seconds: maxSeconds),
        );
        if (v != null) {
          setState(() {
            _video = v;
            // Chọn video thì xóa ảnh để tránh gửi cả 2
            _image = null;
          });
        }
      } else {
        final img = await _picker.pickImage(
          source: source,
          imageQuality: 80,
        );
        if (img != null) {
          setState(() {
            _image = img;
            _video = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chọn ${isVideo ? 'video' : 'ảnh'}: $e')),
        );
      }
    }
  }

  void _clearImage() {
    setState(() => _image = null);
  }

  void _clearVideo() {
    setState(() => _video = null);
  }

  Future<void> _sendMoment() async {
    if (_image == null && _video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn ảnh hoặc video trước nhé!')),
      );
      return;
    }

    setState(() => _uploading = true);

    try {
      final isVideo = _video != null;
      final momentId = FirebaseFirestore.instance
          .collection('couples')
          .doc(widget.coupleId)
          .collection('moments')
          .doc()
          .id;

      final ext = isVideo ? 'mp4' : 'jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('moments/${widget.coupleId}/$momentId.$ext');

      final file = isVideo ? File(_video!.path) : File(_image!.path);
      await storageRef.putFile(file);
      final mediaUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('couples')
          .doc(widget.coupleId)
          .collection('moments')
          .doc(momentId)
          .set({
        'imageUrl': isVideo ? '' : mediaUrl,
        'videoUrl': isVideo ? mediaUrl : '',
        'type': isVideo ? 'video' : 'image',
        'caption': _captionController.text.trim(),
        'senderId': widget.currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'hearts': [],
        'premium': widget.isPremium && isVideo,
      });

      if (mounted) {
        setState(() {
          _image = null;
          _video = null;
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
    final captionLen = _captionController.text.characters.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Preview Ảnh ──
          if (_image != null)
            _ImagePreview(file: File(_image!.path), onClear: _clearImage)
          else if (_video != null)
            _VideoPreview(file: File(_video!.path), onClear: _clearVideo)
          else
            _EmptyPicker(
              onTapImage: () => _showSourcePicker(isVideo: false),
              onTapVideo: () => _showSourcePicker(isVideo: true),
              isPremium: widget.isPremium,
            ),

          const SizedBox(height: 14),

          // ── Quick action row (khi đã chọn media) ──
          if (_image != null || _video != null)
            Row(
              children: [
                Expanded(
                  child: _quickAction(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Đổi ảnh',
                    onTap: () => _showSourcePicker(isVideo: _video != null),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickAction(
                    icon: _video != null
                        ? Icons.photo_outlined
                        : Icons.videocam_outlined,
                    label: _video != null ? 'Chọn ảnh' : 'Chọn video',
                    onTap: () => _showSourcePicker(isVideo: _video == null),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),

          // ── Caption với bộ đếm ký tự ──
          _CaptionField(
            controller: _captionController,
            maxLength: _maxCaption,
            currentLength: captionLen,
          ),

          const SizedBox(height: 16),

          // ── Nút Gửi ──
          _SendButton(
            isUploading: _uploading,
            enabled: _image != null || _video != null,
            onPressed: _sendMoment,
          ),

          const SizedBox(height: 10),
          // Thông tin quyền lợi Premium
          _PremiumHint(isPremium: widget.isPremium),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: MateColors.fieldBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MateColors.border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: MateColors.pink, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: MateColors.plum,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ----- Sub widgets cho Capture view -----

class _EmptyPicker extends StatelessWidget {
  final VoidCallback onTapImage;
  final VoidCallback onTapVideo;
  final bool isPremium;

  const _EmptyPicker({
    required this.onTapImage,
    required this.onTapVideo,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MateColors.fieldBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MateColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          // Ảnh - khu vực chính
          GestureDetector(
            onTap: onTapImage,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              height: 240,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      gradient: MateColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_photo_alternate_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Chọn ảnh khoảnh khắc',
                    style: TextStyle(
                        color: MateColors.plum,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text('Từ camera hoặc thư viện của bạn',
                      style: TextStyle(
                          color: MateColors.rose.withOpacity(0.8),
                          fontSize: 12)),
                ],
              ),
            ),
          ),
          Divider(color: MateColors.border, height: 1, indent: 16, endIndent: 16),
          // Video - hàng phụ
          InkWell(
            onTap: onTapVideo,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPremium
                          ? MateColors.pink.withOpacity(0.15)
                          : MateColors.fieldBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: MateColors.border),
                    ),
                    child: Icon(
                      Icons.videocam_rounded,
                      color: isPremium ? MateColors.pink : MateColors.rose,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Quay / chọn video ngắn',
                              style: TextStyle(
                                color: MateColors.plum,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (!isPremium)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: MateColors.pinkDeep,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text(
                                  '⭐ PRO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPremium
                              ? 'Tối đa 60 giây, chất lượng cao'
                              : 'Tối đa 15 giây (Free)',
                          style: TextStyle(
                              color: MateColors.rose.withOpacity(0.8),
                              fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: MateColors.rose),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final File file;
  final VoidCallback onClear;
  const _ImagePreview({required this.file, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            height: 280,
            decoration: BoxDecoration(
              color: MateColors.fieldBg,
              border: Border.all(color: MateColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Image.file(file, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: _PreviewActionButton(
            icon: Icons.close_rounded,
            onTap: onClear,
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.image, size: 12, color: MateColors.pink),
                SizedBox(width: 4),
                Text('Ảnh',
                    style: TextStyle(
                        color: MateColors.plum,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoPreview extends StatelessWidget {
  final File file;
  final VoidCallback onClear;
  const _VideoPreview({required this.file, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            height: 240,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: MateColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Placeholder — không dùng package video player để tránh
                // thêm dependency. Hiển thị icon play lớn.
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        MateColors.pink.withOpacity(0.4),
                        MateColors.pinkDeep.withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    shape: BoxShape.circle,
                    boxShadow: MateShadows.soft,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: MateColors.pinkDeep, size: 40),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.videocam,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          file.path.split('/').last,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: _PreviewActionButton(
            icon: Icons.close_rounded,
            onTap: onClear,
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.videocam, size: 12, color: MateColors.pink),
                SizedBox(width: 4),
                Text('Video',
                    style: TextStyle(
                        color: MateColors.plum,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _PreviewActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _CaptionField extends StatelessWidget {
  final TextEditingController controller;
  final int maxLength;
  final int currentLength;
  const _CaptionField({
    required this.controller,
    required this.maxLength,
    required this.currentLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          maxLines: 3,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: 'Viết gì đó về khoảnh khắc này...',
            hintStyle: TextStyle(color: MateColors.rose.withOpacity(0.6)),
            filled: true,
            fillColor: MateColors.fieldBg,
            // Tự ẩn counter mặc định của Material — render của riêng mình
            counterText: '',
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
          style: const TextStyle(color: MateColors.plum, fontSize: 15),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 4),
          child: Text(
            '$currentLength/$maxLength ký tự',
            style: TextStyle(
              color: currentLength > maxLength * 0.9
                  ? MateColors.pinkDeep
                  : MateColors.rose,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool isUploading;
  final bool enabled;
  final VoidCallback onPressed;
  const _SendButton({
    required this.isUploading,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? MateColors.primaryGradient : null,
          color: enabled ? null : MateColors.fieldBg,
          borderRadius: BorderRadius.circular(27),
          boxShadow: enabled ? MateShadows.cta : null,
        ),
        child: ElevatedButton(
          onPressed: isUploading || !enabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
          ),
          child: isUploading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_rounded,
                        color: enabled ? Colors.white : MateColors.rose,
                        size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Gửi khoảnh khắc',
                      style: TextStyle(
                          color: enabled ? Colors.white : MateColors.rose,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PremiumHint extends StatelessWidget {
  final bool isPremium;
  const _PremiumHint({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_rounded, size: 14, color: MateColors.online),
          const SizedBox(width: 6),
          Text(
            'Bạn đang dùng gói Premium — video chất lượng cao đã mở khóa',
            style: TextStyle(
                color: MateColors.online.withOpacity(0.95),
                fontSize: 11,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, size: 12, color: MateColors.rose),
        const SizedBox(width: 4),
        Text(
          'Nâng cấp Premium để quay video dài hơn & chất lượng cao',
          style: TextStyle(
              color: MateColors.rose.withOpacity(0.85),
              fontSize: 11.5,
              fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
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
            decoration: const BoxDecoration(
              gradient: MateColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: MateColors.plum,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// =============================================================
// View 2: Kỷ niệm - Album + Daily Diary
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
        .collection('couples')
        .doc(coupleId)
        .collection('moments')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: MateColors.pink));
        }
        if (snap.hasError) {
          return Center(
            child: Text('Lỗi: ${snap.error}',
                style: const TextStyle(color: MateColors.rose)),
          );
        }
        final moments = snap.data?.docs ?? [];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            // ── 1. Nhật ký trong ngày (mock + Premium) ──
            _DailyDiarySection(isPremium: isPremium, coupleId: coupleId),

            const SizedBox(height: 18),

            // ── 2. Album header ──
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(
                    gradient: MateColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('💕',
                      style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Album kỷ niệm của chúng mình',
                    style: TextStyle(
                      color: MateColors.plum,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${moments.length} ảnh',
                  style: TextStyle(
                    color: MateColors.rose.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── 3. Timeline phân nhóm theo ngày ──
            if (moments.isEmpty)
              const _EmptyAlbum()
            else
              _buildGroupedTimeline(
                context,
                moments: moments,
              ),
          ],
        );
      },
    );
  }

  // ----- Group moments theo ngày (yyyy-mm-dd) -----
  Widget _buildGroupedTimeline(
    BuildContext context, {
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> moments,
  }) {
    // Sắp xếp: mới nhất trước
    final sorted = [...moments];
    sorted.sort((a, b) {
      final ta = (a.data()['timestamp'] as Timestamp?)?.toDate();
      final tb = (b.data()['timestamp'] as Timestamp?)?.toDate();
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });

    // Group
    final groups = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    final order = <String>[];
    for (final m in sorted) {
      final t = (m.data()['timestamp'] as Timestamp?)?.toDate();
      final key = t == null
          ? 'Chưa rõ'
          : '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
      if (!groups.containsKey(key)) {
        groups[key] = [];
        order.add(key);
      }
      groups[key]!.add(m);
    }

    final widgets = <Widget>[];
    for (final key in order) {
      final list = groups[key]!;
      final firstTs = (list.first.data()['timestamp'] as Timestamp?)?.toDate();
      widgets.add(_DayHeader(date: firstTs, count: list.length));
      widgets.add(const SizedBox(height: 10));

      // Nếu trong ngày có 1 ảnh: dùng card lớn.
      // Nếu nhiều ảnh: dùng lưới 2 cột.
      if (list.length == 1) {
        widgets.add(_MomentCard(
          data: list.first.data(),
          momentId: list.first.id,
          coupleId: coupleId,
          currentUserId: currentUserId,
          user1Name: user1Name,
          user2Name: user2Name,
        ));
      } else {
        widgets.add(_MomentGrid(
          moments: list,
          coupleId: coupleId,
          currentUserId: currentUserId,
          user1Name: user1Name,
          user2Name: user2Name,
        ));
      }
      widgets.add(const SizedBox(height: 18));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}

// ----- Day header -----
class _DayHeader extends StatelessWidget {
  final DateTime? date;
  final int count;
  const _DayHeader({required this.date, required this.count});

  @override
  Widget build(BuildContext context) {
    if (date == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text('Chưa rõ ngày',
            style: TextStyle(
                color: MateColors.rose.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );
    }
    final today = DateTime.now();
    final isToday = date!.year == today.year &&
        date!.month == today.month &&
        date!.day == today.day;
    final yesterday = today.subtract(const Duration(days: 1));
    final isYesterday = date!.year == yesterday.year &&
        date!.month == yesterday.month &&
        date!.day == yesterday.day;

    String label;
    if (isToday) {
      label = 'Hôm nay';
    } else if (isYesterday) {
      label = 'Hôm qua';
    } else {
      label =
          '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
              gradient: MateColors.primaryGradient,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                color: MateColors.plum,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: MateColors.border,
            ),
          ),
          const SizedBox(width: 8),
          Text('$count khoảnh khắc',
              style: TextStyle(
                  color: MateColors.rose.withOpacity(0.85),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ----- Single moment card -----
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
    final videoUrl = data['videoUrl'] as String? ?? '';
    final caption = data['caption'] as String? ?? '';
    final senderId = data['senderId'] as String? ?? '';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final hearts =
        (data['hearts'] as List<dynamic>?)?.cast<String>() ?? [];
    final hasHearted = hearts.contains(currentUserId);
    final isVideo =
        (data['type'] as String?) == 'video' || videoUrl.isNotEmpty;

    final isUser1 = senderId == currentUserId;
    final senderName = isUser1 ? user1Name : user2Name;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: MateColors.cardBg,
        borderRadius: BorderRadius.circular(MateRadius.cardLg),
        boxShadow: MateShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty || videoUrl.isNotEmpty)
            GestureDetector(
              onTap: () => _openViewer(context,
                  imageUrl: imageUrl, videoUrl: videoUrl, isVideo: isVideo),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl.isNotEmpty)
                      Image.network(imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                                color: MateColors.fieldBg,
                                child: const Icon(Icons.broken_image,
                                    size: 48, color: MateColors.rose),
                              ))
                    else
                      Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: const Icon(Icons.videocam_rounded,
                            color: Colors.white, size: 48),
                      ),
                    if (isVideo)
                      Container(
                        color: Colors.black26,
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: MateColors.pinkDeep, size: 30),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: MateColors.heroGradient,
                      shape: BoxShape.circle,
                      boxShadow: MateShadows.avatar,
                    ),
                    child: Center(
                      child: Text(
                        senderName.isNotEmpty
                            ? senderName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(senderName,
                              style: const TextStyle(
                                  color: MateColors.plum,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          if (timestamp != null)
                            Text(_timeAgo(timestamp),
                                style: TextStyle(
                                    color: MateColors.rose.withOpacity(0.7),
                                    fontSize: 11)),
                        ]),
                  ),
                ]),
                if (caption.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(caption,
                      style: const TextStyle(
                          color: MateColors.plum,
                          fontSize: 14,
                          height: 1.4)),
                ],
                const SizedBox(height: 12),
                _HeartButton(
                  hasHearted: hasHearted,
                  count: hearts.length,
                  onTap: () => _toggleHeart(context),
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
        .collection('couples')
        .doc(coupleId)
        .collection('moments')
        .doc(momentId);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final hearts =
            (snap.data()?['hearts'] as List<dynamic>?)?.cast<String>() ?? [];
        final uid = currentUserId;
        if (hearts.contains(uid)) {
          hearts.remove(uid);
          tx.update(ref, {'hearts': hearts});
          tx.update(
              FirebaseFirestore.instance
                  .collection('couples')
                  .doc(coupleId),
              {'intimacyScore': FieldValue.increment(-2)});
        } else {
          hearts.add(uid);
          tx.update(ref, {'hearts': hearts});
          tx.update(
              FirebaseFirestore.instance
                  .collection('couples')
                  .doc(coupleId),
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

  void _openViewer(BuildContext context,
      {required String imageUrl,
      required String videoUrl,
      required bool isVideo}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _MediaViewer(
          imageUrl: imageUrl,
          videoUrl: videoUrl,
          isVideo: isVideo,
        ),
      ),
    );
  }
}

// ----- Grid cho nhiều ảnh trong cùng ngày -----
class _MomentGrid extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> moments;
  final String coupleId;
  final String currentUserId;
  final String user1Name;
  final String user2Name;

  const _MomentGrid({
    required this.moments,
    required this.coupleId,
    required this.currentUserId,
    required this.user1Name,
    required this.user2Name,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: moments.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, i) {
        final m = moments[i];
        final imageUrl = m.data()['imageUrl'] as String? ?? '';
        final videoUrl = m.data()['videoUrl'] as String? ?? '';
        final caption = m.data()['caption'] as String? ?? '';
        final isVideo =
            (m.data()['type'] as String?) == 'video' || videoUrl.isNotEmpty;
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => _MediaViewer(
                imageUrl: imageUrl,
                videoUrl: videoUrl,
                isVideo: isVideo,
              ),
            ));
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl.isNotEmpty)
                  Image.network(imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                            color: MateColors.fieldBg,
                            child: const Icon(Icons.broken_image,
                                color: MateColors.rose, size: 28),
                          ))
                else
                  Container(
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: const Icon(Icons.videocam,
                        color: Colors.white, size: 28),
                  ),
                if (isVideo)
                  const Center(
                    child: Icon(Icons.play_circle_filled,
                        color: Colors.white, size: 32),
                  ),
                if (caption.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.55),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Text(
                        caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ----- Heart button (tách ra để dùng chung) -----
class _HeartButton extends StatelessWidget {
  final bool hasHearted;
  final int count;
  final VoidCallback onTap;
  const _HeartButton({
    required this.hasHearted,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text('$count',
                  style: const TextStyle(
                      color: MateColors.rose, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

// ----- Empty state -----
class _EmptyAlbum extends StatelessWidget {
  const _EmptyAlbum();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: MateColors.cardBg,
        borderRadius: BorderRadius.circular(MateRadius.cardLg),
        border: Border.all(color: MateColors.border),
        boxShadow: MateShadows.soft,
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              gradient: MateColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.photo_library_outlined,
                color: Colors.white, size: 40),
          ),
          const SizedBox(height: 14),
          const Text(
            'Chưa có kỷ niệm nào',
            style: TextStyle(
              color: MateColors.plum,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hãy gửi khoảnh khắc đầu tiên của hai bạn!',
            style: TextStyle(
                color: MateColors.rose.withOpacity(0.85), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ----- Full-screen media viewer -----
class _MediaViewer extends StatelessWidget {
  final String imageUrl;
  final String videoUrl;
  final bool isVideo;
  const _MediaViewer({
    required this.imageUrl,
    required this.videoUrl,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          child: isVideo
              ? Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_rounded,
                          color: Colors.white70, size: 64),
                      const SizedBox(height: 8),
                      Text(
                        videoUrl.isEmpty
                            ? 'Video chưa sẵn sàng'
                            : 'Nhấn để mở video',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : imageUrl.isEmpty
                  ? const Icon(Icons.broken_image,
                      color: Colors.white70, size: 64)
                  : Image.network(imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

// ----- Time ago util -----
String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 0) return '${diff.inDays} ngày trước';
  if (diff.inHours > 0) return '${diff.inHours} giờ trước';
  if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
  return 'Vừa xong';
}

// =============================================================
// Daily Diary (Nhật ký trong ngày) - Mock UI
// =============================================================
//
// Trạng thái: chưa có backend tạo video, nên chỉ hiển thị UI mock.
// Khi backend sẵn sàng, chỉ cần thay nguồn dữ liệu bên trong
// `_DailyDiarySection` (Stream<DocumentSnapshot>) mà không phải
// sửa widget.
// =============================================================

class _DailyDiarySection extends StatelessWidget {
  final bool isPremium;
  final String coupleId;
  const _DailyDiarySection({required this.isPremium, required this.coupleId});

  @override
  Widget build(BuildContext context) {
    // Mock data tách biệt — không đụng backend.
    final mockToday = _DiaryEntry(
      date: DateTime.now(),
      thumbnailEmoji: '💕',
      title: 'Nhật ký hôm nay',
      subtitle: '5 khoảnh khắc được ghi lại',
      durationLabel: '00:48',
      status: isPremium ? _DiaryStatus.processing : _DiaryStatus.locked,
    );

    final mockPast = <_DiaryEntry>[
      _DiaryEntry(
        date: DateTime.now().subtract(const Duration(days: 1)),
        thumbnailEmoji: '🌅',
        title: 'Ngày hôm qua',
        subtitle: '3 khoảnh khắc',
        durationLabel: '00:32',
        status: isPremium ? _DiaryStatus.ready : _DiaryStatus.locked,
      ),
      _DiaryEntry(
        date: DateTime.now().subtract(const Duration(days: 7)),
        thumbnailEmoji: '🎂',
        title: '7 ngày trước',
        subtitle: '8 khoảnh khắc',
        durationLabel: '01:12',
        status: isPremium ? _DiaryStatus.ready : _DiaryStatus.locked,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card chính
        _DiaryCard(
          entry: mockToday,
          isPremium: isPremium,
          coupleId: coupleId,
        ),
        if (mockPast.isNotEmpty) ...[
          const SizedBox(height: 10),
          // Danh sách các ngày trước
          ...mockPast.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DiaryCompactCard(entry: e, isPremium: isPremium),
            ),
          ),
        ],
      ],
    );
  }
}

enum _DiaryStatus { ready, processing, locked }

class _DiaryEntry {
  final DateTime date;
  final String thumbnailEmoji;
  final String title;
  final String subtitle;
  final String durationLabel;
  final _DiaryStatus status;
  const _DiaryEntry({
    required this.date,
    required this.thumbnailEmoji,
    required this.title,
    required this.subtitle,
    required this.durationLabel,
    required this.status,
  });
}

class _DiaryCard extends StatelessWidget {
  final _DiaryEntry entry;
  final bool isPremium;
  final String coupleId;
  const _DiaryCard({
    required this.entry,
    required this.isPremium,
    required this.coupleId,
  });

  @override
  Widget build(BuildContext context) {
    // `isLocked` / `isProcessing` đã được `_DiaryActionButton`
    // và logic hành vi xử lý trực tiếp qua `entry.status` — không
    // cần biến cục bộ.
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB1CB), Color(0xFFFFD8E4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(MateRadius.cardLg),
        boxShadow: MateShadows.soft,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Thumbnail
          Stack(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: MateShadows.soft,
                ),
                alignment: Alignment.center,
                child: Text(entry.thumbnailEmoji,
                    style: const TextStyle(fontSize: 38)),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.durationLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('🎬',
                        style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: const Text(
                        'Nhật ký trong ngày',
                        style: TextStyle(
                          color: MateColors.plum,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isPremium
                            ? MateColors.online
                            : MateColors.pinkDeep,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        isPremium ? '⭐ PREMIUM' : '🔒 PRO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.subtitle,
                  style: TextStyle(
                      color: MateColors.plum.withOpacity(0.75),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _DiaryActionButton(
                  status: entry.status,
                  isPremium: isPremium,
                  onTap: () => _onAction(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onAction(BuildContext context) {
    if (entry.status == _DiaryStatus.locked) {
      // Mở VietQRSheet để nâng cấp Premium
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => VietQRSheet(coupleId: coupleId),
      );
      return;
    }
    if (entry.status == _DiaryStatus.processing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video kỷ niệm đang được tạo, vui lòng chờ...'),
          backgroundColor: MateColors.pink,
        ),
      );
      return;
    }
    // ready: mở trình xem
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _DiaryViewer(entry: entry),
    ));
  }
}

class _DiaryActionButton extends StatelessWidget {
  final _DiaryStatus status;
  final bool isPremium;
  final VoidCallback onTap;
  const _DiaryActionButton({
    required this.status,
    required this.isPremium,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = status == _DiaryStatus.locked;
    final processing = status == _DiaryStatus.processing;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: locked
              ? Colors.white
              : (processing ? Colors.white : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: locked ? MateColors.border : Colors.white,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (processing) ...[
              const SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6, color: MateColors.pinkDeep,
                ),
              ),
              const SizedBox(width: 6),
              const Text('Đang tạo...',
                  style: TextStyle(
                      color: MateColors.plum,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ] else if (locked) ...[
              const Icon(Icons.lock, size: 13, color: MateColors.pinkDeep),
              const SizedBox(width: 4),
              const Text('Nâng cấp',
                  style: TextStyle(
                      color: MateColors.pinkDeep,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ] else ...[
              const Icon(Icons.play_arrow_rounded,
                  size: 14, color: MateColors.pinkDeep),
              const SizedBox(width: 4),
              const Text('Xem video',
                  style: TextStyle(
                      color: MateColors.pinkDeep,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ]
          ],
        ),
      ),
    );
  }
}

class _DiaryCompactCard extends StatelessWidget {
  final _DiaryEntry entry;
  final bool isPremium;
  const _DiaryCompactCard({required this.entry, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final locked = entry.status == _DiaryStatus.locked;
    return GestureDetector(
      onTap: () {
        if (locked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nâng cấp Premium để xem video kỷ niệm'),
              backgroundColor: MateColors.pink,
            ),
          );
        } else {
          Navigator.of(context).push(MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => _DiaryViewer(entry: entry),
          ));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: MateColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: MateColors.border),
          boxShadow: MateShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: locked
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFFFFB1CB), Color(0xFFFFD8E4)],
                      ),
                color: locked ? MateColors.fieldBg : null,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: locked
                  ? const Icon(Icons.lock, color: MateColors.rose, size: 18)
                  : Text(entry.thumbnailEmoji,
                      style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title,
                      style: const TextStyle(
                        color: MateColors.plum,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.subtitle} · ${entry.durationLabel}',
                    style: TextStyle(
                        color: MateColors.rose.withOpacity(0.85),
                        fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Icon(
              locked
                  ? Icons.lock_outline
                  : (entry.status == _DiaryStatus.processing
                      ? Icons.hourglass_top
                      : Icons.play_circle_fill),
              color: locked
                  ? MateColors.rose
                  : MateColors.pinkDeep,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _DiaryViewer extends StatelessWidget {
  final _DiaryEntry entry;
  const _DiaryViewer({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('🎬 ${entry.title}',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB1CB), Color(0xFFFFD8E4)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: Text(entry.thumbnailEmoji,
                  style: const TextStyle(fontSize: 100)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Video kỷ niệm đang được tổng hợp',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'Tính năng này sẽ sớm sẵn sàng',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
