/// Konstanta nama database, tabel, dan query DDL SQLite untuk aplikasi SmartMed.
class DatabaseTables {
  DatabaseTables._();

  static const String databaseName = 'smartmed_local.db';
  static const int databaseVersion = 5;

  // Nama-nama tabel
  static const String healthCondition = 'health_condition';
  static const String allergies = 'allergies';
  static const String prescription = 'prescription';
  static const String medications = 'medications';
  static const String reminders = 'reminders';
  static const String reminderItems = 'reminder_items';
  static const String recipes = 'recipes';
  static const String recipeIngredients = 'recipe_ingredients';
  static const String recipeNutrition = 'recipe_nutrition';
  static const String carePlans = 'care_plans';

  /// Daftar seluruh nama tabel berurutan berdasarkan dependensi Foreign Key.
  static const List<String> allTables = [
    healthCondition,
    allergies,
    prescription,
    medications,
    reminders,
    reminderItems,
    recipes,
    recipeIngredients,
    recipeNutrition,
  ];

  // 1. health_condition
  static const String createHealthConditionTable = '''
    CREATE TABLE $healthCondition (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name VARCHAR(255) NOT NULL DEFAULT '',
      condition_name TEXT NOT NULL,
      diagnosis TEXT,
      notes TEXT,
      age INTEGER,
      weight REAL,
      height REAL,
      isTherePrescription INTEGER NOT NULL DEFAULT 0 CHECK (isTherePrescription IN (0, 1)),
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  // 2. allergies
  static const String createAllergiesTable = '''
    CREATE TABLE $allergies (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  // 3. prescription
  static const String createPrescriptionTable = '''
    CREATE TABLE $prescription (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      prescription_date TEXT NOT NULL,
      notes TEXT,
      status TEXT NOT NULL DEFAULT 'active',
      start_at TEXT,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  // 4. medications
  static const String createMedicationsTable = '''
    CREATE TABLE $medications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      prescription_id INTEGER NOT NULL,
      medicine_name TEXT NOT NULL,
      dosage TEXT,
      frequency TEXT,
      instruction TEXT,
      quantity INTEGER,
      notes TEXT,
      isAfterEat INTEGER NOT NULL DEFAULT 0 CHECK (isAfterEat IN (0, 1)),
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (prescription_id) REFERENCES $prescription (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
    )
  ''';

  // 5. reminders
  static const String createRemindersTable = '''
    CREATE TABLE $reminders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      prescription_id INTEGER,
      title TEXT NOT NULL,
      schedule_at TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (prescription_id) REFERENCES $prescription (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
    )
  ''';

  // 6. reminder_items
  static const String createReminderItemsTable = '''
    CREATE TABLE $reminderItems (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      reminder_id INTEGER NOT NULL,
      medication_id INTEGER NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (reminder_id) REFERENCES $reminders (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
      FOREIGN KEY (medication_id) REFERENCES $medications (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
    )
  ''';

  // 7. recipes
  static const String createRecipesTable = '''
    CREATE TABLE $recipes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      recipe_name TEXT NOT NULL,
      description TEXT,
      servings INTEGER,
      cooking_time INTEGER,
      instructions TEXT,
      source TEXT,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  // 8. recipe_ingredients
  static const String createRecipeIngredientsTable = '''
    CREATE TABLE $recipeIngredients (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      recipe_id INTEGER NOT NULL,
      ingredient_name TEXT NOT NULL,
      quantity TEXT,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (recipe_id) REFERENCES $recipes (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
    )
  ''';

  // 9. recipe_nutrition
  static const String createRecipeNutritionTable = '''
    CREATE TABLE $recipeNutrition (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      recipe_id INTEGER NOT NULL,
      calories REAL,
      protein REAL,
      carbohydrates REAL,
      fat REAL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (recipe_id) REFERENCES $recipes (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
    )
  ''';

  // 10. care_plans (menyimpan profil pasien lengkap, resep, dan jadwal harian)
  static const String createCarePlansTable = '''
    CREATE TABLE IF NOT EXISTS $carePlans (
      id TEXT PRIMARY KEY,
      patient_name TEXT NOT NULL,
      plan_json TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  /// Daftar statement pembuatan tabel sesuai urutan Foreign Key.
  static const List<String> createTableStatements = [
    createHealthConditionTable,
    createAllergiesTable,
    createPrescriptionTable,
    createMedicationsTable,
    createRemindersTable,
    createReminderItemsTable,
    createRecipesTable,
    createRecipeIngredientsTable,
    createRecipeNutritionTable,
    createCarePlansTable,
  ];

  /// Index untuk mempercepat query relasi Foreign Key dan jadwal pengingat.
  static const List<String> createIndexStatements = [
    'CREATE INDEX idx_medications_prescription_id ON $medications (prescription_id)',
    'CREATE INDEX idx_reminders_prescription_id ON $reminders (prescription_id)',
    'CREATE INDEX idx_reminders_schedule_at ON $reminders (schedule_at)',
    'CREATE INDEX idx_reminder_items_reminder_id ON $reminderItems (reminder_id)',
    'CREATE INDEX idx_reminder_items_medication_id ON $reminderItems (medication_id)',
    'CREATE INDEX idx_recipe_ingredients_recipe_id ON $recipeIngredients (recipe_id)',
    'CREATE INDEX idx_recipe_nutrition_recipe_id ON $recipeNutrition (recipe_id)',
  ];
}

