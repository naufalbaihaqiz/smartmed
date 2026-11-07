import 'package:flutter/material.dart';

import 'care_mark.dart';
import 'demo_data.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.onStart});

  final void Function(String caregiver, String patient, bool hasPrescription)
  onStart;

  Future<void> _chooseDemo(BuildContext context) async {
    final scenario = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: cream,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 430),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('PILIH SKENARIO', style: _eyebrow),
              const SizedBox(height: 6),
              Text(
                'Coba alur TemanRawat',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Data fiktif sudah disiapkan agar kamu bisa '
                'menjelajahi seluruh prototipe.',
              ),
              const SizedBox(height: 16),
              ListTile(
                tileColor: paper,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: line),
                ),
                leading: const CircleAvatar(
                  backgroundColor: paleTeal,
                  foregroundColor: teal,
                  child: Text('R'),
                ),
                title: const Text('Rina & Ibu Sari'),
                subtitle: const Text('Menu campuran dan rutinitas harian'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => Navigator.pop(context, false),
              ),
              const SizedBox(height: 10),
              ListTile(
                tileColor: paper,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: line),
                ),
                leading: const CircleAvatar(
                  backgroundColor: peach,
                  foregroundColor: red,
                  child: Text('D'),
                ),
                title: const Text('Dimas & Pak Arif'),
                subtitle: const Text('Termasuk pengingat obat fiktif'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (scenario == null || !context.mounted) return;
    if (scenario) {
      onStart('Dimas', 'Pak Arif', true);
    } else {
      onStart('Rina', 'Ibu Sari', false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: shellBackground,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: LayoutBuilder(
            builder: (context, constraints) => DecoratedBox(
              decoration: const BoxDecoration(
                color: cream,
                gradient: RadialGradient(
                  center: Alignment(.7, -.54),
                  radius: .55,
                  colors: [Color(0xFFF3E9E6), cream],
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
                          const Row(
                            children: [
                              Icon(Icons.water_drop, color: red, size: 17),
                              SizedBox(width: 6),
                              Text(
                                'TemanRawat',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 230,
                            child: Center(
                              child: Semantics(
                                image: true,
                                label: 'Dua tangan membentuk hati',
                                child: const CustomPaint(
                                  size: Size(208, 173.33),
                                  painter: CareMark(),
                                ),
                              ),
                            ),
                          ),
                          const Text(
                            'TEMAN UNTUK SETIAP LANGKAH PERAWATAN',
                            style: _eyebrow,
                          ),
                          const SizedBox(height: 12),
                          Text.rich(
                            const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Bantu orang tersayang menjalani hari dengan ',
                                ),
                                TextSpan(
                                  text: 'lebih teratur',
                                  style: TextStyle(
                                    color: red,
                                    fontFamily: 'Georgia',
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            style: TextStyle(
                              fontSize: constraints.maxWidth >= 400 ? 40 : 35,
                              height: 1.04,
                              letterSpacing: -1.7,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Susun menu, jadwal, dan catatan harian keluarga '
                            'dalam satu tempat yang sederhana.',
                            style: TextStyle(
                              color: muted,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 28),
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
                          TextButton(
                            onPressed: () => _chooseDemo(context),
                            child: const Text('Coba Demo'),
                          ),
                          const SizedBox(height: 10),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.favorite_border, size: 14, color: red),
                              SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Dibuat untuk pendamping, digunakan dari HP Anda',
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

  final void Function(String, String, bool) onStart;

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
                        hintText: 'Contoh: Rina',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _patient,
                      validator: _requiredName,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama panggilan orang yang dirawat',
                        hintText: 'Contoh: Ibu Sari',
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        if (!_form.currentState!.validate()) return;
                        widget.onStart(
                          _caregiver.text.trim(),
                          _patient.text.trim(),
                          false,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Lanjut ke Menu'),
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
