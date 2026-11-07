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

/// Membersihkan judul jadwal makan agar tidak menampilkan nama masakan
/// (cukup pengingat makan saja sesuai waktu).
String cleanMealTitle(String? rawTitle, int minutes) {
  final hour = minutes ~/ 60;
  if (hour < 11) return 'Waktu Sarapan';
  if (hour < 16) return 'Waktu Makan Siang';
  return 'Waktu Makan Malam';
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
  // Jika sebelum makan: obat diminum 5 menit sebelum makan (makan 5 menit setelah obat)
  // Jika sesudah makan: obat diminum 30 menit setelah makan (makan 30 menit sebelum obat)
  final offset = isAfterEat ? 30 : -5;
  final instruction = ((medication['instruction'] as String?) ?? '')
      .toLowerCase();

  // Aturan klinis: Makan malam paling lama 2 jam sebelum jam tidur (sleepMinutes - 120 menit)
  final maxDinner = (sleepMinutes - 120).clamp(17 * 60, 21 * 60);

  final breakfast = mealMinutes.isNotEmpty
      ? mealMinutes.first
      : (wakeMinutes + 60).clamp(5 * 60, 9 * 60);
  final dinner = mealMinutes.length >= 3
      ? mealMinutes.last.clamp(17 * 60, maxDinner)
      : maxDinner;
  final lunch = mealMinutes.length >= 2
      ? mealMinutes[mealMinutes.length ~/ 2]
      : ((breakfast + dinner) ~/ 2);

  int clampAwake(int minutes) =>
      minutes.clamp(wakeMinutes, sleepMinutes).toInt();

  final safeFreq = freq.clamp(1, 6);

  if (safeFreq == 1) {
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

  // Waktu awal dosis obat (sarapan) dan waktu akhir dosis obat (makan malam, paling lama 2 jam sebelum tidur)
  final startFirst = clampAwake(breakfast + offset);
  final endLast = clampAwake(dinner + offset);

  // Membagi waktu total antara jam bangun tidur dan jam tidur secara merata
  // menghasilkan interval waktu yang konsisten antar jadwal minum obat
  final span = (endLast - startFirst).clamp(120, 24 * 60);
  final step = span / (safeFreq - 1);

  final rawSlots = <int>[];
  for (var i = 0; i < safeFreq; i++) {
    final slot = (startFirst + (step * i)).round();
    rawSlots.add(slot);
  }

  return _dedupeSortedSlots(rawSlots);
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
  // Pastikan tidak ada kategori makan yang sama dalam 1 hari dan makan malam paling lama 2 jam sebelum tidur.
  if (allMeds.isEmpty) {
    final sleepMins = parseMinutesOfDay(
      rutinitas['jam_tidur']?.toString(),
      fallback: 22 * 60,
    );
    final maxDinner = (sleepMins - 120).clamp(17 * 60, 21 * 60);
    final seenCategories = <String>{};
    final singleDay = <Json>[];
    for (final r in templateReminders) {
      final mins = parseMinutesOfDay(r['schedule_at'] as String?);
      final mealTitle = cleanMealTitle(r['title'] as String?, mins);
      if (seenCategories.contains(mealTitle)) {
        continue;
      }
      seenCategories.add(mealTitle);
      var adjustedScheduleAt = r['schedule_at'] as String?;
      if (mealTitle == 'Waktu Makan Malam' && mins > maxDinner) {
        final parsedDt = DateTime.tryParse(adjustedScheduleAt ?? '');
        if (parsedDt != null) {
          adjustedScheduleAt = DateTime(
            parsedDt.year,
            parsedDt.month,
            parsedDt.day,
            maxDinner ~/ 60,
            maxDinner % 60,
          ).toIso8601String();
        }
      }
      singleDay.add({
        ...r,
        'title': mealTitle,
        if (adjustedScheduleAt != null) 'schedule_at': adjustedScheduleAt,
        'status': (r['status'] as String?) ?? 'pending',
        'day_number': 1,
      });
    }
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
        'isAfterEat': med['isAfterEat'] == true,
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
  // Pastikan: Dalam 1 hari TIDAK BOLEH ada kategori makan yang sama
  // (maksimal tepat 1 Waktu Sarapan, 1 Waktu Makan Siang, 1 Waktu Makan Malam per hari).
  final expandedMealReminders = <Json>[];
  for (var dayOffset = 0; dayOffset <= maxDayOffset; dayOffset++) {
    final seenCategoriesThisDay = <String>{};
    for (final mt in mealTemplates) {
      if (dayOffset == 0 && mt.minutes < earliestStartMinutes - 60) {
        continue;
      }
      final mealTitle = cleanMealTitle(mt.template['title'] as String?, mt.minutes);
      if (seenCategoriesThisDay.contains(mealTitle)) {
        continue;
      }
      seenCategoriesThisDay.add(mealTitle);

      final maxDinner = (sleepMinutes - 120).clamp(17 * 60, 21 * 60);
      final mealMinutesEffective = (mealTitle == 'Waktu Makan Malam' && mt.minutes > maxDinner)
          ? maxDinner
          : mt.minutes;

      final scheduledAt = DateTime(
        dayZero.year,
        dayZero.month,
        dayZero.day + dayOffset,
        mealMinutesEffective ~/ 60,
        mealMinutesEffective % 60,
      );
      expandedMealReminders.add({
        ...mt.template,
        'title': mealTitle,
        'schedule_at': scheduledAt.toIso8601String(),
        'status': 'pending',
        'prescription_id': null,
        'reminder_items': <Json>[],
        'day_number': dayOffset + 1,
      });
    }
  }

  // Sinkronisasi jadwal makan dan jadwal minum obat per hari & per sesi:
  // Aturan klinis mutlak:
  // 1. Obat sebelum makan (isAfterEat == false) harus diminum 5 menit SEBELUM makan.
  // 2. Obat sesudah makan (isAfterEat == true) harus diminum 30 menit SETELAH makan.
  // 3. Obat sebelum makan dan obat sesudah makan di sesi yang sama harus berjarak 35 menit.
  // 4. Jadwal makan di hari ke-1 (dan setiap hari) harus selaras dengan jam obat yang aktif di sesi tersebut.
  for (var dayOffset = 0; dayOffset <= maxDayOffset; dayOffset++) {
    final dayMedReminders = expandedMedReminders
        .where((r) => r['day_number'] == dayOffset + 1)
        .toList();

    final sessions = [
      (check: (int h) => h < 11, category: 'Waktu Sarapan'),
      (check: (int h) => h >= 11 && h < 16, category: 'Waktu Makan Siang'),
      (check: (int h) => h >= 16, category: 'Waktu Makan Malam'),
    ];

    for (final session in sessions) {
      final sessionMeds = dayMedReminders.where((r) {
        final dt = DateTime.parse(r['schedule_at'] as String);
        return session.check(dt.hour);
      }).toList();

      if (sessionMeds.isEmpty) continue;

      final beforeEatList = sessionMeds.where((r) => r['isAfterEat'] == false).toList();
      final afterEatList = sessionMeds.where((r) => r['isAfterEat'] == true).toList();

      final sessionMealIndex = expandedMealReminders.indexWhere(
        (r) => r['day_number'] == dayOffset + 1 && r['title'] == session.category,
      );

      DateTime mealDt;
      if (beforeEatList.isNotEmpty) {
        final earliestBefore = beforeEatList
            .map((r) => DateTime.parse(r['schedule_at'] as String))
            .reduce((a, b) => a.isBefore(b) ? a : b);
        mealDt = earliestBefore.add(const Duration(minutes: 5));

        for (final b in beforeEatList) {
          b['schedule_at'] = earliestBefore.toIso8601String();
        }

        if (afterEatList.isNotEmpty) {
          final afterDt = mealDt.add(const Duration(minutes: 30));
          for (final a in afterEatList) {
            a['schedule_at'] = afterDt.toIso8601String();
          }
        }
      } else {
        final earliestAfter = afterEatList
            .map((r) => DateTime.parse(r['schedule_at'] as String))
            .reduce((a, b) => a.isBefore(b) ? a : b);
        mealDt = earliestAfter.subtract(const Duration(minutes: 30));

        for (final a in afterEatList) {
          a['schedule_at'] = earliestAfter.toIso8601String();
        }
      }

      // Pastikan aturan klinis: Makan malam paling lama 2 jam sebelum tidur
      final maxDinner = (sleepMinutes - 120).clamp(17 * 60, 21 * 60);
      final maxDinnerDt = DateTime(
        dayZero.year,
        dayZero.month,
        dayZero.day + dayOffset,
        maxDinner ~/ 60,
        maxDinner % 60,
      );
      if (session.category == 'Waktu Makan Malam' && mealDt.isAfter(maxDinnerDt)) {
        mealDt = maxDinnerDt;
      }

      if (sessionMealIndex != -1) {
        expandedMealReminders[sessionMealIndex]['schedule_at'] = mealDt.toIso8601String();
      } else {
        // Hanya sinkronkan jadwal makan jika kategori ini ada di template AI
        final templateForCategory = mealTemplates.where(
          (m) => cleanMealTitle(m.template['title'] as String?, m.minutes) == session.category,
        );
        if (templateForCategory.isNotEmpty) {
          expandedMealReminders.add({
            ...templateForCategory.first.template,
            'title': session.category,
            'schedule_at': mealDt.toIso8601String(),
            'status': 'pending',
            'prescription_id': null,
            'reminder_items': <Json>[],
            'day_number': dayOffset + 1,
          });
        }
      }
    }
  }

  // Gabungkan pengingat obat yang jatuh pada waktu yang sama DAN status isAfterEat sama
  // ke dalam 1 reminder card sesuai permintaan pengguna.
  final mergedMedReminders = <String, Json>{};
  for (final medRem in expandedMedReminders) {
    final isAfterEat = medRem['isAfterEat'] == true;
    final timeStr = medRem['schedule_at'] as String;
    // Key penggabungan mencakup status isAfterEat sehingga obat beda isAfterEat tidak digabung!
    final key = '${timeStr}_$isAfterEat';
    if (!mergedMedReminders.containsKey(key)) {
      mergedMedReminders[key] = Map<String, dynamic>.from(medRem);
    } else {
      final existing = mergedMedReminders[key]!;
      final exTitle = (existing['title'] as String? ?? 'Minum Obat').trim();
      final newTitle = (medRem['title'] as String? ?? 'Minum Obat').trim();

      // Gabungkan reminder_items
      final exItems = (existing['reminder_items'] as List? ?? []).whereType<Map>().toList();
      final newItems = (medRem['reminder_items'] as List? ?? []).whereType<Map>().toList();
      final existingMedIds = exItems
          .map((e) => (e['medication_id'] as num?)?.toInt())
          .whereType<int>()
          .toSet();

      for (final item in newItems) {
        final id = (item['medication_id'] as num?)?.toInt();
        if (id != null && !existingMedIds.contains(id)) {
          exItems.add(item);
          existingMedIds.add(id);
        }
      }
      existing['reminder_items'] = exItems;

      // Gabungkan judul bila menyebut obat berbeda
      final cleanNewMedName = newTitle.replaceFirst(RegExp(r'^Minum\s+', caseSensitive: false), '').trim();
      if (cleanNewMedName.isNotEmpty && !exTitle.contains(cleanNewMedName)) {
        if (exTitle.startsWith('Minum Obat: ')) {
          existing['title'] = '$exTitle, $cleanNewMedName';
        } else if (exTitle.startsWith('Minum ')) {
          existing['title'] = '$exTitle & $cleanNewMedName';
        } else {
          existing['title'] = 'Minum Obat: $exTitle, $cleanNewMedName';
        }
      }
    }
  }

  final allReminders = <Json>[
    ...expandedMealReminders,
    ...mergedMedReminders.values,
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
