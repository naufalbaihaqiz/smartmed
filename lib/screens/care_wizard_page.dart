import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../care_api.dart';
import '../care_forms.dart';
import '../models/care_plan.dart';
import '../palette.dart';
import '../widgets.dart';

enum _WizardStep {
  patientName,
  healthCondition,
  prescription,
  dietPreferences,
  generatedMeals,
}

class _MedicationDraft {
  _MedicationDraft()
    : name = TextEditingController(),
      dosage = TextEditingController(),
      quantity = TextEditingController(text: '10'),
      frequency = TextEditingController(),
      instruction = TextEditingController(),
      notes = TextEditingController();

  final TextEditingController name;
  final TextEditingController dosage;
  final TextEditingController quantity;
  final TextEditingController frequency;
  final TextEditingController instruction;
  final TextEditingController notes;
  bool isAfterEat = true;

  void dispose() {
    name.dispose();
    dosage.dispose();
    quantity.dispose();
    frequency.dispose();
    instruction.dispose();
    notes.dispose();
  }
}

class CareWizardPage extends StatefulWidget {
  const CareWizardPage({super.key, required this.api});

  final CareApi api;

  @override
  State<CareWizardPage> createState() => _CareWizardPageState();
}

class _CareWizardPageState extends State<CareWizardPage> {
  final _scrollController = ScrollController();

  // Form keys per step
  final _nameFormKey = GlobalKey<FormState>();
  final _healthFormKey = GlobalKey<FormState>();
  final _prescriptionFormKey = GlobalKey<FormState>();
  final _dietFormKey = GlobalKey<FormState>();

  _WizardStep _step = _WizardStep.patientName;

  // Step 1: Patient Name
  final _patientNameCtrl = TextEditingController();

  // Step 2: Health Condition
  final _conditionCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _conditionNotesCtrl = TextEditingController();
  bool _hasPrescription = false;

  // Step 3: Doctor's Prescription & Medications
  late final _prescriptionDateCtrl = TextEditingController(
    text: formatIsoDate(DateTime.now()),
  );
  late final _prescriptionStartCtrl = TextEditingController(
    text: formatIsoDate(DateTime.now()),
  );
  final _prescriptionNotesCtrl = TextEditingController();
  final List<_MedicationDraft> _medications = [_MedicationDraft()];

  // Step 4: Allergies, Preferences & Budget
  final Set<String> _selectedAllergies = {};
  final _customAllergiesCtrl = TextEditingController();
  final Set<String> _selectedPreferences = {};
  final _customPreferencesCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _routineCtrl = TextEditingController();

  // Step 5: API Generation State
  int _inputVersion = 1;
  bool _loadingMeals = false;
  bool _loadingSchedule = false;
  String? _apiError;
  List<String> _aiMessages = [];
  List<Json> _generatedMeals = [];

  static const _commonConditions = [
    'Hipertensi',
    'Diabetes',
    'Asam Lambung (GERD)',
    'Kolesterol Tinggi',
    'Pasca Operasi',
    'Pemulihan Lansia',
  ];

  static const _commonAllergies = [
    'Kacang',
    'Seafood',
    'Telur',
    'Susu Sapi',
    'Ikan Laut',
    'Gluten',
  ];

  static const _commonPreferences = [
    'Tekstur lembut',
    'Makanan rumahan',
    'Rendah garam',
    'Rendah gula',
    'Berkuah hangat',
    'Tinggi protein',
  ];

  static const _budgetPresets = [35000, 50000, 75000, 100000, 150000];

  @override
  void dispose() {
    _scrollController.dispose();
    _patientNameCtrl.dispose();
    _conditionCtrl.dispose();
    _diagnosisCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _conditionNotesCtrl.dispose();
    _prescriptionDateCtrl.dispose();
    _prescriptionStartCtrl.dispose();
    _prescriptionNotesCtrl.dispose();
    for (final med in _medications) {
      med.dispose();
    }
    _customAllergiesCtrl.dispose();
    _customPreferencesCtrl.dispose();
    _budgetCtrl.dispose();
    _routineCtrl.dispose();
    super.dispose();
  }

  List<_WizardStep> get _activeSteps => [
    _WizardStep.patientName,
    _WizardStep.healthCondition,
    if (_hasPrescription) _WizardStep.prescription,
    _WizardStep.dietPreferences,
    _WizardStep.generatedMeals,
  ];

  int get _currentStepNumber => _activeSteps.indexOf(_step) + 1;
  int get _totalSteps => _activeSteps.length;

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _goBack() {
    if (_loadingMeals || _loadingSchedule) return;
    final steps = _activeSteps;
    final index = steps.indexOf(_step);
    if (index <= 0) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _step = steps[index - 1];
      _apiError = null;
    });
    _scrollToTop();
  }

  List<String> _mergedList(Set<String> chips, String freeText) {
    final seen = <String>{};
    final result = <String>[];
    for (final item in [...chips, ...splitCsvItems(freeText)]) {
      final key = item.toLowerCase();
      if (seen.add(key)) result.add(item);
    }
    return result;
  }

  Json _buildHealthConditionPayload() => {
    'condition_name': _conditionCtrl.text.trim(),
    'name': _patientNameCtrl.text.trim(),
    'diagnosis': _diagnosisCtrl.text.trim().isEmpty
        ? null
        : _diagnosisCtrl.text.trim(),
    'notes': _conditionNotesCtrl.text.trim().isEmpty
        ? null
        : _conditionNotesCtrl.text.trim(),
    'age': int.parse(_ageCtrl.text.trim()),
    'weight': parseFlexibleDouble(_weightCtrl.text)!,
    'height': parseFlexibleDouble(_heightCtrl.text)!,
    'isTherePrescription': _hasPrescription,
  };

  List<Json> _buildPrescriptionsPayload() {
    if (!_hasPrescription) return const [];
    return [
      {
        'id': 1,
        'prescription_date': _prescriptionDateCtrl.text.trim(),
        'start_at': _prescriptionStartCtrl.text.trim(),
        'status': 'active',
        'notes': _prescriptionNotesCtrl.text.trim().isEmpty
            ? null
            : _prescriptionNotesCtrl.text.trim(),
        'medications': [
          for (var i = 0; i < _medications.length; i++)
            {
              'id': i + 1,
              'prescription_id': 1,
              'medicine_name': _medications[i].name.text.trim(),
              'dosage': _medications[i].dosage.text.trim(),
              'frequency': _medications[i].frequency.text.trim(),
              'instruction': _medications[i].instruction.text.trim(),
              'quantity': int.parse(_medications[i].quantity.text.trim()),
              'notes': _medications[i].notes.text.trim().isEmpty
                  ? null
                  : _medications[i].notes.text.trim(),
              'isAfterEat': _medications[i].isAfterEat,
            },
        ],
      },
    ];
  }

  Future<void> _fetchGeneratedMeals() async {
    setState(() {
      _loadingMeals = true;
      _apiError = null;
      _aiMessages = [];
      _generatedMeals = [];
      _inputVersion++;
    });

    final version = _inputVersion;
    final allergies = _mergedList(
      _selectedAllergies,
      _customAllergiesCtrl.text,
    ).map<Json>((type) => {'type': type}).toList();
    final preferences = _mergedList(
      _selectedPreferences,
      _customPreferencesCtrl.text,
    );
    final budget = parseRupiah(_budgetCtrl.text) ?? 50000.0;

    try {
      final result = await widget.api.generateMeals({
        'health_condition': _buildHealthConditionPayload(),
        'allergies': allergies,
        'budget': budget,
        'preferensi': preferences,
      }, version);

      if (!mounted || version != _inputVersion) return;

      setState(() {
        _generatedMeals = result.meals;
        _aiMessages = result.messages;
        if (_generatedMeals.isEmpty) {
          _apiError = result.messages.isNotEmpty
              ? result.messages.join('\n')
              : 'Server belum mengembalikan rekomendasi makanan. Silakan sesuaikan budget atau preferensi lalu coba lagi.';
        }
      });
    } on CareApiException catch (e) {
      if (!mounted) return;
      setState(() => _apiError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _apiError = 'Gagal mengambil rekomendasi makanan: $e');
    } finally {
      if (mounted) setState(() => _loadingMeals = false);
    }
  }

  Future<void> _generateScheduleAndFinish() async {
    if (_generatedMeals.isEmpty || _loadingSchedule) return;

    setState(() {
      _loadingSchedule = true;
      _apiError = null;
    });

    final version = _inputVersion;
    final prescriptions = _buildPrescriptionsPayload();
    final routineText = _routineCtrl.text.trim();

    try {
      final result = await widget.api.generateSchedule({
        'menu_disetujui': _generatedMeals,
        'prescriptions': prescriptions,
        'rutinitas': {
          'waktu_makan_standar': 'Pagi 07:00, Siang 12:30, Malam 18:30',
          if (routineText.isNotEmpty) 'notes': routineText,
        },
      }, version);

      if (!mounted || version != _inputVersion) return;

      if (result.reminders.isEmpty) {
        setState(() {
          _apiError = result.messages.isNotEmpty
              ? result.messages.join('\n')
              : 'Server belum berhasil menyusun jadwal. Silakan coba lagi.';
        });
        return;
      }

      final sortedReminders = result.reminders
          .map<Json>((r) => {...r, 'status': 'pending'})
          .toList()
        ..sort(
          (a, b) => DateTime.parse(
            a['schedule_at'] as String,
          ).compareTo(DateTime.parse(b['schedule_at'] as String)),
        );

      final allergies = _mergedList(
        _selectedAllergies,
        _customAllergiesCtrl.text,
      ).map<Json>((type) => {'type': type}).toList();
      final preferences = _mergedList(
        _selectedPreferences,
        _customPreferencesCtrl.text,
      );

      final plan = PatientCarePlan(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        patientName: _patientNameCtrl.text.trim(),
        healthCondition: _buildHealthConditionPayload(),
        prescriptions: prescriptions,
        allergies: allergies,
        preferensi: preferences,
        budget: parseRupiah(_budgetCtrl.text) ?? 50000.0,
        routineNotes: routineText,
        meals: _generatedMeals,
        reminders: sortedReminders,
        aiNotes: [..._aiMessages, ...result.messages],
      );

      Navigator.pop(context, plan);
    } on CareApiException catch (e) {
      if (!mounted) return;
      setState(() => _apiError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _apiError = 'Gagal membuat jadwal: $e');
    } finally {
      if (mounted) setState(() => _loadingSchedule = false);
    }
  }

  void _nextFromName() {
    if (!_nameFormKey.currentState!.validate()) return;
    setState(() => _step = _WizardStep.healthCondition);
    _scrollToTop();
  }

  void _nextFromHealth() {
    if (!_healthFormKey.currentState!.validate()) return;
    setState(() {
      _step = _hasPrescription
          ? _WizardStep.prescription
          : _WizardStep.dietPreferences;
    });
    _scrollToTop();
  }

  void _nextFromPrescription() {
    if (!_prescriptionFormKey.currentState!.validate()) return;
    setState(() => _step = _WizardStep.dietPreferences);
    _scrollToTop();
  }

  void _nextFromDiet() {
    if (!_dietFormKey.currentState!.validate()) return;
    setState(() => _step = _WizardStep.generatedMeals);
    _scrollToTop();
    _fetchGeneratedMeals();
  }

  void _addAnotherMedication() {
    setState(() {
      _medications.add(_MedicationDraft());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _removeMedication(int index) {
    if (_medications.length <= 1) return;
    final removed = _medications.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  // ==================== STEP BUILDERS ====================

  Widget _buildStepHeader({
    required IconData icon,
    required String eyebrow,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconTile(icon, accent: true, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow(eyebrow),
                  const SizedBox(height: 2),
                  Text(
                    'Langkah $_currentStepNumber dari $_totalSteps',
                    style: const TextStyle(
                      fontSize: 12,
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: muted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  Widget _buildPatientNameStep() {
    return Form(
      key: _nameFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader(
            icon: Icons.favorite_rounded,
            eyebrow: 'PROFIL PASIEN',
            title: 'Siapa nama orang yang akan dirawat?',
            subtitle:
                'Masukkan nama panggilan atau nama lengkap orang tersayang yang ingin dibuatkan jadwal makan dan minum obat.',
          ),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _patientNameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _nextFromName(),
                  validator: (v) =>
                      validateRequired(v, 'Masukkan nama orang yang dirawat.'),
                  decoration: const InputDecoration(
                    labelText: 'Nama orang yang dirawat',
                    hintText: 'Contoh: Ibu Sari / Pak Budi',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: teal),
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Icon(Icons.tips_and_updates_outlined, size: 16, color: teal),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Anda dapat menambahkan lebih dari satu anggota keluarga di Beranda.',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthConditionStep() {
    final name = _patientNameCtrl.text.trim();
    return Form(
      key: _healthFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader(
            icon: Icons.assignment_ind_outlined,
            eyebrow: 'KONDISI KESEHATAN',
            title: 'Bagaimana kondisi kesehatan $name?',
            subtitle:
                'Informasi ini digunakan untuk menyusun menu yang aman beserta penjadwalan harian.',
          ),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('PILIH CEPAT ATAU KETIK KONDISI'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final item in _commonConditions)
                      ActionChip(
                        label: Text(item),
                        backgroundColor:
                            _conditionCtrl.text.trim().toLowerCase() ==
                                item.toLowerCase()
                            ? paleTeal
                            : slate,
                        side: BorderSide(
                          color:
                              _conditionCtrl.text.trim().toLowerCase() ==
                                  item.toLowerCase()
                              ? teal
                              : line,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              _conditionCtrl.text.trim().toLowerCase() ==
                                  item.toLowerCase()
                              ? teal
                              : ink,
                        ),
                        onPressed: () => setState(() {
                          _conditionCtrl.text = item;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _conditionCtrl,
                  validator: (v) =>
                      validateRequired(v, 'Kondisi kesehatan wajib diisi.'),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Kondisi kesehatan',
                    hintText: 'Contoh: Hipertensi / Pemulihan demam',
                    prefixIcon: Icon(
                      Icons.medical_information_outlined,
                      color: teal,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _diagnosisCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis dokter (opsional)',
                    hintText: 'Contoh: Tekanan darah tinggi tingkat 1',
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageCtrl,
                        keyboardType: TextInputType.number,
                        validator: validatePositiveInt,
                        decoration: const InputDecoration(
                          labelText: 'Usia (tahun)',
                          suffixText: 'thn',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: validatePositiveNumber,
                        decoration: const InputDecoration(
                          labelText: 'Berat (kg)',
                          suffixText: 'kg',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _heightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: validatePositiveNumber,
                        decoration: const InputDecoration(
                          labelText: 'Tinggi (cm)',
                          suffixText: 'cm',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _conditionNotesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan kondisi tambahan (opsional)',
                    hintText: 'Contoh: Kurangi garam, perlu makanan hangat',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('RESEP DOKTER'),
                const SizedBox(height: 6),
                Text(
                  'Apakah $name memiliki resep obat dari dokter?',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableOptionCard(
                  title: 'Ya, Memiliki Resep Dokter',
                  subtitle: 'Lanjut mengisi daftar obat pada resep dokter',
                  icon: Icons.medication_rounded,
                  selected: _hasPrescription,
                  onTap: () => setState(() => _hasPrescription = true),
                ),
                const SizedBox(height: 10),
                SelectableOptionCard(
                  title: 'Tidak Memiliki Resep Dokter',
                  subtitle: 'Hanya menyusun menu makanan & jadwal makan harian',
                  icon: Icons.restaurant_rounded,
                  selected: !_hasPrescription,
                  onTap: () => setState(() => _hasPrescription = false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionStep() {
    final name = _patientNameCtrl.text.trim();
    return Form(
      key: _prescriptionFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader(
            icon: Icons.medication_liquid_rounded,
            eyebrow: 'DAFTAR RESEP DOKTER',
            title: 'Input obat dari resep dokter',
            subtitle:
                'Masukkan obat yang diresepkan untuk $name. Tekan tombol Tambah Obat Lainnya jika ada lebih dari satu obat.',
          ),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('INFORMASI RESEP'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CalendarDateField(
                        label: 'Tanggal resep',
                        controller: _prescriptionDateCtrl,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CalendarDateField(
                        label: 'Mulai minum',
                        controller: _prescriptionStartCtrl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _prescriptionNotesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Catatan resep dokter (opsional)',
                    hintText: 'Contoh: Resep kontrol rawat jalan',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _medications.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _buildMedicationFormCard(_medications[i], i),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
              side: const BorderSide(color: teal, width: 1.3),
              backgroundColor: paleTeal.withValues(alpha: 0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _addAnotherMedication,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Tambah Obat Lainnya'),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationFormCard(_MedicationDraft med, int index) {
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BadgePill(
                'Obat #${index + 1}',
                color: medSoft,
                textColor: medAccent,
                icon: Icons.medication_outlined,
              ),
              const Spacer(),
              if (_medications.length > 1)
                IconButton(
                  tooltip: 'Hapus obat #${index + 1}',
                  onPressed: () => _removeMedication(index),
                  icon: const Icon(Icons.delete_outline_rounded, color: red),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: med.name,
            validator: (v) => validateRequired(v, 'Nama obat wajib diisi.'),
            decoration: const InputDecoration(
              labelText: 'Nama obat',
              hintText: 'Contoh: Amlodipine / Paracetamol',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: med.dosage,
                  validator: (v) => validateRequired(v, 'Dosis wajib diisi.'),
                  decoration: const InputDecoration(
                    labelText: 'Dosis',
                    hintText: 'Contoh: 5 mg / 1 tab',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: med.quantity,
                  keyboardType: TextInputType.number,
                  validator: validatePositiveInt,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah',
                    hintText: '10',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final freq in ['1x sehari', '2x sehari', '3x sehari'])
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(freq, style: const TextStyle(fontSize: 11.5)),
                  backgroundColor: med.frequency.text.trim() == freq
                      ? paleTeal
                      : slate,
                  onPressed: () => setState(() => med.frequency.text = freq),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: med.frequency,
            validator: (v) => validateRequired(v, 'Frekuensi wajib diisi.'),
            decoration: const InputDecoration(
              labelText: 'Frekuensi minum',
              hintText: 'Contoh: 2x sehari',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: med.instruction,
            validator: (v) => validateRequired(v, 'Instruksi wajib diisi.'),
            decoration: const InputDecoration(
              labelText: 'Instruksi waktu minum',
              hintText: 'Contoh: Pagi pukul 08:00 & Malam pukul 20:00',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Waktu konsumsi terhadap makan:',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const SizedBox(
                    width: double.infinity,
                    child: Text('Sesudah Makan', textAlign: TextAlign.center),
                  ),
                  selected: med.isAfterEat,
                  selectedColor: paleTeal,
                  onSelected: (_) => setState(() => med.isAfterEat = true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const SizedBox(
                    width: double.infinity,
                    child: Text('Sebelum Makan', textAlign: TextAlign.center),
                  ),
                  selected: !med.isAfterEat,
                  selectedColor: paleTeal,
                  onSelected: (_) => setState(() => med.isAfterEat = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: med.notes,
            decoration: const InputDecoration(
              labelText: 'Catatan obat (opsional)',
              hintText: 'Contoh: Jangan diminum bersama susu',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietPreferencesStep() {
    final numberFmt = NumberFormat.decimalPattern('id_ID');
    return Form(
      key: _dietFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader(
            icon: Icons.restaurant_menu_rounded,
            eyebrow: 'KEBUTUHAN NUTRISI & BUDGET',
            title: 'Alergi, preferensi, dan budget makanan',
            subtitle:
                'AI TemanRawat akan menyesuaikan rekomendasi makanan harian berdasarkan pantangan alergi, selera, dan anggaran Anda.',
          ),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('ALERGI MAKANAN (OPSIONAL)'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final item in _commonAllergies)
                      FilterChip(
                        label: Text(item),
                        selected: _selectedAllergies.contains(item),
                        selectedColor: softRed,
                        checkmarkColor: red,
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _selectedAllergies.add(item);
                          } else {
                            _selectedAllergies.remove(item);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customAllergiesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Alergi makanan lainnya (pisahkan koma)',
                    hintText: 'Kosongkan jika tidak ada alergi lain',
                    prefixIcon: Icon(
                      Icons.no_food_outlined,
                      color: red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('PREFERENSI MAKANAN'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final item in _commonPreferences)
                      FilterChip(
                        label: Text(item),
                        selected: _selectedPreferences.contains(item),
                        selectedColor: paleTeal,
                        checkmarkColor: teal,
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _selectedPreferences.add(item);
                          } else {
                            _selectedPreferences.remove(item);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customPreferencesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Preferensi makanan lainnya (pisahkan koma)',
                    hintText: 'Contoh: Sup ayam, bubur, sayur bening',
                    prefixIcon: Icon(
                      Icons.soup_kitchen_outlined,
                      color: teal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('BUDGET MAKANAN HARIAN'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final preset in _budgetPresets)
                      ActionChip(
                        label: Text('Rp${numberFmt.format(preset)}'),
                        backgroundColor:
                            parseRupiah(_budgetCtrl.text) == preset.toDouble()
                            ? paleTeal
                            : slate,
                        onPressed: () => setState(() {
                          _budgetCtrl.text = preset.toString();
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _budgetCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: validateRupiah,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Budget makanan (Rupiah)',
                    hintText: 'Contoh: 75000',
                    prefixText: 'Rp ',
                    prefixIcon: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: teal,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _routineCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Catatan jam makan / rutinitas (opsional)',
                    hintText: 'Contoh: Sarapan pukul 07:00, makan siang 12:30',
                    prefixIcon: Icon(Icons.schedule_rounded, color: teal),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedMealsStep() {
    final name = _patientNameCtrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          icon: Icons.auto_awesome_rounded,
          eyebrow: 'REKOMENDASI AI TEMANRAWAT',
          title: 'Hasil Rekomendasi Makanan',
          subtitle: _loadingMeals
              ? 'Sedang menyusun rekomendasi menu sehat untuk $name...'
              : 'Tinjau menu makanan yang telah digenerate untuk $name sebelum membuat jadwal makan dan minum obat.',
        ),
        if (_loadingMeals)
          Surface(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Column(
              children: [
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    color: teal,
                    strokeWidth: 3.5,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Menghasilkan Menu Makanan...',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'AI sedang mencocokkan kondisi kesehatan, alergi, preferensi, dan budget makanan Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 13.5),
                ),
              ],
            ),
          )
        else if (_apiError != null && _generatedMeals.isEmpty) ...[
          Notice(
            text: _apiError!,
            icon: Icons.error_outline_rounded,
            isError: true,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _goBack,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Ubah Budget / Preferensi'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _fetchGeneratedMeals,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Coba Lagi'),
                ),
              ),
            ],
          ),
        ] else ...[
          if (_aiMessages.isNotEmpty) ...[
            Notice(
              text: _aiMessages.join('\n'),
              icon: Icons.info_outline_rounded,
            ),
            const SizedBox(height: 14),
          ],
          if (_apiError != null) ...[
            Notice(
              text: _apiError!,
              icon: Icons.error_outline_rounded,
              isError: true,
            ),
            const SizedBox(height: 14),
          ],
          for (var i = 0; i < _generatedMeals.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            RecipeCard(meal: _generatedMeals[i], index: i),
          ],
          if (_loadingSchedule) ...[
            const SizedBox(height: 18),
            Surface(
              color: paleTeal,
              child: Row(
                children: const [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: teal,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Sedang membuat jadwal minum obat dan makan harian...',
                      style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget? _buildBottomBar() {
    switch (_step) {
      case _WizardStep.patientName:
        return FilledButton.icon(
          onPressed: _nextFromName,
          icon: const Icon(Icons.arrow_forward_rounded, size: 19),
          label: const Text('Selanjutnya'),
        );
      case _WizardStep.healthCondition:
        return FilledButton.icon(
          onPressed: _nextFromHealth,
          icon: const Icon(Icons.arrow_forward_rounded, size: 19),
          label: const Text('Selanjutnya'),
        );
      case _WizardStep.prescription:
        return FilledButton.icon(
          onPressed: _nextFromPrescription,
          icon: const Icon(Icons.check_circle_outline_rounded, size: 19),
          label: const Text('Selesai & Lanjut'),
        );
      case _WizardStep.dietPreferences:
        return FilledButton.icon(
          onPressed: _nextFromDiet,
          icon: const Icon(Icons.auto_awesome_rounded, size: 19),
          label: const Text('Selanjutnya'),
        );
      case _WizardStep.generatedMeals:
        if (_loadingMeals || _generatedMeals.isEmpty) return null;
        return FilledButton.icon(
          onPressed: _loadingSchedule ? null : _generateScheduleAndFinish,
          icon: _loadingSchedule
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.event_available_rounded, size: 19),
          label: Text(
            _loadingSchedule
                ? 'Membuat Jadwal...'
                : 'Buat Jadwal Makan & Obat',
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _currentStepNumber / _totalSteps;
    final bottomButton = _buildBottomBar();

    return PopScope(
      canPop: _step == _WizardStep.patientName && !_loadingMeals && !_loadingSchedule,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        backgroundColor: cream,
        body: MobileFrame(
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  color: paper,
                  padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Kembali',
                            onPressed:
                                (_loadingMeals || _loadingSchedule) ? null : _goBack,
                            icon: const Icon(Icons.arrow_back_rounded, color: ink),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Tambah Perawatan Baru',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontSize: 16.5),
                            ),
                          ),
                          BadgePill(
                            '$_currentStepNumber/$_totalSteps',
                            color: paleTeal,
                            textColor: teal,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 240),
                            builder: (context, value, _) =>
                                LinearProgressIndicator(
                                  value: value,
                                  minHeight: 6,
                                  backgroundColor: slate,
                                  color: teal,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: switch (_step) {
                      _WizardStep.patientName => _buildPatientNameStep(),
                      _WizardStep.healthCondition =>
                        _buildHealthConditionStep(),
                      _WizardStep.prescription => _buildPrescriptionStep(),
                      _WizardStep.dietPreferences =>
                        _buildDietPreferencesStep(),
                      _WizardStep.generatedMeals => _buildGeneratedMealsStep(),
                    },
                  ),
                ),
                if (bottomButton != null)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    decoration: const BoxDecoration(
                      color: paper,
                      border: Border(top: BorderSide(color: line)),
                    ),
                    child: SizedBox(width: double.infinity, child: bottomButton),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
