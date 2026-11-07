/// Model untuk tabel `medications`.
class Medication {
  Medication({
    this.id,
    required this.prescriptionId,
    required this.medicineName,
    this.dosage,
    this.frequency,
    this.instruction,
    this.quantity,
    this.notes,
    this.isAfterEat = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final int prescriptionId;
  final String medicineName;
  final String? dosage;
  final String? frequency;
  final String? instruction;
  final int? quantity;
  final String? notes;
  final bool isAfterEat;
  final DateTime createdAt;

  Medication copyWith({
    int? id,
    int? prescriptionId,
    String? medicineName,
    String? dosage,
    String? frequency,
    String? instruction,
    int? quantity,
    String? notes,
    bool? isAfterEat,
    DateTime? createdAt,
  }) {
    return Medication(
      id: id ?? this.id,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      instruction: instruction ?? this.instruction,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      isAfterEat: isAfterEat ?? this.isAfterEat,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'prescription_id': prescriptionId,
      'medicine_name': medicineName,
      'dosage': dosage,
      'frequency': frequency,
      'instruction': instruction,
      'quantity': quantity,
      'notes': notes,
      'isAfterEat': isAfterEat ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    final rawAfterEat = map['isAfterEat'] ?? map['is_after_eat'];
    return Medication(
      id: (map['id'] as num?)?.toInt(),
      prescriptionId: (map['prescription_id'] as num).toInt(),
      medicineName: map['medicine_name'] as String? ?? '',
      dosage: map['dosage'] as String?,
      frequency: map['frequency'] as String?,
      instruction: map['instruction'] as String?,
      quantity: (map['quantity'] as num?)?.toInt(),
      notes: map['notes'] as String?,
      isAfterEat: _parseBool(rawAfterEat),
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

