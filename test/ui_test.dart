import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartmed_nutricare/main.dart';

Future<void> openDemo(WidgetTester tester) async {
  await tester.pumpWidget(const TemanRawatApp());
  final demo = find.text('Coba Demo');
  await tester.ensureVisible(demo);
  await tester.tap(demo);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Rina & Ibu Sari'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mobile agenda records a completion and a correction', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openDemo(tester);
    await tester.tap(find.text('Hari Ini'));
    await tester.pumpAndSettle();
    expect(find.text('2 dari 4 kegiatan tercatat'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Jeda untuk beristirahat'), 200);
    await tester.tap(find.text('Jeda untuk beristirahat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Konfirmasi kegiatan selesai'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jeda untuk beristirahat'));
    await tester.pumpAndSettle();
    expect(find.text('Koreksi: belum dikonfirmasi'), findsOneWidget);
    await tester.tap(find.text('Koreksi: belum dikonfirmasi'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop menu approval adds meals once', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openDemo(tester);
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Tinjau Jadwal'), 300);
    await tester.tap(find.text('Tinjau Jadwal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Setujui & masukkan ke agenda'));
    await tester.pumpAndSettle();
    // Breakfast is already present in the initial demo; only two meals are added.
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Rencana sudah diterapkan'), 300);
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Rencana sudah diterapkan'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all pages fit a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openDemo(tester);
    for (final label in ['Menu', 'Riwayat', 'Profil', 'Hari Ini']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  testWidgets('budget can be saved on a short phone with the keyboard open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await openDemo(tester);

    await tester.ensureVisible(find.text('Ubah budget'));
    await tester.tap(find.text('Ubah budget'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '60000');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Simpan budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan budget'));
    await tester.pumpAndSettle();

    expect(find.text('Dari anggaran Rp60.000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
