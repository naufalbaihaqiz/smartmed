import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/care_plan.dart';

/// Data notifikasi saat waktu jadwal makan atau minum obat telah tiba.
class DueScheduleAlert {
  const DueScheduleAlert({
    required this.notificationId,
    required this.key,
    required this.planId,
    required this.patientName,
    required this.reminderIndex,
    required this.title,
    required this.scheduledAt,
    required this.isMedication,
  });

  final int notificationId;
  final String key;
  final String planId;
  final String patientName;
  final int reminderIndex;
  final String title;
  final DateTime scheduledAt;
  final bool isMedication;

  String get timeLabel {
    final hh = scheduledAt.hour.toString().padLeft(2, '0');
    final mm = scheduledAt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String get headline => isMedication
      ? 'Waktunya Minum Obat · $patientName'
      : 'Waktunya Makan · $patientName';

  String get body => '$title (Jadwal pukul $timeLabel)';
}

typedef PlatformNotificationInvoker =
    Future<Object?> Function(String method, Map<String, dynamic>? arguments);

/// Layanan terpadu penjadwalan notifikasi sistem (Android AlarmManager) dan
/// pengingat langsung di dalam aplikasi ketika jadwal makan/obat tiba.
class NotificationService {
  NotificationService({
    DateTime Function()? nowProvider,
    this.platformInvoker,
  }) : _nowProvider = nowProvider ?? DateTime.now;

  static const MethodChannel _channel = MethodChannel(
    'temanrawat/notifications',
  );

  /// Maksimal alarm mendatang yang disinkronkan ke sistem operasi sekaligus.
  static const int maxScheduledSystemAlarms = 80;

  final DateTime Function() _nowProvider;
  final PlatformNotificationInvoker? platformInvoker;

  final StreamController<DueScheduleAlert> _alertController =
      StreamController<DueScheduleAlert>.broadcast();

  /// Berubah setiap kali ada jadwal yang baru memasuki waktunya, agar layar
  /// detail jadwal otomatis memperbarui status tombol selesai.
  final ValueNotifier<int> dueTick = ValueNotifier<int>(0);

  final Set<String> _notifiedKeys = <String>{};
  List<PatientCarePlan> _plans = const [];
  Timer? _wakeupTimer;
  bool _liveMonitoringEnabled = false;
  bool _initialized = false;
  bool _firstSyncCompleted = false;

  Stream<DueScheduleAlert> get onAlert => _alertController.stream;

  static int computeNotificationId(String key) {
    var hash = 17;
    for (final unit in key.codeUnits) {
      hash = ((hash * 31) + unit) & 0x7FFFFFFF;
    }
    return hash == 0 ? 1 : hash;
  }

  static String reminderKey(
    String planId,
    int reminderIndex,
    String scheduleAtIso,
  ) => '$planId|$reminderIndex|$scheduleAtIso';

  Future<void> _invokePlatform(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    final invoker = platformInvoker;
    if (invoker != null) {
      await invoker(method, arguments);
      return;
    }
    if (!_liveMonitoringEnabled || kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    try {
      await _channel
          .invokeMethod<Object?>(method, arguments)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
    } on MissingPluginException {
      // Aman diabaikan pada platform desktop / lingkungan pengujian widget.
    } on PlatformException {
      // Aman diabaikan bila izin alarm/notifikasi ditolak pengguna.
    }
  }

  /// Meminta izin notifikasi OS dan mengaktifkan pemantauan waktu jadwal bila diminta.
  Future<void> initialize({bool enableLiveMonitoring = false}) async {
    _liveMonitoringEnabled = enableLiveMonitoring;
    if (!_initialized) {
      _initialized = true;
      await requestPermission();
    }
    if (_liveMonitoringEnabled) {
      _scheduleNextWakeup();
    } else {
      _wakeupTimer?.cancel();
      _wakeupTimer = null;
    }
  }

  Future<void> requestPermission() async {
    await _invokePlatform('requestPermission');
  }

  /// Menyinkronkan seluruh jadwal perawatan pasien ke alarm sistem & pemantau aktif.
  Future<void> syncPlans(List<PatientCarePlan> plans, {DateTime? now}) async {
    final currentNow = (now ?? _nowProvider()).toLocal();
    _plans = List<PatientCarePlan>.unmodifiable(plans);

    // Pada sinkronisasi awal saat aplikasi baru dibuka, tandai jadwal lama yang
    // sudah lewat lebih dari 2 menit agar tidak memunculkan tumpukan pop-up masa lalu.
    if (!_firstSyncCompleted) {
      _firstSyncCompleted = true;
      for (final plan in _plans) {
        for (var i = 0; i < plan.reminders.length; i++) {
          final rem = plan.reminders[i];
          final rawIso = rem['schedule_at'] as String? ?? '';
          final scheduled = DateTime.tryParse(rawIso)?.toLocal();
          if (scheduled == null) continue;
          final key = reminderKey(plan.id, i, rawIso);
          if (rem['status'] == 'completed' ||
              currentNow.difference(scheduled) > const Duration(minutes: 2)) {
            _notifiedKeys.add(key);
          }
        }
      }
    }

    final upcomingItems = <Map<String, dynamic>>[];
    for (final plan in _plans) {
      for (var i = 0; i < plan.reminders.length; i++) {
        final rem = plan.reminders[i];
        final rawIso = rem['schedule_at'] as String? ?? '';
        final key = reminderKey(plan.id, i, rawIso);
        if (rem['status'] == 'completed') {
          _notifiedKeys.add(key);
          continue;
        }
        final scheduled = DateTime.tryParse(rawIso)?.toLocal();
        if (scheduled == null || !scheduled.isAfter(currentNow)) continue;

        final isMed = plan.isMedicationReminder(rem);
        final title = rem['title'] as String? ?? 'Jadwal Perawatan';
        final hh = scheduled.hour.toString().padLeft(2, '0');
        final mm = scheduled.minute.toString().padLeft(2, '0');

        upcomingItems.add({
          'id': computeNotificationId(key),
          'triggerAtMillis': scheduled.millisecondsSinceEpoch,
          'title': isMed
              ? 'Waktunya Minum Obat · ${plan.patientName}'
              : 'Waktunya Makan · ${plan.patientName}',
          'body': '$title (Jadwal pukul $hh:$mm)',
        });
      }
    }

    upcomingItems.sort(
      (a, b) =>
          (a['triggerAtMillis'] as int).compareTo(b['triggerAtMillis'] as int),
    );

    final boundedItems = upcomingItems
        .take(maxScheduledSystemAlarms)
        .toList(growable: false);

    await _invokePlatform('syncNotifications', {'items': boundedItems});

    if (_liveMonitoringEnabled) {
      checkDueNotifications(now: currentNow);
      _scheduleNextWakeup(now: currentNow);
    }
  }

  /// Memeriksa apakah ada jadwal pending yang waktunya baru saja tiba (`<= now`),
  /// lalu memicu notifikasi sistem dan banner dalam aplikasi.
  List<DueScheduleAlert> checkDueNotifications({DateTime? now}) {
    final currentNow = (now ?? _nowProvider()).toLocal();
    final newlyDue = <DueScheduleAlert>[];

    for (final plan in _plans) {
      for (var i = 0; i < plan.reminders.length; i++) {
        final rem = plan.reminders[i];
        if (rem['status'] == 'completed') continue;

        final rawIso = rem['schedule_at'] as String? ?? '';
        final scheduled = DateTime.tryParse(rawIso)?.toLocal();
        if (scheduled == null) continue;

        // Jadwal belum tiba.
        if (currentNow.isBefore(scheduled)) continue;

        // Abaikan jadwal yang sudah terlalu lampau (> 2 jam).
        if (currentNow.difference(scheduled) > const Duration(hours: 2)) {
          continue;
        }

        final key = reminderKey(plan.id, i, rawIso);
        if (!_notifiedKeys.add(key)) continue;

        final alert = DueScheduleAlert(
          notificationId: computeNotificationId(key),
          key: key,
          planId: plan.id,
          patientName: plan.patientName,
          reminderIndex: i,
          title: rem['title'] as String? ?? 'Jadwal Perawatan',
          scheduledAt: scheduled,
          isMedication: plan.isMedicationReminder(rem),
        );
        newlyDue.add(alert);
      }
    }

    if (newlyDue.isNotEmpty) {
      dueTick.value++;
      SystemSound.play(SystemSoundType.alert);
      for (final alert in newlyDue) {
        _invokePlatform('showNotification', {
          'id': alert.notificationId,
          'title': alert.headline,
          'body': alert.body,
        });
        if (!_alertController.isClosed) {
          _alertController.add(alert);
        }
      }
    }

    return newlyDue;
  }

  void onAppResumed() {
    final now = _nowProvider().toLocal();
    checkDueNotifications(now: now);
    if (_liveMonitoringEnabled) {
      _scheduleNextWakeup(now: now);
    }
  }

  void _scheduleNextWakeup({DateTime? now}) {
    _wakeupTimer?.cancel();
    _wakeupTimer = null;
    if (!_liveMonitoringEnabled) return;

    final currentNow = (now ?? _nowProvider()).toLocal();
    DateTime? nearestFuture;

    for (final plan in _plans) {
      for (final rem in plan.reminders) {
        if (rem['status'] == 'completed') continue;
        final scheduled = DateTime.tryParse(
          rem['schedule_at'] as String? ?? '',
        )?.toLocal();
        if (scheduled == null || !scheduled.isAfter(currentNow)) continue;
        if (nearestFuture == null || scheduled.isBefore(nearestFuture)) {
          nearestFuture = scheduled;
        }
      }
    }

    if (nearestFuture == null) return;

    var waitDuration =
        nearestFuture.difference(currentNow) +
        const Duration(milliseconds: 250);
    // Batasi maksimum 15 menit per siklus timer agar tetap tahan terhadap perubahan jam sistem.
    if (waitDuration > const Duration(minutes: 15)) {
      waitDuration = const Duration(minutes: 15);
    }
    if (waitDuration.isNegative) {
      waitDuration = const Duration(milliseconds: 100);
    }

    _wakeupTimer = Timer(waitDuration, () {
      final wakeupNow = _nowProvider().toLocal();
      checkDueNotifications(now: wakeupNow);
      _scheduleNextWakeup(now: wakeupNow);
    });
  }

  Future<void> cancelAll() async {
    _wakeupTimer?.cancel();
    _wakeupTimer = null;
    _notifiedKeys.clear();
    await _invokePlatform('cancelAll');
  }

  void dispose() {
    _wakeupTimer?.cancel();
    _wakeupTimer = null;
    dueTick.dispose();
    _alertController.close();
  }
}

