/// Model untuk tabel `recipes`.
class Recipe {
  Recipe({
    this.id,
    required this.recipeName,
    this.description,
    this.servings,
    this.cookingTime,
    this.instructions,
    this.source,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final String recipeName;
  final String? description;
  final int? servings;
  final int? cookingTime;
  final String? instructions;
  final String? source;
  final DateTime createdAt;

  Recipe copyWith({
    int? id,
    String? recipeName,
    String? description,
    int? servings,
    int? cookingTime,
    String? instructions,
    String? source,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      recipeName: recipeName ?? this.recipeName,
      description: description ?? this.description,
      servings: servings ?? this.servings,
      cookingTime: cookingTime ?? this.cookingTime,
      instructions: instructions ?? this.instructions,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'recipe_name': recipeName,
      'description': description,
      'servings': servings,
      'cooking_time': cookingTime,
      'instructions': instructions,
      'source': source,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: (map['id'] as num?)?.toInt(),
      recipeName: map['recipe_name'] as String? ?? '',
      description: map['description'] as String?,
      servings: (map['servings'] as num?)?.toInt(),
      cookingTime: (map['cooking_time'] as num?)?.toInt(),
      instructions: map['instructions'] as String?,
      source: map['source'] as String?,
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

