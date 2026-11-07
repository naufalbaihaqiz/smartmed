import 'package:flutter_test/flutter_test.dart';
import 'package:smartmed_nutricare/services/schedule_expander.dart';

void main() {
  group('Schedule Expander Rules Test', () {
    test('Deduplikasi kategori makan: tidak boleh ada kategori yang sama dalam 1 hari', () {
      final templates = [
        {
          'id': 1,
          'title': 'Menu Ayam Geprek Pedas',
          'schedule_at': '2026-11-08T07:00:00',
        },
        {
          'id': 2,
          'title': 'Menu Bubur Ayam Gurih',
          'schedule_at': '2026-11-08T08:30:00', // Kategori Sarapan kedua di hari yang sama
        },
        {
          'id': 3,
          'title': 'Menu Nasi Goreng Spesial',
          'schedule_at': '2026-11-08T12:00:00', // Makan Siang
        },
        {
          'id': 4,
          'title': 'Menu Sup Ikan',
          'schedule_at': '2026-11-08T18:00:00', // Makan Malam
        },
      ];

      // Kasus tanpa resep obat:
      final resultNoMeds = expandCareSchedule(
        templateReminders: templates,
        prescriptions: [],
        rutinitas: {'jam_bangun': '06:00', 'jam_tidur': '22:00'},
      );

      final titlesNoMeds = resultNoMeds.map((r) => r['title']).toList();
      expect(titlesNoMeds, ['Waktu Sarapan', 'Waktu Makan Siang', 'Waktu Makan Malam']);
      // Pastikan sarapan kedua diabaikan
      expect(titlesNoMeds.where((t) => t == 'Waktu Sarapan').length, 1);
    });

    test('Aturan jarak 35 menit antar obat beda isAfterEat dan penggabungan isAfterEat sama', () {
      final templates = [
        {
          'id': 1,
          'title': 'Waktu Sarapan',
          'schedule_at': '2026-11-08T07:05:00',
        },
        {
          'id': 2,
          'title': 'Minum Obat: Omeprazole',
          'schedule_at': '2026-11-08T07:00:00',
          'prescription_id': 10,
          'reminder_items': [{'medication_id': 1}],
        },
        {
          'id': 3,
          'title': 'Minum Obat: Paracetamol',
          'schedule_at': '2026-11-08T07:00:00', // Awalnya AI jadwalkan jam 07:00 padahal sesudah makan!
          'prescription_id': 10,
          'reminder_items': [{'medication_id': 2}],
        },
        {
          'id': 4,
          'title': 'Minum Obat: Vitamin C',
          'schedule_at': '2026-11-08T07:00:00', // Sebelum makan juga di jam yang sama
          'prescription_id': 10,
          'reminder_items': [{'medication_id': 3}],
        },
      ];

      final prescriptions = [
        {
          'id': 10,
          'start_at': '07:00',
          'medications': [
            {
              'id': 1,
              'medicine_name': 'Omeprazole',
              'frequency': '1x sehari',
              'quantity': 1,
              'dosage': '1 tablet',
              'isAfterEat': false, // Sebelum makan
            },
            {
              'id': 2,
              'medicine_name': 'Paracetamol',
              'frequency': '1x sehari',
              'quantity': 1,
              'dosage': '1 tablet',
              'isAfterEat': true, // Sesudah makan
            },
            {
              'id': 3,
              'medicine_name': 'Vitamin C',
              'frequency': '1x sehari',
              'quantity': 1,
              'dosage': '1 tablet',
              'isAfterEat': false, // Sebelum makan
            },
          ],
        }
      ];

      final result = expandCareSchedule(
        templateReminders: templates,
        prescriptions: prescriptions,
        rutinitas: {'jam_bangun': '06:00', 'jam_tidur': '22:00'},
      );

      // Cari jadwal obat sebelum makan (Omeprazole & Vitamin C)
      final beforeEatReminders = result.where((r) =>
        r['reminder_items'] != null &&
        (r['reminder_items'] as List).isNotEmpty &&
        r['isAfterEat'] == false
      ).toList();

      // Karena sama-sama isAfterEat=false dan jam sama (07:00), harus digabung jadi 1 card
      expect(beforeEatReminders.length, 1);
      final combinedItems = beforeEatReminders.first['reminder_items'] as List;
      expect(combinedItems.length, 2); // 2 obat digabung dalam 1 jadwal card

      // Cari jadwal obat sesudah makan (Paracetamol)
      final afterEatReminders = result.where((r) =>
        r['reminder_items'] != null &&
        (r['reminder_items'] as List).isNotEmpty &&
        r['isAfterEat'] == true
      ).toList();

      expect(afterEatReminders.length, 1);
      final dtBefore = DateTime.parse(beforeEatReminders.first['schedule_at'] as String);
      final dtAfter = DateTime.parse(afterEatReminders.first['schedule_at'] as String);

      // Jarak minimal antara sebelum makan dan setelah makan harus >= 35 menit
      final diff = dtAfter.difference(dtBefore).inMinutes;
      expect(diff >= 35, isTrue);

      // Jadwal makan harus tepat 1 sarapan di hari 1
      final meals = result.where((r) => r['prescription_id'] == null).toList();
      final breakfastMeals = meals.where((r) => r['title'] == 'Waktu Sarapan').toList();
      expect(breakfastMeals.length, 1);
    });

    test('Sinkronisasi Hari Pertama: Obat sebelum makan harus selalu SEBELUM jadwal makan meskipun start_at 08:00', () {
      final templates = [
        {
          'id': 1,
          'title': 'Waktu Sarapan',
          'schedule_at': '2026-11-08T07:05:00', // Dari AI template jam 07:05
        },
        {
          'id': 2,
          'title': 'Minum Obat: bat',
          'schedule_at': '2026-11-08T07:00:00',
          'prescription_id': 1,
          'reminder_items': [{'medication_id': 101}],
        },
        {
          'id': 3,
          'title': 'Minum Obat: obat',
          'schedule_at': '2026-11-08T07:35:00',
          'prescription_id': 1,
          'reminder_items': [{'medication_id': 102}],
        },
      ];

      final prescriptions = [
        {
          'id': 1,
          'start_at': '08:00', // Pengguna memulai minum jam 08:00 di hari ke-1
          'medications': [
            {
              'id': 101,
              'medicine_name': 'bat',
              'frequency': '3x sehari',
              'quantity': 6,
              'dosage': '2 tablet',
              'isAfterEat': false, // Sebelum makan
            },
            {
              'id': 102,
              'medicine_name': 'obat',
              'frequency': '3x sehari',
              'quantity': 3,
              'dosage': '1 tablet',
              'isAfterEat': true, // Sesudah makan
            },
          ],
        }
      ];

      final result = expandCareSchedule(
        baseDate: DateTime(2026, 11, 8),
        templateReminders: templates,
        prescriptions: prescriptions,
        rutinitas: {'jam_bangun': '06:00', 'jam_tidur': '22:00'},
      );

      // Filter pengingat di Hari ke-1 (day_number == 1)
      final day1 = result.where((r) => r['day_number'] == 1).toList();

      final day1BeforeEat = day1.firstWhere(
        (r) => r['reminder_items'] != null && (r['reminder_items'] as List).isNotEmpty && r['isAfterEat'] == false,
      );
      final day1Meal = day1.firstWhere(
        (r) => r['title'] == 'Waktu Sarapan',
      );
      final day1AfterEat = day1.firstWhere(
        (r) => r['reminder_items'] != null && (r['reminder_items'] as List).isNotEmpty && r['isAfterEat'] == true,
      );

      final dtMedBefore = DateTime.parse(day1BeforeEat['schedule_at'] as String);
      final dtMeal = DateTime.parse(day1Meal['schedule_at'] as String);
      final dtMedAfter = DateTime.parse(day1AfterEat['schedule_at'] as String);

      // 1. Obat sebelum makan harus jam 08:00 (sesuai start_at)
      expect(dtMedBefore.hour, 8);
      expect(dtMedBefore.minute, 0);

      // 2. WAKTU SARAPAN HARUS TEPAT 5 MENIT SETELAH OBAT SEBELUM MAKAN (08:05, BUKAN 07:05!)
      expect(dtMeal.hour, 8);
      expect(dtMeal.minute, 5);
      expect(dtMedBefore.isBefore(dtMeal), isTrue, reason: 'Obat sebelum makan WAJIB diminum sebelum jadwal makan!');

      // 3. Obat sesudah makan harus tepat 30 menit setelah sarapan (08:35)
      expect(dtMedAfter.hour, 8);
      expect(dtMedAfter.minute, 35);
      expect(dtMeal.isBefore(dtMedAfter), isTrue, reason: 'Obat sesudah makan WAJIB diminum setelah jadwal makan!');

      // Jeda obat sebelum makan ke sesudah makan tepat 35 menit
      expect(dtMedAfter.difference(dtMedBefore).inMinutes, 35);
    });

    test('Aturan Pembagian Waktu Bangun ke Tidur Konsisten & Makan Malam Maksimal 2 Jam Sebelum Tidur', () {
      final templates = [
        {
          'id': 1,
          'title': 'Waktu Sarapan',
          'schedule_at': '2026-11-08T07:05:00',
        },
        {
          'id': 2,
          'title': 'Minum Obat: Amoxicillin',
          'schedule_at': '2026-11-08T07:00:00',
          'prescription_id': 1,
          'reminder_items': [{'medication_id': 1}],
        },
        {
          'id': 3,
          'title': 'Minum Obat: Captopril',
          'schedule_at': '2026-11-08T07:00:00',
          'prescription_id': 2,
          'reminder_items': [{'medication_id': 2}],
        },
        {
          'id': 4,
          'title': 'Waktu Makan Malam',
          'schedule_at': '2026-11-08T20:30:00', // Template awal 20:30 (terlalu malam jika tidur 21:00)
        },
      ];

      final prescriptions = [
        {
          'id': 1,
          'start_at': '07:00',
          'medications': [
            {
              'id': 1,
              'medicine_name': 'Amoxicillin',
              'frequency': '3x sehari', // Dibagi konsisten antara bangun dan sebelum tidur!
              'quantity': 6,
              'dosage': '1 kapsul',
              'isAfterEat': false,
            },
          ],
        },
        {
          'id': 2,
          'start_at': '07:00',
          'medications': [
            {
              'id': 2,
              'medicine_name': 'Captopril',
              'frequency': '2x sehari', // Pagi dan malam berjarak 12 jam!
              'quantity': 4,
              'dosage': '1 tablet',
              'isAfterEat': false,
            },
          ],
        },
      ];

      final result = expandCareSchedule(
        baseDate: DateTime(2026, 11, 8),
        templateReminders: templates,
        prescriptions: prescriptions,
        rutinitas: {'jam_bangun': '06:00', 'jam_tidur': '21:00'}, // Tidur jam 21:00
      );

      // Hari 1 untuk Amoxicillin (3x sehari)
      final amoxDay1 = result.where((r) {
        final items = r['reminder_items'] as List? ?? [];
        return r['day_number'] == 1 && items.any((it) => it['medication_id'] == 1);
      }).toList();

      expect(amoxDay1.length, 3);
      final amoxTimes = amoxDay1.map((r) => DateTime.parse(r['schedule_at'] as String)).toList();
      // Jarak antar dosis 1 -> 2 dan 2 -> 3 konsisten sama rata
      final diff1 = amoxTimes[1].difference(amoxTimes[0]).inMinutes;
      final diff2 = amoxTimes[2].difference(amoxTimes[1]).inMinutes;
      expect((diff1 - diff2).abs() <= 15, isTrue, reason: 'Jarak antar dosis harus konsisten!');

      // Pastikan jadwal makan malam paling lama 2 jam sebelum jam tidur (21:00 - 2 jam = 19:00)
      final dinnerReminder = result.firstWhere((r) => r['title'] == 'Waktu Makan Malam' && r['day_number'] == 1);
      final dtDinner = DateTime.parse(dinnerReminder['schedule_at'] as String);
      final latestDinnerAllowed = DateTime(2026, 11, 8, 19, 0);
      expect(
        dtDinner.isAfter(latestDinnerAllowed),
        isFalse,
        reason: 'Waktu makan malam tidak boleh melewati 2 jam sebelum jam tidur (maksimal 19:00 jika tidur 21:00)',
      );

      // Hari 1 untuk Captopril (2x sehari)
      final captoDay1 = result.where((r) {
        final items = r['reminder_items'] as List? ?? [];
        return r['day_number'] == 1 && items.any((it) => it['medication_id'] == 2);
      }).toList();

      expect(captoDay1.length, 2);
      final captoTimes = captoDay1.map((r) => DateTime.parse(r['schedule_at'] as String)).toList();
      expect(captoTimes[1].difference(captoTimes[0]).inHours >= 11, isTrue);
    });
  });
}
