import 'package:flutter_test/flutter_test.dart';
import 'package:smartmed_nutricare/database/database_helper.dart';
import 'package:smartmed_nutricare/database/database_tables.dart';
import 'package:smartmed_nutricare/models/models.dart';
import 'package:smartmed_nutricare/repositories/repositories.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late DatabaseHelper dbHelper;
  late HealthConditionRepository healthRepo;
  late AllergyRepository allergyRepo;
  late PrescriptionRepository prescriptionRepo;
  late RecipeRepository recipeRepo;

  setUp(() async {
    dbHelper = DatabaseHelper.custom(
      customFactory: databaseFactoryFfi,
      customDbPath: inMemoryDatabasePath,
    );
    healthRepo = HealthConditionRepository(dbHelper: dbHelper);
    allergyRepo = AllergyRepository(dbHelper: dbHelper);
    prescriptionRepo = PrescriptionRepository(dbHelper: dbHelper);
    recipeRepo = RecipeRepository(dbHelper: dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  test('Semua 9 tabel terbuat beserta kolom created_at', () async {
    final db = await dbHelper.database;

    final tableRows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
    );
    final createdTables = tableRows.map((r) => r['name'] as String).toSet();

    expect(createdTables, containsAll(DatabaseTables.allTables));

    for (final table in DatabaseTables.allTables) {
      final columns = await db.rawQuery('PRAGMA table_info($table)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      if (table == DatabaseTables.healthCondition) {
        expect(columnNames, contains('name'));
      }
      expect(
        columnNames,
        contains('id'),
        reason: 'Tabel $table harus memiliki kolom id',
      );
      expect(
        columnNames,
        contains('created_at'),
        reason: 'Tabel $table harus memiliki kolom created_at',
      );
    }
  });

  test('CRUD health_condition dan allergies berjalan dengan benar', () async {
    final conditionId = await healthRepo.insert(
      HealthCondition(
        name: 'Ibu Sari',
        conditionName: 'Hipertensi',
        diagnosis: 'Tekanan darah tinggi tingkat 1',
        notes: 'Kurangi konsumsi garam',
        age: 45,
        weight: 68.50,
        height: 170.25,
        isTherePrescription: true,
      ),
    );

    final condition = await healthRepo.getById(conditionId);
    expect(condition, isNotNull);
    expect(condition!.name, 'Ibu Sari');
    expect(condition.conditionName, 'Hipertensi');
    expect(condition.weight, 68.50);
    expect(condition.height, 170.25);
    expect(condition.isTherePrescription, isTrue);

    final allergyId = await allergyRepo.insert(
      Allergy(type: 'Kacang Tanah'),
    );
    final allergies = await allergyRepo.getAll();
    expect(allergies.length, 1);
    expect(allergies.first.id, allergyId);
    expect(allergies.first.type, 'Kacang Tanah');
  });

  test(
    'Relasi prescription, medications, reminders, reminder_items & ON DELETE CASCADE',
    () async {
      final prescriptionId = await prescriptionRepo
          .insertPrescriptionWithMedications(
            prescription: Prescription(
              prescriptionDate: DateTime(2026, 11, 7),
              notes: 'Resep kontrol bulanan',
              status: PrescriptionStatus.active.value,
              startAt: DateTime(2026, 11, 8, 7, 0),
            ),
            medications: [
              Medication(
                prescriptionId: 0,
                medicineName: 'Amlodipine',
                dosage: '5 mg',
                frequency: '1x sehari',
                instruction: 'Diminum pagi hari',
                quantity: 30,
                notes: 'Jangan terlewat',
                isAfterEat: true,
              ),
            ],
          );

      final meds = await prescriptionRepo.getMedicationsByPrescription(
        prescriptionId,
      );
      expect(meds.length, 1);
      expect(meds.first.isAfterEat, isTrue);

      final reminderId = await prescriptionRepo.insertReminderWithMedications(
        reminder: Reminder(
          prescriptionId: prescriptionId,
          title: 'Minum Obat Pagi',
          scheduleAt: DateTime(2026, 11, 8, 7, 30),
          status: ReminderStatus.pending.value,
        ),
        medicationIds: [meds.first.id!],
      );
      expect(reminderId, greaterThan(0));

      final detail = await prescriptionRepo.getPrescriptionDetail(
        prescriptionId,
      );
      expect(detail, isNotNull);
      expect(detail!.reminders.length, 1);
      expect(detail.reminders.first.medications.first.medicineName, 'Amlodipine');

      // Hapus prescription -> cascade menghapus medications, reminders, reminder_items
      await prescriptionRepo.deletePrescription(prescriptionId);
      expect(
        await prescriptionRepo.getMedicationsByPrescription(prescriptionId),
        isEmpty,
      );
      expect(
        await prescriptionRepo.getRemindersByPrescription(prescriptionId),
        isEmpty,
      );
      expect(await prescriptionRepo.getItemsByReminder(reminderId), isEmpty);
    },
  );

  test(
    'Relasi recipes, recipe_ingredients, recipe_nutrition & ON DELETE CASCADE',
    () async {
      final recipeId = await recipeRepo.insertRecipeWithDetails(
        recipe: Recipe(
          recipeName: 'Sup Ayam Rendah Garam',
          description: 'Cocok untuk penderita hipertensi',
          servings: 2,
          cookingTime: 25,
          instructions: 'Rebus dada ayam bersama sayuran segar.',
          source: 'SmartMed NutriCare',
        ),
        ingredients: [
          RecipeIngredient(
            recipeId: 0,
            ingredientName: 'Dada Ayam Tanpa Kulit',
            quantity: '200 gram',
          ),
          RecipeIngredient(
            recipeId: 0,
            ingredientName: 'Wortel',
            quantity: '1 buah',
          ),
        ],
        nutrition: RecipeNutrition(
          recipeId: 0,
          calories: 245.50,
          protein: 32.40,
          carbohydrates: 12.80,
          fat: 5.20,
        ),
      );

      final detail = await recipeRepo.getRecipeDetail(recipeId);
      expect(detail, isNotNull);
      expect(detail!.ingredients.length, 2);
      expect(detail.nutrition, isNotNull);
      expect(detail.nutrition!.calories, 245.50);
      expect(detail.nutrition!.protein, 32.40);

      await recipeRepo.deleteRecipe(recipeId);
      expect(await recipeRepo.getIngredientsByRecipe(recipeId), isEmpty);
      expect(await recipeRepo.getNutritionByRecipe(recipeId), isNull);
    },
  );
}

