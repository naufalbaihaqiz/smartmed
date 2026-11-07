import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'care_api.dart';
import 'care_forms.dart';
import 'database/database_helper.dart';
import 'palette.dart';
import 'widgets.dart';
import 'welcome.dart';
import 'web_demo.dart';

const webDemoEnabled = kIsWeb && bool.fromEnvironment('TEMANRAWAT_WEB_DEMO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    await DatabaseHelper.instance.database;
  }
  runApp(const TemanRawatApp());
}

class TemanRawatApp extends StatefulWidget {
  const TemanRawatApp({super.key, this.api});

  final CareApi? api;
  @override
  State<TemanRawatApp> createState() => _TemanRawatAppState();
}

class _TemanRawatAppState extends State<TemanRawatApp> {
  ({String caregiver, String patient})? profile;
  WebDemo? demo;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TemanRawat',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      fontFamily: 'Segoe UI',
      colorScheme: ColorScheme.fromSeed(seedColor: teal, surface: paper),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: ink,
          letterSpacing: -1.2,
        ),
        headlineSmall: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w700,
          color: ink,
          letterSpacing: -.6,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: ink, height: 1.55),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: teal,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: teal, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line),
        ),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
    ),
    home: profile == null
        ? WelcomePage(
            onDemo: webDemoEnabled
                ? (withPrescription) {
                    final scenario = WebDemo(
                      withPrescription: withPrescription,
                    );
                    setState(() {
                      demo = scenario;
                      profile = (
                        caregiver: scenario.caregiver,
                        patient: scenario.patient,
                      );
                    });
                  }
                : null,
            onStart: (caregiver, patient) {
              setState(
                () => profile = (caregiver: caregiver, patient: patient),
              );
            },
          )
        : HomeShell(
            caregiver: profile!.caregiver,
            patient: profile!.patient,
            api: widget.api,
            demo: demo,
            onExitDemo: demo == null
                ? null
                : () => setState(() {
                    demo = null;
                    profile = null;
                  }),
          ),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.caregiver,
    required this.patient,
    this.api,
    this.demo,
    this.onExitDemo,
  });

  final String caregiver, patient;
  final CareApi? api;
  final WebDemo? demo;
  final VoidCallback? onExitDemo;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final CareApi api = widget.api ?? widget.demo?.createApi() ?? CareApi();
  int page = 0;
  int version = 1;
  int nextPrescriptionId = 1;
  int nextMedicationId = 1;
  bool busy = false;
  String? message;
  Json? mealInput;
  String routine = '';
  String availability = '';
  final prescriptions = <Json>[];
  List<Json> meals = [];
  List<Json> scheduleDraft = [];
  List<Json> agenda = [];
  final history =
      <
        ({String title, String status, DateTime recordedAt, String agendaKey})
      >[];
  bool agendaArchived = false;

  @override
  void initState() {
    super.initState();
    final demo = widget.demo;
    if (demo == null) return;
    page = 1;
    mealInput = demo.mealInput;
    prescriptions.addAll(demo.prescriptions);
    if (prescriptions.isNotEmpty) {
      nextPrescriptionId = 2;
      nextMedicationId = 2;
    }
    meals = demo.meals;
    agenda = demo.agenda;
    routine = 'Sarapan pukul 07.30, makan siang pukul 12.30.';
    availability = 'Pendamping tersedia pada pagi dan siang.';
    history.add((
      title: agenda.first['title'] as String,
      status: 'Selesai',
      recordedAt: DateTime.parse(agenda.first['schedule_at'] as String),
      agendaKey: _agendaKey(agenda.first),
    ));
  }

  @override
  void dispose() {
    if (widget.api == null) api.close();
    super.dispose();
  }

  void _inputsChanged() {
    version++;
    meals = [];
    scheduleDraft = [];
    message = null;
  }

  Future<T?> _sheet<T>(String title, Widget child) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: paper,
    constraints: const BoxConstraints(maxWidth: 430),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _editMealInput() async {
    final input = await _sheet<Json>(
      'Profil perawatan',
      MealInputForm(
        input: mealInput,
        hasPrescription: prescriptions.isNotEmpty,
      ),
    );
    if (!mounted || input == null) return;
    setState(() {
      mealInput = input;
      _inputsChanged();
    });
  }

  Future<void> _addPrescription() async {
    final result = await _sheet<Json>('Tambah resep', const PrescriptionForm());
    if (!mounted || result == null) return;
    setState(() {
      final id = nextPrescriptionId++;
      prescriptions.add({
        ...result,
        'id': id,
        'medications': (result['medications'] as List<Json>)
            .map<Json>(
              (item) => {
                ...item,
                'id': nextMedicationId++,
                'prescription_id': id,
              },
            )
            .toList(),
      });
      _inputsChanged();
    });
  }

  Future<void> _editRoutine() async {
    final form = GlobalKey<FormState>();
    var newRoutine = routine;
    var newAvailability = availability;
    final result = await _sheet<bool>(
      'Rutinitas dan ketersediaan',
      Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CareFormField(
              'Rutinitas harian',
              initialValue: routine,
              maxLines: 3,
              onSaved: (value) => newRoutine = value,
            ),
            CareFormField(
              'Ketersediaan pendamping',
              initialValue: availability,
              maxLines: 3,
              onSaved: (value) => newAvailability = value,
            ),
            FilledButton(
              onPressed: () {
                form.currentState!.save();
                Navigator.pop(form.currentContext!, true);
              },
              child: const Text('Simpan rutinitas'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || result != true) return;
    setState(() {
      routine = newRoutine;
      availability = newAvailability;
      version++;
      scheduleDraft = [];
      message = null;
    });
  }

  Future<void> _request(Future<void> Function(int) action) async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await action(version);
    } on CareApiException catch (error) {
      if (mounted) setState(() => message = error.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _generateMeals() async {
    final input = mealInput;
    if (input == null || busy) return;
    setState(() {
      meals = [];
      scheduleDraft = [];
    });
    await _request((requestVersion) async {
      final health = input['health_condition'] as Json;
      final result = await api.generateMeals({
        ...input,
        'health_condition': {
          ...health,
          'name': widget.patient,
          'isTherePrescription': prescriptions.isNotEmpty,
        },
      }, requestVersion);
      if (!mounted || version != requestVersion) return;
      setState(() {
        meals = result.status == 'draft' ? result.meals : [];
        scheduleDraft = [];
        message = [
          ...result.messages,
          if (meals.isEmpty && result.messages.isEmpty) 'Server belum mengembalikan menu. Coba ulang atau sesuaikan profil dan budget.',
          if (meals.isEmpty && result.messages.isNotEmpty)
            'Belum ada draf menu yang bisa ditinjau.',
        ].join('\n');
      });
    });
  }

  Future<void> _generateSchedule() async {
    if (meals.isEmpty || busy) return;
    setState(() => scheduleDraft = []);
    await _request((requestVersion) async {
      final result = await api.generateSchedule({
        'menu_disetujui': meals,
        'prescriptions': prescriptions,
        'rutinitas': {if (routine.isNotEmpty) 'notes': routine},
        'ketersediaan_caregiver': {
          if (availability.isNotEmpty) 'notes': availability,
        },
      }, requestVersion);
      if (!mounted || version != requestVersion) return;
      final invalidReference = result.reminders.any((reminder) {
        final id = reminder['prescription_id'];
        final items = (reminder['reminder_items'] as List?) ?? [];
        if (id == null) return items.isNotEmpty;
        return !prescriptions.any(
          (prescription) =>
              prescription['id'] == id &&
              items.isNotEmpty &&
              items.every(
                (item) => (prescription['medications'] as List<Json>).any(
                  (medication) => medication['id'] == item['medication_id'],
                ),
              ),
        );
      });
      setState(() {
        scheduleDraft =
            result.status == 'draft' &&
                !result.hasConflicts &&
                !invalidReference
            ? result.reminders
            : [];
        message = [
          ...result.messages,
          if (invalidReference)
            'Referensi obat atau resep pada jadwal tidak cocok.',
          if (scheduleDraft.isEmpty) 'Belum ada jadwal yang bisa disetujui.',
        ].join('\n');
      });
    });
  }

  String _dateTime(DateTime date) {
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} · '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String _reminderTime(Json reminder) =>
      _dateTime(DateTime.parse(reminder['schedule_at'] as String));

  String _agendaKey(Json reminder) =>
      '${reminder['title']}|${DateTime.parse(reminder['schedule_at'] as String).toIso8601String()}';

  void _finishAgenda() {
    if (agenda.isEmpty ||
        agenda.any((reminder) => reminder['status'] != 'completed')) {
      return;
    }
    final recordedAt = DateTime.now();
    final existingKeys = history.map((item) => item.agendaKey).toSet();
    final finishedActivities =
        <
          ({String title, String status, DateTime recordedAt, String agendaKey})
        >[
          for (final reminder in agenda)
            if (!existingKeys.contains(_agendaKey(reminder)))
              (
                title: reminder['title'] as String,
                status: 'Selesai',
                recordedAt: recordedAt,
                agendaKey: _agendaKey(reminder),
              ),
        ];
    setState(() {
      history.insertAll(0, finishedActivities);
      agenda = [];
      agendaArchived = true;
      page = 2;
    });
  }

  List<String> _medicationInstructions(Json reminder) {
    final items = reminder['reminder_items'] as List? ?? [];
    final ids = items.map((item) => item['medication_id']).toSet();
    return [
      for (final prescription in prescriptions)
        if (prescription['id'] == reminder['prescription_id'])
          for (final medication in prescription['medications'] as List<Json>)
            if (ids.contains(medication['id']))
              '${medication['medicine_name']} · ${medication['dosage']} · '
                  '${medication['frequency']} · ${medication['instruction']}',
    ];
  }

  Widget _heading(
    String title,
    String description, {
    required String label,
    required IconData icon,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(label),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 6),
              Text(description, style: const TextStyle(color: muted)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconTile(icon),
      ],
    ),
  );

  Widget _summaryCard({
    required String label,
    required String title,
    required String description,
    required Widget trailing,
  }) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: ink,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFB3D6BA),
                  letterSpacing: 1,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 23,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(color: Color(0xFFD1DFD2), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        trailing,
      ],
    ),
  );

  Widget _agendaProgress() {
    final complete = agenda
        .where((reminder) => reminder['status'] == 'completed')
        .length;
    final progress = complete / agenda.length;
    return _summaryCard(
      label: 'PROGRES PERAWATAN',
      title: '$complete / ${agenda.length}',
      description: 'Kegiatan sudah dicatat',
      trailing: SizedBox.square(
        dimension: 60,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: progress,
              color: signal,
              backgroundColor: Colors.white24,
              strokeWidth: 5,
            ),
            Center(
              child: Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recipe(Json meal) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const IconTile(Icons.ramen_dining_outlined, accent: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['recipe_name'] as String,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${meal['servings']} porsi · ${meal['cooking_time']} menit',
                    style: const TextStyle(color: muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (meal['source'] case final String source) ...[
          const SizedBox(height: 10),
          BadgePill(source),
        ],
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          onPressed: () => _sheet<void>(
            meal['recipe_name'] as String,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (meal['description'] is String)
                  Text(meal['description'] as String),
                if (meal['source'] is String) Text('Sumber: ${meal['source']}'),
                for (final ingredient in (meal['ingredients'] as List? ?? []))
                  Text(
                    '• ${ingredient['ingredient_name']} · ${ingredient['quantity']}',
                  ),
                const SizedBox(height: 12),
                Text(meal['instructions'] as String),
                if (meal['nutrition'] case final Json nutrition) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Energi ${nutrition['calories']} kkal · Protein ${nutrition['protein']} g',
                  ),
                  Text(
                    'Karbohidrat ${nutrition['carbohydrates']} g · Lemak ${nutrition['fat']} g',
                  ),
                ],
              ],
            ),
          ),
          label: const Text('Lihat detail'),
        ),
      ],
    ),
  );

  Widget _menu() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(
        'Menu Hari Ini',
        'Tinjau rencana makan untuk ${widget.patient}.',
        label: 'RENCANA MAKAN',
        icon: Icons.restaurant_menu_rounded,
      ),
      if (mealInput == null)
        OutlinedButton(
          onPressed: busy ? null : _editMealInput,
          child: const Text('Lengkapi profil dan budget'),
        )
      else ...[
        _summaryCard(
          label: 'BUDGET BELANJA',
          title:
              'Rp${NumberFormat.decimalPattern('id_ID').format(mealInput!['budget'])}',
          description: 'Anggaran dari profil perawatan',
          trailing: const Icon(
            Icons.account_balance_wallet_outlined,
            color: Color(0xFFB3D6BA),
            size: 29,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: busy ? null : _generateMeals,
          icon: const Icon(Icons.auto_awesome_outlined, size: 19),
          label: const Text('Buat draf menu'),
        ),
      ],
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: Text(
              'Resep obat',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton.filledTonal(
            onPressed: busy ? null : _addPrescription,
            tooltip: 'Tambah resep',
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      if (prescriptions.isEmpty)
        const Notice(
          text: 'Belum ada resep yang dicatat.',
          icon: Icons.medication_outlined,
        ),
      for (final prescription in prescriptions)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const IconTile(Icons.medication_outlined, accent: true),
          title: Text('Resep ${prescription['prescription_date']}'),
          subtitle: Text(
            (prescription['medications'] as List<Json>)
                .map((item) => item['medicine_name'])
                .join(', '),
          ),
        ),
      if (busy) const LinearProgressIndicator(),
      if (message != null && message!.isNotEmpty) ...[
        const SizedBox(height: 12),
        Notice(text: message!, icon: Icons.info_outline),
      ],
      if (meals.isEmpty) ...[
        const SizedBox(height: 12),
        const EmptyPanel(
          icon: Icons.ramen_dining_outlined,
          title: 'Belum ada menu.',
          description: 'Draf akan tampil setelah server mengirim resep.',
        ),
      ],
      for (final meal in meals) ...[const SizedBox(height: 12), _recipe(meal)],
      if (meals.isNotEmpty) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: busy ? null : _editRoutine,
          icon: const Icon(Icons.tune_rounded, size: 19),
          label: const Text('Isi rutinitas pendampingan'),
        ),
        FilledButton.icon(
          onPressed: busy ? null : _generateSchedule,
          icon: const Icon(Icons.event_available_outlined, size: 19),
          label: const Text('Setujui menu dan buat jadwal'),
        ),
      ],
      if (scheduleDraft.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('Tinjau jadwal', style: Theme.of(context).textTheme.titleLarge),
        const Text(
          'Periksa waktu dan kecocokannya dengan resep sebelum menyetujui.',
        ),
        for (final reminder in scheduleDraft)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const IconTile(Icons.schedule_rounded),
            title: Text(reminder['title'] as String),
            subtitle: Text(
              [
                _reminderTime(reminder),
                ..._medicationInstructions(reminder),
              ].join('\n'),
            ),
          ),
        FilledButton(
          onPressed: busy
              ? null
              : () => setState(() {
                  agenda =
                      scheduleDraft
                          .map((item) => {...item, 'status': 'pending'})
                          .toList()
                        ..sort(
                          (a, b) => DateTime.parse(a['schedule_at'] as String)
                              .compareTo(
                                DateTime.parse(b['schedule_at'] as String),
                              ),
                        );
                  agendaArchived = false;
                  scheduleDraft = [];
                  page = 0;
                }),
          child: const Text('Setujui dan masukkan ke agenda'),
        ),
      ],
    ],
  );

  Widget _agenda() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(
        'Agenda Perawatan',
        'Jadwal yang disetujui untuk ${widget.patient}.',
        label: 'PENDAMPINGAN',
        icon: Icons.calendar_today_outlined,
      ),
      if (agenda.isNotEmpty) ...[
        _agendaProgress(),
        const SizedBox(height: 20),
        Text('Agenda hari ini', style: Theme.of(context).textTheme.titleLarge),
      ],
      if (agenda.isEmpty)
        EmptyPanel(
          title: agendaArchived
              ? 'Semua kegiatan hari ini selesai.'
              : 'Belum ada jadwal yang disetujui.',
          icon: agendaArchived ? Icons.task_alt_rounded : Icons.event_outlined,
          description: agendaArchived
              ? 'Semua kegiatan sudah disimpan ke Riwayat.'
              : 'Jadwal yang kamu setujui di halaman Menu akan tampil di sini.',
        ),
      for (final reminder in agenda) ...[
        const SizedBox(height: 12),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconTile(
                    reminder['status'] == 'completed'
                        ? Icons.check_rounded
                        : reminder['prescription_id'] != null
                        ? Icons.medication_outlined
                        : Icons.schedule_rounded,
                    accent: reminder['prescription_id'] != null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder['title'] as String,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          _reminderTime(reminder),
                          style: const TextStyle(color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final instruction in _medicationInstructions(reminder))
                Text(instruction),
              if (reminder['status'] == 'completed')
                const BadgePill('Selesai')
              else
                TextButton(
                  onPressed: () =>
                      setState(() => reminder['status'] = 'completed'),
                  child: const Text('Catat sebagai selesai'),
                ),
            ],
          ),
        ),
      ],
      if (agenda.isNotEmpty &&
          agenda.every((reminder) => reminder['status'] == 'completed')) ...[
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _finishAgenda,
          icon: const Icon(Icons.done_all_rounded),
          label: const Text('Selesai dan simpan semua ke riwayat'),
        ),
      ],
    ],
  );

  Widget _history() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(
        'Riwayat',
        'Pencatatan kegiatan oleh ${widget.caregiver}.',
        label: 'CATATAN PERAWATAN',
        icon: Icons.history_rounded,
      ),
      if (history.isEmpty)
        const EmptyPanel(
          title: 'Belum ada kegiatan yang dicatat.',
          icon: Icons.history,
          description:
              'Catat kegiatan di Agenda untuk melihat riwayatnya di sini.',
        ),
      for (final item in history) ...[
        Surface(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const IconTile(Icons.fact_check_outlined),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${item.status} · ${_dateTime(item.recordedAt)}'),
          ),
        ),
        const SizedBox(height: 10),
      ],
    ],
  );

  Widget _profile() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(
        'Profil Perawatan',
        'Pendamping: ${widget.caregiver}',
        label: 'RUANG KELUARGA',
        icon: Icons.badge_outlined,
      ),
      _summaryCard(
        label: 'PENDAMPING',
        title: widget.caregiver,
        description: 'Profil aktif',
        trailing: const Icon(
          Icons.badge_outlined,
          color: Color(0xFFB3D6BA),
          size: 28,
        ),
      ),
      const SizedBox(height: 12),
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const IconTile(Icons.person_outline_rounded),
            const SizedBox(height: 12),
            const Eyebrow('ORANG YANG DIRAWAT'),
            const SizedBox(height: 4),
            Text(widget.patient, style: Theme.of(context).textTheme.titleLarge),
            Text(
              mealInput == null
                  ? 'Kondisi kesehatan belum diisi.'
                  : (mealInput!['health_condition'] as Json)['condition_name']
                        as String,
            ),
            TextButton(
              onPressed: busy ? null : _editMealInput,
              child: const Text('Isi profil dan kebutuhan makan'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text('Resep obat', style: Theme.of(context).textTheme.titleLarge),
      if (prescriptions.isEmpty) ...[
        const SizedBox(height: 8),
        const Notice(
          text: 'Belum ada resep yang dicatat.',
          icon: Icons.medication_outlined,
        ),
      ],
      for (final prescription in prescriptions)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const IconTile(Icons.medication_outlined, accent: true),
          title: Text('Resep ${prescription['prescription_date']}'),
          subtitle: Text(
            (prescription['medications'] as List<Json>)
                .map((item) => item['medicine_name'])
                .join(', '),
          ),
        ),
      OutlinedButton.icon(
        onPressed: busy ? null : _addPrescription,
        icon: const Icon(Icons.add_rounded, size: 19),
        label: const Text('Tambah resep'),
      ),
      if (widget.onExitDemo != null) ...[
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: busy ? null : widget.onExitDemo,
          icon: const Icon(Icons.swap_horiz_rounded),
          label: const Text('Ganti skenario demo'),
        ),
      ],
      const SizedBox(height: 16),
      const Text(
        'Input dan catatan saat ini tersimpan selama sesi aplikasi.',
        style: TextStyle(fontSize: 12, color: muted),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: shellBackground,

    bottomNavigationBar: Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: NavigationBar(
          height: 68,
          backgroundColor: paper,
          indicatorColor: paleTeal,
          selectedIndex: page,
          onDestinationSelected: (value) => setState(() => page = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Hari Ini',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_rounded),
              label: 'Menu',
            ),
            NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    ),
    body: SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ColoredBox(
            color: cream,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: paper,
                    border: Border(bottom: BorderSide(color: line)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Row(
                    children: [
                      const Expanded(child: Brand(compact: true)),
                      const SizedBox(width: 8),
                      if (widget.demo != null) ...[
                        const BadgePill('Demo web', color: softRed),
                        const SizedBox(width: 8),
                      ],
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: paleTeal,
                        foregroundColor: ink,
                        child: Text(
                          widget.caregiver.characters.first.toUpperCase(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    key: ValueKey(page),
                    padding: const EdgeInsets.all(20),
                    child: switch (page) {
                      0 => _agenda(),
                      1 => _menu(),
                      2 => _history(),
                      _ => _profile(),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
