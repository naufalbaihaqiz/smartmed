import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../care_api.dart';
import '../care_forms.dart';
import '../models/care_plan.dart';
import '../palette.dart';
import '../widgets.dart';

class PatientCareDetailPage extends StatefulWidget {
  const PatientCareDetailPage({
    super.key,
    required this.initialPlan,
    required this.onPlanUpdated,
    this.onDeletePlan,
    this.nowProvider,
    this.refreshListenable,
  });

  final PatientCarePlan initialPlan;
  final ValueChanged<PatientCarePlan> onPlanUpdated;
  final VoidCallback? onDeletePlan;
  final DateTime Function()? nowProvider;
  final Listenable? refreshListenable;

  @override
  State<PatientCareDetailPage> createState() => _PatientCareDetailPageState();
}

class _PatientCareDetailPageState extends State<PatientCareDetailPage> {
  static const List<String> _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  late PatientCarePlan _plan = widget.initialPlan;
  int _selectedTab = 0;

  /// `null` berarti menampilkan seluruh hari sekaligus ("Semua Hari").
  String? _selectedDayKey;
  bool _daySelectionInitialized = false;

  DateTime _now() => (widget.nowProvider ?? DateTime.now)().toLocal();

  @override
  void initState() {
    super.initState();
    _initDefaultDaySelection();
    widget.refreshListenable?.addListener(_handleExternalRefresh);
  }

  @override
  void didUpdateWidget(covariant PatientCareDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshListenable != widget.refreshListenable) {
      oldWidget.refreshListenable?.removeListener(_handleExternalRefresh);
      widget.refreshListenable?.addListener(_handleExternalRefresh);
    }
  }

  @override
  void dispose() {
    widget.refreshListenable?.removeListener(_handleExternalRefresh);
    super.dispose();
  }

  void _handleExternalRefresh() {
    if (mounted) setState(() {});
  }

  void _initDefaultDaySelection() {
    if (_daySelectionInitialized) return;
    _daySelectionInitialized = true;
    final keys = _orderedDayKeys();
    if (keys.length <= 1) {
      _selectedDayKey = null;
      return;
    }
    final todayKey = formatIsoDate(_now());
    _selectedDayKey = keys.contains(todayKey) ? todayKey : keys.first;
  }

  List<String> _orderedDayKeys() {
    final seen = <String>{};
    final ordered = <String>[];
    for (final rem in _plan.reminders) {
      final dt = PatientCarePlan.parseReminderTime(rem);
      if (dt == null) continue;
      final key = formatIsoDate(dt);
      if (seen.add(key)) {
        ordered.add(key);
      }
    }
    return ordered;
  }

  String _formatTime(String rawIso) {
    final parsed = DateTime.tryParse(rawIso)?.toLocal();
    if (parsed == null) return rawIso;
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatShortDateFromKey(String isoDate) {
    final parts = isoDate.split('-');
    if (parts.length != 3) return isoDate;
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;
    return '$day ${_shortMonths[(month - 1).clamp(0, 11)]}';
  }

  String _formatDateBadge(String rawIso) {
    final parsed = DateTime.tryParse(rawIso)?.toLocal();
    if (parsed == null) return '';
    return '${parsed.day} ${_shortMonths[(parsed.month - 1).clamp(0, 11)]}';
  }

  String _formatFullDateTime(String rawIso) {
    final parsed = DateTime.tryParse(rawIso)?.toLocal();
    if (parsed == null) return rawIso;
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    final month = _shortMonths[(parsed.month - 1).clamp(0, 11)];
    return '${parsed.day} $month ${parsed.year} pukul $hh:$mm';
  }

  void _toggleReminder(int index) {
    final target = _plan.reminders[index];
    final isCurrentlyCompleted = target['status'] == 'completed';

    if (!isCurrentlyCompleted &&
        !PatientCarePlan.isReminderDue(target, now: _now())) {
      final title = target['title'] as String? ?? 'Jadwal';
      final whenText = _formatFullDateTime(
        target['schedule_at'] as String? ?? '',
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: ink,
            content: Text(
              'Belum waktunya! "$title" baru dapat ditandai selesai pada $whenText.',
            ),
          ),
        );
      return;
    }

    final updatedReminders = [
      for (var i = 0; i < _plan.reminders.length; i++)
        if (i == index)
          {
            ..._plan.reminders[i],
            'status': isCurrentlyCompleted ? 'pending' : 'completed',
          }
        else
          Map<String, dynamic>.from(_plan.reminders[i]),
    ];
    final updated = _plan.copyWith(reminders: updatedReminders);
    setState(() => _plan = updated);
    widget.onPlanUpdated(updated);
  }

  void _completeAllDueReminders() {
    final currentNow = _now();
    var changedCount = 0;
    final updatedReminders = [
      for (final reminder in _plan.reminders)
        if (reminder['status'] != 'completed' &&
            PatientCarePlan.isReminderDue(reminder, now: currentNow))
          () {
            changedCount++;
            return <String, dynamic>{...reminder, 'status': 'completed'};
          }()
        else
          Map<String, dynamic>.from(reminder),
    ];

    if (changedCount == 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Belum ada jadwal yang memasuki waktunya untuk ditandai selesai.',
            ),
          ),
        );
      return;
    }

    final updated = _plan.copyWith(reminders: updatedReminders);
    setState(() => _plan = updated);
    widget.onPlanUpdated(updated);

    final remainingPending =
        updated.totalSchedules - updated.completedSchedules;
    if (remainingPending > 0 && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              '$changedCount jadwal yang sudah tiba ditandai selesai. '
              '$remainingPending jadwal berikutnya menunggu waktunya tiba.',
            ),
          ),
        );
    }
  }

  void _resetAllReminders() {
    final updatedReminders = [
      for (final reminder in _plan.reminders)
        {...reminder, 'status': 'pending'},
    ];
    final updated = _plan.copyWith(reminders: updatedReminders);
    setState(() => _plan = updated);
    widget.onPlanUpdated(updated);
  }

  Future<void> _confirmDelete() async {
    final onDelete = widget.onDeletePlan;
    if (onDelete == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data Perawatan?'),
        content: Text(
          'Jadwal dan resep untuk ${_plan.patientName} akan dihapus dari daftar perawatan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      onDelete();
      Navigator.pop(context);
    }
  }

  Widget _buildHeroCard() {
    final rupiah = NumberFormat.decimalPattern('id_ID').format(_plan.budget);
    final completed = _plan.completedSchedules;
    final total = _plan.totalSchedules;
    final percent = (_plan.progress * 100).round();
    final daysCount = _plan.totalDays;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [deepForest, teal],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22113826),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScheduleStatusBadge(completed: _plan.isScheduleCompleted),
                    const SizedBox(height: 12),
                    Text(
                      _plan.patientName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _plan.conditionName,
                      style: const TextStyle(
                        color: Color(0xFFD5EBD9),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox.square(
                dimension: 68,
                child: Stack(
                  alignment: Alignment.center,
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: _plan.progress,
                      strokeWidth: 6,
                      backgroundColor: Colors.white24,
                      color: _plan.isScheduleCompleted
                          ? const Color(0xFF86EFAC)
                          : signal,
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$percent%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '$completed/$total',
                            style: const TextStyle(
                              color: Color(0xFFD5EBD9),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (daysCount > 1)
                _HeroMetricChip(
                  '$daysCount hari jadwal',
                  Icons.calendar_month_rounded,
                ),
              if (_plan.age != null)
                _HeroMetricChip('${_plan.age} thn', Icons.cake_outlined),
              if (_plan.weight != null)
                _HeroMetricChip(
                  '${_plan.weight} kg',
                  Icons.monitor_weight_outlined,
                ),
              if (_plan.height != null)
                _HeroMetricChip('${_plan.height} cm', Icons.height_rounded),
              _HeroMetricChip(
                'Rp$rupiah',
                Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: slate,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Jadwal (${_plan.reminders.length})',
              icon: Icons.event_note_rounded,
              selected: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SegmentButton(
              label: 'Resep (${_plan.meals.length})',
              icon: Icons.restaurant_menu_rounded,
              selected: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayFilterBar(List<String> dayKeys) {
    final todayKey = formatIsoDate(_now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: paleTeal,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: teal.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.date_range_rounded, size: 17, color: teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Jadwal disusun untuk ${dayKeys.length} hari perawatan sampai seluruh obat habis.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var d = 0; d < dayKeys.length; d++) ...[
                if (d > 0) const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(
                    dayKeys[d] == todayKey
                        ? 'Hari ${d + 1} · Hari Ini'
                        : 'Hari ${d + 1} · ${_formatShortDateFromKey(dayKeys[d])}',
                  ),
                  selected: _selectedDayKey == dayKeys[d],
                  selectedColor: paleTeal,
                  onSelected: (_) =>
                      setState(() => _selectedDayKey = dayKeys[d]),
                ),
              ],
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Semua Hari (${_plan.reminders.length})'),
                selected: _selectedDayKey == null,
                selectedColor: paleTeal,
                onSelected: (_) => setState(() => _selectedDayKey = null),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildScheduleTab() {
    if (_plan.reminders.isEmpty) {
      return const EmptyPanel(
        icon: Icons.event_busy_outlined,
        title: 'Belum Ada Jadwal',
        description: 'Jadwal makan dan minum obat belum tersedia.',
      );
    }

    final currentNow = _now();
    final dayKeys = _orderedDayKeys();
    final isMultiDay = dayKeys.length > 1;
    final activeDayKey =
        isMultiDay &&
            _selectedDayKey != null &&
            dayKeys.contains(_selectedDayKey)
        ? _selectedDayKey
        : null;

    final visibleEntries = <({int index, Json reminder})>[
      for (var i = 0; i < _plan.reminders.length; i++)
        if (activeDayKey == null ||
            (() {
              final dt = PatientCarePlan.parseReminderTime(_plan.reminders[i]);
              return dt != null && formatIsoDate(dt) == activeDayKey;
            })())
          (index: i, reminder: _plan.reminders[i]),
    ];

    final duePendingCount = _plan.duePendingCount(now: currentNow);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isMultiDay) _buildDayFilterBar(dayKeys),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            const Eyebrow('JADWAL MAKAN & MINUM OBAT'),
            if (_plan.isScheduleCompleted)
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: _resetAllReminders,
                icon: const Icon(Icons.restart_alt_rounded, size: 17),
                label: const Text('Ulangi Jadwal'),
              )
            else if (duePendingCount > 0)
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: _completeAllDueReminders,
                icon: const Icon(Icons.done_all_rounded, size: 17),
                label: Text('Selesaikan Jatuh Tempo ($duePendingCount)'),
              )
            else
              const BadgePill(
                'Menunggu Waktu Jadwal',
                color: slate,
                textColor: muted,
                icon: Icons.lock_clock_outlined,
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < visibleEntries.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildReminderCard(
            visibleEntries[i].reminder,
            visibleEntries[i].index,
            currentNow: currentNow,
            showDateBadge: isMultiDay,
          ),
        ],
      ],
    );
  }

  Widget _buildReminderCard(
    Json reminder,
    int index, {
    required DateTime currentNow,
    required bool showDateBadge,
  }) {
    final isDone = reminder['status'] == 'completed';
    final isDue = PatientCarePlan.isReminderDue(reminder, now: currentNow);
    final isLocked = !isDone && !isDue;
    final isMed = _plan.isMedicationReminder(reminder);
    final meds = _plan.medicationsForReminder(reminder);
    final rawScheduleAt = reminder['schedule_at'] as String? ?? '';
    final timeText = _formatTime(rawScheduleAt);
    final dateBadge = _formatDateBadge(rawScheduleAt);
    final title = reminder['title'] as String? ?? 'Kegiatan Perawatan';
    final doseNumber = (reminder['dose_number'] as num?)?.toInt();
    final totalDoses = (reminder['total_doses'] as num?)?.toInt();

    return Surface(
      color: isDone
          ? const Color(0xFFF3FAF5)
          : isLocked
          ? const Color(0xFFF4F6F4)
          : paper,
      borderColor: isDone ? const Color(0xFFBBDFC6) : line,
      onTap: () => _toggleReminder(index),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDone
                      ? successSoft
                      : isLocked
                      ? slate
                      : isMed
                      ? medSoft
                      : paleTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : isLocked
                          ? Icons.lock_clock_outlined
                          : isMed
                          ? Icons.medication_rounded
                          : Icons.restaurant_rounded,
                      size: 18,
                      color: isDone
                          ? successGreen
                          : isLocked
                          ? muted
                          : isMed
                          ? medAccent
                          : teal,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: isDone
                            ? successGreen
                            : isLocked
                            ? muted
                            : isMed
                            ? medAccent
                            : ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        BadgePill(
                          isMed ? 'Minum Obat' : 'Jadwal Makan',
                          color: isMed ? medSoft : paleTeal,
                          textColor: isMed ? medAccent : teal,
                        ),
                        if (showDateBadge && dateBadge.isNotEmpty)
                          BadgePill(
                            dateBadge,
                            color: slate,
                            textColor: ink,
                          ),
                        if (doseNumber != null && totalDoses != null)
                          BadgePill(
                            'Dosis $doseNumber/$totalDoses',
                            color: slate,
                            textColor: muted,
                          ),
                        if (isDone)
                          const BadgePill(
                            'Selesai',
                            color: successSoft,
                            textColor: successGreen,
                          )
                        else if (isDue)
                          const BadgePill(
                            'Sudah Waktunya',
                            color: warningSoft,
                            textColor: warningAmber,
                          )
                        else
                          const BadgePill(
                            'Belum Waktunya',
                            color: slate,
                            textColor: muted,
                            icon: Icons.schedule_rounded,
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDone || isLocked ? muted : ink,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isDone
                    ? 'Batalkan selesai'
                    : isDue
                    ? 'Tandai selesai'
                    : 'Belum waktunya jadwal',
                onPressed: () => _toggleReminder(index),
                icon: Icon(
                  isDone
                      ? Icons.check_circle_rounded
                      : isDue
                      ? Icons.radio_button_unchecked_rounded
                      : Icons.lock_clock_outlined,
                  color: isDone
                      ? successGreen
                      : isDue
                      ? teal
                      : muted,
                  size: 25,
                ),
              ),
            ],
          ),
          if (meds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDone ? Colors.white70 : cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var m = 0; m < meds.length; m++) ...[
                    if (m > 0) const Divider(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_pharmacy_outlined,
                          size: 16,
                          color: medAccent,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            '${meds[m]['medicine_name']} · ${meds[m]['dosage']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: ink,
                            ),
                          ),
                        ),
                        BadgePill(
                          meds[m]['isAfterEat'] == true
                              ? 'Sesudah makan'
                              : 'Sebelum makan',
                          color: slate,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meds[m]['frequency']} — ${meds[m]['instruction']}',
                      style: const TextStyle(fontSize: 12.5, color: muted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecipesAndMedicationsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Eyebrow('DAFTAR RESEP MAKANAN YANG DIGENERATE'),
        const SizedBox(height: 10),
        if (_plan.meals.isEmpty)
          const EmptyPanel(
            icon: Icons.ramen_dining_outlined,
            title: 'Belum Ada Resep Makanan',
            description: 'Tidak ada resep makanan yang tersimpan.',
          )
        else
          for (var i = 0; i < _plan.meals.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            RecipeCard(meal: _plan.meals[i], index: i),
          ],
        const SizedBox(height: 24),
        const Eyebrow('DAFTAR RESEP OBAT DOKTER'),
        const SizedBox(height: 10),
        if (!_plan.hasPrescription)
          const Notice(
            text:
                'Pasien tidak memiliki resep obat dokter. Jadwal fokus pada pemenuhan nutrisi harian.',
            icon: Icons.medication_outlined,
          )
        else
          for (final prescription in _plan.prescriptions) ...[
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IconTile(
                        Icons.description_outlined,
                        backgroundColor: medSoft,
                        iconColor: medAccent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resep Dokter · ${prescription['prescription_date']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                                color: ink,
                              ),
                            ),
                            Text(
                              'Jam mulai minum hari pertama: ${prescription['start_at']}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (prescription['notes'] is String &&
                      (prescription['notes'] as String).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Catatan dokter: ${prescription['notes']}',
                      style: const TextStyle(fontSize: 13, color: muted),
                    ),
                  ],
                  const SizedBox(height: 14),
                  for (final med
                      in (prescription['medications'] as List? ?? const [])
                          .whereType<Map>()) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: cream,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${med['medicine_name']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                    color: ink,
                                  ),
                                ),
                              ),
                              BadgePill(
                                med['isAfterEat'] == true
                                    ? 'Sesudah makan'
                                    : 'Sebelum makan',
                                color: medSoft,
                                textColor: medAccent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Dosis: ${med['dosage']} · Frekuensi: ${med['frequency']} · Jumlah: ${med['quantity']}',
                            style: const TextStyle(fontSize: 12.5, color: ink),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Instruksi: ${med['instruction']}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: muted,
                            ),
                          ),
                          if (med['notes'] is String &&
                              (med['notes'] as String).isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              'Catatan: ${med['notes']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        if (_plan.allergies.isNotEmpty || _plan.preferensi.isNotEmpty) ...[
          const SizedBox(height: 12),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('CATATAN ALERGI & PREFERENSI MAKANAN'),
                const SizedBox(height: 10),
                if (_plan.allergies.isNotEmpty) ...[
                  const Text(
                    'Alergi yang dihindari:',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final a in _plan.allergies)
                        BadgePill(
                          a['type']?.toString() ?? '',
                          color: softRed,
                          textColor: red,
                          icon: Icons.warning_amber_rounded,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (_plan.preferensi.isNotEmpty) ...[
                  const Text(
                    'Preferensi menu:',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final pref in _plan.preferensi)
                        BadgePill(pref, color: paleTeal, textColor: teal),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: MobileFrame(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                decoration: const BoxDecoration(
                  color: paper,
                  border: Border(bottom: BorderSide(color: line)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Kembali ke Beranda',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: ink),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jadwal & Resep',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontSize: 17),
                          ),
                          Text(
                            _plan.patientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: muted),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onDeletePlan != null)
                      IconButton(
                        tooltip: 'Hapus perawatan',
                        onPressed: _confirmDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: red,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeroCard(),
                      if (_plan.aiNotes.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Notice(
                          text: _plan.aiNotes.join('\n'),
                          icon: Icons.info_outline_rounded,
                        ),
                      ],
                      const SizedBox(height: 18),
                      _buildTabSwitcher(),
                      const SizedBox(height: 18),
                      if (_selectedTab == 0)
                        _buildScheduleTab()
                      else
                        _buildRecipesAndMedicationsTab(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroMetricChip extends StatelessWidget {
  const _HeroMetricChip(this.label, this.icon);
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.5, color: const Color(0xFFD5EBD9)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? paper : Colors.transparent,
    borderRadius: BorderRadius.circular(11),
    elevation: selected ? 1 : 0,
    shadowColor: const Color(0x18143526),
    child: InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: selected ? teal : muted),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? ink : muted,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
