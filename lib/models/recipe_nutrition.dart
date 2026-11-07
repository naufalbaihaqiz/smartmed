/// Model untuk tabel `recipe_nutrition`.
class RecipeNutrition {
  RecipeNutrition({
    this.id,
    required this.recipeId,
    this.calories,
    this.protein,
    this.carbohydrates,
    this.fat,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final int recipeId;
  final double? calories;
  final double? protein;
  final double? carbohydrates;
  final double? fat;
  final DateTime createdAt;

  RecipeNutrition copyWith({
    int? id,
    int? recipeId,
    double? calories,
    double? protein,
    double? carbohydrates,
    double? fat,
    DateTime? createdAt,
  }) {
    return RecipeNutrition(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbohydrates: carbohydrates ?? this.carbohydrates,
      fat: fat ?? this.fat,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'recipe_id': recipeId,
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RecipeNutrition.fromMap(Map<String, dynamic> map) {
    return RecipeNutrition(
      id: (map['id'] as num?)?.toInt(),
      recipeId: (map['recipe_id'] as num).toInt(),
      calories: _toDouble(map['calories']),
      protein: _toDouble(map['protein']),
      carbohydrates: _toDouble(map['carbohydrates']),
      fat: _toDouble(map['fat']),
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }
}

