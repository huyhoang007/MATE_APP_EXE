import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/mate_theme.dart';
import '../services/pair_service.dart';
import '../widgets/mate_card.dart';
import '../widgets/mate_cloud.dart';

/// ============================================================
/// Onboarding Screen - Màn hình ghép đôi
/// Nhập biệt danh, chọn ngày bắt đầu yêu, tạo/nhập mã MATE-xxxx.
/// Tích hợp PairService + Firestore để ghép đôi realtime.
/// ============================================================

enum PairRole { creator, joiner }

class OnboardingData {
  final String nickname;
  final DateTime startDate;
  final String code;
  final PairRole role;

  const OnboardingData({
    required this.nickname,
    required this.startDate,
    required this.code,
    required this.role,
  });
}

class OnboardingScreen extends StatefulWidget {
  /// Callback khi ghép đôi thành công (cả bên tạo lẫn bên tham gia).
  final ValueChanged<OnboardingData>? onCompleted;

  const OnboardingScreen({super.key, this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Tab hiện tại: true = Tạo mã mới, false = Nhập mã
  bool newTab = true;
  bool copied = false;

  // Form inputs
  DateTime date = DateTime(2020, 3, 22);
  final nameCtrl = TextEditingController();
  final codeCtrl = TextEditingController();

  // Pairing state
  String? _createdCode; // mã phòng vừa tạo (chờ đối phương vào)
  bool _isCreating = false;
  bool _isJoining = false;
  StreamSubscription<PairSession>? _roomSub;
  String? _pairError;

  @override
  void dispose() {
    nameCtrl.dispose();
    codeCtrl.dispose();
    _roomSub?.cancel();
    super.dispose();
  }

  // ---------------- UI helpers ----------------

  InputDecoration _field(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: MateColors.rose.withOpacity(0.6)),
        filled: true,
        fillColor: MateColors.fieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MateRadius.field),
          borderSide: const BorderSide(color: MateColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MateRadius.field),
          borderSide: const BorderSide(color: MateColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MateRadius.field),
          borderSide: const BorderSide(color: MateColors.pink),
        ),
      );

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => date = d);
  }

  void _copy() {
    final code = _createdCode;
    if (code == null) return;
    Clipboard.setData(ClipboardData(text: code));
    setState(() => copied = true);
    Future.delayed(
      const Duration(milliseconds: 1800),
      () => mounted ? setState(() => copied = false) : null,
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? MateColors.pinkDeep : MateColors.pink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  // ---------------- Pairing actions ----------------

  /// Tạo phòng + mã. Bắt đầu lắng nghe realtime.
  Future<void> _createRoom() async {
    final nickname = nameCtrl.text.trim();
    if (nickname.isEmpty) {
      _showSnack('Vui lòng nhập biệt danh trước nhé 💕', isError: true);
      return;
    }
    setState(() {
      _isCreating = true;
      _pairError = null;
    });
    try {
      final code = await PairService.instance.createRoom(
        nickname: nickname,
        startDate: date,
      );
      if (!mounted) return;
      setState(() {
        _createdCode = code;
        _isCreating = false;
      });
      _startListening(code);
    } on PairException catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      _showSnack(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      _showSnack('Không thể tạo mã. Vui lòng thử lại nhé 💕', isError: true);
    }
  }

  /// Lắng nghe realtime; tự chuyển Home khi partner tham gia.
  void _startListening(String code) {
    _roomSub?.cancel();
    _roomSub = PairService.instance.watchRoom(code).listen((session) {
      if (!mounted) return;
      if (session.status == PairStatus.paired) {
        _roomSub?.cancel();
        _complete(
          nicknameOverride: null,
          code: session.code,
          role: PairRole.creator,
        );
      }
    }, onError: (e) {
      if (!mounted) return;
      // Bỏ qua lỗi permission/unauthenticated tạm thời (network retry).
      final msg = e.toString();
      if (msg.contains('permission') || msg.contains('authentication')) {
        return;
      }
      setState(() => _pairError = 'Mất kết nối, đang thử lại...');
    });
  }

  /// Người thứ 2 nhập mã để tham gia.
  Future<void> _joinRoom() async {
    final nickname = nameCtrl.text.trim();
    if (nickname.isEmpty) {
      _showSnack('Vui lòng nhập biệt danh trước nhé 💕', isError: true);
      return;
    }
    final raw = codeCtrl.text.trim();
    if (raw.isEmpty) {
      _showSnack('Vui lòng nhập mã ghép đôi', isError: true);
      return;
    }
    setState(() {
      _isJoining = true;
      _pairError = null;
    });
    try {
      final session = await PairService.instance.joinRoom(
        code: raw,
        partnerNickname: nickname,
      );
      if (!mounted) return;
      setState(() => _isJoining = false);
      _complete(
        nicknameOverride: null,
        code: session.code,
        role: PairRole.joiner,
      );
    } on PairException catch (e) {
      // Lỗi đã được service chuẩn hoá -> hiển thị message tiếng Việt.
      if (!mounted) return;
      setState(() => _isJoining = false);
      _showSnack(e.message, isError: true);
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() => _isJoining = false);
      _showSnack(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isJoining = false);
      _showSnack('Không thể ghép đôi. Vui lòng thử lại nhé 💕', isError: true);
    }
  }

  /// Gọi callback để chuyển sang Home.
  void _complete({
    String? nicknameOverride,
    required String code,
    required PairRole role,
  }) {
    final name = (nicknameOverride ?? nameCtrl.text).trim();
    widget.onCompleted?.call(OnboardingData(
      nickname: name.isEmpty ? 'Bạn' : name,
      startDate: date,
      code: code,
      role: role,
    ));
  }

  // ---------------- Build ----------------

  @override
  Widget build(BuildContext context) {
    final name = nameCtrl.text.trim();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: MateColors.bgGradient),
        child: Stack(
          children: [
            const Positioned(left: -40, top: 100, child: MateCloud(size: 160)),
            const Positioned(right: -50, top: 220, child: MateCloud(size: 120)),
            const Positioned(left: -30, bottom: 20, child: MateCloud(size: 200)),
            const Positioned(right: -40, bottom: -10, child: MateCloud(size: 240)),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  children: [
                    Text(
                      'MATE',
                      style: GoogleFonts.dancingScript(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: MateColors.plum,
                      ),
                    ),
                    const Text(
                      'Không gian riêng tư kết nối hai trái tim',
                      style: TextStyle(color: MateColors.rose, fontSize: 14),
                    ),
                    const SizedBox(height: 20),

                    // Card 1: Biệt danh + Ngày bắt đầu yêu
                    MateCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Biệt danh của bạn',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: MateColors.plum,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nameCtrl,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(color: MateColors.plum),
                            decoration: _field('Ví dụ: Bé Mèo 🐱'),
                          ),
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Icon(Icons.event_available,
                                  size: 16, color: MateColors.pink),
                              SizedBox(width: 6),
                              Text(
                                'Chọn ngày bắt đầu yêu',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: MateColors.plum,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickDate,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: MateColors.fieldBg,
                                      borderRadius:
                                          BorderRadius.circular(MateRadius.pill),
                                      border:
                                          Border.all(color: MateColors.border),
                                    ),
                                    child: Text(
                                      '${date.day} tháng ${date.month} năm ${date.year}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: MateColors.plum,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: MateColors.pink,
                                  child: Icon(Icons.arrow_forward,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 2: Kết nối với người yêu
                    MateCard(
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: MateColors.border,
                                child: Icon(Icons.lock,
                                    size: 14, color: MateColors.pink),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Kết nối với người yêu',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: MateColors.plum,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: MateColors.border,
                              borderRadius: BorderRadius.circular(MateRadius.pill),
                            ),
                            child: Row(
                              children: [
                                for (final t in [false, true])
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (_isCreating || _isJoining) return;
                                        setState(() => newTab = t);
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        decoration: BoxDecoration(
                                          color: newTab == t
                                              ? Colors.white
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                              MateRadius.pill),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          t ? 'Tạo mã mới' : 'Tôi có mã ghép đôi',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: newTab == t
                                                ? MateColors.pink
                                                : MateColors.rose,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (newTab) _buildCreateTab(name)
                          else _buildJoinTab(),
                          const SizedBox(height: 20),
                          if (_pairError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                _pairError!,
                                style: const TextStyle(
                                  color: MateColors.pinkDeep,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: MateColors.primaryGradient,
                                  border: Border.all(
                                      color: MateColors.border, width: 4),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  name.isEmpty ? 'Tôi' : name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Text(' - - ',
                                  style: TextStyle(color: MateColors.pink)),
                              const Icon(Icons.favorite,
                                  color: MateColors.pink, size: 20),
                              const Text(' - - ',
                                  style: TextStyle(color: MateColors.pink)),
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: MateColors.pink.withOpacity(0.6),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(Icons.add,
                                    color: MateColors.pink),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Footer: CTA chính thay đổi theo tab
                    if (!newTab) _buildJoinCta(),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 12, color: MateColors.rose),
                        SizedBox(width: 4),
                        Text(
                          'Không gian hoàn toàn riêng tư & bảo mật 1-1',
                          style: TextStyle(color: MateColors.rose, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Sub-widgets ----------------

  Widget _buildCreateTab(String name) {
    // Chưa có mã -> hiển thị nút "Tạo mã"
    if (_createdCode == null) {
      return _primaryCta(
        label: _isCreating ? 'Đang tạo mã...' : 'Tạo mã ghép đôi',
        icon: Icons.auto_awesome,
        onPressed: _isCreating ? null : _createRoom,
      );
    }

    // Đã có mã -> hiển thị mã + copy + trạng thái chờ
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: MateColors.subtlePink,
            borderRadius: BorderRadius.circular(MateRadius.field),
            border: Border.all(
              color: MateColors.pink.withOpacity(0.5),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            _createdCode!,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: MateColors.plum,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _copy,
          style: TextButton.styleFrom(
            backgroundColor: MateColors.border,
            foregroundColor: MateColors.pink,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          icon: Icon(copied ? Icons.check : Icons.copy, size: 16),
          label: Text(
            copied ? 'Đã sao chép!' : 'Sao chép mã gửi cho đối phương',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(MateColors.pink),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Đang chờ người yêu ghép đôi...',
              style: TextStyle(
                color: MateColors.rose,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJoinTab() {
    return Column(
      children: [
        TextField(
          controller: codeCtrl,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          maxLength: 8,
          // Tự động uppercase + chỉ giữ chữ và số.
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[A-Za-z0-9\-]'),
            ),
            _UpperCaseFormatter(),
          ],
          // Tự động thêm dấu "-" sau 4 ký tự đầu (MATE-XXXX).
          onChanged: _onCodeChanged,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: MateColors.plum,
          ),
          decoration: _field('Nhập mã, ví dụ MATE-XXXX').copyWith(
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _buildJoinCta() {
    return _primaryCta(
      label: _isJoining ? 'Đang ghép đôi...' : 'Ghép đôi ngay',
      icon: Icons.favorite,
      onPressed: _isJoining ? null : _joinRoom,
    );
  }

  Widget _primaryCta({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MateRadius.pill),
        gradient: MateColors.primaryGradient,
        boxShadow: onPressed == null
            ? []
            : MateShadows.cta.map((s) => s.copyWith(
                  color: s.color.withOpacity(0.3),
                )).toList(),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
        ),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ---------------- Input helpers ----------------

  /// Khi user nhập mã: tự động format "ABC123" -> "ABC-123" đẹp mắt.
  void _onCodeChanged(String value) {
    final cleaned = value.replaceAll('-', '').toUpperCase();
    String formatted = cleaned;
    if (cleaned.length > 4) {
      formatted = '${cleaned.substring(0, 4)}-${cleaned.substring(4)}';
    }
    if (formatted != value) {
      codeCtrl.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {}); // cập nhật trạng thái enable/disable nút
  }
}

/// Tự động uppercase cho TextField.
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}