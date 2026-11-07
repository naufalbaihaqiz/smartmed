import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartmed_nutricare/care_api.dart';
import 'package:smartmed_nutricare/main.dart';
import 'package:smartmed_nutricare/services/notification_service.dart';
import 'package:smartmed_nutricare/services/schedule_expander.dart';
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

  test(
    'expandCareSchedule starts at HH:mm on Day 1 and expands days until all medications run out',
    () {
      final base = DateTime(2026, 11, 7, 9, 0);
      final expanded = expandCareSchedule(
        baseDate: base,
        rutinitas: {'jam_bangun': '06:00', 'jam_tidur': '21:00'},
        prescriptions: [
          {
            'id': 1,
            'prescription_date': '2026-11-07',
            'start_at': '13:00',
            'status': 'active',
            'medications': [
              {
                'id': 1,
                'prescription_id': 1,
                'medicine_name': 'Amoxicillin',
                'dosage': '2 kapsul',
                'frequency': '3x sehari',
                'instruction': 'Sesudah makan',
                'quantity': 10, // 10 / 2 kapsul = tepat 5 dosis!
                'isAfterEat': true,
              },
            ],
          },
        ],
        templateReminders: [
          {
            'title': 'Sarapan: Bubur Ayam',
            'schedule_at': '2026-11-07T07:00:00',
            'status': 'pending',
            'prescription_id': null,
            'reminder_items': <Json>[],
          },
          {
            'title': 'Makan Siang: Sup Ikan',
            'schedule_at': '2026-11-07T12:30:00',
            'status': 'pending',
            'prescription_id': null,
            'reminder_items': <Json>[],
          },
          {
            'title': 'Makan Malam: Sayur Bening',
            'schedule_at': '2026-11-07T18:30:00',
            'status': 'pending',
            'prescription_id': null,
            'reminder_items': <Json>[],
          },
          {
            'title': 'Minum Amoxicillin',
            'schedule_at': '2026-11-07T07:30:00',
            'status': 'pending',
            'prescription_id': 1,
            'reminder_items': [
              {'medication_id': 1},
            ],
          },
        ],
      );

      final medReminders = expanded
          .where((r) => (r['reminder_items'] as List).isNotEmpty)
          .toList();

      // 10 kapsul dengan dosis 2 kapsul sekali minum -> tepat 5 kali minum (habis di Hari ke-2 malam!)
      expect(medReminders, hasLength(5));

      // Hari 1: mulai jam 13:00 (`start_at`), lanjut 19:00
      expect(
        DateTime.parse(medReminders[0]['schedule_at'] as String),
        DateTime(2026, 11, 7, 13, 0),
      );
      expect(
        DateTime.parse(medReminders[1]['schedule_at'] as String),
        DateTime(2026, 11, 7, 19, 0),
      );

      // Hari 2: kembali ke jadwal harian normal berjarak konsisten (07:30, 13:15, 19:00) lalu berhenti karena obat habis
      expect(
        DateTime.parse(medReminders[2]['schedule_at'] as String),
        DateTime(2026, 11, 8, 7, 30),
      );
      expect(
        DateTime.parse(medReminders[3]['schedule_at'] as String),
        DateTime(2026, 11, 8, 13, 15),
      );
      expect(
        DateTime.parse(medReminders[4]['schedule_at'] as String),
        DateTime(2026, 11, 8, 19, 0),
      );
      expect(medReminders.last['dose_number'], 5);
      expect(medReminders.last['total_doses'], 5);
    },
  );

  test(
    'expandCareSchedule menggabungkan obat dengan isAfterEat sama di waktu yang sama, dan memisahkan obat beda isAfterEat minimal 35 menit di sesi sama',
    () {
      final base = DateTime(2026, 11, 7, 6, 0);
      final expanded = expandCareSchedule(
        baseDate: base,
        rutinitas: {'jam_bangun': '06:00', 'jam_tidur': '21:00'},
        prescriptions: [
          {
            'id': 1,
            'prescription_date': '2026-11-07',
            'start_at': '07:00',
            'status': 'active',
            'medications': [
              {
                'id': 10,
                'prescription_id': 1,
                'medicine_name': 'Omeprazole',
                'dosage': '1 kapsul',
                'frequency': '1x sehari',
                'instruction': 'Sebelum makan',
                'quantity': 1,
                'isAfterEat': false,
              },
              {
                'id': 20,
                'prescription_id': 1,
                'medicine_name': 'Amlodipine',
                'dosage': '1 tablet',
                'frequency': '1x sehari',
                'instruction': 'Sesudah makan',
                'quantity': 1,
                'isAfterEat': true,
              },
              {
                'id': 30,
                'prescription_id': 1,
                'medicine_name': 'Paracetamol',
                'dosage': '1 tablet',
                'frequency': '1x sehari',
                'instruction': 'Sesudah makan',
                'quantity': 1,
                'isAfterEat': true,
              },
            ],
          },
        ],
        templateReminders: [
          {
            'title': 'Minum Omeprazole',
            'schedule_at': '2026-11-07T07:00:00',
            'status': 'pending',
            'prescription_id': 1,
            'reminder_items': [
              {'medication_id': 10},
            ],
          },
          {
            'title': 'Waktu Sarapan',
            'schedule_at': '2026-11-07T07:05:00',
            'status': 'pending',
            'prescription_id': null,
            'reminder_items': <Json>[],
          },
          {
            'title': 'Minum Amlodipine',
            'schedule_at': '2026-11-07T07:35:00',
            'status': 'pending',
            'prescription_id': 1,
            'reminder_items': [
              {'medication_id': 20},
            ],
          },
          {
            'title': 'Minum Paracetamol',
            'schedule_at': '2026-11-07T07:35:00',
            'status': 'pending',
            'prescription_id': 1,
            'reminder_items': [
              {'medication_id': 30},
            ],
          },
        ],
      );

      final medReminders = expanded
          .where((r) => (r['reminder_items'] as List).isNotEmpty)
          .toList();

      // Omeprazole (sebelum makan) di 07:00
      // Amlodipine & Paracetamol (keduanya sesudah makan pada 07:35) digabung jadi 1 card!
      // Total reminder obat menjadi tepat 2 card!
      expect(medReminders, hasLength(2));

      final omeprazoleCard = medReminders[0];
      final afterEatComboCard = medReminders[1];

      expect(omeprazoleCard['title'], contains('Omeprazole'));
      expect((omeprazoleCard['reminder_items'] as List), hasLength(1));

      // Amlodipine & Paracetamol digabung karena isAfterEat sama (true) dan jam sama (07:35)
      expect(afterEatComboCard['title'], contains('Amlodipine'));
      expect(afterEatComboCard['title'], contains('Paracetamol'));
      expect((afterEatComboCard['reminder_items'] as List), hasLength(2));

      // Verifikasi jarak antara obat sebelum makan (07:00) dan sesudah makan (07:35) tepat 35 menit
      final dtBefore = DateTime.parse(omeprazoleCard['schedule_at'] as String);
      final dtAfter = DateTime.parse(afterEatComboCard['schedule_at'] as String);
      expect(dtAfter.difference(dtBefore).inMinutes, greaterThanOrEqualTo(35));
    },
  );

  testWidgets(
    'completes care flow with HH:mm start_at, multi-day schedule until meds finish, premature completion lock, and arrival notifications',
    (tester) async {
      usePhone(tester);
      var fakeNow = DateTime(2026, 11, 7, 10, 0);
      final platformCalls = <({String method, Map<String, dynamic>? args})>[];
      final notificationService = NotificationService(
        nowProvider: () => fakeNow,
        platformInvoker: (method, args) async {
          platformCalls.add((method: method, args: args));
          return true;
        },
      );
      addTearDown(notificationService.dispose);

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
            expect(payload['request_id'], startsWith('req-meal-'));
            expect(payload['input_version'], 1);
            final hc = payload['health_condition'] as Json;
            expect(hc['name'], 'Pak Budi');
            expect(hc['condition_name'], 'Hipertensi');
            expect(hc['isTherePrescription'], true);
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
          expect(payload['request_id'], startsWith('req-sched-'));
          final prescriptions = payload['prescriptions'] as List;
          expect(prescriptions, hasLength(1));
          // Pastikan start_at dikirim sebagai format jam HH:mm ('13:00')
          expect((prescriptions.single as Json)['start_at'], '13:00');
          final meds = (prescriptions.single as Json)['medications'] as List;
          expect(meds, hasLength(2));

          return http.Response(
            jsonEncode({
              'status': 'draft',
              'input_version': payload['input_version'],
              'reminders': [
                {
                  'title': 'Makan Siang: Sup Ayam Rendah Garam',
                  'schedule_at': '12:30',
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
                  'schedule_at': '13:00',
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

      await tester.pumpWidget(
        TemanRawatApp(
          api: api,
          notificationService: notificationService,
          nowProvider: () => fakeNow,
        ),
      );
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

      // Step 3: Doctor's Prescription & Medications (Jam mulai minum = HH:mm)
      expect(find.text('Jam mulai minum'), findsOneWidget);
      await tapText(tester, '13:00');

      await enterFieldAt(tester, 'Nama obat', 'Amlodipine', index: 0);
      await enterFieldAt(tester, 'Takaran', '5 mg', index: 0);
      await enterFieldAt(tester, 'Jumlah', '2', index: 0);
      await enterFieldAt(tester, 'Frekuensi minum', '1x sehari', index: 0);
      await enterFieldAt(
        tester,
        'Instruksi minum obat',
        'Pagi setelah sarapan',
        index: 0,
      );

      // Add a second medication
      await tapText(tester, 'Tambah Obat Lainnya');
      await enterFieldAt(tester, 'Nama obat', 'Paracetamol', index: 1);
      await enterFieldAt(tester, 'Takaran', '500 mg', index: 1);
      await enterFieldAt(tester, 'Jumlah', '4', index: 1);
      await enterFieldAt(tester, 'Frekuensi minum', '3x sehari', index: 1);
      await enterFieldAt(
        tester,
        'Instruksi minum obat',
        'Sesudah makan',
        index: 1,
      );

      await tapText(tester, 'Selesai & Lanjut');

      // Step 4: Allergies, Food Preferences & Budget
      await tapText(tester, 'Kacang');
      await tapText(tester, 'Rendah garam');
      await enterFieldAt(tester, 'Budget makanan (Rupiah)', '5000');
      await tapText(tester, 'Selanjutnya');
      expect(
        find.text('Minimal budget harian adalah Rp 10.000.'),
        findsOneWidget,
      );

      await enterFieldAt(tester, 'Budget makanan (Rupiah)', '75000');
      await tapText(tester, 'Selanjutnya');

      // Step 5: Generated Meals shown from API
      expect(mealRequests, 1);
      expect(find.text('Sup Ayam Rendah Garam'), findsOneWidget);

      // Generate Schedule & Finish
      await tapText(tester, 'Buat Jadwal Makan & Obat');
      expect(scheduleRequests, 1);

      // Now on PatientCareDetailPage:
      // Amlodipine (qty 2, 1x/hari) & Paracetamol (qty 4, 3x/hari mulai 13:00) -> 2 hari jadwal!
      // Hari 1: 12:30 Makan Siang, 13:00 Amlodipine (1/2), 13:00 Paracetamol (1/4), 19:00 Paracetamol (2/4) = 4 item
      // Hari 2: 07:30 Amlodipine (2/2), 07:30 Paracetamol (3/4), 12:30 Makan Siang, 13:00 Paracetamol (4/4) = 4 item -> Total 8 jadwal!
      expect(
        find.text(
          'Jadwal disusun untuk 2 hari perawatan sampai seluruh obat habis.',
        ),
        findsOneWidget,
      );
      expect(find.text('Hari 1 · Hari Ini'), findsOneWidget);
      expect(find.text('Hari 2 · 8 Nov'), findsOneWidget);
      // Obat pada jam 13:00 Hari 1 & 07:30 Hari 2 digabungkan ke 1 card -> total 6 jadwal
      expect(find.text('Semua Hari (6)'), findsOneWidget);

      // Verifikasi tombol "Lihat Rekomendasi Menu & Resep" pada card jadwal makan
      expect(find.text('Lihat Rekomendasi Menu & Resep'), findsWidgets);
      await tapText(tester, 'Lihat Rekomendasi Menu & Resep');
      // Berpindah ke tab Resep
      expect(find.text('DAFTAR RESEP MAKANAN YANG DIGENERATE'), findsOneWidget);
      // Kembali ke tab Jadwal
      await tapText(tester, 'Jadwal (6)');

      // Pastikan alarm sistem operasi telah disinkronkan
      final syncCall = platformCalls
          .where((c) => c.method == 'syncNotifications')
          .last;
      expect((syncCall.args!['items'] as List), hasLength(6));

      // Karena jam saat ini masih 10:00 dan jadwal pertama pukul 12:30 / 13:00,
      // jadwal BELUM BISA ditandai selesai!
      expect(find.text('Menunggu Waktu Jadwal'), findsOneWidget);
      expect(find.text('Belum Waktunya'), findsWidgets);

      await tapText(tester, 'Minum Amlodipine & Paracetamol');
      expect(find.textContaining('Belum waktunya!'), findsOneWidget);
      // Masih 0/6 selesai
      expect(find.text('0/6'), findsOneWidget);

      // Majukan waktu ke pukul 13:01 di Hari 1 -> jadwal 12:30 dan 13:00 tiba!
      fakeNow = DateTime(2026, 11, 7, 13, 1);
      final alerts = notificationService.checkDueNotifications(now: fakeNow);
      await tester.pumpAndSettle();

      // Notifikasi muncul untuk jadwal yang waktunya sudah tiba (12:30 Makan + 13:00 Gabungan Obat)
      expect(alerts, hasLength(2));
      expect(find.textContaining('Waktunya'), findsWidgets);

      // Sekarang jadwal yang sudah waktunya BISA ditandai selesai, sedangkan pukul 19:00 belum!
      await tapText(tester, 'Selesaikan Jatuh Tempo (2)');
      expect(find.text('2/6'), findsOneWidget);

      // Majukan waktu hingga akhir Hari ke-2 (8 Nov pukul 23:59) sehingga seluruh jadwal telah tiba
      fakeNow = DateTime(2026, 11, 8, 23, 59);
      notificationService.dueTick.value++;
      await tester.pumpAndSettle();

      await tapText(tester, 'Selesaikan Jatuh Tempo (4)');
      expect(
        find.descendant(
          of: find.byType(ScheduleStatusBadge),
          matching: find.text('Jadwal Selesai'),
        ),
        findsOneWidget,
      );

      // Kembali ke Beranda -> status pasien menjadi Jadwal Selesai (6/6 jadwal, 2 Hari)
      await tapWidget(tester, find.byTooltip('Kembali ke Beranda'));
      expect(find.text('Pak Budi'), findsOneWidget);
      expect(find.text('2 Hari'), findsOneWidget);
      expect(find.text('6/6 jadwal'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ScheduleStatusBadge),
          matching: find.text('Jadwal Selesai'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'skips prescription step when patient does not have a doctor prescription',
    (tester) async {
      usePhone(tester);
      final fakeNow = DateTime(2026, 11, 7, 8, 0);
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

      await tester.pumpWidget(
        TemanRawatApp(api: api, nowProvider: () => fakeNow),
      );
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
