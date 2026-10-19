// Widget test cho NotificationCenterSheet: đảm bảo popup không
// bị RenderFlex overflow ở các kích thước màn hình phổ biến
// (320 - iPhone SE, 375 - iPhone 8, 390 - iPhone 12/13).
//
// KHÔNG cần Firestore — NotificationService hoạt động in-memory.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mate_couple_app/services/notification_service.dart';
import 'package:mate_couple_app/widgets/notification_center_sheet.dart';

Future<void> _pumpAtSize(WidgetTester tester, Size size) async {
  // Reset service trước mỗi test để mock data luôn có.
  NotificationService.instance.resetForTest();
  // Đóng mọi overlay/popup còn sót từ test trước.
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => NotificationCenterSheet.show(ctx),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'), warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
}

void main() {
  setUp(() {
    // Reset service để mỗi test có state độc lập (unread=9 mock).
    NotificationService.instance.resetForTest();
  });

  for (final size in const [
    Size(320, 720),  // iPhone SE nhỏ nhất
    Size(375, 720),  // iPhone 8
    Size(390, 800),  // iPhone 12/13
    Size(430, 900),  // iPhone 14 Pro Max (MATE wrapper max)
  ]) {
    testWidgets('Notification popup no overflow at width ${size.width.toInt()}', (tester) async {
      // Dùng surface size hẹp hơn wrapper 430 để giả lập popup
      // hoạt động trong device thật.
      await _pumpAtSize(tester, size);

      // Không có exception render (đặc biệt là RenderFlex overflow).
      expect(tester.takeException(), isNull);

      // Header + tabs + (optional mark all) + list đều hiện.
      expect(find.text('Thông báo'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Chưa đọc'), findsOneWidget);
      // Có unread nên nút "Đánh dấu tất cả đã đọc" phải hiện.
      expect(find.text('Đánh dấu tất cả đã đọc'), findsOneWidget);
      // Ít nhất 1 thông báo phải hiện (mock có 9).
      expect(find.byType(IconButton), findsWidgets);
    });
  }

  testWidgets('Mark-all-read hides button when 0 unread', (tester) async {
    await _pumpAtSize(tester, const Size(390, 800));
    // Đánh dấu tất cả đã đọc.
    NotificationService.instance.markAllRead();
    await tester.pump();
    // Nút phải ẩn.
    expect(find.text('Đánh dấu tất cả đã đọc'), findsNothing);
    // Không có exception.
    expect(tester.takeException(), isNull);
  });

  // ------------------------------------------------------------
  // Header alignment tests: nhóm tiêu đề phải căn giữa popup,
  // nút X nằm sát mép phải, badge nằm ngay sau title.
  // ------------------------------------------------------------
  testWidgets('Header title is centered and close button at right edge', (tester) async {
    final report = <String>[];
    for (final size in const [Size(320, 720), Size(375, 720), Size(390, 800)]) {
      await _pumpAtSize(tester, size);
      expect(tester.takeException(), isNull,
          reason: 'width=${size.width} must not overflow');

      // Tìm widget Text "Thông báo" trong header.
      final titleFinder = find.text('Thông báo');
      expect(titleFinder, findsOneWidget, reason: 'width=${size.width}');
      final titleGlobal = titleFinder.evaluate().first.renderObject as RenderBox;
      final titleCenterGlobal =
          titleGlobal.localToGlobal(titleGlobal.size.center(Offset.zero));

      // Tính popup render width thực tế.
      final popupRenderBox = find
          .byType(NotificationCenterSheet)
          .evaluate()
          .first
          .renderObject as RenderBox?;
      expect(popupRenderBox, isNotNull);
      final popupSize = popupRenderBox!.size;
      final popupGlobal = popupRenderBox.localToGlobal(Offset.zero);

      // Lấy tọa độ title theo global để so với popup left edge.
      final titleCenterInPopup = titleCenterGlobal.dx - popupGlobal.dx;
      final popupCenter = popupSize.width / 2;
      final offsetFromCenter = titleCenterInPopup - popupCenter;

      report.add(
          'width=${size.width}: titleCenterInPopup=$titleCenterInPopup, popupCenter=$popupCenter, offset=$offsetFromCenter, popupSize=$popupSize');

      // Tiêu đề phải nằm gần giữa popup (sai số 20px để chừa padding icon + text).
      expect(
        offsetFromCenter.abs() < 20,
        isTrue,
        reason: 'width=${size.width}: offset=$offsetFromCenter',
      );

      // Nút X (IconButton close) phải có right edge nằm trong
      // vùng 40px cuối cùng bên phải popup (= padding hợp lý 0..40px).
      final closeFinder = find.byTooltip('Đóng');
      expect(closeFinder, findsOneWidget, reason: 'width=${size.width}');
      final closeGlobal = closeFinder.evaluate().first.renderObject as RenderBox;
      final closeRightGlobal =
          closeGlobal.localToGlobal(Offset(closeGlobal.size.width, closeGlobal.size.height / 2));
      final closeRightInPopup = closeRightGlobal.dx - popupGlobal.dx;
      report.add('  closeRightInPopup=$closeRightInPopup, popupWidth=${popupSize.width}, rightPadding=${popupSize.width - closeRightInPopup}');
      expect(
        closeRightInPopup >= popupSize.width - 40 && closeRightInPopup <= popupSize.width,
        isTrue,
        reason: 'width=${size.width}: closeRightInPopup=$closeRightInPopup',
      );

      // Badge phải nằm ngay sau title (right edge của title < left edge của badge).
      final badgeFinder = find.byKey(const ValueKey('notif_badge'));
      expect(badgeFinder, findsOneWidget, reason: 'width=${size.width}');
      final titleRightGlobal = titleGlobal.localToGlobal(
        Offset(titleGlobal.size.width, titleGlobal.size.height / 2),
      );
      final badgeBox = badgeFinder.evaluate().first.renderObject as RenderBox;
      final badgeLeftGlobal =
          badgeBox.localToGlobal(Offset(0, badgeBox.size.height / 2));
      final gap = badgeLeftGlobal.dx - titleRightGlobal.dx;
      report.add('  badgeGap=$gap (should be > 0)');
      expect(
        badgeLeftGlobal.dx > titleRightGlobal.dx - 1,
        isTrue,
        reason: 'width=${size.width}: badge phải nằm sau title (gap=$gap)',
      );
    }
    // In report để debug dễ.
    // ignore: avoid_print
    for (final line in report) {
      // ignore: avoid_print
      print(line);
    }
  });

  testWidgets('Header close button dismisses popup', (tester) async {
    await _pumpAtSize(tester, const Size(390, 800));
    expect(find.text('Thông báo'), findsOneWidget);
    // Nhấn nút X.
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    // Popup phải đóng.
    expect(find.text('Thông báo'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
