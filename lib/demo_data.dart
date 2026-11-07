import 'package:flutter/material.dart';

const teal = Color(0xFF21643E);
const red = Color(0xFFAC393B);
const ink = Color(0xFF173D2B);
const muted = Color(0xFF526456);
const cream = Color(0xFFF8F8F3);
const shellBackground = Color(0xFFE8E9E4);
const paper = Color(0xFFFFFEFA);
const paleTeal = Color(0xFFE7F3E9);
const peach = Color(0xFFFAE7E5);
const line = Color(0xFFE5E9E1);

String money(int value) =>
    'Rp${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

class CareActivity {
  CareActivity({
    this.id,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.source,
    required this.icon,
    required this.tint,
    required this.note,
    this.done = false,
  });
  final String? id;
  final String time, title, subtitle, source, note;
  final IconData icon;
  final Color tint;
  bool done;
}

List<CareActivity> initialActivities() => [
  CareActivity(
    time: '06.30',
    title: 'Waktu untuk memulai hari',
    subtitle: 'Bangun pagi & bersiap dengan tenang',
    source: 'Rutinitas pengguna',
    icon: Icons.wb_sunny_outlined,
    tint: peach,
    note: 'Waktu pilihan pengguna untuk demo.',
    done: true,
  ),
  CareActivity(
    id: 'breakfast',
    time: '07.00',
    title: 'Sarapan hangat',
    subtitle: 'Bubur oat pisang • 1 porsi',
    source: 'Menu contoh',
    icon: Icons.restaurant_outlined,
    tint: peach,
    note: 'Data fiktif; bukan rekomendasi diet individual.',
    done: true,
  ),
  CareActivity(
    time: '08.00',
    title: 'Periksa jadwal obat pagi',
    subtitle: 'Cek kembali aturan pada catatan resep',
    source: 'Contoh arahan konsultasi',
    icon: Icons.medication_outlined,
    tint: paleTeal,
    note: 'Detail obat dan aturan belum dikonfirmasi. Tidak ada pengingat obat aktif.',
  ),
  CareActivity(
    time: '10.00',
    title: 'Jeda untuk beristirahat',
    subtitle: 'Nikmati waktu tenang sejenak',
    source: 'Preferensi pengguna',
    icon: Icons.chair_outlined,
    tint: Color(0xFFEEEAF4),
    note: 'Preferensi rutinitas, bukan arahan terapi.',
  ),
  CareActivity(
    time: '17.00',
    title: 'Siapkan catatan kontrol',
    subtitle: 'Tulis pertanyaan untuk konsultasi berikutnya',
    source: 'Ditambahkan caregiver',
    icon: Icons.edit_note_rounded,
    tint: paleTeal,
    note: 'Bawa catatan yang ingin didiskusikan saat konsultasi.',
  ),
];

class DemoMeal {
  const DemoMeal(
    this.id,
    this.slot,
    this.name,
    this.time,
    this.cost,
    this.minutes,
    this.tint,
    this.kind,
    this.ingredients,
    this.steps,
  );
  final String id, slot, name, time, ingredients, steps;
  final int cost, minutes, kind;
  final Color tint;
}

const demoMeals = [
  DemoMeal(
    'breakfast',
    'Sarapan',
    'Bubur oat pisang',
    '07.00',
    8000,
    10,
    Color(0xFFF3E9DA),
    1,
    'Oat 50 g\nPisang 1 buah\nAir secukupnya',
    '1. Masak oat dengan air hingga lembut.\n2. Iris pisang dan tambahkan di atas bubur.\n3. Sajikan hangat.',
  ),
  DemoMeal(
    'lunch',
    'Makan siang',
    'Sup ayam & sayur',
    '12.00',
    18000,
    25,
    Color(0xFFE9EDDF),
    0,
    'Ayam 100 g\nWortel 50 g\nKentang 100 g\nBumbu dapur contoh',
    '1. Potong bahan menjadi bagian kecil.\n2. Masak ayam hingga matang sempurna.\n3. Tambahkan sayur dan masak hingga lunak.',
  ),
  DemoMeal(
    'dinner',
    'Makan malam',
    'Tahu kukus & nasi',
    '18.00',
    12000,
    20,
    Color(0xFFF2E4D9),
    2,
    'Tahu 100 g\nBeras 75 g\nSayur 50 g\nBumbu dapur contoh',
    '1. Masak beras hingga matang.\n2. Kukus tahu dan sayur hingga matang.\n3. Sajikan bersama nasi.',
  ),
];
const shopping = [
  ('Ayam', '100 g', 10000),
  ('Sayur & kentang', '1 paket', 10000),
  ('Oat & pisang', '1 paket', 8000),
  ('Tahu', '1 paket', 5000),
  ('Beras & bumbu', '1 paket', 5000),
];
int get demoCost => shopping.fold(0, (sum, item) => sum + item.$3);
