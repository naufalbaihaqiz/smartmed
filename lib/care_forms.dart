import 'package:flutter/material.dart';

import 'palette.dart';

String? validateRequired(String? input, [String message = 'Wajib diisi.']) =>
    input == null || input.trim().isEmpty ? message : null;

double? parseFlexibleDouble(String? input) =>
    double.tryParse((input ?? '').trim().replaceAll(',', '.'));

double? parseRupiah(String? input) {
  final raw = (input ?? '').trim().replaceAll(RegExp(r'[Rp\s]'), '');
  if (raw.isEmpty) return null;
  if (RegExp(r'^\d{1,3}(\.\d{3})+(,\d+)?$').hasMatch(raw)) {
    return double.tryParse(raw.replaceAll('.', '').replaceAll(',', '.'));
  }
  return double.tryParse(raw.replaceAll(',', '.'));
}

String? validateRupiah(String? input) {
  final value = parseRupiah(input);
  return value != null && value.isFinite && value > 0
      ? null
      : 'Masukkan nominal budget lebih dari nol.';
}

String? validatePositiveNumber(String? input) {
  final value = parseFlexibleDouble(input);
  return value != null && value.isFinite && value > 0
      ? null
      : 'Masukkan angka lebih dari nol.';
}

String? validatePositiveInt(String? input) {
  final value = int.tryParse((input ?? '').trim());
  return value != null && value > 0
      ? null
      : 'Masukkan bilangan bulat lebih dari nol.';
}

String? validateIsoDate(String? input) {
  final value = (input ?? '').trim();
  final date = DateTime.tryParse(value);
  if (date == null || date.toIso8601String().split('T').first != value) {
    return 'Gunakan format YYYY-MM-DD.';
  }
  return null;
}

List<String> splitCsvItems(String input) => input
    .split(RegExp(r'[,\n]'))
    .map((item) => item.trim())
    .where((item) => item.isNotEmpty)
    .toList();

String formatIsoDate(DateTime date) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

class CalendarDateField extends StatefulWidget {
  const CalendarDateField({
    super.key,
    required this.label,
    required this.controller,
    this.validator = validateIsoDate,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  State<CalendarDateField> createState() => _CalendarDateFieldState();
}

class _CalendarDateFieldState extends State<CalendarDateField> {
  Future<void> _pickDate() async {
    final initialDate =
        DateTime.tryParse(widget.controller.text) ?? DateTime.now();
    var selectedDate = initialDate;
    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.label),
        content: SizedBox(
          width: 320,
          height: 340,
          child: CalendarDatePicker(
            initialDate: initialDate,
            firstDate: DateTime(2000),
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
    setState(() {
      widget.controller.text = formatIsoDate(result);
    });
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    readOnly: true,
    validator: widget.validator,
    onTap: _pickDate,
    decoration: InputDecoration(
      labelText: widget.label,
      suffixIcon: IconButton(
        tooltip: 'Pilih tanggal',
        onPressed: _pickDate,
        icon: const Icon(Icons.calendar_month_outlined, color: teal),
      ),
    ),
  );
}

/// Kartu pilihan interaktif (misal: Ya, Ada Resep Dokter vs Tidak Ada Resep).
class SelectableOptionCard extends StatelessWidget {
  const SelectableOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    decoration: BoxDecoration(
      color: selected ? paleTeal : paper,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: selected ? teal : line,
        width: selected ? 1.8 : 1,
      ),
    ),
    child: Material(
      type: MaterialType.transparency,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected ? teal : slate,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: selected ? Colors.white : muted,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: selected ? ink : ink.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12.5, color: muted),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? teal : muted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
