import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/main_wrapper.dart';
import 'screens/onboarding_screen.dart';
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
  runApp(const CoupleApp());
}

class CoupleApp extends StatelessWidget {
  const CoupleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MATE - Không Gian Đôi',
      theme: ThemeData(
        textTheme: GoogleFonts.beVietnamProTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFFFEBF1),
      ),
      home: const _Gate(),
    );
  }
}

/// Màn hình cổng: hiển thị Onboarding trước,
/// sau khi ghép đôi thành công chuyển sang MainWrapper.
/// Cả 2 đều được wrap trong MobileFrame để responsive.
class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  OnboardingData? _data;

  void _onCompleted(OnboardingData data) {
    setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) {
    return MobileFrame(
      background: const Color(0xFFFCE4EC),
      child: _data == null
          ? OnboardingScreen(onCompleted: _onCompleted)
          : MainWrapper(
              coupleCode: _data!.code,
              myNickname: _data!.nickname,
              // Người tạo phòng = user1; người tham gia = user2.
              isUser1: _data!.role == PairRole.creator,
            ),
    );
  }
}