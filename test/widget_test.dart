// This is a basic Flutter widget test cho MATE app.
import 'package:flutter_test/flutter_test.dart';
import 'package:mate_couple_app/main.dart';

void main() {
  testWidgets('MATE app khởi động thành công', (WidgetTester tester) async {
    await tester.pumpWidget(const MateApp());
    await tester.pump();
  });
}
