import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartmed_nutricare/care_api.dart';
import 'package:smartmed_nutricare/main.dart';
import 'package:smartmed_nutricare/widgets.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  await tapWidget(tester, find.text(text).first);
}

Future<void> tapWidget(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target, warnIfMissed: true);
  await tester.pumpAndSettle();
}

Future<void> enterFieldAt(
  WidgetTester tester,
  String label,
  String value, {
  int index = 0,
}) async {
  final field = find.widgetWithText(TextFormField, label).at(index);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

void usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'opens directly on Home without bottom navigation bar and shows + FAB',
    (tester) async {
      usePhone(tester);
      await tester.pumpWidget(const TemanRawatApp());
      await tester.pumpAndSettle();

      expect(find.text('Daftar Orang yang Dirawat'), findsOneWidget);
      expect(find.text('Belum Ada yang Dirawat'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'completes full care flow with prescription + multiple medications and updates Home status',
    (tester) async {
      usePhone(tester);
      final generatedMeal = <String, dynamic>{
        'recipe_name': 'Sup Ayam Rendah Garam',
        'description': 'Menu sehat tinggi protein rendah natrium',
        'servings': 1,
        'cooking_time': 25,
        'instructions': '1. Rebus ayam.\n2. Masukkan sayuran segar.',
        'source': 'AI TemanRawat',
        'ingredients': [
          {'ingredient_name': 'Dada ayam', 'quantity': '100 g'},
          {'ingredient_name': 'Wortel', 'quantity': '50 g'},
        ],
        'nutrition': {
          'calories': 240.0,
          'protein': 24.0,
          'carbohydrates': 14.0,
          'fat': 6.0,
        },
      };

      var mealRequests = 0;
      var scheduleRequests = 0;

      final api = CareApi(
        baseUrl: 'https://temanrawat.test',
        client: MockClient((request) async {
          final payload = jsonDecode(request.body) as Json;
          if (request.url.path == '/api/meal-plans/generate') {
            mealRequests++;
            final hc = payload['health_condition'] as Json;
            expect(hc['name'], 'Pak Budi');
            expect(hc['condition_name'], 'Hipertensi');
            expect(hc['age'], 62);
            expect(hc['weight'], 65.5);
            expect(hc['height'], 168.0);
            expect(hc['isTherePrescription'], true);
            expect(payload['allergies'], [
              {'type': 'Kacang'},
            ]);
            expect(payload['preferensi'], ['Rendah garam']);
            expect(payload['budget'], 75000.0);

            return http.Response(
              jsonEncode({
                'status': 'draft',
                'meals': [generatedMeal],
                'questions': <String>[],
                'review_notes': <String>[],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }

          expect(request.url.path, '/api/schedules/generate');
          scheduleRequests++;
          final prescriptions = payload['prescriptions'] as List;
          expect(prescriptions, hasLength(1));
          final meds =
              (prescriptions.single as Json)['medications'] as List;
          expect(meds, hasLength(2));
          expect((meds[0] as Json)['medicine_name'], 'Amlodipine');
          expect((meds[1] as Json)['medicine_name'], 'Paracetamol');

          return http.Response(
            jsonEncode({
              'status': 'draft',
              'input_version': payload['input_version'],
              'reminders': [
                {
                  'title': 'Sarapan: Sup Ayam Rendah Garam',
                  'schedule_at': '07:00',
                  'status': 'pending',
                  'prescription_id': null,
                  'reminder_items': <Json>[],
                },
                {
                  'title': 'Minum Amlodipine',
                  'schedule_at': '07:30',
                  'status': 'pending',
                  'prescription_id': 1,
                  'reminder_items': [
                    {'medication_id': 1},
                  ],
                },
                {
                  'title': 'Minum Paracetamol',
                  'schedule_at': '12:30',
                  'status': 'pending',
                  'prescription_id': 1,
                  'reminder_items': [
                    {'medication_id': 2},
                  ],
                },
              ],
              'conflicts': <String>[],
              'questions': <String>[],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(api.close);

      await tester.pumpWidget(TemanRawatApp(api: api));
      await tester.pumpAndSettle();

      // Tap + button at bottom right
      await tapWidget(tester, find.byType(FloatingActionButton));

      // Step 1: Patient Name
      await enterFieldAt(tester, 'Nama orang yang dirawat', 'Pak Budi');
      await tapText(tester, 'Selanjutnya');

      // Step 2: Health Condition + Has Prescription = Yes
      await enterFieldAt(tester, 'Kondisi kesehatan', 'Hipertensi');
      await enterFieldAt(tester, 'Usia (tahun)', '62');
      await enterFieldAt(tester, 'Berat (kg)', '65,5');
      await enterFieldAt(tester, 'Tinggi (cm)', '168');
      await tapText(tester, 'Ya, Memiliki Resep Dokter');
      await tapText(tester, 'Selanjutnya');

      // Step 3: Doctor's Prescription & Medications
      await enterFieldAt(tester, 'Nama obat', 'Amlodipine', index: 0);
      await enterFieldAt(tester, 'Dosis', '5 mg', index: 0);
      await enterFieldAt(tester, 'Jumlah', '30', index: 0);
      await enterFieldAt(tester, 'Frekuensi minum', '1x sehari', index: 0);
      await enterFieldAt(
        tester,
        'Instruksi waktu minum',
        'Pagi setelah sarapan',
        index: 0,
      );

      // Add a second medication
      await tapText(tester, 'Tambah Obat Lainnya');
      await enterFieldAt(tester, 'Nama obat', 'Paracetamol', index: 1);
      await enterFieldAt(tester, 'Dosis', '500 mg', index: 1);
      await enterFieldAt(tester, 'Jumlah', '10', index: 1);
      await enterFieldAt(tester, 'Frekuensi minum', '3x sehari', index: 1);
      await enterFieldAt(
        tester,
        'Instruksi waktu minum',
        'Bila demam sesudah makan',
        index: 1,
      );

      await tapText(tester, 'Selesai & Lanjut');

      // Step 4: Allergies, Food Preferences & Budget
      await tapText(tester, 'Kacang');
      await tapText(tester, 'Rendah garam');
      await enterFieldAt(tester, 'Budget makanan (Rupiah)', '75000');
      await tapText(tester, 'Selanjutnya');

      // Step 5: Generated Meals shown from API
      expect(mealRequests, 1);
      expect(find.text('Sup Ayam Rendah Garam'), findsOneWidget);

      // Generate Schedule & Finish
      await tapText(tester, 'Buat Jadwal Makan & Obat');
      expect(scheduleRequests, 1);

      // Now on PatientCareDetailPage (Jadwal & Resep)
      expect(find.text('Jadwal & Resep'), findsOneWidget);
      expect(find.text('Sarapan: Sup Ayam Rendah Garam'), findsOneWidget);
      expect(find.text('Minum Amlodipine'), findsOneWidget);
      expect(find.text('Minum Paracetamol'), findsOneWidget);

      // Switch to Resep tab to verify generated recipe & prescription list
      await tapText(tester, 'Resep (1)');
      expect(find.text('Sup Ayam Rendah Garam'), findsOneWidget);
      expect(find.text('Amlodipine'), findsOneWidget);
      expect(find.text('Paracetamol'), findsOneWidget);

      // Return to Home -> verify patient listed with status Belum Selesai
      await tapWidget(tester, find.byTooltip('Kembali ke Beranda'));
      expect(find.text('Pak Budi'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ScheduleStatusBadge),
          matching: find.text('Belum Selesai'),
        ),
        findsOneWidget,
      );
      expect(find.text('0/3 jadwal'), findsOneWidget);

      // Re-open Pak Budi, complete all schedules, and verify Home shows Jadwal Selesai
      await tapText(tester, 'Pak Budi');
      await tapText(tester, 'Selesaikan Semua');
      expect(
        find.descendant(
          of: find.byType(ScheduleStatusBadge),
          matching: find.text('Jadwal Selesai'),
        ),
        findsOneWidget,
      );

      await tapWidget(tester, find.byTooltip('Kembali ke Beranda'));
      expect(find.text('Pak Budi'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ScheduleStatusBadge),
          matching: find.text('Jadwal Selesai'),
        ),
        findsOneWidget,
      );
      expect(find.text('3/3 jadwal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'skips prescription step when patient does not have a doctor prescription',
    (tester) async {
      usePhone(tester);
      final api = CareApi(
        baseUrl: 'https://temanrawat.test',
        client: MockClient((request) async {
          final payload = jsonDecode(request.body) as Json;
          if (request.url.path == '/api/meal-plans/generate') {
            final hc = payload['health_condition'] as Json;
            expect(hc['isTherePrescription'], false);
            return http.Response(
              jsonEncode({
                'status': 'draft',
                'meals': [
                  {
                    'recipe_name': 'Bubur Oat Pisang',
                    'servings': 1,
                    'cooking_time': 15,
                    'instructions': 'Masak oat dengan air hangat.',
                    'ingredients': [
                      {'ingredient_name': 'Oat', 'quantity': '50 g'},
                    ],
                  },
                ],
                'questions': <String>[],
                'review_notes': <String>[],
              }),
              200,
            );
          }
          expect(payload['prescriptions'], isEmpty);
          return http.Response(
            jsonEncode({
              'status': 'draft',
              'input_version': payload['input_version'],
              'reminders': [
                {
                  'title': 'Sarapan: Bubur Oat Pisang',
                  'schedule_at': '07:30',
                  'status': 'pending',
                  'prescription_id': null,
                  'reminder_items': <Json>[],
                },
              ],
              'conflicts': <String>[],
              'questions': <String>[],
            }),
            200,
          );
        }),
      );
      addTearDown(api.close);

      await tester.pumpWidget(TemanRawatApp(api: api));
      await tester.pumpAndSettle();

      await tapWidget(tester, find.byType(FloatingActionButton));
      await enterFieldAt(tester, 'Nama orang yang dirawat', 'Ibu Rina');
      await tapText(tester, 'Selanjutnya');

      await enterFieldAt(tester, 'Kondisi kesehatan', 'Pemulihan');
      await enterFieldAt(tester, 'Usia (tahun)', '55');
      await enterFieldAt(tester, 'Berat (kg)', '54');
      await enterFieldAt(tester, 'Tinggi (cm)', '156');
      await tapText(tester, 'Tidak Memiliki Resep Dokter');
      await tapText(tester, 'Selanjutnya');

      // Directly on Allergies, Preferences & Budget step (prescription skipped)
      expect(
        find.text('Alergi, preferensi, dan budget makanan'),
        findsOneWidget,
      );
      await enterFieldAt(tester, 'Budget makanan (Rupiah)', '50000');
      await tapText(tester, 'Selanjutnya');

      expect(find.text('Bubur Oat Pisang'), findsOneWidget);
      await tapText(tester, 'Buat Jadwal Makan & Obat');

      expect(find.text('Jadwal & Resep'), findsOneWidget);
      await tapWidget(tester, find.byTooltip('Kembali ke Beranda'));
      expect(find.text('Ibu Rina'), findsOneWidget);
      expect(find.text('Tanpa Resep'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
