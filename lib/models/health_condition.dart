/// Model untuk tabel `health_condition`.
class HealthCondition {
  HealthCondition({
    this.id,
    required this.name,
    required this.conditionName,
    this.diagnosis,
    this.notes,
    this.age,
    this.weight,
    this.height,
    this.isTherePrescription = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final String name;
  final String conditionName;
  final String? diagnosis;
  final String? notes;
  final int? age;
  final double? weight;
  final double? height;
  final bool isTherePrescription;
  final DateTime createdAt;

  HealthCondition copyWith({
    int? id,
    String? name,
    String? conditionName,
    String? diagnosis,
    String? notes,
    int? age,
    double? weight,
    double? height,
    bool? isTherePrescription,
    DateTime? createdAt,
  }) {
    return HealthCondition(
      id: id ?? this.id,
      name: name ?? this.name,
      conditionName: conditionName ?? this.conditionName,
      diagnosis: diagnosis ?? this.diagnosis,
      notes: notes ?? this.notes,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      isTherePrescription: isTherePrescription ?? this.isTherePrescription,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'name': name,
      'condition_name': conditionName,
      'diagnosis': diagnosis,
      'notes': notes,
      'age': age,
      'weight': weight,
      'height': height,
      'isTherePrescription': isTherePrescription ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HealthCondition.fromMap(Map<String, dynamic> map) {
    final rawHasPrescription =
        map['isTherePrescription'] ?? map['is_there_prescription'];
    return HealthCondition(
      id: (map['id'] as num?)?.toInt(),
      name: map['name'] as String? ?? '',
      conditionName: map['condition_name'] as String? ?? '',
      diagnosis: map['diagnosis'] as String?,
      notes: map['notes'] as String?,
      age: (map['age'] as num?)?.toInt(),
      weight: _toDouble(map['weight']),
      height: _toDouble(map['height']),
      isTherePrescription: _parseBool(rawHasPrescription),
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  static bool _parseBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == '1' || normalized == 'true';
    }
    return false;
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

