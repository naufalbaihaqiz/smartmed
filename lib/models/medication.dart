/// Model untuk tabel `medications`.
class DoseTypeOption {
  const DoseTypeOption({
    required this.code,
    required this.name,
    required this.doseUnit,
    required this.quantityUnit,
    required this.doseHint,
    required this.quantityHint,
  });

  final String code;
  final String name;
  final String doseUnit;
  final String quantityUnit;
  final String doseHint;
  final String quantityHint;
}

const List<DoseTypeOption> doseTypeOptions = [
  DoseTypeOption(
    code: 'TABLET',
    name: 'TABLET ("tablet")',
    doseUnit: 'tablet',
    quantityUnit: 'tablet',
    doseHint: 'Contoh: 1 tablet',
    quantityHint: '10',
  ),
  DoseTypeOption(
    code: 'KAPSUL',
    name: 'KAPSUL ("kapsul")',
    doseUnit: 'kapsul',
    quantityUnit: 'kapsul',
    doseHint: 'Contoh: 1 kapsul',
    quantityHint: '10',
  ),
  DoseTypeOption(
    code: 'SIRUP_SPOON',
    name: 'SIRUP_SPOON ("sendok makan" / 15 ml)',
    doseUnit: 'sdm (15 ml)',
    quantityUnit: 'ml',
    doseHint: 'Contoh: 1 sendok makan (15 ml)',
    quantityHint: '60',
  ),
  DoseTypeOption(
    code: 'TEASPOON',
    name: 'TEASPOON ("sendok teh" / 5 ml)',
    doseUnit: 'sdt (5 ml)',
    quantityUnit: 'ml',
    doseHint: 'Contoh: 1 sendok teh (5 ml)',
    quantityHint: '60',
  ),
  DoseTypeOption(
    code: 'BUNGKUS',
    name: 'BUNGKUS ("bungkus" / puyer)',
    doseUnit: 'bungkus',
    quantityUnit: 'bungkus',
    doseHint: 'Contoh: 1 bungkus',
    quantityHint: '10',
  ),
];

DoseTypeOption getDoseTypeOption(String? code) {
  if (code == null) return doseTypeOptions.first;
  final upper = code.trim().toUpperCase();
  for (final opt in doseTypeOptions) {
    if (opt.code == upper) return opt;
  }
  return doseTypeOptions.first;
}

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
    this.doseType = 'TABLET',
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
  final String? doseType;
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
    String? doseType,
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
      doseType: doseType ?? this.doseType,
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
      'dose_type': doseType,
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
      doseType: (map['dose_type'] as String?) ?? 'TABLET',
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

