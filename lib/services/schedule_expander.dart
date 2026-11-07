import '../care_api.dart';

/// Mengurai string waktu (`"HH:mm"` atau ISO-8601) menjadi total menit sejak `00:00`.
int parseMinutesOfDay(String? raw, {int fallback = 8 * 60}) {
  if (raw == null || raw.trim().isEmpty) return fallback;
  final cleaned = raw
      .trim()
      .replaceAll(RegExp(r'\s*(WIB|WITA|WIT)\s*$', caseSensitive: false), '');

  final hmMatch = RegExp(
    r'^(0?\d|1\d|2[0-3])[:.]([0-5]\d)(?:[:.][0-5]\d)?$',
  ).firstMatch(cleaned);
  if (hmMatch != null) {
    final h = int.parse(hmMatch.group(1)!);
    final m = int.parse(hmMatch.group(2)!);
    return h * 60 + m;
  }

  final parsed = DateTime.tryParse(cleaned)?.toLocal();
  if (parsed != null) {
    return parsed.hour * 60 + parsed.minute;
  }
  return fallback;
}

/// Menghitung berapa kali minum (dosis) hingga stok `quantity` obat habis.
int calculateMedicationTotalDoses(Json medication, {int maxDoses = 540}) {
  final rawQty = (medication['quantity'] as num?)?.toInt() ?? 0;
  if (rawQty <= 0) return 0;

  final dosage = (medication['dosage'] as String? ?? '').trim();
  final discreteMatch = RegExp(
    r'^(\d+(?:[.,]\d+)?)\s*(tablet|tab|kapsul|kaplet|pil|butir|bungkus|sachet)\b',
    caseSensitive: false,
  ).firstMatch(dosage);

  var unitsPerDose = 1.0;
  if (discreteMatch != null) {
    final parsed = double.tryParse(
      discreteMatch.group(1)!.replaceAll(',', '.'),
    );
    if (parsed != null && parsed > 0) {
      unitsPerDose = parsed;
    }
  }

  final doses = (rawQty / unitsPerDose).ceil();
  return doses.clamp(1, maxDoses);
}

/// Mengurai frekuensi konsumsi harian dari teks seperti `"3x sehari"`, `"2 kali"`,
/// atau `"tiap 8 jam"`.
int parseDailyFrequency(String? rawFrequency, {int fallback = 1}) {
  final text = (rawFrequency ?? '').trim().toLowerCase();
  if (text.isEmpty) return fallback.clamp(1, 6);

  final hourlyMatch = RegExp(
    r'(?:tiap|setiap|per)\s*(\d+)\s*jam',
  ).firstMatch(text);
  if (hourlyMatch != null) {
    final hours = int.tryParse(hourlyMatch.group(1)!) ?? 0;
    if (hours > 0) {
      return (24 / hours).round().clamp(1, 6);
    }
  }

  final timesMatch = RegExp(r'(\d+)\s*(?:x|kali)\b').firstMatch(text);
  if (timesMatch != null) {
    final count = int.tryParse(timesMatch.group(1)!) ?? fallback;
    return count.clamp(1, 6);
  }

  if (text.contains('tiga kali')) return 3;
  if (text.contains('dua kali')) return 2;
  if (text.contains('sekali')) return 1;

  return fallback.clamp(1, 6);
}

bool _isTemplateMedicationReminder(Json reminder, List<String> medNamesLower) {
  final items = reminder['reminder_items'] as List?;
  if (items != null && items.isNotEmpty) return true;
  if (reminder['prescription_id'] != null) return true;

  final titleLower = ((reminder['title'] as String?) ?? '').toLowerCase();
  if (titleLower.startsWith('minum ') || titleLower.contains('obat')) {
    return true;
  }
  for (final name in medNamesLower) {
    if (name.isNotEmpty && titleLower.contains(name)) return true;
  }
  return false;
}

List<int> _dedupeSortedSlots(Iterable<int> rawSlots) {
  final sorted = rawSlots.map((s) => s.clamp(0, 23 * 60 + 59)).toList()..sort();
  final result = <int>[];
  for (final s in sorted) {
    if (result.isEmpty || (s - result.last).abs() >= 15) {
      result.add(s);
    }
  }
  return result;
}

List<int> _buildDailyMedicationSlots({
  required Json medication,
  required int freq,
  required List<int> aiSlots,
  required List<int> mealMinutes,
  required int wakeMinutes,
  required int sleepMinutes,
}) {
  final isAfterEat = medication['isAfterEat'] != false;
  final offset = isAfterEat ? 30 : -30;
  final instruction = ((medication['instruction'] as String?) ?? '')
      .toLowerCase();

  final breakfast = mealMinutes.isNotEmpty
      ? mealMinutes.first
      : (wakeMinutes + 60).clamp(5 * 60, 9 * 60);
  final lunch = mealMinutes.length >= 2
      ? mealMinutes[mealMinutes.length ~/ 2]
      : 12 * 60 + 30;
  final dinner = mealMinutes.length >= 3
      ? mealMinutes.last
      : (sleepMinutes - 150).clamp(17 * 60 + 30, 19 * 60 + 30);

  int clampAwake(int minutes) =>
      minutes.clamp(wakeMinutes, sleepMinutes).toInt();

  if (freq == 1) {
    int defaultSingle;
    if (instruction.contains('malam') || instruction.contains('tidur')) {
      defaultSingle = clampAwake(dinner + offset);
    } else if (instruction.contains('siang') || instruction.contains('sore')) {
      defaultSingle = clampAwake(lunch + offset);
    } else {
      defaultSingle = clampAwake(breakfast + offset);
    }

    if (aiSlots.isNotEmpty) {
      final aiFirst = aiSlots.first;
      final explicitlyMorning =
          instruction.contains('pagi') || instruction.contains('sarapan');
      if (explicitlyMorning && aiFirst >= 11 * 60) {
        return [defaultSingle];
      }
      return [aiFirst];
    }
    return [defaultSingle];
  }

  if (freq == 2) {
    if (aiSlots.length >= 2) return aiSlots.take(2).toList();
    final morning = clampAwake(breakfast + offset);
    final evening = clampAwake(dinner + offset);
    if (aiSlots.length == 1) {
      final only = aiSlots.first;
      if (only < 13 * 60) {
        final second = evening - only >= 240
            ? evening
            : (only + 480).clamp(only + 240, 23 * 60);
        return _dedupeSortedSlots([only, second]);
      } else {
        return _dedupeSortedSlots([morning, only]);
      }
    }
    return _dedupeSortedSlots([morning, evening]);
  }

  if (freq == 3) {
    if (aiSlots.length >= 3) return aiSlots.take(3).toList();
    final morning = clampAwake(breakfast + offset);
    final midday = clampAwake(lunch + offset);
    final evening = clampAwake(dinner + offset);
    return _dedupeSortedSlots([morning, midday, evening]);
  }

  if (aiSlots.length >= freq) return aiSlots.take(freq).toList();
  final spanStart = (wakeMinutes + 30).clamp(0, 22 * 60);
  final spanEnd = (sleepMinutes - 30).clamp(spanStart + 120, 23 * 60 + 30);
  final step = (spanEnd - spanStart) / (freq - 1);
  return [
    for (var i = 0; i < freq; i++) (spanStart + (step * i)).round(),
  ];
}

/// Memperluas template jadwal 1 hari dari AI menjadi jadwal multi-hari
/// dimulai dari jam `prescription.start_at` pada hari pertama, lalu disesuaikan
/// mengikuti jadwal rutin pada hari-hari berikutnya sampai seluruh obat habis.
List<Json> expandCareSchedule({
  required List<Json> templateReminders,
  required List<Json> prescriptions,
  required Json rutinitas,
  DateTime? baseDate,
  int maxCareDays = 90,
}) {
  final anchor = (baseDate ?? DateTime.now()).toLocal();
  final dayZero = DateTime(anchor.year, anchor.month, anchor.day);

  final allMeds = <({Json prescription, Json medication})>[
    for (final p in prescriptions)
      for (final m in (p['medications'] as List? ?? const []).whereType<Map>())
        (prescription: p, medication: Map<String, dynamic>.from(m)),
  ];

  // Jika tidak ada resep obat, gunakan jadwal 1 hari sebagaimana dikembalikan AI.
  if (allMeds.isEmpty) {
    final singleDay = [
      for (final r in templateReminders)
        <String, dynamic>{
          ...r,
          'status': (r['status'] as String?) ?? 'pending',
          'day_number': 1,
        },
    ];
    singleDay.sort(
      (a, b) => DateTime.parse(
        a['schedule_at'] as String,
      ).compareTo(DateTime.parse(b['schedule_at'] as String)),
    );
    return singleDay;
  }

  final medNamesLower = allMeds
      .map(
        (entry) =>
            ((entry.medication['medicine_name'] as String?) ?? '')
                .trim()
                .toLowerCase(),
      )
      .where((name) => name.isNotEmpty)
      .toList();

  final mealTemplates = <({Json template, int minutes})>[];
  final medTemplates = <({Json template, int minutes})>[];

  for (final r in templateReminders) {
    final mins = parseMinutesOfDay(r['schedule_at'] as String?);
    if (_isTemplateMedicationReminder(r, medNamesLower)) {
      medTemplates.add((template: r, minutes: mins));
    } else {
      mealTemplates.add((template: r, minutes: mins));
    }
  }
  mealTemplates.sort((a, b) => a.minutes.compareTo(b.minutes));

  final wakeMinutes = parseMinutesOfDay(
    rutinitas['jam_bangun']?.toString(),
    fallback: 6 * 60,
  );
  var sleepMinutes = parseMinutesOfDay(
    rutinitas['jam_tidur']?.toString(),
    fallback: 21 * 60,
  );
  if (sleepMinutes <= wakeMinutes + 120) {
    sleepMinutes = 21 * 60;
  }

  final mealMinutes = mealTemplates.map((m) => m.minutes).toList();
  final expandedMedReminders = <Json>[];
  var maxDayOffset = 0;
  var earliestStartMinutes = 24 * 60;

  for (final entry in allMeds) {
    final prescription = entry.prescription;
    final med = entry.medication;
    final medId = (med['id'] as num?)?.toInt();
    final prescId = (prescription['id'] as num?)?.toInt();
    final medName = (med['medicine_name'] as String? ?? 'Obat').trim();
    final medNameLower = medName.toLowerCase();

    // Cari slot waktu AI yang merujuk ke obat ini.
    final matchedTemplates = medTemplates.where((mt) {
      final rawItems = mt.template['reminder_items'] as List? ?? const [];
      final ids = rawItems
          .whereType<Map>()
          .map((item) => (item['medication_id'] as num?)?.toInt())
          .whereType<int>()
          .toSet();
      if (medId != null && ids.contains(medId)) return true;
      final titleLower =
          ((mt.template['title'] as String?) ?? '').toLowerCase();
      return medNameLower.isNotEmpty && titleLower.contains(medNameLower);
    }).toList();

    final aiSlots = _dedupeSortedSlots(matchedTemplates.map((m) => m.minutes));
    final freq = parseDailyFrequency(
      med['frequency']?.toString(),
      fallback: aiSlots.isNotEmpty ? aiSlots.length : 1,
    );
    final totalDoses = calculateMedicationTotalDoses(
      med,
      maxDoses: freq * maxCareDays,
    );
    if (totalDoses <= 0) continue;

    final dailySlots = _buildDailyMedicationSlots(
      medication: med,
      freq: freq,
      aiSlots: aiSlots,
      mealMinutes: mealMinutes,
      wakeMinutes: wakeMinutes,
      sleepMinutes: sleepMinutes,
    );

    final startMinutes = parseMinutesOfDay(
      prescription['start_at']?.toString(),
      fallback: dailySlots.first,
    );
    if (startMinutes < earliestStartMinutes) {
      earliestStartMinutes = startMinutes;
    }

    // Gunakan judul spesifik dari AI bila reminder tersebut hanya memuat 1 obat ini.
    String reminderTitle = 'Minum $medName';
    for (final mt in matchedTemplates) {
      final items = mt.template['reminder_items'] as List? ?? const [];
      final candidate = (mt.template['title'] as String?)?.trim();
      if (items.length <= 1 && candidate != null && candidate.isNotEmpty) {
        reminderTitle = candidate;
        break;
      }
    }

    // Hari 1: dosis pertama dimulai tepat pada jam `start_at` yang dipilih pengguna,
    // lalu diikuti slot harian tersisa pada hari tersebut yang memiliki jeda aman.
    final minGap = freq <= 2 ? 240 : (freq == 3 ? 180 : 120);
    final day1Slots = <int>[startMinutes];
    for (final s in dailySlots) {
      if (s > startMinutes &&
          day1Slots.length < freq &&
          (s - day1Slots.last) >= minGap) {
        day1Slots.add(s);
      }
    }

    var remaining = totalDoses;
    var doseNumber = 0;

    void addDoseReminder(int dayOffset, int slotMinutes) {
      doseNumber++;
      remaining--;
      if (dayOffset > maxDayOffset) maxDayOffset = dayOffset;
      final scheduledAt = DateTime(
        dayZero.year,
        dayZero.month,
        dayZero.day + dayOffset,
        slotMinutes ~/ 60,
        slotMinutes % 60,
      );
      expandedMedReminders.add({
        'title': reminderTitle,
        'schedule_at': scheduledAt.toIso8601String(),
        'status': 'pending',
        'prescription_id': prescId,
        'reminder_items': [
          if (medId != null) {'medication_id': medId},
        ],
        'dose_number': doseNumber,
        'total_doses': totalDoses,
        'day_number': dayOffset + 1,
      });
    }

    for (final slot in day1Slots) {
      if (remaining <= 0) break;
      addDoseReminder(0, slot);
    }

    // Hari ke-2 dan seterusnya: sesuaikan kembali ke jadwal harian normal sampai obat habis.
    var dayOffset = 1;
    while (remaining > 0 && dayOffset < maxCareDays) {
      for (final slot in dailySlots) {
        if (remaining <= 0) break;
        addDoseReminder(dayOffset, slot);
      }
      dayOffset++;
    }
  }

  if (earliestStartMinutes == 24 * 60) {
    earliestStartMinutes = 0;
  }

  // Perluas jadwal makan harian mengikuti rentang hari perawatan aktif.
  final expandedMealReminders = <Json>[];
  for (var dayOffset = 0; dayOffset <= maxDayOffset; dayOffset++) {
    for (final mt in mealTemplates) {
      if (dayOffset == 0 && mt.minutes < earliestStartMinutes - 60) {
        continue;
      }
      final scheduledAt = DateTime(
        dayZero.year,
        dayZero.month,
        dayZero.day + dayOffset,
        mt.minutes ~/ 60,
        mt.minutes % 60,
      );
      expandedMealReminders.add({
        ...mt.template,
        'schedule_at': scheduledAt.toIso8601String(),
        'status': 'pending',
        'prescription_id': null,
        'reminder_items': <Json>[],
        'day_number': dayOffset + 1,
      });
    }
  }

  final allReminders = <Json>[
    ...expandedMealReminders,
    ...expandedMedReminders,
  ];
  allReminders.sort((a, b) {
    final cmp = DateTime.parse(
      a['schedule_at'] as String,
    ).compareTo(DateTime.parse(b['schedule_at'] as String));
    if (cmp != 0) return cmp;
    final aIsMed = (a['reminder_items'] as List?)?.isNotEmpty == true ? 1 : 0;
    final bIsMed = (b['reminder_items'] as List?)?.isNotEmpty == true ? 1 : 0;
    return aIsMed.compareTo(bIsMed);
  });

  return allReminders;
}
