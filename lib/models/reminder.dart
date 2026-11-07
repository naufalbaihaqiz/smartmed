/// Pilihan status standar untuk jadwal pengingat (`reminders.status`).
enum ReminderStatus {
  pending('pending'),
  completed('completed'),
  missed('missed'),
  skipped('skipped'),
  snoozed('snoozed');

  const ReminderStatus(this.value);
  final String value;

  static ReminderStatus? tryFromValue(String? raw) {
    if (raw == null) return null;
    for (final item in ReminderStatus.values) {
      if (item.value == raw) return item;
    }
    return null;
  }
}

/// Model untuk tabel `reminders`.
class Reminder {
  Reminder({
    this.id,
    this.prescriptionId,
    required this.title,
    required this.scheduleAt,
    this.status = 'pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final int? prescriptionId;
  final String title;
  final DateTime scheduleAt;
  final String status;
  final DateTime createdAt;

  ReminderStatus? get statusEnum => ReminderStatus.tryFromValue(status);

  Reminder copyWith({
    int? id,
    int? prescriptionId,
    String? title,
    DateTime? scheduleAt,
    String? status,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      title: title ?? this.title,
      scheduleAt: scheduleAt ?? this.scheduleAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'prescription_id': prescriptionId,
      'title': title,
      'schedule_at': scheduleAt.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: (map['id'] as num?)?.toInt(),
      prescriptionId: (map['prescription_id'] as num?)?.toInt(),
      title: map['title'] as String? ?? '',
      scheduleAt: _parseDateTime(map['schedule_at']),
      status: map['status'] as String? ?? ReminderStatus.pending.value,
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

