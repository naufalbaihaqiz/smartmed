import '../database/database_helper.dart';
import '../database/database_tables.dart';
import '../models/allergy.dart';

/// Repository CRUD untuk tabel `allergies`.
class AllergyRepository {
  AllergyRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<int> insert(Allergy allergy) async {
    final db = await _dbHelper.database;
    return db.insert(DatabaseTables.allergies, allergy.toMap());
  }

  Future<List<Allergy>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.allergies,
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(Allergy.fromMap).toList();
  }

  Future<Allergy?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.allergies,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Allergy.fromMap(rows.first);
  }

  Future<int> update(Allergy allergy) async {
    if (allergy.id == null) {
      throw ArgumentError('Allergy.id tidak boleh null saat update.');
    }
    final db = await _dbHelper.database;
    return db.update(
      DatabaseTables.allergies,
      allergy.toMap(),
      where: 'id = ?',
      whereArgs: [allergy.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      DatabaseTables.allergies,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return db.delete(DatabaseTables.allergies);
  }
}

