import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'care_api.dart';
import 'database/database_helper.dart';
import 'models/care_plan.dart';
import 'palette.dart';
import 'screens/care_wizard_page.dart';
import 'screens/patient_care_detail_page.dart';
import 'web_demo.dart';
import 'widgets.dart';

const webDemoEnabled = kIsWeb && bool.fromEnvironment('TEMANRAWAT_WEB_DEMO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CarePlanStore? persistentStore;
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    await DatabaseHelper.instance.database;
    persistentStore = SqliteCarePlanStore();
  }
  runApp(TemanRawatApp(store: persistentStore));
}

class TemanRawatApp extends StatelessWidget {
  const TemanRawatApp({super.key, this.api, this.store});

  final CareApi? api;
  final CarePlanStore? store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TemanRawat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        fontFamily: 'Segoe UI',
        colorScheme: ColorScheme.fromSeed(
          seedColor: teal,
          primary: teal,
          surface: paper,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: ink,
            letterSpacing: -1.0,
          ),
          headlineSmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: ink,
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          bodyMedium: TextStyle(fontSize: 14, color: ink, height: 1.5),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: teal,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: teal,
            minimumSize: const Size(0, 50),
            side: const BorderSide(color: line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: paper,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: teal, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: red, width: 1.6),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: line),
          ),
        ),
        dividerTheme: const DividerThemeData(color: line, thickness: 1),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
      ),
      home: HomePage(api: api, store: store),
    );
  }
}

enum _PatientFilter { all, ongoing, completed }

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.api, this.store});

  final CareApi? api;
  final CarePlanStore? store;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final CareApi _api =
      widget.api ?? (webDemoEnabled ? WebDemo().createApi() : CareApi());
  late final CarePlanStore _store =
      widget.store ??
      MemoryCarePlanStore(
        webDemoEnabled ? WebDemo.sampleCarePlans() : const [],
      );

  List<PatientCarePlan> _plans = [];
  bool _loading = true;
  _PatientFilter _filter = _PatientFilter.all;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void dispose() {
    if (widget.api == null) _api.close();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    final loaded = await _store.loadAll();
    if (!mounted) return;
    setState(() {
      _plans = List<PatientCarePlan>.from(loaded);
      _loading = false;
    });
  }

  Future<void> _upsertPlan(PatientCarePlan plan) async {
    await _store.save(plan);
    if (!mounted) return;
    setState(() {
      final index = _plans.indexWhere((item) => item.id == plan.id);
      if (index >= 0) {
        _plans[index] = plan;
      } else {
        _plans.insert(0, plan);
      }
    });
  }

  Future<void> _deletePlan(String id) async {
    await _store.delete(id);
    if (!mounted) return;
    setState(() {
      _plans.removeWhere((item) => item.id == id);
    });
  }

  Future<void> _openDetail(PatientCarePlan plan) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PatientCareDetailPage(
          initialPlan: plan,
          onPlanUpdated: _upsertPlan,
          onDeletePlan: () => _deletePlan(plan.id),
        ),
      ),
    );
  }

  Future<void> _startAddPatientFlow() async {
    final createdPlan = await Navigator.push<PatientCarePlan>(
      context,
      MaterialPageRoute(
        builder: (_) => CareWizardPage(api: _api),
      ),
    );
    if (createdPlan == null || !mounted) return;
    await _upsertPlan(createdPlan);
    if (!mounted) return;
    await _openDetail(createdPlan);
  }

  Future<void> _openApiSettingsDialog() async {
    final ctrl = TextEditingController(text: _api.baseUrl);
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alamat Server API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Atur URL backend TemanRawat (misal http://10.0.2.2:8000 untuk emulator atau IP lokal untuk HP fisik).',
              style: TextStyle(fontSize: 13, color: muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'TEMANRAWAT_API_URL',
                hintText: 'http://10.0.2.2:8000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() => _api.baseUrl = saved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server API diatur ke: $saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<PatientCarePlan> get _filteredPlans => switch (_filter) {
    _PatientFilter.all => _plans,
    _PatientFilter.ongoing =>
      _plans.where((p) => !p.isScheduleCompleted).toList(),
    _PatientFilter.completed =>
      _plans.where((p) => p.isScheduleCompleted).toList(),
  };

  Widget _buildHeroOverview() {
    final totalPatients = _plans.length;
    final completedPatients = _plans
        .where((p) => p.isScheduleCompleted)
        .length;
    final ongoingPatients = totalPatients - completedPatients;

    final totalTasks = _plans.fold<int>(0, (sum, p) => sum + p.totalSchedules);
    final doneTasks = _plans.fold<int>(
      0,
      (sum, p) => sum + p.completedSchedules,
    );
    final overallProgress = totalTasks == 0 ? 0.0 : doneTasks / totalTasks;

    return Container(
      padding: const EdgeInsets.all(22),
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
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: totalPatients == 0
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                BadgePill(
                  'PENDAMPING KELUARGA',
                  color: Color(0x29FFFFFF),
                  textColor: Colors.white,
                  icon: Icons.favorite_rounded,
                ),
                SizedBox(height: 14),
                Text(
                  'Kelola Menu Sehat & Jadwal Obat Lebih Teratur',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tekan tombol + di kanan bawah untuk menambahkan orang yang dirawat beserta kondisi kesehatan, resep dokter, dan rekomendasi makanannya.',
                  style: TextStyle(
                    color: Color(0xFFD5EBD9),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RINGKASAN PERAWATAN HARI INI',
                  style: TextStyle(
                    color: Color(0xFFB3D6BA),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalPatients Orang Dirawat',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$doneTasks dari $totalTasks jadwal harian telah diselesaikan',
                            style: const TextStyle(
                              color: Color(0xFFD5EBD9),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${(overallProgress * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: overallProgress,
                    minHeight: 7,
                    backgroundColor: Colors.white24,
                    color: const Color(0xFF86EFAC),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MiniSummaryStat(
                        label: 'Jadwal Selesai',
                        value: '$completedPatients orang',
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniSummaryStat(
                        label: 'Belum Selesai',
                        value: '$ongoingPatients orang',
                        icon: Icons.pending_actions_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildPatientCard(PatientCarePlan plan) {
    final initial = plan.patientName.trim().isEmpty
        ? '?'
        : plan.patientName.trim().characters.first.toUpperCase();
    final isDone = plan.isScheduleCompleted;

    return Surface(
      onTap: () => _openDetail(plan),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDone ? successSoft : paleTeal,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: isDone ? successGreen : teal,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.patientName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 17.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        plan.conditionName,
                        if (plan.age != null) '${plan.age} thn',
                      ].join(' · '),
                      style: const TextStyle(color: muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ScheduleStatusBadge(completed: isDone),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: plan.progress,
                    minHeight: 7,
                    backgroundColor: slate,
                    color: isDone ? successGreen : teal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${plan.completedSchedules}/${plan.totalSchedules} jadwal',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    BadgePill(
                      '${plan.meals.length} Menu Makanan',
                      color: slate,
                      icon: Icons.restaurant_menu_rounded,
                    ),
                    if (plan.hasPrescription)
                      BadgePill(
                        '${plan.allMedications.length} Obat Resep',
                        color: medSoft,
                        textColor: medAccent,
                        icon: Icons.medication_outlined,
                      )
                    else
                      const BadgePill(
                        'Tanpa Resep',
                        color: slate,
                        textColor: muted,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: muted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _plans.where((p) => p.isScheduleCompleted).length;
    final ongoingCount = _plans.length - completedCount;
    final visiblePlans = _filteredPlans;

    return MobileFrame(
      child: Scaffold(
        backgroundColor: cream,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionButton(
          tooltip: 'Tambah orang yang dirawat',
          onPressed: _startAddPatientFlow,
          child: const Icon(Icons.add_rounded, size: 30),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 13, 12, 13),
                decoration: const BoxDecoration(
                  color: paper,
                  border: Border(bottom: BorderSide(color: line)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Brand(
                        compact: true,
                        subtitle: 'Pendamping Perawatan Harian',
                      ),
                    ),
                    if (webDemoEnabled) ...[
                      const BadgePill(
                        'Demo',
                        color: softRed,
                        textColor: red,
                      ),
                      const SizedBox(width: 4),
                    ],
                    IconButton(
                      tooltip: 'Pengaturan Server API',
                      onPressed: _openApiSettingsDialog,
                      icon: const Icon(Icons.dns_outlined, color: muted),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: teal),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                        children: [
                          _buildHeroOverview(),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Daftar Orang yang Dirawat',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              if (_plans.isNotEmpty)
                                BadgePill(
                                  '${_plans.length} orang',
                                  color: paleTeal,
                                  textColor: teal,
                                ),
                            ],
                          ),
                          if (_plans.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: Text('Semua (${_plans.length})'),
                                  selected: _filter == _PatientFilter.all,
                                  selectedColor: paleTeal,
                                  onSelected: (_) => setState(
                                    () => _filter = _PatientFilter.all,
                                  ),
                                ),
                                ChoiceChip(
                                  label: Text('Belum Selesai ($ongoingCount)'),
                                  selected: _filter == _PatientFilter.ongoing,
                                  selectedColor: warningSoft,
                                  onSelected: (_) => setState(
                                    () => _filter = _PatientFilter.ongoing,
                                  ),
                                ),
                                ChoiceChip(
                                  label: Text('Selesai ($completedCount)'),
                                  selected: _filter == _PatientFilter.completed,
                                  selectedColor: successSoft,
                                  onSelected: (_) => setState(
                                    () => _filter = _PatientFilter.completed,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),
                          if (_plans.isEmpty)
                            EmptyPanel(
                              icon: Icons.volunteer_activism_outlined,
                              title: 'Belum Ada yang Dirawat',
                              description:
                                  'Tekan tombol + di pojok kanan bawah untuk mulai mengisi kondisi kesehatan, daftar resep obat, alergi & budget makanan, hingga jadwal harian.',
                              action: OutlinedButton.icon(
                                onPressed: _startAddPatientFlow,
                                icon: const Icon(Icons.add_rounded, size: 19),
                                label: const Text('Tambah Orang yang Dirawat'),
                              ),
                            )
                          else if (visiblePlans.isEmpty)
                            const EmptyPanel(
                              icon: Icons.filter_list_off_rounded,
                              title: 'Tidak Ada Data pada Filter Ini',
                              description:
                                  'Pilih kategori filter lainnya untuk melihat daftar perawatan.',
                            )
                          else
                            for (var i = 0; i < visiblePlans.length; i++) ...[
                              if (i > 0) const SizedBox(height: 12),
                              _buildPatientCard(visiblePlans[i]),
                            ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniSummaryStat extends StatelessWidget {
  const _MiniSummaryStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.11),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFD5EBD9)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFD5EBD9),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
