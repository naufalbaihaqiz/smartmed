import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../care_api.dart';
import '../database/database_helper.dart';
import '../database/database_tables.dart';

/// Menyimpan seluruh informasi perawatan satu orang pasien:
/// profil kondisi kesehatan, resep dokter & obat, alergi, preferensi, budget,
/// daftar resep makanan hasil AI, serta jadwal makan & minum obat harian.
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
    required this.meals,
    required this.reminders,
    this.aiNotes = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String patientName;
  final Json healthCondition;
  final List<Json> prescriptions;
  final List<Json> allergies;
  final List<String> preferensi;
  final double budget;
  final String routineNotes;
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
      meals: mapList(map['meals']),
      reminders: mapList(map['reminders']),
      aiNotes: stringList(map['ai_notes']),
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Abstraksi penyimpanan daftar orang yang dirawat.
abstract class CarePlanStore {
  Future<List<PatientCarePlan>> loadAll();
  Future<void> save(PatientCarePlan plan);
  Future<void> delete(String id);
}

/// Penyimpanan sesi di memori (untuk Web & pengujian widget).
class MemoryCarePlanStore implements CarePlanStore {
  MemoryCarePlanStore([List<PatientCarePlan>? initial])
    : _items = List<PatientCarePlan>.from(initial ?? const []);

  final List<PatientCarePlan> _items;

  @override
  Future<List<PatientCarePlan>> loadAll() async =>
      List<PatientCarePlan>.unmodifiable(_items);

  @override
  Future<void> save(PatientCarePlan plan) async {
    final index = _items.indexWhere((item) => item.id == plan.id);
    if (index >= 0) {
      _items[index] = plan;
    } else {
      _items.insert(0, plan);
    }
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
  }
}

/// Penyimpanan persisten SQLite di perangkat lokal.
class SqliteCarePlanStore implements CarePlanStore {
  SqliteCarePlanStore({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

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
  Future<void> save(PatientCarePlan plan) async {
    final db = await _dbHelper.database;
    await db.insert(DatabaseTables.carePlans, {
      'id': plan.id,
      'patient_name': plan.patientName,
      'plan_json': jsonEncode(plan.toJson()),
      'created_at': plan.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(DatabaseTables.carePlans, where: 'id = ?', whereArgs: [id]);
  }
}
