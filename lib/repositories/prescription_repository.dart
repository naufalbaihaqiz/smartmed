import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../database/database_tables.dart';
import '../models/models.dart';

/// Repository CRUD & relasi untuk `prescription`, `medications`, `reminders`, dan `reminder_items`.
class PrescriptionRepository {
  PrescriptionRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  // ==================== PRESCRIPTION ====================

  Future<int> insertPrescription(Prescription prescription) async {
    final db = await _dbHelper.database;
    return db.insert(DatabaseTables.prescription, prescription.toMap());
  }

  Future<List<Prescription>> getAllPrescriptions({String? status}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.prescription,
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status] : null,
      orderBy: 'prescription_date DESC, id DESC',
    );
    return rows.map(Prescription.fromMap).toList();
  }

  Future<Prescription?> getPrescriptionById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.prescription,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Prescription.fromMap(rows.first);
  }

  Future<int> updatePrescription(Prescription prescription) async {
    if (prescription.id == null) {
      throw ArgumentError('Prescription.id tidak boleh null saat update.');
    }
    final db = await _dbHelper.database;
    return db.update(
      DatabaseTables.prescription,
      prescription.toMap(),
      where: 'id = ?',
      whereArgs: [prescription.id],
    );
  }

  /// Menghapus `prescription` (otomatis menghapus `medications`, `reminders`, dan `reminder_items` terkait karena ON DELETE CASCADE).
  Future<int> deletePrescription(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      DatabaseTables.prescription,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== MEDICATIONS ====================

  Future<int> insertMedication(Medication medication) async {
    final db = await _dbHelper.database;
    return db.insert(DatabaseTables.medications, medication.toMap());
  }

  Future<List<Medication>> getMedicationsByPrescription(
    int prescriptionId,
  ) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.medications,
      where: 'prescription_id = ?',
      whereArgs: [prescriptionId],
      orderBy: 'id ASC',
    );
    return rows.map(Medication.fromMap).toList();
  }

  Future<Medication?> getMedicationById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.medications,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Medication.fromMap(rows.first);
  }

  Future<int> updateMedication(Medication medication) async {
    if (medication.id == null) {
      throw ArgumentError('Medication.id tidak boleh null saat update.');
    }
    final db = await _dbHelper.database;
    return db.update(
      DatabaseTables.medications,
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  Future<int> deleteMedication(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      DatabaseTables.medications,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== REMINDERS & REMINDER ITEMS ====================

  Future<int> insertReminder(Reminder reminder) async {
    final db = await _dbHelper.database;
    return db.insert(DatabaseTables.reminders, reminder.toMap());
  }

  Future<int> insertReminderItem(ReminderItem item) async {
    final db = await _dbHelper.database;
    return db.insert(DatabaseTables.reminderItems, item.toMap());
  }

  /// Menyimpan `Reminder` sekaligus daftar `medicationIds` ke `reminder_items` dalam 1 transaksi.
  Future<int> insertReminderWithMedications({
    required Reminder reminder,
    required List<int> medicationIds,
  }) async {
    final db = await _dbHelper.database;
    return db.transaction<int>((txn) async {
      final reminderId = await txn.insert(
        DatabaseTables.reminders,
        reminder.toMap(),
      );
      for (final medId in medicationIds) {
        final item = ReminderItem(
          reminderId: reminderId,
          medicationId: medId,
        );
        await txn.insert(DatabaseTables.reminderItems, item.toMap());
      }
      return reminderId;
    });
  }

  Future<List<Reminder>> getRemindersByPrescription(int prescriptionId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.reminders,
      where: 'prescription_id = ?',
      whereArgs: [prescriptionId],
      orderBy: 'schedule_at ASC',
    );
    return rows.map(Reminder.fromMap).toList();
  }

  Future<List<Reminder>> getAllReminders({String? status}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.reminders,
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status] : null,
      orderBy: 'schedule_at ASC',
    );
    return rows.map(Reminder.fromMap).toList();
  }

  Future<int> updateReminder(Reminder reminder) async {
    if (reminder.id == null) {
      throw ArgumentError('Reminder.id tidak boleh null saat update.');
    }
    final db = await _dbHelper.database;
    return db.update(
      DatabaseTables.reminders,
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> updateReminderStatus(int reminderId, String status) async {
    final db = await _dbHelper.database;
    return db.update(
      DatabaseTables.reminders,
      {'status': status},
      where: 'id = ?',
      whereArgs: [reminderId],
    );
  }

  Future<int> deleteReminder(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      DatabaseTables.reminders,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ReminderItem>> getItemsByReminder(int reminderId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.reminderItems,
      where: 'reminder_id = ?',
      whereArgs: [reminderId],
      orderBy: 'id ASC',
    );
    return rows.map(ReminderItem.fromMap).toList();
  }

  Future<int> deleteReminderItem(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      DatabaseTables.reminderItems,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== TRANSACTIONAL & COMPOSITE QUERIES ====================

  /// Menyimpan `Prescription` beserta daftar `Medication` dalam 1 transaksi atomik.
  Future<int> insertPrescriptionWithMedications({
    required Prescription prescription,
    required List<Medication> medications,
  }) async {
    final db = await _dbHelper.database;
    return db.transaction<int>((txn) async {
      final prescriptionId = await txn.insert(
        DatabaseTables.prescription,
        prescription.toMap(),
      );
      for (final med in medications) {
        final medWithFk = med.copyWith(prescriptionId: prescriptionId);
        await txn.insert(DatabaseTables.medications, medWithFk.toMap());
      }
      return prescriptionId;
    });
  }

  /// Mengambil detail lengkap `Reminder` beserta `ReminderItem` dan `Medication` terkait.
  Future<List<ReminderWithItems>> getRemindersWithItems({
    int? prescriptionId,
    String? status,
  }) async {
    final db = await _dbHelper.database;
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (prescriptionId != null) {
      whereClauses.add('prescription_id = ?');
      whereArgs.add(prescriptionId);
    }
    if (status != null) {
      whereClauses.add('status = ?');
      whereArgs.add(status);
    }

    final reminderRows = await db.query(
      DatabaseTables.reminders,
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'schedule_at ASC',
    );

    final result = <ReminderWithItems>[];
    for (final row in reminderRows) {
      final reminder = Reminder.fromMap(row);
      final items = await _fetchReminderItems(db, reminder.id!);
      final medications = await _fetchMedicationsForReminder(db, reminder.id!);
      result.add(
        ReminderWithItems(
          reminder: reminder,
          items: items,
          medications: medications,
        ),
      );
    }
    return result;
  }

  /// Mengambil detail lengkap `Prescription` beserta obat dan jadwal pengingatnya.
  Future<PrescriptionDetail?> getPrescriptionDetail(int prescriptionId) async {
    final prescription = await getPrescriptionById(prescriptionId);
    if (prescription == null) return null;

    final medications = await getMedicationsByPrescription(prescriptionId);
    final reminders = await getRemindersWithItems(
      prescriptionId: prescriptionId,
    );

    return PrescriptionDetail(
      prescription: prescription,
      medications: medications,
      reminders: reminders,
    );
  }

  Future<List<ReminderItem>> _fetchReminderItems(
    DatabaseExecutor db,
    int reminderId,
  ) async {
    final rows = await db.query(
      DatabaseTables.reminderItems,
      where: 'reminder_id = ?',
      whereArgs: [reminderId],
      orderBy: 'id ASC',
    );
    return rows.map(ReminderItem.fromMap).toList();
  }

  Future<List<Medication>> _fetchMedicationsForReminder(
    DatabaseExecutor db,
    int reminderId,
  ) async {
    final rows = await db.rawQuery(
      '''
      SELECT m.*
      FROM ${DatabaseTables.medications} m
      INNER JOIN ${DatabaseTables.reminderItems} ri
        ON ri.medication_id = m.id
      WHERE ri.reminder_id = ?
      ORDER BY ri.id ASC
      ''',
      [reminderId],
    );
    return rows.map(Medication.fromMap).toList();
  }
}

