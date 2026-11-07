/// Pilihan status standar untuk resep obat (`prescription.status`).
enum PrescriptionStatus {
  active('active'),
  completed('completed'),
  paused('paused'),
  cancelled('cancelled');

  const PrescriptionStatus(this.value);
  final String value;

  static PrescriptionStatus? tryFromValue(String? raw) {
    if (raw == null) return null;
    for (final item in PrescriptionStatus.values) {
      if (item.value == raw) return item;
    }
    return null;
  }
}

/// Model untuk tabel `prescription`.
class Prescription {
  Prescription({
    this.id,
    required this.prescriptionDate,
    this.notes,
    this.status = 'active',
    this.startAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final DateTime prescriptionDate;
  final String? notes;
  final String status;
  final DateTime? startAt;
  final DateTime createdAt;

  PrescriptionStatus? get statusEnum => PrescriptionStatus.tryFromValue(status);

  Prescription copyWith({
    int? id,
    DateTime? prescriptionDate,
    String? notes,
    String? status,
    DateTime? startAt,
    DateTime? createdAt,
  }) {
    return Prescription(
      id: id ?? this.id,
      prescriptionDate: prescriptionDate ?? this.prescriptionDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      startAt: startAt ?? this.startAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'prescription_date': prescriptionDate.toIso8601String(),
      'notes': notes,
      'status': status,
      'start_at': startAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: (map['id'] as num?)?.toInt(),
      prescriptionDate: _parseDateTime(map['prescription_date']),
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? PrescriptionStatus.active.value,
      startAt: _tryParseDateTime(map['start_at']),
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  static DateTime? _tryParseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  static DateTime _parseDateTime(Object? value) {
    return _tryParseDateTime(value) ?? DateTime.now();
  }
}

