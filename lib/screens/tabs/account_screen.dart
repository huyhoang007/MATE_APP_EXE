import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/mate_theme.dart';
import '../../services/auth_service.dart';

/// ============================================================
/// AccountScreen - Quản lý tài khoản người dùng.
///
/// MATE dùng "đăng nhập không cần form": Firebase Anonymous Auth tự sinh
/// UID và lưu trên thiết bị. Người dùng KHÔNG cần đăng ký để dùng app.
///
/// Màn hình này cho phép NÂNG CẤP hồ sơ lên Email/Google:
///   - `linkWithCredential` giữ nguyên UID → không mất cặp đôi, không mất
///     khoảnh khắc, tin nhắn, pet... (khác hẳn `createUserWithEmailAndPassword`
///     vốn tạo UID mới).
///   - Sau khi nâng cấp, đăng nhập được trên nhiều thiết bị.
///
/// Ngoài ra cho phép:
///   - Đổi biệt danh
///   - Xem thông tin phiên
///   - Đăng xuất (dữ liệu cặp đôi vẫn giữ trên server)
/// ============================================================

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController _nickCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  bool _savingNickname = false;
  bool _linking = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _nickCtrl.text = AuthService.instance.nickname;
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? MateColors.pinkDeep : MateColors.pink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Future<void> _saveNickname() async {
    final name = _nickCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Biệt danh không được để trống', isError: true);
      return;
    }
    setState(() => _savingNickname = true);
    try {
      await AuthService.instance.updateNickname(name);
      _snack('Đã cập nhật biệt danh 💕');
    } catch (e) {
      _snack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _savingNickname = false);
    }
  }

  Future<void> _linkEmail() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (!_isValidEmail(email)) {
      _snack('Email không hợp lệ', isError: true);
      return;
    }
    if (pass.length < 6) {
      _snack('Mật khẩu phải có ít nhất 6 ký tự', isError: true);
      return;
    }

    setState(() => _linking = true);
    try {
      await AuthService.instance.linkEmail(email: email, password: pass);
      _emailCtrl.clear();
      _passCtrl.clear();
      _snack('Đã liên kết email thành công! 🎉');
    } on AuthException catch (e) {
      _snack(e.message, isError: true);
    } catch (e) {
      _snack('Không thể liên kết email. Vui lòng thử lại.', isError: true);
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  Future<void> _linkGoogle() async {
    // Google Sign-In cần cấu hình OAuth client cho từng platform
    // (SHA-1 Android / iOS Service ID / Web Client ID). Chưa cấu hình
    // trong project nên chỉ hướng dẫn user dùng email.
    _snack(
      'Đăng nhập Google chưa khả dụng trên phiên bản này. '
      'Vui lòng dùng email nhé 💕',
      isError: true,
    );
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(value);
  }

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Đăng xuất?',
          style: TextStyle(color: MateColors.plum, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Tài khoản trên máy này sẽ bị đăng xuất. Dữ liệu cặp đôi vẫn được '
          'giữ an toàn trên máy chủ. Nếu bạn đã liên kết email, hãy đăng nhập '
          'lại bằng email để khôi phục.',
          style: TextStyle(color: MateColors.rose, fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ', style: TextStyle(color: MateColors.rose)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: MateColors.pinkDeep, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;
    await AuthService.instance.signOut();
    if (!mounted) return;
    // Quay lại màn hình ghép đôi (root gate sẽ tự xử lý).
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final isAnonymous = firebaseUser?.isAnonymous ?? true;
    final linkedEmail = auth.profile == null ? null : _readEmail();

    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: MateColors.plum),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tài khoản',
          style: TextStyle(
            color: MateColors.plum,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // ---------- Card hồ sơ ----------
          _ProfileCard(
            nickname: auth.nickname,
            uid: auth.uid ?? '—',
            isAnonymous: isAnonymous,
            email: linkedEmail,
            coupleCode: auth.coupleCode,
          ),
          const SizedBox(height: 18),

          // ---------- Biệt danh ----------
          const _SectionTitle(icon: Icons.badge_outlined, title: 'Biệt danh'),
          const SizedBox(height: 8),
          _CardGroup(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nickCtrl,
                        style: const TextStyle(
                          color: MateColors.plum,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Nhập biệt danh',
                          hintStyle: TextStyle(color: MateColors.rose),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 36,
                      child: FilledButton(
                        onPressed: _savingNickname ? null : _saveNickname,
                        style: FilledButton.styleFrom(
                          backgroundColor: MateColors.pink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _savingNickname
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Lưu',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ---------- Nâng cấp tài khoản ----------
          const _SectionTitle(
            icon: Icons.verified_user_outlined,
            title: 'Bảo mật tài khoản',
          ),
          const SizedBox(height: 8),
          _CardGroup(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isAnonymous)
                      const Text(
                        'Tài khoản của bạn hiện chưa liên kết email. '
                        'Liên kết để đăng nhập trên nhiều thiết bị — '
                        'cặp đôi và kỷ niệm vẫn giữ nguyên.',
                        style: TextStyle(
                          color: MateColors.rose,
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                      )
                    else
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded,
                              color: MateColors.online, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              linkedEmail ?? 'Đã liên kết email',
                              style: const TextStyle(
                                color: MateColors.plum,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (isAnonymous) ...[
                      const SizedBox(height: 14),
                      // Ô email
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: MateColors.plum),
                        decoration: _inputDeco('Email của bạn'),
                      ),
                      const SizedBox(height: 10),
                      // Ô mật khẩu
                      TextField(
                        controller: _passCtrl,
                        obscureText: !_showPassword,
                        style: const TextStyle(color: MateColors.plum),
                        decoration: _inputDeco('Mật khẩu (tối thiểu 6 ký tự)').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: MateColors.rose,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: FilledButton.icon(
                          onPressed: _linking ? null : _linkEmail,
                          icon: _linking
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.mail_rounded, size: 18),
                          style: FilledButton.styleFrom(
                            backgroundColor: MateColors.pink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(MateRadius.pill),
                            ),
                          ),
                          label: const Text(
                            'Liên kết email',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: _linking ? null : _linkGoogle,
                          icon: const Icon(Icons.g_mobiledata_rounded, size: 22),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MateColors.plum,
                            side: const BorderSide(color: MateColors.border, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(MateRadius.pill),
                            ),
                          ),
                          label: const Text(
                            'Tiếp tục với Google',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ---------- Thông tin phiên ----------
          const _SectionTitle(icon: Icons.info_outline_rounded, title: 'Thông tin phiên'),
          const SizedBox(height: 8),
          _CardGroup(
            children: [
              _InfoRow(label: 'Mã cặp đôi', value: auth.coupleCode ?? 'Chưa ghép đôi'),
              _InfoRow(label: 'Loại tài khoản', value: isAnonymous ? 'Tạm thời' : 'Đã xác thực'),
              _InfoRow(label: 'Mã thiết bị', value: _shortUid(auth.uid)),
            ],
          ),
          const SizedBox(height: 18),

          // ---------- Đăng xuất ----------
          _CardGroup(
            children: [
              InkWell(
                onTap: _confirmSignOut,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: MateColors.pinkDeep, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Đăng xuất',
                        style: TextStyle(
                          color: MateColors.pinkDeep,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Center(
            child: Text(
              'MATE · Dành cho những người yêu nhau 💕',
              style: TextStyle(
                color: MateColors.rose.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _readEmail() {
    final u = FirebaseAuth.instance.currentUser;
    return u?.email;
  }

  static String _shortUid(String? uid) {
    if (uid == null || uid.isEmpty) return '—';
    return uid.length <= 10 ? uid : '${uid.substring(0, 8)}…';
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: MateColors.rose, fontSize: 13),
      filled: true,
      fillColor: MateColors.fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
  }
}

// =============================================================
// Sub-widgets
// =============================================================

class _ProfileCard extends StatelessWidget {
  final String nickname;
  final String uid;
  final bool isAnonymous;
  final String? email;
  final String? coupleCode;

  const _ProfileCard({
    required this.nickname,
    required this.uid,
    required this.isAnonymous,
    this.email,
    this.coupleCode,
  });

  @override
  Widget build(BuildContext context) {
    final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB1CB), Color(0xFFFFD8E4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(MateRadius.cardLg),
        boxShadow: MateShadows.hero,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
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
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: const TextStyle(
                    color: MateColors.plum,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email ?? (isAnonymous ? 'Tài khoản tạm thời' : 'Đã xác thực'),
                  style: const TextStyle(color: MateColors.rose, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(MateRadius.pill),
                  ),
                  child: Text(
                    coupleCode == null
                        ? 'Chưa ghép đôi'
                        : 'Mã cặp đôi: $coupleCode',
                    style: const TextStyle(
                      color: MateColors.plum,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
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
          indent: 14,
          endIndent: 14,
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: MateColors.rose, fontSize: 12.5),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: MateColors.plum,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
