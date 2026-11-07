import '../database/database_helper.dart';
import '../database/database_tables.dart';
import '../models/models.dart';

/// Repository CRUD & relasi untuk `recipes`, `recipe_ingredients`, dan `recipe_nutrition`.
class RecipeRepository {
  RecipeRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  // ==================== RECIPES ====================

  Future<int> insertRecipe(Recipe recipe) async {
    final db = await _dbHelper.database;
    return db.insert(DatabaseTables.recipes, recipe.toMap());
  }

  Future<List<Recipe>> getAllRecipes() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.recipes,
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(Recipe.fromMap).toList();
  }

  Future<List<Recipe>> searchRecipes(String keyword) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.recipes,
      where: 'recipe_name LIKE ? OR description LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(Recipe.fromMap).toList();
  }

  Future<Recipe?> getRecipeById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.recipes,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Recipe.fromMap(rows.first);
  }

  Future<int> updateRecipe(Recipe recipe) async {
    if (recipe.id == null) {
      throw ArgumentError('Recipe.id tidak boleh null saat update.');
    }
    final db = await _dbHelper.database;
    return db.update(
      DatabaseTables.recipes,
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  /// Menghapus `recipes` (otomatis menghapus `recipe_ingredients` & `recipe_nutrition` karena ON DELETE CASCADE).
  Future<int> deleteRecipe(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      DatabaseTables.recipes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== INGREDIENTS ====================

  Future<int> insertIngredient(RecipeIngredient ingredient) async {
    final db = await _dbHelper.database;
    return db.insert(DatabaseTables.recipeIngredients, ingredient.toMap());
  }

  Future<List<RecipeIngredient>> getIngredientsByRecipe(int recipeId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.recipeIngredients,
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      orderBy: 'id ASC',
    );
    return rows.map(RecipeIngredient.fromMap).toList();
  }

  Future<int> updateIngredient(RecipeIngredient ingredient) async {
    if (ingredient.id == null) {
      throw ArgumentError('RecipeIngredient.id tidak boleh null saat update.');
    }
    final db = await _dbHelper.database;
    return db.update(
      DatabaseTables.recipeIngredients,
      ingredient.toMap(),
      where: 'id = ?',
      whereArgs: [ingredient.id],
    );
  }

  Future<int> deleteIngredient(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      DatabaseTables.recipeIngredients,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== NUTRITION ====================

  Future<int> insertNutrition(RecipeNutrition nutrition) async {
    final db = await _dbHelper.database;
    return db.insert(DatabaseTables.recipeNutrition, nutrition.toMap());
  }

  Future<RecipeNutrition?> getNutritionByRecipe(int recipeId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.recipeNutrition,
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RecipeNutrition.fromMap(rows.first);
  }

  Future<int> updateNutrition(RecipeNutrition nutrition) async {
    if (nutrition.id == null) {
      throw ArgumentError('RecipeNutrition.id tidak boleh null saat update.');
    }
    final db = await _dbHelper.database;
    return db.update(
      DatabaseTables.recipeNutrition,
      nutrition.toMap(),
      where: 'id = ?',
      whereArgs: [nutrition.id],
    );
  }

  Future<int> deleteNutrition(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      DatabaseTables.recipeNutrition,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== TRANSACTIONAL & COMPOSITE QUERIES ====================

  /// Menyimpan `Recipe` beserta daftar bahan (`ingredients`) dan `nutrition` dalam 1 transaksi atomik.
  Future<int> insertRecipeWithDetails({
    required Recipe recipe,
    List<RecipeIngredient> ingredients = const [],
    RecipeNutrition? nutrition,
  }) async {
    final db = await _dbHelper.database;
    return db.transaction<int>((txn) async {
      final recipeId = await txn.insert(
        DatabaseTables.recipes,
        recipe.toMap(),
      );
      for (final ingredient in ingredients) {
        final item = ingredient.copyWith(recipeId: recipeId);
        await txn.insert(DatabaseTables.recipeIngredients, item.toMap());
      }
      if (nutrition != null) {
        final nut = nutrition.copyWith(recipeId: recipeId);
        await txn.insert(DatabaseTables.recipeNutrition, nut.toMap());
      }
      return recipeId;
    });
  }

  /// Mengambil detail lengkap `Recipe` beserta bahan dan nutrisinya.
  Future<RecipeDetail?> getRecipeDetail(int recipeId) async {
    final recipe = await getRecipeById(recipeId);
    if (recipe == null) return null;

    final ingredients = await getIngredientsByRecipe(recipeId);
    final nutrition = await getNutritionByRecipe(recipeId);

    return RecipeDetail(
      recipe: recipe,
      ingredients: ingredients,
      nutrition: nutrition,
    );
  }

  /// Mengambil seluruh daftar `RecipeDetail` lengkap.
  Future<List<RecipeDetail>> getAllRecipeDetails() async {
    final recipes = await getAllRecipes();
    final details = <RecipeDetail>[];
    for (final recipe in recipes) {
      final ingredients = await getIngredientsByRecipe(recipe.id!);
      final nutrition = await getNutritionByRecipe(recipe.id!);
      details.add(
        RecipeDetail(
          recipe: recipe,
          ingredients: ingredients,
          nutrition: nutrition,
        ),
      );
    }
    return details;
  }
}

