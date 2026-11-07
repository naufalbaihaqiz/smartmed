import 'package:flutter/material.dart';

import 'care_api.dart';

String? _required(String? input) =>
    input == null || input.trim().isEmpty ? 'Wajib diisi.' : null;

double? _decimal(String? input) =>
    double.tryParse((input ?? '').trim().replaceAll(',', '.'));

String? _positive(String? input) {
  final value = _decimal(input);
  return value != null && value.isFinite && value > 0
      ? null
      : 'Masukkan angka lebih dari nol.';
}

String? _integer(String? input) {
  final value = int.tryParse((input ?? '').trim());
  return value != null && value >= 0
      ? null
      : 'Masukkan bilangan bulat minimal nol.';
}

String? _date(String? input) {
  final value = (input ?? '').trim();
  final date = DateTime.tryParse(value);
  if (date == null || date.toIso8601String().split('T').first != value) {
    return 'Gunakan format YYYY-MM-DD.';
  }
  return null;
}

List<String> _items(String input) => input
    .split(RegExp(r'[,\n]'))
    .map((item) => item.trim())
    .where((item) => item.isNotEmpty)
    .toList();

String? _optional(String input) => input.isEmpty ? null : input;

class CareFormField extends StatelessWidget {
  const CareFormField(
    this.label, {
    super.key,
    this.initialValue,
    this.validator,
    required this.onSaved,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final String? initialValue;
  final String? Function(String?)? validator;
  final void Function(String) onSaved;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      initialValue: initialValue,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, alignLabelWithHint: true),
      onSaved: (value) => onSaved((value ?? '').trim()),
    ),
  );
}

class CalendarDateField extends StatefulWidget {
  const CalendarDateField(
    this.label, {
    super.key,
    this.initialValue,
    this.validator,
    required this.onSaved,
  });

  final String label;
  final String? initialValue;
  final String? Function(String?)? validator;
  final void Function(String) onSaved;

  @override
  State<CalendarDateField> createState() => _CalendarDateFieldState();
}

class _CalendarDateFieldState extends State<CalendarDateField> {
  late final controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initialDate = DateTime.tryParse(controller.text) ?? DateTime.now();
    var selectedDate = initialDate;
    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.label),
        content: SizedBox(
          width: 320,
          height: 360,
          child: CalendarDatePicker(
            initialDate: initialDate,
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
            onDateChanged: (date) => selectedDate = date,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, selectedDate),
            child: const Text('Pilih tanggal'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    String two(int value) => value.toString().padLeft(2, '0');
    setState(() {
      controller.text =
          '${result.year}-${two(result.month)}-${two(result.day)}';
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      readOnly: true,
      showCursor: false,
      enableInteractiveSelection: false,
      validator: widget.validator,
      onTap: _pickDate,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          tooltip: 'Pilih tanggal dari kalender',
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_month_outlined),
        ),
      ),
      onSaved: (value) => widget.onSaved((value ?? '').trim()),
    ),
  );
}

class MealInputForm extends StatefulWidget {
  const MealInputForm({
    super.key,
    required this.input,
    required this.hasPrescription,
  });

  final Json? input;
  final bool hasPrescription;

  @override
  State<MealInputForm> createState() => _MealInputFormState();
}

class _MealInputFormState extends State<MealInputForm> {
  final form = GlobalKey<FormState>();
  final values = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final input = widget.input;
    final health = input?['health_condition'] as Json?;

    CareFormField field(
      String label,
      String key, {
      String? initial,
      String? Function(String?)? validator,
      TextInputType? keyboard,
      int lines = 1,
    }) => CareFormField(
      label,
      initialValue: initial,
      validator: validator,
      keyboardType: keyboard,
      maxLines: lines,
      onSaved: (value) => values[key] = value,
    );

    return Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field(
            'Kondisi kesehatan',
            'condition_name',
            initial: health?['condition_name'] as String?,
            validator: _required,
          ),
          field(
            'Diagnosis dari konsultasi (opsional)',
            'diagnosis',
            initial: health?['diagnosis'] as String?,
          ),
          field(
            'Catatan (opsional)',
            'notes',
            initial: health?['notes'] as String?,
            lines: 2,
          ),
          field(
            'Usia (tahun)',
            'age',
            initial: health?['age']?.toString(),
            validator: _integer,
            keyboard: TextInputType.number,
          ),
          field(
            'Berat (kg)',
            'weight',
            initial: health?['weight']?.toString(),
            validator: _positive,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
          field(
            'Tinggi (cm)',
            'height',
            initial: health?['height']?.toString(),
            validator: _positive,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
          field(
            'Alergi, pisahkan dengan koma',
            'allergies',
            initial: (input?['allergies'] as List<Json>?)
                ?.map((a) => a['type'])
                .join(', '),
          ),
          field(
            'Budget belanja (rupiah)',
            'budget',
            initial: input?['budget']?.toString(),
            validator: _positive,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
          field(
            'Preferensi, pisahkan dengan koma',
            'preferensi',
            initial: (input?['preferensi'] as List<String>?)?.join(', '),
          ),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              form.currentState!.save();
              Navigator.pop(context, <String, dynamic>{
                'health_condition': <String, dynamic>{
                  'condition_name': values['condition_name'],
                  'diagnosis': _optional(values['diagnosis']!),
                  'notes': _optional(values['notes']!),
                  'age': int.parse(values['age']!),
                  'weight': _decimal(values['weight']),
                  'height': _decimal(values['height']),
                  'isTherePrescription': widget.hasPrescription,
                },
                'allergies': _items(values['allergies']!)
                    .map<Json>((type) => {'type': type})
                    .toList(),
                'budget': _decimal(values['budget']),
                'preferensi': _items(values['preferensi']!),
              });
            },
            child: const Text('Simpan profil perawatan'),
          ),
        ],
      ),
    );
  }
}

class PrescriptionForm extends StatefulWidget {
  const PrescriptionForm({super.key});

  @override
  State<PrescriptionForm> createState() => _PrescriptionFormState();
}

class _PrescriptionFormState extends State<PrescriptionForm> {
  final form = GlobalKey<FormState>();
  final values = <String, String>{};
  final medications = <Json>[];

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Salin informasi obat dari resep yang kamu miliki.'),
        const SizedBox(height: 14),
        for (final (key, label) in [
          ('prescription_date', 'Tanggal resep (YYYY-MM-DD)'),
          ('start_at', 'Tanggal mulai (YYYY-MM-DD)'),
        ])
          CalendarDateField(
            label,
            validator: _date,
            onSaved: (value) => values[key] = value,
          ),
        CareFormField(
          'Catatan resep (opsional)',
          onSaved: (value) => values['notes'] = value,
        ),
        for (var i = 0; i < medications.length; i++)
          ListTile(
            title: Text(medications[i]['medicine_name'] as String),
            subtitle: Text(medications[i]['instruction'] as String),
            trailing: IconButton(
              tooltip: 'Hapus obat',
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => medications.removeAt(i)),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () async {
            final medication = await showDialog<Json>(
              context: context,
              builder: (context) => const _MedicationDialog(),
            );
            if (mounted && medication != null) {
              setState(() => medications.add(medication));
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Tambah obat'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: medications.isEmpty
              ? null
              : () {
                  if (!form.currentState!.validate()) return;
                  form.currentState!.save();
                  Navigator.pop(context, <String, dynamic>{
                    'prescription_date': values['prescription_date'],
                    'start_at': values['start_at'],
                    'status': 'active',
                    'notes': _optional(values['notes']!),
                    'medications': medications,
                  });
                },
          child: const Text('Simpan resep'),
        ),
      ],
    ),
  );
}

class _MedicationDialog extends StatefulWidget {
  const _MedicationDialog();

  @override
  State<_MedicationDialog> createState() => _MedicationDialogState();
}

class _MedicationDialogState extends State<_MedicationDialog> {
  final form = GlobalKey<FormState>();
  final values = <String, String>{};
  bool afterEating = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Tambah obat dari resep'),
    scrollable: true,
    content: Form(
      key: form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (key, label) in [
            ('medicine_name', 'Nama obat'),
            ('dosage', 'Dosis'),
            ('frequency', 'Frekuensi'),
            ('instruction', 'Instruksi dari resep'),
            ('quantity', 'Jumlah'),
            ('notes', 'Catatan obat (opsional)'),
          ])
            CareFormField(
              label,
              validator: switch (key) {
                'quantity' => _integer,
                'notes' => null,
                _ => _required,
              },
              keyboardType: key == 'quantity' ? TextInputType.number : null,
              onSaved: (value) => values[key] = value,
            ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Diminum setelah makan sesuai resep'),
            value: afterEating,
            onChanged: (value) => setState(() => afterEating = value ?? false),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: () {
          if (!form.currentState!.validate()) return;
          form.currentState!.save();
          Navigator.pop(context, <String, dynamic>{
            ...values,
            'quantity': int.parse(values['quantity']!),
            'notes': _optional(values['notes']!),
            'isAfterEat': afterEating,
          });
        },
        child: const Text('Simpan obat'),
      ),
    ],
  );
}
