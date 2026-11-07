import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'care_api.dart';

/// Fixtures for the explicitly enabled web preview.
class WebDemo {
  WebDemo({required this.withPrescription});

  final bool withPrescription;
  String get caregiver => withPrescription ? 'Dimas' : 'Rina';
  String get patient => withPrescription ? 'Pak Arif' : 'Ibu Sari';

  Json get mealInput => {
    'health_condition': <String, dynamic>{
      'condition_name': 'Pemulihan setelah konsultasi',
      'notes': 'Skenario fiktif untuk pratinjau.',
      'age': withPrescription ? 65 : 68,
      'weight': 54.0,
      'height': 154.0,
      'isTherePrescription': withPrescription,
    },
    'allergies': <Json>[
      {'type': 'Kacang'},
    ],
    'budget': 45000.0,
    'stok_bahan': ['Beras', 'Wortel', 'Tahu'],
    'preferensi': ['Makanan rumahan', 'Tekstur lembut'],
  };

  List<Json> get prescriptions => [
    if (withPrescription)
      {
        'id': 1,
        'prescription_date': DateTime.now().toIso8601String().split('T').first,
        'start_at': DateTime.now().toIso8601String().split('T').first,
        'status': 'active',
        'notes': 'Resep fiktif untuk pratinjau.',
        'medications': <Json>[
          {
            'id': 1,
            'prescription_id': 1,
            'medicine_name': 'Obat contoh A',
            'dosage': 'Sesuai catatan contoh',
            'frequency': 'Sekali sehari',
            'instruction': 'Pengingat fiktif setelah sarapan.',
            'quantity': 7,
            'isAfterEat': true,
          },
        ],
      },
  ];

  List<Json> get meals => [
    {
      'recipe_name': 'Bubur ayam rumahan',
      'description': 'Menu sarapan dalam skenario perawatan.',
      'servings': 1,
      'cooking_time': 25,
      'instructions': 'Masak beras dan kaldu hingga lembut. Tambahkan ayam matang saat disajikan.',
      'source': 'Masak di rumah',
      'ingredients': [
        {'ingredient_name': 'Beras', 'quantity': '50 g'},
        {'ingredient_name': 'Ayam', 'quantity': '60 g'},
      ],
      'nutrition': {
        'calories': 265,
        'protein': 16,
        'carbohydrates': 38,
        'fat': 5,
      },
    },
    {
      'recipe_name': 'Nasi tim ayam sayur',
      'description': 'Menu makan siang dalam skenario perawatan.',
      'servings': 1,
      'cooking_time': 35,
      'instructions': 'Kukus nasi dengan ayam dan sayur sampai matang.',
      'source': 'Masak di rumah',
      'ingredients': [
        {'ingredient_name': 'Nasi', 'quantity': '150 g'},
        {'ingredient_name': 'Wortel', 'quantity': '40 g'},
      ],
    },
    {
      'recipe_name': 'Sup tahu sayur',
      'description': 'Menu makan malam dalam skenario perawatan.',
      'servings': 1,
      'cooking_time': 30,
      'instructions':
          'Masak sayur dan tahu hingga matang, lalu sajikan hangat.',
      'source': 'Masak di rumah',
      'ingredients': [
        {'ingredient_name': 'Tahu', 'quantity': '80 g'},
        {'ingredient_name': 'Sayur', 'quantity': '100 g'},
      ],
    },
  ];

  List<Json> reminders({bool completedBreakfast = false, Json? medication}) {
    final today = DateTime.now();
    String time(int hour, int minute) => DateTime(
      today.year,
      today.month,
      today.day,
      hour,
      minute,
    ).toIso8601String();
    return [
      {
        'title': 'Sarapan',
        'schedule_at': time(7, 30),
        'status': completedBreakfast ? 'completed' : 'pending',
        'reminder_items': <Json>[],
      },
      if (medication != null)
        {
          'title': 'Cek jadwal obat',
          'schedule_at': time(8, 0),
          'status': 'pending',
          'prescription_id': medication['prescription_id'],
          'reminder_items': <Json>[
            {'medication_id': medication['id']},
          ],
        },
      {
        'title': 'Makan siang',
        'schedule_at': time(12, 30),
        'status': 'pending',
        'reminder_items': <Json>[],
      },
      {
        'title': 'Waktu istirahat',
        'schedule_at': time(13, 15),
        'status': 'pending',
        'reminder_items': <Json>[],
      },
      {
        'title': 'Makan malam',
        'schedule_at': time(18, 30),
        'status': 'pending',
        'reminder_items': <Json>[],
      },
    ];
  }

  List<Json> get agenda => reminders(
    completedBreakfast: true,
    medication: withPrescription
        ? (prescriptions.single['medications'] as List<Json>).single
        : null,
  );

  CareApi createApi() => CareApi(
    baseUrl: 'https://temanrawat-preview.invalid',
    client: MockClient((request) async {
      final input = jsonDecode(request.body) as Json;
      final response = switch (request.url.path) {
        '/api/meal-plans/generate' => {
          'status': 'draft',
          'meals': meals,
          'questions': [],
          'review_notes': ['Ini adalah draf simulasi untuk preview web.'],
        },
        '/api/schedules/generate' => {
          'status': 'draft',
          'input_version': input['input_version'],
          'reminders': reminders(medication: _firstMedication(input)),
          'questions': [],
          'conflicts': [],
        },
        _ => null,
      };
      return http.Response(
        jsonEncode(response),
        response == null ? 404 : 200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );

  Json? _firstMedication(Json input) {
    final prescriptions = input['prescriptions'] as List;
    for (final prescription in prescriptions) {
      final medications = prescription['medications'] as List;
      if (medications.isNotEmpty) return medications.first as Json;
    }
    return null;
  }
}
