import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'care_api.dart';
import 'care_forms.dart';
import 'models/care_plan.dart';

/// Fixtures dan simulasi server untuk pratinjau web (`TEMANRAWAT_WEB_DEMO=true`).
class WebDemo {
  WebDemo({this.withPrescription = true});

  final bool withPrescription;

  static List<Json> get sampleMeals => [
    {
      'recipe_name': 'Bubur Ayam Kaldu Lembut',
      'description': 'Menu sarapan hangat tinggi protein dan mudah dicerna.',
      'servings': 1,
      'cooking_time': 25,
      'instructions':
          '1. Masak beras bersama kaldu ayam rendah garam hingga lembut.\n'
          '2. Masukkan suwiran dada ayam dan wortel cincang.\n'
          '3. Sajikan hangat dengan taburan seledri segar.',
      'source': 'AI TemanRawat',
      'ingredients': [
        {'ingredient_name': 'Beras putih', 'quantity': '50 g'},
        {'ingredient_name': 'Dada ayam tanpa kulit', 'quantity': '60 g'},
        {'ingredient_name': 'Wortel parut', 'quantity': '30 g'},
      ],
      'nutrition': {
        'calories': 265,
        'protein': 18,
        'carbohydrates': 38,
        'fat': 4.5,
      },
    },
    {
      'recipe_name': 'Nasi Tim Ikan & Bayam',
      'description': 'Menu makan siang kaya zat besi dengan tekstur lembut.',
      'servings': 1,
      'cooking_time': 30,
      'instructions':
          '1. Kukus nasi lembek bersama fillet ikan kukus.\n'
          '2. Tambahkan daun bayam muda di 5 menit terakhir.\n'
          '3. Hidangkan selagi hangat.',
      'source': 'AI TemanRawat',
      'ingredients': [
        {'ingredient_name': 'Nasi putih lembut', 'quantity': '120 g'},
        {'ingredient_name': 'Fillet ikan nila', 'quantity': '75 g'},
        {'ingredient_name': 'Daun bayam segar', 'quantity': '50 g'},
      ],
      'nutrition': {
        'calories': 310,
        'protein': 22,
        'carbohydrates': 42,
        'fat': 5.0,
      },
    },
    {
      'recipe_name': 'Sup Tahu Sayur Bening',
      'description': 'Menu makan malam ringan yang nyaman di lambung.',
      'servings': 1,
      'cooking_time': 20,
      'instructions':
          '1. Didihkan air bersama bawang putih geprek.\n'
          '2. Masukkan wortel dan labu siam hingga empuk.\n'
          '3. Masukkan tahu putih potong dadu, masak sebentar lalu angkat.',
      'source': 'AI TemanRawat',
      'ingredients': [
        {'ingredient_name': 'Tahu putih sutra', 'quantity': '80 g'},
        {'ingredient_name': 'Labu siam & wortel', 'quantity': '100 g'},
      ],
      'nutrition': {
        'calories': 185,
        'protein': 11,
        'carbohydrates': 18,
        'fat': 6.0,
      },
    },
  ];

  static String _todayTime(int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute).toIso8601String();
  }

  static List<PatientCarePlan> sampleCarePlans() {
    final today = formatIsoDate(DateTime.now());
    return [
      PatientCarePlan(
        id: 'demo-pak-arif',
        patientName: 'Pak Arif',
        healthCondition: {
          'condition_name': 'Hipertensi',
          'name': 'Pak Arif',
          'diagnosis': 'Hipertensi tingkat 1',
          'notes': 'Kurangi konsumsi garam berlebih',
          'age': 65,
          'weight': 62.0,
          'height': 165.0,
          'isTherePrescription': true,
        },
        prescriptions: [
          {
            'id': 1,
            'prescription_date': today,
            'start_at': '07:30',
            'status': 'active',
            'notes': 'Kontrol tekanan darah rutin',
            'medications': [
              {
                'id': 1,
                'prescription_id': 1,
                'medicine_name': 'Amlodipine',
                'dosage': '5 mg',
                'frequency': '1x sehari',
                'instruction': 'Pagi hari setelah sarapan',
                'quantity': 30,
                'notes': null,
                'isAfterEat': true,
              },
            ],
          },
        ],
        allergies: const [
          {'type': 'Kacang'},
        ],
        preferensi: const ['Rendah garam', 'Tekstur lembut'],
        budget: 60000,
        meals: sampleMeals,
        reminders: [
          {
            'title': 'Sarapan: Bubur Ayam Kaldu Lembut',
            'schedule_at': _todayTime(7, 0),
            'status': 'completed',
            'prescription_id': null,
            'reminder_items': <Json>[],
          },
          {
            'title': 'Minum Amlodipine',
            'schedule_at': _todayTime(7, 30),
            'status': 'pending',
            'prescription_id': 1,
            'reminder_items': const [
              {'medication_id': 1},
            ],
          },
          {
            'title': 'Makan Siang: Nasi Tim Ikan & Bayam',
            'schedule_at': _todayTime(12, 30),
            'status': 'pending',
            'prescription_id': null,
            'reminder_items': <Json>[],
          },
          {
            'title': 'Makan Malam: Sup Tahu Sayur Bening',
            'schedule_at': _todayTime(18, 30),
            'status': 'pending',
            'prescription_id': null,
            'reminder_items': <Json>[],
          },
        ],
      ),
      PatientCarePlan(
        id: 'demo-ibu-sari',
        patientName: 'Ibu Sari',
        healthCondition: {
          'condition_name': 'Pemulihan Pasca Rawat',
          'name': 'Ibu Sari',
          'diagnosis': null,
          'notes': 'Perlu makanan hangat',
          'age': 68,
          'weight': 54.0,
          'height': 154.0,
          'isTherePrescription': false,
        },
        prescriptions: const [],
        allergies: const [],
        preferensi: const ['Berkuah hangat', 'Makanan rumahan'],
        budget: 50000,
        meals: sampleMeals.take(2).toList(),
        reminders: [
          {
            'title': 'Sarapan: Bubur Ayam Kaldu Lembut',
            'schedule_at': _todayTime(7, 30),
            'status': 'completed',
            'prescription_id': null,
            'reminder_items': <Json>[],
          },
          {
            'title': 'Makan Siang: Nasi Tim Ikan & Bayam',
            'schedule_at': _todayTime(12, 30),
            'status': 'completed',
            'prescription_id': null,
            'reminder_items': <Json>[],
          },
        ],
      ),
    ];
  }

  CareApi createApi() => CareApi(
    baseUrl: 'https://temanrawat-preview.invalid',
    client: MockClient((request) async {
      final input = jsonDecode(request.body) as Json;
      if (request.url.path == '/api/meal-plans/generate') {
        return http.Response(
          jsonEncode({
            'status': 'draft',
            'meals': sampleMeals,
            'questions': <String>[],
            'review_notes': ['Menu disimulasikan pada mode pratinjau demo.'],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (request.url.path == '/api/schedules/generate') {
        final prescriptions = (input['prescriptions'] as List? ?? const []);
        final reminders = <Json>[
          {
            'title': 'Sarapan: Bubur Ayam Kaldu Lembut',
            'schedule_at': '07:00',
            'status': 'pending',
            'prescription_id': null,
            'reminder_items': <Json>[],
          },
          for (final p in prescriptions.whereType<Map>())
            for (var idx = 0;
                idx < ((p['medications'] as List?)?.length ?? 0);
                idx++)
              {
                'title':
                    'Minum ${((p['medications'] as List)[idx] as Map)['medicine_name']}',
                'schedule_at': '0${7 + (idx % 2)}:30',
                'status': 'pending',
                'prescription_id': p['id'],
                'reminder_items': [
                  {
                    'medication_id':
                        ((p['medications'] as List)[idx] as Map)['id'],
                  },
                ],
              },
          {
            'title': 'Makan Siang: Nasi Tim Ikan & Bayam',
            'schedule_at': '12:30',
            'status': 'pending',
            'prescription_id': null,
            'reminder_items': <Json>[],
          },
          {
            'title': 'Makan Malam: Sup Tahu Sayur Bening',
            'schedule_at': '18:30',
            'status': 'pending',
            'prescription_id': null,
            'reminder_items': <Json>[],
          },
        ];
        return http.Response(
          jsonEncode({
            'status': 'draft',
            'input_version': input['input_version'],
            'reminders': reminders,
            'questions': <String>[],
            'conflicts': <String>[],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response('Not Found', 404);
    }),
  );
}
