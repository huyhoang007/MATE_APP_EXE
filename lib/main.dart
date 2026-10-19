import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/main_wrapper_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/user_id_service.dart';
import 'constants/mate_theme.dart';
import 'widgets/mobile_frame.dart';

/// ============================================================
/// MATE - Không Gian Đôi
/// Entry point: khởi tạo Firebase + theme + điều hướng.
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
/// Hiển thị Onboarding; sau khi ghép đôi thành công thì
/// pushReplacement sang MainWrapperScreen với coupleId + currentUserId.
/// TUYỆT ĐỐI không bỏ qua bước ghép đôi.
/// ============================================================

class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  /// Lưu thông tin onboarding nếu user đã ghép đôi trong session hiện tại
  /// (dùng để chuyển trang mượt mà ngay khi callback bắn ra).
  OnboardingData? _pendingData;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Lấy trước userId thiết bị (không cần login FirebaseAuth).
  Future<void> _bootstrap() async {
    try {
      final id = await UserIdService.instance.getOrCreate();
      if (mounted) setState(() => _userId = id);
    } catch (_) {
      // SharedPreferences có thể chưa sẵn sàng trên web lần đầu;
      // vẫn tiếp tục để vào onboarding, MainWrapper sẽ lấy lại sau.
    }
  }

  void _onCompleted(OnboardingData data) {
    setState(() => _pendingData = data);
    _goToMain();
  }

  Future<void> _goToMain() async {
    final data = _pendingData;
    if (data == null || !mounted) return;

    // Lấy userId nếu bootstrap xong; nếu chưa thì lấy lại tại đây.
    var uid = _userId;
    if (uid == null) {
      try {
        uid = await UserIdService.instance.getOrCreate();
      } catch (_) {
        uid = 'anonymous';
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => MainWrapperScreen(
          coupleId: data.code,
          currentUserId: uid!,
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
    // Luôn hiển thị Onboarding trước - KHÔNG bypass.
    return OnboardingScreen(onCompleted: _onCompleted);
  }
}
