import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_tables.dart';

/// Singleton helper untuk mengelola koneksi database SQLite lokal di perangkat.
class DatabaseHelper {
  DatabaseHelper._internal([this._customFactory, this._customDbPath]);

  /// Instance utama untuk digunakan di seluruh aplikasi.
  static final DatabaseHelper instance = DatabaseHelper._internal();

  /// Constructor khusus untuk kebutuhan unit testing (misal in-memory SQLite).
  factory DatabaseHelper.custom({
    DatabaseFactory? customFactory,
    String? customDbPath,
  }) {
    return DatabaseHelper._internal(customFactory, customDbPath);
  }

  final DatabaseFactory? _customFactory;
  final String? _customDbPath;

  Database? _database;
  Future<Database>? _initFuture;

  /// Mengambil koneksi aktif SQLite, atau membuat file database lokal jika belum ada.
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _initFuture ??= _initDatabase();
    try {
      _database = await _initFuture!;
      return _database!;
    } catch (e) {
      _initFuture = null;
      rethrow;
    }
  }

  Future<String> _resolveDatabasePath() async {
    if (_customDbPath != null) {
      return _customDbPath;
    }
    final dbDirectory = await (_customFactory?.getDatabasesPath() ??
        getDatabasesPath());
    return p.join(dbDirectory, DatabaseTables.databaseName);
  }

  Future<Database> _initDatabase() async {
    final path = await _resolveDatabasePath();
    final options = OpenDatabaseOptions(
      version: DatabaseTables.databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    if (_customFactory != null) {
      return _customFactory.openDatabase(path, options: options);
    }
    return openDatabase(
      path,
      version: options.version,
      onConfigure: options.onConfigure,
      onCreate: options.onCreate,
      onUpgrade: options.onUpgrade,
    );
  }

  /// Mengaktifkan Foreign Key constraint pada setiap koneksi SQLite.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Membuat kesembilan tabel dan index saat aplikasi pertama kali dijalankan di HP.
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final statement in DatabaseTables.createTableStatements) {
      batch.execute(statement);
    }
    for (final indexStatement in DatabaseTables.createIndexStatements) {
      batch.execute(indexStatement);
    }
    await batch.commit(noResult: true);
  }

  /// Hook migrasi skema untuk versi database mendatang.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE ${DatabaseTables.healthCondition} '
        'ADD COLUMN isTherePrescription INTEGER NOT NULL DEFAULT 0 CHECK (isTherePrescription IN (0, 1))',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE ${DatabaseTables.healthCondition} '
        "ADD COLUMN name VARCHAR(255) NOT NULL DEFAULT ''",
      );
    }
    if (oldVersion < 4) {
      await db.execute(DatabaseTables.createCarePlansTable);
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE ${DatabaseTables.reminders} RENAME TO reminders_old');
      await db.execute(DatabaseTables.createRemindersTable);
      await db.execute('''
        INSERT INTO ${DatabaseTables.reminders} (id, prescription_id, title, schedule_at, status, created_at)
        SELECT id, prescription_id, title, schedule_at, status, created_at FROM reminders_old
      ''');
      await db.execute('DROP TABLE reminders_old');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_reminders_prescription_id ON ${DatabaseTables.reminders} (prescription_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_reminders_schedule_at ON ${DatabaseTables.reminders} (schedule_at)',
      );
    }
  }

  /// Menutup koneksi database yang sedang aktif.
  Future<void> close() async {
    final db = _database;
    _database = null;
    _initFuture = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }

  /// Menghapus seluruh file database lokal dan menginisialisasi ulang dari awal.
  Future<void> resetDatabase() async {
    await close();
    final path = await _resolveDatabasePath();
    if (path != inMemoryDatabasePath) {
      if (_customFactory != null) {
        await _customFactory.deleteDatabase(path);
      } else {
        await deleteDatabase(path);
      }
    }
    await database;
  }
}

