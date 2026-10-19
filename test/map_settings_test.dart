// Widget test cho MapSettingsSheet: đảm bảo popup không
// bị RenderFlex overflow ở các kích thước màn hình phổ biến
// (320 / 375 / 390 / 430), header căn giữa, nút X nằm phải,
// toggle thay đổi MapPreferencesService, callback refresh hoạt động.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mate_couple_app/services/map_preferences_service.dart';
import 'package:mate_couple_app/widgets/map_settings_sheet.dart';

Future<void> _pumpAtSize(WidgetTester tester, Size size) async {
  // Reset service + mock SharedPreferences.
  await MapPreferencesService.instance.resetForTest();
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
                onPressed: () => MapSettingsSheet.show(ctx),
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
  setUp(() async {
    // Mock SharedPreferences cho service persistence.
    SharedPreferences.setMockInitialValues({});
    await MapPreferencesService.instance.resetForTest();
  });

  for (final size in const [
    Size(320, 720),  // iPhone SE
    Size(375, 720),  // iPhone 8
    Size(390, 800),  // iPhone 12/13
    Size(430, 900),  // MATE wrapper max
  ]) {
    testWidgets('Map settings no overflow at width ${size.width.toInt()}',
        (tester) async {
      await _pumpAtSize(tester, size);

      // Không có exception render.
      expect(tester.takeException(), isNull,
          reason: 'width=${size.width} must not overflow');

      // Header + 3 card titles hiện.
      expect(find.text('Cài đặt bản đồ'), findsOneWidget);
      expect(find.text('Hiển thị bản đồ'), findsOneWidget);
      expect(find.text('Vị trí & Chia sẻ'), findsOneWidget);

      // SegmentedControl 2 options.
      expect(find.text('Sáng'), findsOneWidget);
      expect(find.text('Tối'), findsOneWidget);

      // 3 toggle tile titles.
      expect(find.text('Hiển thị vị trí hai người'), findsOneWidget);
      expect(find.text('Hiển thị đường kết nối'), findsOneWidget);
      expect(find.text('Hiển thị khoảng cách'), findsOneWidget);

      // 2 ListTile trong card Vị trí.
      expect(find.text('Làm mới vị trí'), findsOneWidget);
      expect(find.text('Quyền truy cập vị trí'), findsOneWidget);

      // Nút X.
      expect(find.byTooltip('Đóng'), findsOneWidget);

      // Scroll xuống xem card "Địa điểm & Cảnh báo" + 2 tile bên trong.
      await tester.dragUntilVisible(
        find.text('Địa điểm & Cảnh báo'),
        find.byType(MapSettingsSheet),
        const Offset(0, -120),
      );
      expect(find.text('Địa điểm & Cảnh báo'), findsOneWidget);
      expect(find.text('Địa điểm quan trọng'), findsOneWidget);
      expect(find.text('Thông báo đến / rời địa điểm'), findsOneWidget);
      // 4 "Sắp ra mắt" badges (2 trong card 2 + 2 trong card 3)
      // Lưu ý: card 2 có 2 unsupported tile, card 3 có 2 → tổng 4.
      expect(find.text('Sắp ra mắt'), findsNWidgets(4));
    });
  }

  testWidgets('Header title is centered and close button at right edge',
      (tester) async {
    for (final size in const [Size(320, 720), Size(375, 720), Size(390, 800)]) {
      await _pumpAtSize(tester, size);
      expect(tester.takeException(), isNull,
          reason: 'width=${size.width} must not overflow');

      final titleFinder = find.text('Cài đặt bản đồ');
      expect(titleFinder, findsOneWidget, reason: 'width=${size.width}');
      final titleGlobal =
          titleFinder.evaluate().first.renderObject as RenderBox;
      final titleCenterGlobal =
          titleGlobal.localToGlobal(titleGlobal.size.center(Offset.zero));

      final popupRenderBox = find
          .byType(MapSettingsSheet)
          .evaluate()
          .first
          .renderObject as RenderBox?;
      expect(popupRenderBox, isNotNull);
      final popupSize = popupRenderBox!.size;
      final popupGlobal = popupRenderBox.localToGlobal(Offset.zero);

      final titleCenterInPopup = titleCenterGlobal.dx - popupGlobal.dx;
      final popupCenter = popupSize.width / 2;
      final offset = titleCenterInPopup - popupCenter;

      // Title phải nằm gần giữa popup (sai số 25px — optical center
      // chuẩn vì text "Cài đặt bản đồ" có thể render hơi lệch).
      expect(offset.abs() < 25, isTrue,
          reason: 'width=${size.width}: offset=$offset, popupSize=$popupSize');

      // Nút X nằm trong 40px cuối cùng bên phải.
      final closeFinder = find.byTooltip('Đóng');
      expect(closeFinder, findsOneWidget);
      final closeGlobal =
          closeFinder.evaluate().first.renderObject as RenderBox;
      final closeRightGlobal = closeGlobal.localToGlobal(
          Offset(closeGlobal.size.width, closeGlobal.size.height / 2));
      final closeRightInPopup = closeRightGlobal.dx - popupGlobal.dx;
      expect(
        closeRightInPopup >= popupSize.width - 40 &&
            closeRightInPopup <= popupSize.width,
        isTrue,
        reason:
            'width=${size.width}: closeRightInPopup=$closeRightInPopup, popupSize=$popupSize',
      );
    }
  });

  testWidgets('Tap "Sáng" switches map style to light', (tester) async {
    await _pumpAtSize(tester, const Size(390, 800));
    expect(MapPreferencesService.instance.mapStyle, MapStyleMode.dark);
    await tester.tap(find.text('Sáng'));
    await tester.pumpAndSettle();
    expect(MapPreferencesService.instance.mapStyle, MapStyleMode.light);
  });

  testWidgets('Toggle markers off persists to service', (tester) async {
    await _pumpAtSize(tester, const Size(390, 800));
    expect(MapPreferencesService.instance.showBothMarkers, isTrue);

    // Tìm SwitchListTile có title "Hiển thị vị trí hai người" rồi tap switch.
    final titleFinder = find.text('Hiển thị vị trí hai người');
    expect(titleFinder, findsOneWidget);
    // Tìm ancestor SwitchListTile, rồi tap trên nó.
    final tileFinder = find.ancestor(
      of: titleFinder,
      matching: find.byType(SwitchListTile),
    );
    expect(tileFinder, findsOneWidget);
    await tester.tap(tileFinder, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(MapPreferencesService.instance.showBothMarkers, isFalse);
  });

  testWidgets('Tap "Làm mới vị trí" calls onRefreshLocation', (tester) async {
    var called = 0;
    Future<bool> fakeRefresh() async {
      called++;
      return true;
    }

    await tester.binding.setSurfaceSize(const Size(390, 800));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(390, 800)),
        child: MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => MapSettingsSheet.show(
                    ctx,
                    onRefreshLocation: fakeRefresh,
                    locationPermission: geo.LocationPermission.whileInUse,
                    locationServiceEnabled: true,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Làm mới vị trí'), findsOneWidget);
    // Đảm bảo tile nằm trong viewport, rồi tap trực tiếp.
    await tester.ensureVisible(find.text('Làm mới vị trí'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Làm mới vị trí'), warnIfMissed: false);
    // Đợi Future của callback hoàn tất.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(called, 1);
  });

  testWidgets('Tap "Làm mới vị trí" shows error when callback returns false',
      (tester) async {
    Future<bool> fakeRefresh() async => false;

    await tester.binding.setSurfaceSize(const Size(390, 800));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(390, 800)),
        child: MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => MapSettingsSheet.show(
                    ctx,
                    onRefreshLocation: fakeRefresh,
                    locationPermission: geo.LocationPermission.denied,
                    locationServiceEnabled: true,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Đảm bảo tile nằm trong viewport.
    await tester.ensureVisible(find.text('Làm mới vị trí'));
    await tester.pumpAndSettle();
    // Tap trực tiếp vào text — Flutter widget test cho phép tap text
    // nếu text nằm trong 1 InkWell/GestureDetector/ListTile có onTap.
    await tester.tap(find.text('Làm mới vị trí'), warnIfMissed: false);
    // Pump nhiều lần để chờ Future callback + setState rebuild.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Không thể cập nhật'),
      findsOneWidget,
    );
  });

  testWidgets('Tap close button dismisses sheet', (tester) async {
    await _pumpAtSize(tester, const Size(390, 800));
    expect(find.text('Cài đặt bản đồ'), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(find.text('Cài đặt bản đồ'), findsNothing);
  });
}
