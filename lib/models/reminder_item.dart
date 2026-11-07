/// Model untuk tabel `reminder_items`.
class ReminderItem {
  ReminderItem({
    this.id,
    required this.reminderId,
    required this.medicationId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final int reminderId;
  final int medicationId;
  final DateTime createdAt;

  ReminderItem copyWith({
    int? id,
    int? reminderId,
    int? medicationId,
    DateTime? createdAt,
  }) {
    return ReminderItem(
      id: id ?? this.id,
      reminderId: reminderId ?? this.reminderId,
      medicationId: medicationId ?? this.medicationId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'reminder_id': reminderId,
      'medication_id': medicationId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReminderItem.fromMap(Map<String, dynamic> map) {
    return ReminderItem(
      id: (map['id'] as num?)?.toInt(),
      reminderId: (map['reminder_id'] as num).toInt(),
      medicationId: (map['medication_id'] as num).toInt(),
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

