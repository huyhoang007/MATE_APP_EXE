import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/mate_theme.dart';
import '../services/couple_service.dart';

/// ============================================================
/// VietQRSheet - ModalBottomSheet hiển thị QR chuyển khoản premium
/// 29.000đ/tháng. Có nút TEST KÍCH HOẠT để cập nhật
/// `isPremium: true` lên Firestore (chỉ dành cho demo).
/// ============================================================

class VietQRSheet extends StatefulWidget {
  final String coupleId;
  final String? accountBank;
  final String? accountNumber;
  final String? accountName;
  final int amountVnd;

  const VietQRSheet({
    super.key,
    required this.coupleId,
    this.accountBank = 'TPBank',
    this.accountNumber = '0000 0000 0000',
    this.accountName = 'MATE APP',
    this.amountVnd = 29000,
  });

  @override
  State<VietQRSheet> createState() => _VietQRSheetState();
}

class _VietQRSheetState extends State<VietQRSheet> {
  bool _activating = false;
  bool _activated = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final transferNote = 'PREMIUM ${widget.coupleId}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: MateColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Center(
            child: Text(
              '💕 Nâng cấp Premium',
              style: TextStyle(
                color: MateColors.plum, fontSize: 22, fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              '1 Đăng ký — 2 Người Dùng',
              style: TextStyle(color: MateColors.rose, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),

          // Price tag
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                gradient: MateColors.heroGradient,
                borderRadius: BorderRadius.circular(MateRadius.card),
                boxShadow: MateShadows.hero,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatVnd(widget.amountVnd),
                    style: const TextStyle(
                      color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('/tháng', style: TextStyle(
                    color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500,
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // QR code
          Center(
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MateColors.border),
                boxShadow: MateShadows.soft,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 150, height: 150,
                    decoration: BoxDecoration(
                      color: MateColors.subtlePink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code_2, color: MateColors.pinkDeep, size: 130,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Quét để thanh toán', style: TextStyle(
                    color: MateColors.rose, fontSize: 11,
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Bank info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MateColors.fieldBg,
              borderRadius: BorderRadius.circular(MateRadius.field),
            ),
            child: Column(
              children: [
                _InfoRow(label: 'Ngân hàng', value: widget.accountBank!),
                const Divider(height: 14),
                _InfoRow(label: 'Số tài khoản', value: widget.accountNumber!),
                const Divider(height: 14),
                _InfoRow(label: 'Chủ tài khoản', value: widget.accountName!),
                const Divider(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nội dung CK', style: TextStyle(
                      color: MateColors.rose, fontSize: 12,
                    )),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: transferNote));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép nội dung CK'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(transferNote, style: const TextStyle(
                            color: MateColors.plum, fontSize: 12,
                            fontWeight: FontWeight.w700,
                          )),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy, size: 12, color: MateColors.pink),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Status message
          if (_activated)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MateColors.subtlePink,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MateColors.online),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: MateColors.online, size: 20),
                  SizedBox(width: 8),
                  Text('Đã kích hoạt Premium! 🎉', style: TextStyle(
                    color: MateColors.plum, fontWeight: FontWeight.w700,
                  )),
                ],
              ),
            )
          else if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!, style: const TextStyle(
                color: Colors.red, fontWeight: FontWeight.w600,
              )),
            ),

          const SizedBox(height: 14),

          // Test Activate button
          if (!_activated)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _activating ? null : _testActivate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MateColors.pinkDeep,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                  elevation: 4,
                ),
                child: _activating
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        '🧪 TEST KÍCH HOẠT PREMIUM',
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MateColors.online,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: const Text(
                  'ĐÃ XONG ✨',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),
          if (!_activated)
            const Center(
              child: Text(
                '(Demo: ghi isPremium: true lên Firestore)',
                style: TextStyle(
                  color: MateColors.rose, fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _testActivate() async {
    setState(() {
      _activating = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    try {
      await CoupleService.instance.activatePremium(widget.coupleId);
      if (!mounted) return;
      setState(() {
        _activating = false;
        _activated = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _activating = false;
        _error = 'Lỗi: $e';
      });
    }
  }

  String _formatVnd(int vnd) {
    final s = vnd.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()}đ';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: MateColors.rose, fontSize: 13)),
        Text(value, style: const TextStyle(
          color: MateColors.plum, fontSize: 13, fontWeight: FontWeight.w700,
        )),
      ],
    );
  }
}
