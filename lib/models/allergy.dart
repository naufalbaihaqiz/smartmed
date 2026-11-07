/// Model untuk tabel `allergies`.
class Allergy {
  Allergy({
    this.id,
    required this.type,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final String type;
  final DateTime createdAt;

  Allergy copyWith({
    int? id,
    String? type,
    DateTime? createdAt,
  }) {
    return Allergy(
      id: id ?? this.id,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Allergy.fromMap(Map<String, dynamic> map) {
    return Allergy(
      id: (map['id'] as num?)?.toInt(),
      type: map['type'] as String? ?? '',
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

