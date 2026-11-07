import '../database/database_helper.dart';
import '../database/database_tables.dart';
import '../models/health_condition.dart';

/// Repository CRUD untuk tabel `health_condition`.
class HealthConditionRepository {
  HealthConditionRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<int> insert(HealthCondition condition) async {
    final db = await _dbHelper.database;
    return db.insert(DatabaseTables.healthCondition, condition.toMap());
  }

  Future<List<HealthCondition>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.healthCondition,
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(HealthCondition.fromMap).toList();
  }

  Future<HealthCondition?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.healthCondition,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return HealthCondition.fromMap(rows.first);
  }

  Future<int> update(HealthCondition condition) async {
    if (condition.id == null) {
      throw ArgumentError('HealthCondition.id tidak boleh null saat update.');
    }
    final db = await _dbHelper.database;
    return db.update(
      DatabaseTables.healthCondition,
      condition.toMap(),
      where: 'id = ?',
      whereArgs: [condition.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      DatabaseTables.healthCondition,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return db.delete(DatabaseTables.healthCondition);
  }
}

