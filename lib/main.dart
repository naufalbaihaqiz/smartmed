import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'database/database_helper.dart';
import 'demo_data.dart';
import 'widgets.dart';
import 'welcome.dart';

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
  const TemanRawatApp({super.key});
  @override
  State<TemanRawatApp> createState() => _TemanRawatAppState();
}

class _TemanRawatAppState extends State<TemanRawatApp> {
  ({String caregiver, String patient, bool hasPrescription})? profile;

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
          fontSize: 34,
          fontWeight: FontWeight.w700,
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
        bodyMedium: TextStyle(fontSize: 14, color: ink, height: 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line),
        ),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
    ),
    home: profile != null
        ? HomeShell(
            caregiver: profile!.caregiver,
            patient: profile!.patient,
            hasPrescription: profile!.hasPrescription,
          )
        : WelcomePage(
            onStart: (caregiver, patient, hasPrescription) {
              setState(
                () => profile = (
                  caregiver: caregiver,
                  patient: patient,
                  hasPrescription: hasPrescription,
                ),
              );
            },
          ),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.caregiver,
    required this.patient,
    required this.hasPrescription,
  });

  final String caregiver, patient;
  final bool hasPrescription;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int page = 1, filter = 0, budget = 45000;
  bool family = true, approved = false;
  late List<CareActivity> activities = _initialAgenda();

  List<CareActivity> _initialAgenda() => initialActivities()
      .where(
        (activity) =>
            widget.hasPrescription ||
            activity.icon != Icons.medication_outlined,
      )
      .toList();
  final List<String> issues = [], logs = [];
  String get person => family ? widget.patient : widget.caregiver;
  int get completed => activities.where((a) => a.done).length;
  void toast(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
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
          selectedIndex: page,
          indicatorColor: paleTeal,
          onDestinationSelected: (value) => setState(() => page = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Hari Ini',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu),
              label: 'Menu',
            ),
            NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
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
                _topbar(),
                Expanded(
                  child: SingleChildScrollView(
                    key: ValueKey(page),
                    padding: const EdgeInsets.all(20),
                    child: switch (page) {
                      0 => _today(),
                      1 => _meals(),
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

  Widget _topbar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    decoration: const BoxDecoration(
      color: paper,
      border: Border(bottom: BorderSide(color: line)),
    ),
    child: Row(
      children: [
        const Icon(Icons.water_drop, color: red, size: 17),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'TemanRawat',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        CircleAvatar(
          radius: 17,
          backgroundColor: paleTeal,
          foregroundColor: teal,
          child: Text(widget.caregiver.characters.first.toUpperCase()),
        ),
      ],
    ),
  );

  Widget _today() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Eyebrow('PROGRES HARI INI'),
      const SizedBox(height: 8),
      Text(
        'Selamat pagi, ${widget.caregiver}',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 8),
      Text(
        'Mari jalani hari yang lebih teratur bersama $person.',
        style: const TextStyle(color: muted),
      ),
      const SizedBox(height: 26),
      _hero(),
      const SizedBox(height: 24),
      LayoutBuilder(
        builder: (context, c) {
          final agenda = _agenda();
          final aside = Column(
            children: [_menuSummary(), const SizedBox(height: 20), _careNote()],
          );
          return c.maxWidth > 720
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: agenda),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: aside),
                  ],
                )
              : Column(children: [agenda, const SizedBox(height: 24), aside]);
        },
      ),
      const SizedBox(height: 24),
      const Center(
        child: Text(
          'Dibuat untuk menemani, satu hari pada satu waktu.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
      ),
    ],
  );

  Widget _hero() => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: teal,
      borderRadius: BorderRadius.circular(24),
    ),
    child: LayoutBuilder(
      builder: (context, c) => Row(
        children: [
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_outline,
                        size: 16,
                        color: Color(0xFFBCDDD2),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          family ? 'RAWAT KELUARGA' : 'RAWAT DIRI',
                          style: const TextStyle(
                            color: Color(0xFFBCDDD2),
                            letterSpacing: 1.7,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Ruang tenang untuk\nmerawat $person.',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: c.maxWidth > 600 ? 32 : 25,
                      height: 1.25,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tak perlu mengingat semuanya sendiri.\nKita jalani satu per satu, ya.',
                    style: TextStyle(
                      color: Color(0xFFD0E5DF),
                      height: 1.7,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$completed dari ${activities.length} kegiatan tercatat',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: completed / activities.length,
                                minHeight: 6,
                                color: const Color(0xFFEAB18F),
                                backgroundColor: Colors.white24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${(completed / activities.length * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (c.maxWidth > 540)
            const Expanded(
              flex: 4,
              child: SizedBox(height: 270, child: CareIllustration()),
            ),
        ],
      ),
    ),
  );

  Widget _agenda() {
    final visible = activities.where(
      (a) => filter == 0 || (filter == 1 ? !a.done : a.done),
    );
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Agenda hari ini',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Tambah kegiatan',
                onPressed: _addActivity,
                icon: const Icon(Icons.add, color: teal),
              ),
            ],
          ),
          const Text(
            'Sedikit demi sedikit, tetap berarti.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            children: List.generate(
              3,
              (i) => ChoiceChip(
                label: Text(['Semua', 'Belum dicatat', 'Selesai'][i]),
                selected: filter == i,
                showCheckmark: false,
                selectedColor: paleTeal,
                side: BorderSide(color: filter == i ? paleTeal : line),
                labelStyle: TextStyle(
                  color: filter == i ? teal : muted,
                  fontSize: 12,
                ),
                onSelected: (_) => setState(() => filter = i),
              ),
            ),
          ),
          const SizedBox(height: 22),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Belum ada kegiatan pada kategori ini.',
                style: TextStyle(color: muted),
              ),
            ),
          ...visible.map(_activityTile),
          const Divider(height: 28),
          Center(
            child: TextButton.icon(
              onPressed: _addActivity,
              icon: const Icon(Icons.add, size: 17),
              label: const Text('Tambah kegiatan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityTile(CareActivity a) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: () => _activityDetails(a),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(top: 13),
              child: Text(
                a.time,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: a.done ? paleTeal : a.tint,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              a.done ? Icons.check_rounded : a.icon,
              color: a.done ? teal : ink,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  a.subtitle,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  a.done ? '✓  Sudah dicatat' : a.source,
                  style: TextStyle(
                    color: a.done ? teal : muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: muted, size: 20),
        ],
      ),
    ),
  );

  Widget _menuSummary() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome_outlined, color: teal, size: 19),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Di dapur hari ini',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          height: 130,
          decoration: BoxDecoration(
            color: const Color(0xFFF0E7D5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(child: FoodIllustration()),
        ),
        const SizedBox(height: 16),
        const Eyebrow('MENU MAKAN SIANG'),
        const SizedBox(height: 6),
        const Text(
          'Sup ayam & sayur hangat',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 7),
        const Text(
          'Sederhana, hangat, dan mudah disiapkan.',
          style: TextStyle(fontSize: 12, color: muted),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.schedule, size: 15, color: muted),
            const SizedBox(width: 5),
            const Expanded(
              child: Text(
                '25 menit',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                money(18000),
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: teal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 28),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Estimasi belanja hari ini',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
            Text(
              money(demoCost),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          'Dari budget ${money(budget)} • harga contoh',
          style: const TextStyle(color: muted, fontSize: 11),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => setState(() => page = 1),
            child: const Text('Lihat menu & budget  ↗'),
          ),
        ),
      ],
    ),
  );

  Widget _careNote() => Container(
    padding: const EdgeInsets.all(23),
    decoration: BoxDecoration(
      color: peach,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 18,
              color: Color(0xFF936249),
            ),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Untuk yang merawat',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF79513C),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Kamu juga butuh jeda. Ambil napas, minum air, dan beri ruang untuk dirimu.',
          style: TextStyle(color: Color(0xFF79513C), height: 1.7, fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _reportIssue,
          child: Text(
            issues.isEmpty
                ? 'Ada kendala? Catat di sini →'
                : '${issues.length} kendala tercatat →',
            style: const TextStyle(color: Color(0xFF79513C), fontSize: 12),
          ),
        ),
      ],
    ),
  );

  Widget _meals() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Menu Hari Ini', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 8),
      Text('Rencana makan untuk $person', style: const TextStyle(color: muted)),
      const SizedBox(height: 20),
      DecoratedBox(
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ESTIMASI ANGGARAN',
                style: TextStyle(
                  color: Color(0xFFBFE2C8),
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                money(demoCost),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (demoCost / budget).clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                color: budget >= demoCost ? const Color(0xFFBFE2C8) : peach,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 8),
              Text(
                'Dari anggaran ${money(budget)}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      for (final meal in demoMeals) ...[
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BadgePill(
                meal.slot.toUpperCase(),
                color: meal.id == 'lunch' ? peach : paleTeal,
              ),
              const SizedBox(height: 10),
              Text(meal.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                '${meal.minutes} menit · 1 porsi · ${money(meal.cost)}',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              TextButton.icon(
                onPressed: () => _recipe(meal),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Lihat Detail'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
      Notice(
        text: approved ? 'Jadwal aktif untuk hari ini.' : 'Periksa waktu dan sumber setiap kegiatan sebelum mengaktifkannya.',
        icon: Icons.schedule_outlined,
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: approved ? null : _reviewSchedule,
          icon: Icon(approved ? Icons.check : Icons.arrow_forward),
          label: Text(approved ? 'Rencana sudah diterapkan' : 'Tinjau Jadwal'),
        ),
      ),
      const SizedBox(height: 24),
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Daftar belanja',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: _editBudget,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Ubah budget'),
                ),
              ],
            ),
            const Text(
              'Kebutuhan contoh untuk 1 orang • stok sudah diperhitungkan',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ...shopping.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 19,
                      color: muted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$1),
                          Text(
                            item.$2,
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        money(item.$3),
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 30),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total estimasi belanja',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  money(demoCost),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              budget >= demoCost
                  ? 'Sisa budget ${money(budget - demoCost)} dari ${money(budget)}'
                  : 'Melebihi budget sebesar ${money(demoCost - budget)}',
              style: TextStyle(
                color: budget >= demoCost ? teal : const Color(0xFFA3453D),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Harga dan menu adalah data fiktif untuk demo.',
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _history() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Eyebrow('SETIAP CATATAN PUNYA CERITA'),
      const SizedBox(height: 8),
      Text(
        'Riwayat perawatan',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 8),
      Text(
        'Catatan kecil perjalanan perawatan $person.',
        style: const TextStyle(color: muted),
      ),
      const SizedBox(height: 26),
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BadgePill('Sabtu, 7 November 2026'),
            const SizedBox(height: 22),
            Text(
              '$completed kegiatan tercatat',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Catatan merupakan laporan pengguna atau caregiver.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            const Divider(height: 32),
            ...activities.where((a) => a.done).map(_activityTile),
            if (logs.isNotEmpty) ...[
              const Divider(height: 28),
              const Eyebrow('AKTIVITAS SESI INI'),
              const SizedBox(height: 12),
              ...logs.reversed.map(
                (l) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.receipt_long_outlined, color: teal),
                  title: Text(l, style: const TextStyle(fontSize: 13)),
                ),
              ),
            ],
            if (issues.isNotEmpty) ...[
              const Divider(height: 28),
              const Eyebrow('KENDALA TERBUKA'),
              ...issues.map(
                (i) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.flag_outlined,
                    color: Color(0xFFA3453D),
                  ),
                  title: Text(i),
                  subtitle: Text(
                    'Dicatat oleh ${widget.caregiver} • belum ditangani',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );

  Widget _profile() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Eyebrow('KENALI YANG KITA RAWAT'),
      const SizedBox(height: 8),
      Text(
        'Profil perawatan',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 8),
      const Text(
        'Arahan yang jelas, perawatan lebih terarah.',
        style: TextStyle(color: muted),
      ),
      const SizedBox(height: 26),
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mode perawatan',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Rawat Keluarga'),
                  selected: family,
                  onSelected: (_) => _switchMode(true),
                ),
                ChoiceChip(
                  label: const Text('Rawat Diri'),
                  selected: !family,
                  onSelected: (_) => _switchMode(false),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: peach,
                  child: Text(
                    family ? 'S' : 'R',
                    style: const TextStyle(fontSize: 25, color: ink),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        family
                            ? 'Dirawat oleh ${widget.caregiver}'
                            : '28 tahun • Dikelola sendiri',
                        style: const TextStyle(color: muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 36),
            const Notice(
              text: 'Konsultasi tercatat • 5 November 2026\nSumber: catatan konsultasi fiktif untuk demo.',
              icon: Icons.verified_outlined,
            ),
            const SizedBox(height: 24),
            const Text(
              'Arahan & kebutuhan',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.restaurant_outlined, color: teal),
              title: Text('Makanan rumahan'),
              subtitle: Text('Preferensi: tekstur lembut, mudah dimasak.'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info_outline, color: teal),
              title: Text('Aturan obat dari catatan konsultasi'),
              subtitle: Text(
                'Contoh pemeriksaan catatan pukul 08.00. Detail resep perlu dikonfirmasi.',
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.account_balance_wallet_outlined,
                color: teal,
              ),
              title: const Text('Budget harian'),
              subtitle: Text('${money(budget)} • ubah di Menu & Budget'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Notice(
        text: 'Prototipe tampilan: perubahan hanya bertahan selama sesi ini. AI, penyimpanan permanen, dan notifikasi perangkat belum terhubung.',
        icon: Icons.science_outlined,
      ),
    ],
  );

  void _switchMode(bool value) {
    if (value == family) return;
    setState(() {
      family = value;
      activities = _initialAgenda();
      approved = false;
      filter = 0;
      budget = 45000;
      issues.clear();
      logs.clear();
    });
    toast('Beralih ke profil demo $person. Data sesi direset.');
  }

  Future<void> _sheet(String title, Widget Function(BuildContext) content) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: paper,
        constraints: const BoxConstraints(maxWidth: 620),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              0,
              24,
              MediaQuery.viewInsetsOf(ctx).bottom + 24,
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(ctx).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  content(ctx),
                ],
              ),
            ),
          ),
        ),
      );

  void _activityDetails(CareActivity a) => _sheet(
    a.title,
    (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BadgePill(
          '${a.time}  •  ${a.done ? 'Sudah dicatat' : 'Belum dicatat'}',
        ),
        const SizedBox(height: 20),
        Text(a.subtitle),
        const SizedBox(height: 16),
        Notice(text: '${a.source}\n${a.note}', icon: Icons.info_outline),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              setState(() {
                a.done = !a.done;
                logs.add(
                  '${a.done ? 'Konfirmasi' : 'Koreksi catatan'}: ${a.title} • ${widget.caregiver}',
                );
              });
              Navigator.pop(ctx);
            },
            icon: Icon(a.done ? Icons.undo : Icons.check),
            label: Text(
              a.done
                  ? 'Koreksi: belum dikonfirmasi'
                  : 'Konfirmasi kegiatan selesai',
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            _reportIssue();
          },
          child: const Text('Catat kendala'),
        ),
      ],
    ),
  );

  Future<void> _addActivity() async {
    final name = TextEditingController();
    TimeOfDay time = const TimeOfDay(hour: 16, minute: 0);
    await _sheet(
      'Tambah kegiatan',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tambahkan kegiatan pribadi ke agenda contoh.',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Nama kegiatan',
                hintText: 'Contoh: menyiapkan makan malam',
              ),
              maxLength: 80,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule, color: teal),
              title: Text(
                'Waktu ${time.hour.toString().padLeft(2, '0')}.${time.minute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () async {
                final picked = await showTimePicker(
                  context: ctx,
                  initialTime: time,
                );
                if (picked != null) update(() => time = picked);
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                setState(() {
                  activities.add(
                    CareActivity(
                      time:
                          '${time.hour.toString().padLeft(2, '0')}.${time.minute.toString().padLeft(2, '0')}',
                      title: name.text.trim(),
                      subtitle: 'Kegiatan pribadi',
                      source: 'Ditambahkan pengguna',
                      icon: Icons.event_note_outlined,
                      tint: paleTeal,
                      note: 'Bukan arahan medis.',
                    ),
                  );
                  activities.sort((a, b) => a.time.compareTo(b.time));
                  filter = 0;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Simpan kegiatan'),
            ),
          ],
        ),
      ),
    );
    // The route can animate out after its future completes.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    name.dispose();
  }

  Future<void> _reportIssue() async {
    final note = TextEditingController();
    await _sheet(
      'Catat kendala',
      (ctx) => Column(
        children: [
          TextField(
            controller: note,
            maxLines: 3,
            maxLength: 240,
            decoration: const InputDecoration(
              labelText: 'Apa yang perlu diperhatikan?',
              hintText: 'Contoh: bahan untuk makan siang habis',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (note.text.trim().isEmpty) return;
                setState(() => issues.add(note.text.trim()));
                Navigator.pop(ctx);
                toast('Kendala tersimpan di riwayat sesi ini.');
              },
              child: const Text('Simpan catatan'),
            ),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    note.dispose();
  }

  Future<void> _editBudget() async {
    final amount = TextEditingController(text: '$budget');
    String? error;
    await _sheet(
      'Budget belanja harian',
      (ctx) => StatefulBuilder(
        builder: (ctx, update) => Column(
          children: [
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Budget dalam rupiah',
                prefixText: 'Rp ',
                errorText: error,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                final n = int.tryParse(amount.text.trim());
                if (n == null || n <= 0) {
                  update(() => error = 'Masukkan angka rupiah lebih dari nol.');
                  return;
                }
                setState(() => budget = n);
                Navigator.pop(ctx);
              },
              child: const Text('Simpan budget'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    amount.dispose();
  }

  void _recipe(DemoMeal m) => _sheet(
    m.name,
    (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${m.minutes} menit • 1 porsi • ${money(m.cost)} estimasi'),
        const SizedBox(height: 20),
        const Eyebrow('BAHAN'),
        const SizedBox(height: 10),
        Text(m.ingredients),
        const SizedBox(height: 20),
        const Eyebrow('CARA MENYIAPKAN'),
        const SizedBox(height: 10),
        Text(m.steps),
        const SizedBox(height: 20),
        const Notice(
          text: 'Resep contoh untuk memperagakan tampilan. Kecocokan dengan kebutuhan individual belum dinilai.',
          icon: Icons.info_outline,
        ),
      ],
    ),
  );

  void _reviewSchedule() => _sheet(
    'Tinjau Jadwal',
    (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Notice(
          text: 'Jadwal ini adalah contoh, bukan hasil AI. Persetujuan hanya menambahkan kegiatan makan ke agenda sesi ini.',
          icon: Icons.auto_awesome_outlined,
        ),
        const SizedBox(height: 16),
        ...demoMeals.map(
          (m) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.restaurant_outlined, color: teal),
            title: Text(m.name),
            subtitle: Text('${m.time} • Usulan waktu, dapat ditinjau'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              if (!approved) {
                setState(() {
                  for (final m in demoMeals) {
                    if (!activities.any((a) => a.id == m.id)) {
                      activities.add(
                        CareActivity(
                          id: m.id,
                          time: m.time,
                          title: m.name,
                          subtitle: m.slot,
                          source: 'Menu contoh disetujui pengguna',
                          icon: Icons.restaurant_outlined,
                          tint: peach,
                          note: 'Usulan waktu dari data demo.',
                        ),
                      );
                    }
                  }
                  activities.sort((a, b) => a.time.compareTo(b.time));
                  approved = true;
                  logs.add(
                    'Rencana menu contoh disetujui • ${widget.caregiver}',
                  );
                  page = 0;
                  filter = 0;
                });
              }
              Navigator.pop(ctx);
              toast('Menu diterapkan ke agenda tanpa duplikasi.');
            },
            child: const Text('Setujui & masukkan ke agenda'),
          ),
        ),
      ],
    ),
  );
}
