import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../care_api.dart';
import '../database/database_helper.dart';
import '../database/database_tables.dart';

/// Menyimpan seluruh informasi perawatan satu orang pasien yang tersinkronisasi
/// 1-ke-1 dengan skema API dan tabel SQLite lokal.
class PatientCarePlan {
  PatientCarePlan({
    required this.id,
    required this.patientName,
    required this.healthCondition,
    required this.prescriptions,
    required this.allergies,
    required this.preferensi,
    required this.budget,
    this.routineNotes = '',
    Json? rutinitas,
    required this.meals,
    required this.reminders,
    this.aiNotes = const [],
    DateTime? createdAt,
  }) : rutinitas =
           rutinitas ??
           {
             'jam_bangun': '06:00',
             'jam_tidur': '21:00',
             if (routineNotes.isNotEmpty)
               'preferensi_waktu_makan': routineNotes,
           },
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final String patientName;
  final Json healthCondition;
  final List<Json> prescriptions;
  final List<Json> allergies;
  final List<String> preferensi;
  final double budget;
  final String routineNotes;
  final Json rutinitas;
  final List<Json> meals;
  final List<Json> reminders;
  final List<String> aiNotes;
  final DateTime createdAt;

  String get conditionName =>
      (healthCondition['condition_name'] as String?) ?? '-';
  String? get diagnosis => healthCondition['diagnosis'] as String?;
  String? get conditionNotes => healthCondition['notes'] as String?;
  int? get age => (healthCondition['age'] as num?)?.toInt();
  double? get weight => (healthCondition['weight'] as num?)?.toDouble();
  double? get height => (healthCondition['height'] as num?)?.toDouble();

  bool get hasPrescription =>
      healthCondition['isTherePrescription'] == true &&
      prescriptions.isNotEmpty;

  List<Json> get allMedications => [
    for (final prescription in prescriptions)
      for (final item in (prescription['medications'] as List? ?? const []))
        if (item is Map) Map<String, dynamic>.from(item),
  ];

  int get totalSchedules => reminders.length;

  int get completedSchedules =>
      reminders.where((item) => item['status'] == 'completed').length;

  bool get isScheduleCompleted =>
      reminders.isNotEmpty && completedSchedules == totalSchedules;

  double get progress =>
      totalSchedules == 0 ? 0.0 : completedSchedules / totalSchedules;

  /// Jumlah hari perawatan unik yang tercakup dalam daftar pengingat jadwal.
  int get totalDays {
    if (reminders.isEmpty) return 0;
    final days = <String>{};
    for (final rem in reminders) {
      final dt = parseReminderTime(rem);
      if (dt != null) {
        final y = dt.year.toString().padLeft(4, '0');
        final m = dt.month.toString().padLeft(2, '0');
        final d = dt.day.toString().padLeft(2, '0');
        days.add('$y-$m-$d');
      }
    }
    return days.isEmpty ? 1 : days.length;
  }

  /// Mengurai `schedule_at` dari pengingat menjadi waktu lokal `DateTime`.
  static DateTime? parseReminderTime(Json reminder) {
    final raw = reminder['schedule_at'] as String?;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  /// Mengembalikan `true` apabila waktu saat ini sudah mencapai atau melewati
  /// waktu `schedule_at`, sehingga jadwal diizinkan untuk ditandai selesai.
  static bool isReminderDue(Json reminder, {DateTime? now}) {
    final scheduled = parseReminderTime(reminder);
    if (scheduled == null) return true;
    final current = (now ?? DateTime.now()).toLocal();
    return !current.isBefore(scheduled);
  }

  /// Menghitung jumlah pengingat berstatus `pending` yang waktunya sudah tiba.
  int duePendingCount({DateTime? now}) {
    final current = (now ?? DateTime.now()).toLocal();
    return reminders
        .where(
          (item) =>
              item['status'] != 'completed' &&
              isReminderDue(item, now: current),
        )
        .length;
  }

  /// Mencari detail obat yang terhubung dengan suatu jadwal pengingat.
  List<Json> medicationsForReminder(Json reminder) {
    final meds = allMedications;
    if (meds.isEmpty) return const [];

    final rawItems = reminder['reminder_items'] as List? ?? const [];
    final itemIds = rawItems
        .whereType<Map>()
        .map((item) => (item['medication_id'] as num?)?.toInt())
        .whereType<int>()
        .toSet();

    if (itemIds.isNotEmpty) {
      final matched = meds
          .where((med) => itemIds.contains((med['id'] as num?)?.toInt()))
          .toList();
      if (matched.isNotEmpty) return matched;
    }

    final titleLower = ((reminder['title'] as String?) ?? '').toLowerCase();
    final byTitle = meds.where((med) {
      final name = ((med['medicine_name'] as String?) ?? '').toLowerCase();
      return name.isNotEmpty && titleLower.contains(name);
    }).toList();
    if (byTitle.isNotEmpty) return byTitle;

    final prescriptionId = (reminder['prescription_id'] as num?)?.toInt();
    if (prescriptionId != null) {
      for (final prescription in prescriptions) {
        if ((prescription['id'] as num?)?.toInt() == prescriptionId) {
          final list = (prescription['medications'] as List? ?? const [])
              .whereType<Map>()
              .map(Map<String, dynamic>.from)
              .toList();
          if (list.length == 1) return list;
        }
      }
    }
    return const [];
  }

  bool isMedicationReminder(Json reminder) {
    if (medicationsForReminder(reminder).isNotEmpty) return true;
    if (reminder['prescription_id'] != null) return true;
    final items = reminder['reminder_items'] as List?;
    if (items != null && items.isNotEmpty) return true;
    final title = ((reminder['title'] as String?) ?? '').toLowerCase();
    return title.contains('obat') || title.startsWith('minum ');
  }

  PatientCarePlan copyWith({
    String? id,
    String? patientName,
    Json? healthCondition,
    List<Json>? prescriptions,
    List<Json>? allergies,
    List<String>? preferensi,
    double? budget,
    String? routineNotes,
    Json? rutinitas,
    List<Json>? meals,
    List<Json>? reminders,
    List<String>? aiNotes,
    DateTime? createdAt,
  }) {
    return PatientCarePlan(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      healthCondition: healthCondition ?? this.healthCondition,
      prescriptions: prescriptions ?? this.prescriptions,
      allergies: allergies ?? this.allergies,
      preferensi: preferensi ?? this.preferensi,
      budget: budget ?? this.budget,
      routineNotes: routineNotes ?? this.routineNotes,
      rutinitas: rutinitas ?? this.rutinitas,
      meals: meals ?? this.meals,
      reminders: reminders ?? this.reminders,
      aiNotes: aiNotes ?? this.aiNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Json toJson() => {
    'id': id,
    'patient_name': patientName,
    'health_condition': healthCondition,
    'prescriptions': prescriptions,
    'allergies': allergies,
    'preferensi': preferensi,
    'budget': budget,
    'routine_notes': routineNotes,
    'rutinitas': rutinitas,
    'meals': meals,
    'reminders': reminders,
    'ai_notes': aiNotes,
    'created_at': createdAt.toIso8601String(),
  };

  factory PatientCarePlan.fromJson(Json map) {
    List<Json> mapList(Object? raw) => (raw as List? ?? const [])
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList();

    List<String> stringList(Object? raw) =>
        (raw as List? ?? const []).map((item) => item.toString()).toList();

    return PatientCarePlan(
      id:
          map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      patientName: map['patient_name'] as String? ?? '',
      healthCondition: map['health_condition'] is Map
          ? Map<String, dynamic>.from(map['health_condition'] as Map)
          : <String, dynamic>{},
      prescriptions: mapList(map['prescriptions']),
      allergies: mapList(map['allergies']),
      preferensi: stringList(map['preferensi']),
      budget: (map['budget'] as num?)?.toDouble() ?? 0.0,
      routineNotes: map['routine_notes'] as String? ?? '',
      rutinitas: map['rutinitas'] is Map
          ? Map<String, dynamic>.from(map['rutinitas'] as Map)
          : null,
      meals: mapList(map['meals']),
      reminders: mapList(map['reminders']),
      aiNotes: stringList(map['ai_notes']),
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Menetapkan ID berurutan pada daftar resep makanan bila belum memiliki ID SQLite.
List<Json> assignMealIds(List<Json> meals) {
  var nextIngredientId = 1;
  return [
    for (var r = 0; r < meals.length; r++)
      () {
        final meal = meals[r];
        final recipeId = (meal['id'] as num?)?.toInt() ?? (r + 1);
        final rawIngredients = (meal['ingredients'] as List? ?? const [])
            .whereType<Map>()
            .toList();
        final ingredients = <Json>[
          for (final ing in rawIngredients)
            {
              'id': (ing['id'] as num?)?.toInt() ?? nextIngredientId++,
              'recipe_id': recipeId,
              'ingredient_name': ing['ingredient_name'],
              'quantity': ing['quantity'],
            },
        ];
        final rawNut = meal['nutrition'];
        final nutrition = rawNut is Map
            ? <String, dynamic>{
                'id': (rawNut['id'] as num?)?.toInt() ?? recipeId,
                'recipe_id': recipeId,
                'calories': (rawNut['calories'] as num).toDouble(),
                'protein': (rawNut['protein'] as num).toDouble(),
                'carbohydrates': (rawNut['carbohydrates'] as num).toDouble(),
                'fat': (rawNut['fat'] as num).toDouble(),
              }
            : null;
        return <String, dynamic>{
          ...meal,
          'id': recipeId,
          'ingredients': ingredients,
          'nutrition': nutrition,
        };
      }(),
  ];
}

/// Menetapkan ID berurutan pada daftar resep obat bila belum memiliki ID SQLite.
List<Json> assignPrescriptionIds(
  List<Json> prescriptions, {
  int startPrescId = 1,
  int startMedId = 1,
}) {
  var pId = startPrescId;
  var mId = startMedId;
  return [
    for (final p in prescriptions)
      () {
        final currentPrescId = (p['id'] as num?)?.toInt() ?? pId++;
        final rawMeds = (p['medications'] as List? ?? const [])
            .whereType<Map>()
            .toList();
        final meds = <Json>[
          for (final m in rawMeds)
            {
              ...m,
              'id': (m['id'] as num?)?.toInt() ?? mId++,
              'prescription_id': currentPrescId,
            },
        ];
        return <String, dynamic>{
          ...p,
          'id': currentPrescId,
          'medications': meds,
        };
      }(),
  ];
}

/// Abstraksi penyimpanan daftar orang yang dirawat beserta sinkronisasi entitasnya.
abstract class CarePlanStore {
  Future<List<PatientCarePlan>> loadAll();
  Future<PatientCarePlan> save(PatientCarePlan plan);
  Future<void> delete(String id);

  /// Menyimpan daftar menu yang disetujui ke penyimpanan lokal sehingga memiliki
  /// `id` dan `recipe_id` valid sebelum dikirim ke `/api/schedules/generate`.
  Future<List<Json>> persistApprovedMeals(List<Json> meals) async =>
      assignMealIds(meals);

  /// Menyimpan daftar resep obat ke penyimpanan lokal sehingga memiliki `id`
  /// dan `medication.id` valid sebelum dikirim ke `/api/schedules/generate`.
  Future<List<Json>> persistPrescriptions(List<Json> prescriptions) async =>
      prescriptions;
}

/// Penyimpanan sesi di memori (untuk Web & pengujian widget).
class MemoryCarePlanStore extends CarePlanStore {
  MemoryCarePlanStore([List<PatientCarePlan>? initial])
    : _items = List<PatientCarePlan>.from(initial ?? const []);

  final List<PatientCarePlan> _items;
  int _memMedCounter = 100;
  int _memPrescCounter = 100;

  @override
  Future<List<PatientCarePlan>> loadAll() async =>
      List<PatientCarePlan>.unmodifiable(_items);

  @override
  Future<List<Json>> persistPrescriptions(List<Json> prescriptions) async {
    return assignPrescriptionIds(
      prescriptions,
      startPrescId: _memPrescCounter += 10,
      startMedId: _memMedCounter += 20,
    );
  }

  @override
  Future<PatientCarePlan> save(PatientCarePlan plan) async {
    final normalized = plan.copyWith(
      meals: assignMealIds(plan.meals),
      prescriptions: assignPrescriptionIds(plan.prescriptions),
    );
    final index = _items.indexWhere((item) => item.id == normalized.id);
    if (index >= 0) {
      _items[index] = normalized;
    } else {
      _items.insert(0, normalized);
    }
    return normalized;
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
  }
}

/// Penyimpanan persisten SQLite yang menyinkronkan entitas 1-ke-1 ke seluruh
/// tabel relasional (`health_condition`, `allergies`, `prescription`,
/// `medications`, `recipes`, `recipe_ingredients`, `recipe_nutrition`,
/// `reminders`, `reminder_items`) serta indeks ringkasan `care_plans`.
class SqliteCarePlanStore extends CarePlanStore {
  SqliteCarePlanStore({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  @override
  Future<List<Json>> persistApprovedMeals(List<Json> meals) async {
    final db = await _dbHelper.database;
    return db.transaction<List<Json>>((txn) async {
      return _insertMealsInTxn(txn, meals);
    });
  }

  @override
  Future<List<Json>> persistPrescriptions(List<Json> prescriptions) async {
    if (prescriptions.isEmpty) return const [];
    final db = await _dbHelper.database;
    return db.transaction<List<Json>>((txn) async {
      return _insertPrescriptionsInTxn(txn, prescriptions);
    });
  }

  Future<List<Json>> _insertMealsInTxn(
    DatabaseExecutor txn,
    List<Json> meals,
  ) async {
    final savedMeals = <Json>[];
    final nowIso = DateTime.now().toIso8601String();
    for (final meal in meals) {
      final existingId = (meal['id'] as num?)?.toInt();
      if (existingId != null) {
        final existingRows = await txn.query(
          DatabaseTables.recipes,
          where: 'id = ?',
          whereArgs: [existingId],
          limit: 1,
        );
        if (existingRows.isNotEmpty) {
          savedMeals.add(meal);
          continue;
        }
      }

      final recipeId = await txn.insert(DatabaseTables.recipes, {
        'recipe_name': meal['recipe_name'] as String,
        'description': meal['description'] as String?,
        'servings': (meal['servings'] as num?)?.toInt(),
        'cooking_time': (meal['cooking_time'] as num?)?.toInt(),
        'instructions': meal['instructions'] as String?,
        'source': meal['source'] as String?,
        'created_at': nowIso,
      });

      final rawIngredients = (meal['ingredients'] as List? ?? const [])
          .whereType<Map>()
          .toList();
      final savedIngredients = <Json>[];
      for (final ing in rawIngredients) {
        final ingId = await txn.insert(DatabaseTables.recipeIngredients, {
          'recipe_id': recipeId,
          'ingredient_name': ing['ingredient_name'] as String,
          'quantity': ing['quantity']?.toString(),
          'created_at': nowIso,
        });
        savedIngredients.add({
          'id': ingId,
          'recipe_id': recipeId,
          'ingredient_name': ing['ingredient_name'],
          'quantity': ing['quantity'],
        });
      }

      Json? savedNutrition;
      if (meal['nutrition'] is Map) {
        final nut = Map<String, dynamic>.from(meal['nutrition'] as Map);
        final nutId = await txn.insert(DatabaseTables.recipeNutrition, {
          'recipe_id': recipeId,
          'calories': (nut['calories'] as num?)?.toDouble(),
          'protein': (nut['protein'] as num?)?.toDouble(),
          'carbohydrates': (nut['carbohydrates'] as num?)?.toDouble(),
          'fat': (nut['fat'] as num?)?.toDouble(),
          'created_at': nowIso,
        });
        savedNutrition = {
          'id': nutId,
          'recipe_id': recipeId,
          'calories': (nut['calories'] as num).toDouble(),
          'protein': (nut['protein'] as num).toDouble(),
          'carbohydrates': (nut['carbohydrates'] as num).toDouble(),
          'fat': (nut['fat'] as num).toDouble(),
        };
      }

      savedMeals.add({
        ...meal,
        'id': recipeId,
        'ingredients': savedIngredients,
        'nutrition': savedNutrition,
      });
    }
    return savedMeals;
  }

  Future<List<Json>> _insertPrescriptionsInTxn(
    DatabaseExecutor txn,
    List<Json> prescriptions,
  ) async {
    final savedPrescriptions = <Json>[];
    final nowIso = DateTime.now().toIso8601String();
    for (final p in prescriptions) {
      final existingId = (p['id'] as num?)?.toInt();
      int prescriptionId;
      if (existingId != null) {
        final existingRows = await txn.query(
          DatabaseTables.prescription,
          where: 'id = ?',
          whereArgs: [existingId],
          limit: 1,
        );
        if (existingRows.isNotEmpty) {
          prescriptionId = existingId;
        } else {
          prescriptionId = await txn.insert(DatabaseTables.prescription, {
            'id': existingId,
            'prescription_date': p['prescription_date'] as String,
            'notes': p['notes'] as String?,
            'status': (p['status'] as String?) ?? 'active',
            'start_at': p['start_at'] as String?,
            'created_at': nowIso,
          });
        }
      } else {
        prescriptionId = await txn.insert(DatabaseTables.prescription, {
          'prescription_date': p['prescription_date'] as String,
          'notes': p['notes'] as String?,
          'status': (p['status'] as String?) ?? 'active',
          'start_at': p['start_at'] as String?,
          'created_at': nowIso,
        });
      }

      final rawMeds = (p['medications'] as List? ?? const [])
          .whereType<Map>()
          .toList();
      final savedMeds = <Json>[];
      for (final m in rawMeds) {
        final existingMedId = (m['id'] as num?)?.toInt();
        int medId;
        if (existingMedId != null) {
          final existingMedRows = await txn.query(
            DatabaseTables.medications,
            where: 'id = ?',
            whereArgs: [existingMedId],
            limit: 1,
          );
          if (existingMedRows.isNotEmpty) {
            medId = existingMedId;
          } else {
            medId = await txn.insert(DatabaseTables.medications, {
              'id': existingMedId,
              'prescription_id': prescriptionId,
              'medicine_name': m['medicine_name'] as String,
              'dosage': m['dosage'] as String?,
              'frequency': m['frequency'] as String?,
              'instruction': m['instruction'] as String?,
              'quantity': (m['quantity'] as num?)?.toInt(),
              'notes': m['notes'] as String?,
              'isAfterEat': m['isAfterEat'] == true ? 1 : 0,
              'dose_type': (m['dose_type'] as String?) ?? 'TABLET',
              'created_at': nowIso,
            });
          }
        } else {
          medId = await txn.insert(DatabaseTables.medications, {
            'prescription_id': prescriptionId,
            'medicine_name': m['medicine_name'] as String,
            'dosage': m['dosage'] as String?,
            'frequency': m['frequency'] as String?,
            'instruction': m['instruction'] as String?,
            'quantity': (m['quantity'] as num?)?.toInt(),
            'notes': m['notes'] as String?,
            'isAfterEat': m['isAfterEat'] == true ? 1 : 0,
            'dose_type': (m['dose_type'] as String?) ?? 'TABLET',
            'created_at': nowIso,
          });
        }
        savedMeds.add({
          ...m,
          'id': medId,
          'prescription_id': prescriptionId,
        });
      }

      savedPrescriptions.add({
        ...p,
        'id': prescriptionId,
        'medications': savedMeds,
      });
    }
    return savedPrescriptions;
  }

  @override
  Future<List<PatientCarePlan>> loadAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.carePlans,
      orderBy: 'created_at DESC',
    );
    return rows.map((row) {
      final decoded = jsonDecode(row['plan_json'] as String);
      return PatientCarePlan.fromJson(
        Map<String, dynamic>.from(decoded as Map),
      );
    }).toList();
  }

  @override
  Future<PatientCarePlan> save(PatientCarePlan plan) async {
    final db = await _dbHelper.database;
    return db.transaction<PatientCarePlan>((txn) async {
      final nowIso = DateTime.now().toIso8601String();
      final existingPlanRows = await txn.query(
        DatabaseTables.carePlans,
        where: 'id = ?',
        whereArgs: [plan.id],
        limit: 1,
      );

      var hc = Map<String, dynamic>.from(plan.healthCondition);
      var allergies = plan.allergies.map(Map<String, dynamic>.from).toList();
      var prescriptions = plan.prescriptions
          .map(Map<String, dynamic>.from)
          .toList();
      var meals = plan.meals.map(Map<String, dynamic>.from).toList();
      var reminders = plan.reminders.map(Map<String, dynamic>.from).toList();

      if (existingPlanRows.isEmpty) {
        // 1. Simpan health_condition
        final hcId = await txn.insert(DatabaseTables.healthCondition, {
          'name': (hc['name'] as String?) ?? plan.patientName,
          'condition_name': (hc['condition_name'] as String?) ?? '-',
          'diagnosis': hc['diagnosis'] as String?,
          'notes': hc['notes'] as String?,
          'age': (hc['age'] as num?)?.toInt(),
          'weight': (hc['weight'] as num?)?.toDouble(),
          'height': (hc['height'] as num?)?.toDouble(),
          'isTherePrescription': hc['isTherePrescription'] == true ? 1 : 0,
          'created_at': nowIso,
        });
        hc['id'] = hcId;

        // 2. Simpan allergies
        final savedAllergies = <Json>[];
        for (final allergy in allergies) {
          final allergyId = await txn.insert(DatabaseTables.allergies, {
            'type': allergy['type'] as String,
            'created_at': nowIso,
          });
          savedAllergies.add({'id': allergyId, 'type': allergy['type']});
        }
        allergies = savedAllergies;

        // 3. Pastikan prescriptions & meals tersimpan di tabel relasional
        prescriptions = await _insertPrescriptionsInTxn(txn, prescriptions);
        meals = await _insertMealsInTxn(txn, meals);

        final validPrescriptionIds = prescriptions
            .map((p) => (p['id'] as num?)?.toInt())
            .whereType<int>()
            .toSet();
        final validMedicationIds = {
          for (final p in prescriptions)
            for (final m in (p['medications'] as List? ?? const []))
              if (m is Map && m['id'] is num) (m['id'] as num).toInt(),
        };

        // 4. Simpan reminders & reminder_items
        final savedReminders = <Json>[];
        for (final rem in reminders) {
          final rawPrescId = (rem['prescription_id'] as num?)?.toInt();
          final safePrescId =
              rawPrescId != null && validPrescriptionIds.contains(rawPrescId)
              ? rawPrescId
              : null;
          final reminderId = await txn.insert(DatabaseTables.reminders, {
            'prescription_id': safePrescId,
            'title': rem['title'] as String,
            'schedule_at': rem['schedule_at'] as String,
            'status': (rem['status'] as String?) ?? 'pending',
            'created_at': nowIso,
          });
          final rawItems = (rem['reminder_items'] as List? ?? const [])
              .whereType<Map>()
              .toList();
          final savedItems = <Json>[];
          for (final item in rawItems) {
            final medId = (item['medication_id'] as num?)?.toInt();
            if (medId != null && validMedicationIds.contains(medId)) {
              final itemId = await txn.insert(DatabaseTables.reminderItems, {
                'reminder_id': reminderId,
                'medication_id': medId,
                'created_at': nowIso,
              });
              savedItems.add({
                'id': itemId,
                'reminder_id': reminderId,
                'medication_id': medId,
              });
            }
          }
          savedReminders.add({
            ...rem,
            'id': reminderId,
            'prescription_id': safePrescId,
            'reminder_items': savedItems,
          });
        }
        reminders = savedReminders;
      } else {
        // Sinkronkan perubahan status reminder ke tabel `reminders`
        for (final rem in reminders) {
          final remId = (rem['id'] as num?)?.toInt();
          if (remId != null) {
            await txn.update(
              DatabaseTables.reminders,
              {'status': (rem['status'] as String?) ?? 'pending'},
              where: 'id = ?',
              whereArgs: [remId],
            );
          }
        }
      }

      final syncedPlan = plan.copyWith(
        healthCondition: hc,
        allergies: allergies,
        prescriptions: prescriptions,
        meals: meals,
        reminders: reminders,
      );

      await txn.insert(
        DatabaseTables.carePlans,
        {
          'id': syncedPlan.id,
          'patient_name': syncedPlan.patientName,
          'plan_json': jsonEncode(syncedPlan.toJson()),
          'created_at': syncedPlan.createdAt.toIso8601String(),
          'updated_at': nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return syncedPlan;
    });
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        DatabaseTables.carePlans,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final plan = PatientCarePlan.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(rows.first['plan_json'] as String) as Map,
          ),
        );
        final hcId = (plan.healthCondition['id'] as num?)?.toInt();
        if (hcId != null) {
          await txn.delete(
            DatabaseTables.healthCondition,
            where: 'id = ?',
            whereArgs: [hcId],
          );
        }
        for (final a in plan.allergies) {
          final aId = (a['id'] as num?)?.toInt();
          if (aId != null) {
            await txn.delete(
              DatabaseTables.allergies,
              where: 'id = ?',
              whereArgs: [aId],
            );
          }
        }
        for (final r in plan.reminders) {
          final rId = (r['id'] as num?)?.toInt();
          if (rId != null) {
            await txn.delete(
              DatabaseTables.reminders,
              where: 'id = ?',
              whereArgs: [rId],
            );
          }
        }
        for (final p in plan.prescriptions) {
          final pId = (p['id'] as num?)?.toInt();
          if (pId != null) {
            await txn.delete(
              DatabaseTables.prescription,
              where: 'id = ?',
              whereArgs: [pId],
            );
          }
        }
        for (final m in plan.meals) {
          final mId = (m['id'] as num?)?.toInt();
          if (mId != null) {
            await txn.delete(
              DatabaseTables.recipes,
              where: 'id = ?',
              whereArgs: [mId],
            );
          }
        }
      }
      await txn.delete(
        DatabaseTables.carePlans,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }
}
