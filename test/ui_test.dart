import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartmed_nutricare/care_api.dart';
import 'package:smartmed_nutricare/main.dart';
import 'package:smartmed_nutricare/web_demo.dart';
import 'package:smartmed_nutricare/welcome.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  await tapWidget(tester, find.text(text));
}

Future<void> tapWidget(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target, warnIfMissed: true);
  await tester.pumpAndSettle();
}

Future<void> enterField(WidgetTester tester, String label, String value) async {
  final field = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

void usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> startCare(WidgetTester tester, {CareApi? api}) async {
  await tester.pumpWidget(TemanRawatApp(api: api));
  expect(
    find.text('Coba Demo'),
    webDemoEnabled ? findsOneWidget : findsNothing,
  );
  await tapText(tester, 'Mulai Mendampingi');
  await enterField(tester, 'Nama panggilan kamu', 'Pendamping Uji');
  await enterField(tester, 'Nama panggilan orang yang dirawat', 'Pasien Uji');
  await tapText(tester, 'Lanjut ke Profil');
}

void main() {
  testWidgets(
    'web demo opens populated screens and simulates schedule generation',
    (tester) async {
      usePhone(tester);
      WebDemo? scenario;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              final demo = scenario;
              return demo == null
                  ? WelcomePage(
                      onStart: (_, _) {},
                      onDemo: (withPrescription) => setState(
                        () => scenario = WebDemo(
                          withPrescription: withPrescription,
                        ),
                      ),
                    )
                  : HomeShell(
                      caregiver: demo.caregiver,
                      patient: demo.patient,
                      demo: demo,
                      onExitDemo: () => setState(() => scenario = null),
                    );
            },
          ),
        ),
      );
      await tapText(tester, 'Coba Demo');
      await tapText(tester, 'Dimas & Pak Arif');
      expect(find.text('Demo web'), findsOneWidget);
      expect(find.text('Bubur ayam rumahan'), findsOneWidget);
      await tapWidget(tester, find.text('Lihat detail').first);
      expect(find.text('• Beras · 50 g'), findsOneWidget);
      await tapWidget(tester, find.byTooltip('Tutup'));
      await tapText(tester, 'Buat draf menu');
      expect(
        find.text('Ini adalah draf simulasi untuk preview web.'),
        findsOneWidget,
      );
      await tapText(tester, 'Hari Ini');
      expect(find.text('PROGRES PERAWATAN'), findsOneWidget);
      await tapText(tester, 'Riwayat');
      expect(find.text('Sarapan'), findsOneWidget);
      await tapText(tester, 'Profil');
      expect(find.text('Obat contoh A'), findsOneWidget);
      await tapText(tester, 'Menu');
      await tapText(tester, 'Isi rutinitas pendampingan');
      await enterField(tester, 'Rutinitas harian', 'Makan bersama keluarga');
      await tapText(tester, 'Simpan rutinitas');
      await tapText(tester, 'Setujui menu dan buat jadwal');
      expect(find.text('Tinjau jadwal'), findsOneWidget);
      await tapText(tester, 'Setujui dan masukkan ke agenda');
      expect(find.text('Agenda Perawatan'), findsOneWidget);
      await tapWidget(tester, find.text('Catat sebagai selesai').at(1));
      await tapText(tester, 'Riwayat');
      expect(find.text('Cek jadwal obat'), findsOneWidget);
      await tapText(tester, 'Profil');
      await tapText(tester, 'Ganti skenario demo');
      await tapText(tester, 'Coba Demo');
      await tapText(tester, 'Rina & Ibu Sari');
      await tapText(tester, 'Profil');
      expect(find.text('Belum ada resep yang dicatat.'), findsOneWidget);
      expect(find.text('Ibu Sari'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('new session starts without recipes, reminders or history', (
    tester,
  ) async {
    usePhone(tester);
    await startCare(tester);
    expect(find.text('Kondisi kesehatan belum diisi.'), findsOneWidget);
    expect(find.text('Belum ada resep yang dicatat.'), findsOneWidget);

    await tapText(tester, 'Menu');
    expect(find.textContaining('Belum ada menu.'), findsOneWidget);
    await tapText(tester, 'Hari Ini');
    expect(find.text('Belum ada jadwal yang disetujui.'), findsOneWidget);
    await tapText(tester, 'Riwayat');
    expect(find.text('Belum ada kegiatan yang dicatat.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'sends entered profile and returned recipe through the API workflow',
    (tester) async {
      usePhone(tester);
      final recipe = <String, dynamic>{
        'recipe_name': 'Resep dari server uji',
        'servings': 2,
        'cooking_time': 15,
        'instructions': 'Instruksi dari server uji',
        'ingredients': [
          {'ingredient_name': 'Bahan uji', 'quantity': '100 g'},
        ],
      };
      var requests = 0;
      final api = CareApi(
        baseUrl: 'https://example.test',
        client: MockClient((request) async {
          requests++;
          final payload = jsonDecode(request.body) as Json;
          expect(payload['request_id'], isA<String>());
          expect(payload['input_version'], isA<int>());
          expect(payload.containsKey('patient'), isFalse);
          if (request.url.path == '/api/meal-plans/generate') {
            expect(payload['health_condition'], {
              'condition_name': 'Kondisi yang diinput',
              'diagnosis': null,
              'notes': null,
              'age': 58,
              'weight': 60.5,
              'height': 160.0,
              'isTherePrescription': true,
            });
            expect(payload['allergies'], [
              {'type': 'kacang'},
            ]);
            expect(payload['budget'], 75000);
            expect(payload['stok_bahan'], ['beras']);
            expect(payload['preferensi'], ['makanan lembut']);
            return http.Response(
              jsonEncode({
                'status': 'draft',
                'meals': [recipe],
                'questions': [],
                'review_notes': [],
              }),
              200,
            );
          }
          expect(request.url.path, '/api/schedules/generate');
          expect(payload['menu_disetujui'], [recipe]);
          final prescription =
              (payload['prescriptions'] as List).single as Json;
          final medication =
              (prescription['medications'] as List).single as Json;
          expect(prescription['prescription_date'], '2026-11-07');
          expect(prescription['start_at'], '2026-11-08');
          expect(medication['prescription_id'], prescription['id']);
          expect(medication['medicine_name'], 'Nama sesuai input uji');
          expect(medication['quantity'], 10);
          expect(medication['isAfterEat'], true);
          expect(payload['rutinitas'], {'notes': 'Sarapan pukul 08.00'});
          expect(payload['ketersediaan_caregiver'], {'notes': 'Tersedia pagi'});
          return http.Response(
            jsonEncode({
              'status': 'draft',
              'input_version': payload['input_version'],
              'reminders': [
                {
                  'title': 'Pengingat dari server uji',
                  'schedule_at': '2026-11-07T08:00:00+07:00',
                  'status': 'pending',
                  'prescription_id': prescription['id'],
                  'reminder_items': [
                    {'medication_id': medication['id']},
                  ],
                },
              ],
              'conflicts': [],
              'questions': [],
            }),
            200,
          );
        }),
      );
      addTearDown(api.close);
      await startCare(tester, api: api);
      await tapText(tester, 'Isi profil dan kebutuhan makan');
      for (final (label, value) in [
        ('Kondisi kesehatan', 'Kondisi yang diinput'),
        ('Usia (tahun)', '58'),
        ('Berat (kg)', '60,5'),
        ('Tinggi (cm)', '160'),
        ('Alergi, pisahkan dengan koma', 'kacang'),
        ('Budget belanja (rupiah)', '75000'),
        ('Stok bahan, pisahkan dengan koma', 'beras'),
        ('Preferensi, pisahkan dengan koma', 'makanan lembut'),
      ]) {
        await enterField(tester, label, value);
      }
      await tapText(tester, 'Simpan profil perawatan');
      await tapText(tester, 'Tambah resep');
      await enterField(tester, 'Tanggal resep (YYYY-MM-DD)', '2026-11-07');
      await enterField(tester, 'Tanggal mulai (YYYY-MM-DD)', '2026-11-08');
      await tapText(tester, 'Tambah obat');
      for (final (label, value) in [
        ('Nama obat', 'Nama sesuai input uji'),
        ('Dosis', 'Dosis uji'),
        ('Frekuensi', 'Frekuensi uji'),
        ('Instruksi dari resep', 'Instruksi uji'),
        ('Jumlah', '10'),
      ]) {
        await enterField(tester, label, value);
      }
      await tapText(tester, 'Diminum setelah makan sesuai resep');
      await tapText(tester, 'Simpan obat');
      await tapText(tester, 'Simpan resep');
      await tapText(tester, 'Menu');
      await tapText(tester, 'Buat draf menu');
      expect(find.text('Resep dari server uji'), findsOneWidget);
      await tapText(tester, 'Isi rutinitas pendampingan');
      await enterField(tester, 'Rutinitas harian', 'Sarapan pukul 08.00');
      await enterField(tester, 'Ketersediaan pendamping', 'Tersedia pagi');
      await tapText(tester, 'Simpan rutinitas');
      await tapText(tester, 'Setujui menu dan buat jadwal');
      expect(find.text('Pengingat dari server uji'), findsOneWidget);
      expect(
        find.textContaining('Nama sesuai input uji · Dosis uji'),
        findsOneWidget,
      );
      await tapText(tester, 'Setujui dan masukkan ke agenda');
      await tapText(tester, 'Catat sebagai selesai');
      await tapText(tester, 'Riwayat');
      expect(find.text('Pengingat dari server uji'), findsOneWidget);
      expect(requests, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
