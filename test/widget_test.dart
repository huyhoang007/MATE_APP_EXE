// This is a basic Flutter widget test cho MATE app.
import 'package:flutter_test/flutter_test.dart';
import 'package:mate_couple_app/main.dart';

void main() {
  testWidgets('MATE app khởi động thành công', (WidgetTester tester) async {
    await tester.pumpWidget(const CoupleApp());
    await tester.pump();

    // Verify app hiển thị logo MATE ở màn Onboarding.
    expect(find.text('MATE'), findsOneWidget);
  });
}