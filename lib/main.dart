import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/main_wrapper_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'constants/mate_theme.dart';
import 'widgets/mobile_frame.dart';

/// ============================================================
/// MATE - Không Gian Đôi
/// Entry point: khởi tạo Firebase + theme + điều hướng.
///
/// ĐĂNG NHẬP:
///   App dùng Firebase Anonymous Authentication nên user KHÔNG cần
///   đăng ký / đăng nhập thủ công để dùng được. UID được sinh tự động
///   và persist trên thiết bị → mở app lại vẫn giữ đúng cặp đôi cũ.
///
///   Nếu user muốn "lưu đăng nhập" lâu dài hơn (đổi máy, xoá app),
///   họ có thể nâng cấp hồ sơ sang Email/Google trong Tab Hồ sơ →
///   "Tài khoản" (không mất UID, không mất dữ liệu cặp đôi).
/// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MateApp());
}

class MateApp extends StatelessWidget {
  const MateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MATE - Không Gian Đôi',
      theme: ThemeData(
        textTheme: GoogleFonts.beVietnamProTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFFFEBF1),
        primaryColor: MateColors.pink,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MateColors.pink,
          primary: MateColors.pink,
          secondary: MateColors.rose,
        ),
      ),
      // MobileFrame bọc mọi page trong root Navigator, đảm bảo cả các
      // màn hình push (như Games) đều nằm trong khung mobile 430px
      // khi chạy trên web/desktop, thay vì tràn full-width.
      builder: (context, child) {
        return MobileFrame(
          background: const Color(0xFFFCE4EC),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const _Gate(),
    );
  }
}

/// ============================================================
/// _Gate - Cổng điều hướng.
///
/// Luồng:
///   1. Đăng nhập anonymous (tự động, không cần form).
///   2. Nếu hồ sơ đã có `coupleCode` → vào thẳng MainWrapperScreen.
///   3. Ngược lại → OnboardingScreen để ghép đôi.
///
/// TUYỆT ĐỐI không bypass bước ghép đôi cho user mới.
/// ============================================================

class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  /// Đang khởi tạo session (đăng nhập + đọc hồ sơ).
  bool _booting = true;
  String? _bootError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }
  /// Đăng nhập anonymous + tự khôi phục cặp đôi cũ nếu có.
  Future<void> _bootstrap({bool force = false}) async {
    try {
      await AuthService.instance.ensureSignedIn(force: force);

      final code = AuthService.instance.coupleCode;
      if (code != null && code.isNotEmpty) {
        // Đã từng ghép đôi → vào thẳng cặp đôi đó.
        _goToMain(code);
        return;
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _bootError = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _bootError =
            'Không thể kết nối. Vui lòng kiểm tra kết nối mạng nhé 💕');
      }
    } finally {
      if (mounted) setState(() => _booting = false);
    }
  }

  void _onCompleted(OnboardingData data) {
    _goToMain(data.code);
  }
  Future<void> _goToMain(String code) async {
    final uid = AuthService.instance.uid;
    if (uid == null) return;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => MainWrapperScreen(
          coupleId: code,
          currentUserId: uid,
        ),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Đang bootstrap → hiện loader.
    if (_booting) {
      return const _BootScreen();
    }

    // 2. Lỗi đăng nhập → cho thử lại hoặc dùng thử khách.
    if (_bootError != null) {
      return _BootErrorScreen(
        message: _bootError!,
        onRetry: () {
          setState(() {
            _bootError = null;
            _booting = true;
          });
          _bootstrap(force: true);
        },
        onUseGuest: () {
          AuthService.instance.useGuestMode();
          setState(() {
            _bootError = null;
            _booting = false;
          });
        },
      );
    }

    // 3. Bình thường → Onboarding (ghép đôi).
    return OnboardingScreen(onCompleted: _onCompleted);
  }
}

/// Màn hình chờ trong lúc đăng nhập.
class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: MateColors.bgGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_rounded, color: MateColors.pink, size: 56),
              const SizedBox(height: 16),
              const Text(
                'MATE',
                style: TextStyle(
                  color: MateColors.plum,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: MateColors.pink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Đang chuẩn bị không gian của hai bạn...',
                style: TextStyle(
                  color: MateColors.rose.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Màn hình lỗi khi không đăng nhập được.
class _BootErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onUseGuest;
  const _BootErrorScreen({
    required this.message,
    required this.onRetry,
    this.onUseGuest,
  });

  @override
  Widget build(BuildContext context) {
    final isConfigError = message.contains('Anonymous') ||
        message.contains('configuration-not-found') ||
        message.contains('admin-restricted-operation');
    final isAdminRestricted = message.contains('admin-restricted-operation');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: MateColors.bgGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, color: MateColors.pink, size: 52),
                const SizedBox(height: 14),
                const Text(
                  'Chưa kết nối được',
                  style: TextStyle(
                    color: MateColors.plum,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: MateColors.border),
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: MateColors.plum,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),
                if (isConfigError) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MateColors.pink.withOpacity(0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tips_and_updates_rounded,
                                color: MateColors.pink, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Cách khắc phục (1 phút trên Firebase):',
                              style: TextStyle(
                                color: MateColors.plum,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAdminRestricted
                              ? '1. Mở Firebase Console → Project "mateapp-8d44d"\n'
                                '2. Vào Build > Authentication > tab Settings (Cài đặt)\n'
                                '3. Tìm mục "User actions" (Thao tác của người dùng)\n'
                                '4. Tích BẬT ô "Enable create (sign-up)" rồi bấm Save.\n'
                                '5. Bấm nút "Thử lại kết nối" bên dưới.'
                              : '1. Mở Firebase Console → Project "mateapp-8d44d"\n'
                                '2. Vào Build > Authentication > tab Sign-in method\n'
                                '3. Bấm vào "Anonymous" (Ẩn danh) và gạt Enable\n'
                                '4. Nhấn Save, sau đó bấm nút "Thử lại kết nối" bên dưới.',
                          style: const TextStyle(
                            color: MateColors.rose,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MateColors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MateRadius.pill),
                      ),
                      elevation: 2,
                    ),
                    label: const Text(
                      'Thử lại kết nối',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
                if (onUseGuest != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onUseGuest,
                      icon: const Icon(Icons.play_circle_outline_rounded,
                          color: MateColors.pink, size: 18),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MateColors.pink,
                        side: const BorderSide(color: MateColors.pink, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(MateRadius.pill),
                        ),
                      ),
                      label: const Text(
                        'Dùng thử chế độ Khách (Offline)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
