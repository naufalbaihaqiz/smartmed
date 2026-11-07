/// Model untuk tabel `recipe_ingredients`.
class RecipeIngredient {
  RecipeIngredient({
    this.id,
    required this.recipeId,
    required this.ingredientName,
    this.quantity,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final int recipeId;
  final String ingredientName;
  final String? quantity;
  final DateTime createdAt;

  RecipeIngredient copyWith({
    int? id,
    int? recipeId,
    String? ingredientName,
    String? quantity,
    DateTime? createdAt,
  }) {
    return RecipeIngredient(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      ingredientName: ingredientName ?? this.ingredientName,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'recipe_id': recipeId,
      'ingredient_name': ingredientName,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      id: (map['id'] as num?)?.toInt(),
      recipeId: (map['recipe_id'] as num).toInt(),
      ingredientName: map['ingredient_name'] as String? ?? '',
      quantity: map['quantity'] as String?,
      createdAt: _parseDateTime(map['created_at']),
    );
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

