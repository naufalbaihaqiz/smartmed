import 'package:flutter/material.dart';

import 'care_mark.dart';
import 'palette.dart';
import 'widgets.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.onStart, this.onDemo});

  final void Function(String caregiver, String patient) onStart;
  final void Function(bool withPrescription)? onDemo;

  Future<void> _chooseDemo(BuildContext context) async {
    final choose = onDemo;
    if (choose == null) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: cream,
      constraints: const BoxConstraints(maxWidth: 430),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('PILIH SKENARIO WEB'),
              const SizedBox(height: 8),
              Text(
                'Coba alur TemanRawat',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Data contoh hanya digunakan untuk melihat tampilan.'),
              const SizedBox(height: 12),
              Surface(
                child: Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const IconTile(Icons.person_outline),
                    title: const Text('Rina & Ibu Sari'),
                    subtitle: const Text('Menu dan rutinitas tanpa resep obat'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => Navigator.pop(context, false),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Surface(
                child: Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const IconTile(
                      Icons.medication_outlined,
                      accent: true,
                    ),
                    title: const Text('Dimas & Pak Arif'),
                    subtitle: const Text(
                      'Menu dan jadwal dengan resep obat contoh',
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => Navigator.pop(context, true),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (context.mounted && result != null) choose(result);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: shellBackground,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 430,
            maxHeight: MediaQuery.sizeOf(context).width >= 520
                ? 760
                : double.infinity,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => DecoratedBox(
              decoration: const BoxDecoration(
                color: cream,
                gradient: RadialGradient(
                  center: Alignment(.72, -.50),
                  radius: .55,
                  colors: [Color(0xFFF3E8E4), cream],
                ),
              ),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Brand(),
                          const CareArtwork(),
                          const SizedBox(height: 8),
                          const Text(
                            'TEMAN UNTUK SETIAP LANGKAH PERAWATAN',
                            style: _eyebrow,
                          ),
                          const SizedBox(height: 10),
                          Text.rich(
                            const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Bantu orang tersayang menjalani hari dengan ',
                                ),
                                TextSpan(
                                  text: 'lebih teratur',
                                  style: TextStyle(color: red),
                                ),
                              ],
                            ),
                            style: TextStyle(
                              fontSize: constraints.maxWidth >= 400 ? 40 : 35,
                              height: 1.07,
                              letterSpacing: -1.45,
                              fontWeight: FontWeight.w800,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Susun rencana makan, tinjau jadwal, dan catat kegiatan perawatan keluarga dalam satu tempat.',
                            style: TextStyle(
                              color: muted,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () => Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    _CareSetupPage(onStart: onStart),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(child: Text('Mulai Mendampingi')),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                          ),
                          if (onDemo != null)
                            TextButton(
                              onPressed: () => _chooseDemo(context),
                              child: const Text('Coba Demo'),
                            ),
                          const SizedBox(height: 10),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite_border_rounded,
                                size: 14,
                                color: red,
                              ),
                              SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Dibuat untuk pendamping keluarga',
                                  style: TextStyle(fontSize: 11, color: muted),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

const _eyebrow = TextStyle(
  color: red,
  fontSize: 11,
  letterSpacing: 1.35,
  fontWeight: FontWeight.w700,
);

class _CareSetupPage extends StatefulWidget {
  const _CareSetupPage({required this.onStart});

  final void Function(String, String) onStart;

  @override
  State<_CareSetupPage> createState() => _CareSetupPageState();
}

class _CareSetupPageState extends State<_CareSetupPage> {
  final _form = GlobalKey<FormState>();
  final _caregiver = TextEditingController();
  final _patient = TextEditingController();

  @override
  void dispose() {
    _caregiver.dispose();
    _patient.dispose();
    super.dispose();
  }

  String? _requiredName(String? value) =>
      value == null || value.trim().isEmpty ? 'Isi nama panggilan.' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: shellBackground,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ColoredBox(
            color: cream,
            child: SizedBox.expand(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Align(alignment: Alignment.centerLeft, child: BackButton()),
                    const SizedBox(height: 20),
                    const IconTile(Icons.badge_outlined, accent: true),
                    const SizedBox(height: 14),
                    const Text('PROFIL PERAWATAN', style: _eyebrow),
                    const SizedBox(height: 8),
                    Text(
                      'Siapa yang kamu dampingi?',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Ceritakan sedikit agar rencana harian terasa lebih personal.',
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _caregiver,
                      validator: _requiredName,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nama panggilan kamu',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _patient,
                      validator: _requiredName,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama panggilan orang yang dirawat',
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        if (!_form.currentState!.validate()) return;
                        widget.onStart(
                          _caregiver.text.trim(),
                          _patient.text.trim(),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Lanjut ke Profil'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
