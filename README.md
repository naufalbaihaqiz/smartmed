# TemanRawat

Frontend Flutter untuk pendamping perawatan keluarga. Data awal kosong. Profil, alergi, resep, budget, stok, preferensi, rutinitas, dan catatan diisi oleh pengguna selama sesi aplikasi.

## Menjalankan di Android

Siapkan Android SDK lalu nyalakan emulator atau sambungkan HP. Jalankan dari folder proyek:

```powershell
flutter pub get
flutter devices
flutter run -d ID_PERANGKAT --dart-define=TEMANRAWAT_API_BASE_URL=http://10.0.2.2:8000
```

`10.0.2.2` menunjuk ke komputer host dari Android Emulator. Untuk HP, gunakan alamat server yang dapat dijangkau HP. HTTP lokal didukung pada build debug. Gunakan HTTPS untuk build produksi.

Untuk pratinjau Chrome gunakan `flutter run -d chrome --web-port 5173` dan tambahkan `--dart-define=TEMANRAWAT_API_BASE_URL=URL_SERVER` jika backend mengizinkan origin browser melalui CORS.

## Preview web dengan data contoh

Jalankan `./run-local.ps1 -Demo` atau tambahkan `--dart-define=TEMANRAWAT_WEB_DEMO=true` ke perintah Flutter untuk Chrome. Pilih **Coba Demo** pada layar pembuka. Mode ini mengisi skenario dengan atau tanpa resep dan menjalankan simulasi API di browser. Flutter hanya menampilkan mode tersebut jika targetnya web dan flag demo diaktifkan.

## Kontrak API

- `POST /api/meal-plans/generate` mengirim objek `health_condition`, daftar objek `allergies`, budget, stok, dan preferensi. Resep beserta bahan dan nutrisi dibaca dari `meals`.
- `POST /api/schedules/generate` mengirim resep makanan yang disetujui, resep obat beserta obatnya, rutinitas, dan ketersediaan. Aplikasi membaca `reminders` dan meminta pengguna meninjau jadwal sebelum memasukkannya ke agenda.
- Kedua permintaan menyertakan `request_id` dan `input_version`. Waktu pengingat diterima sebagai ISO 8601. Catatan bebas rutinitas dan ketersediaan dikirim melalui kunci `notes` di objek masing-masing.
- Skema API ini perlu tersedia di server. Jika server belum dikonfigurasi, mengirim format lama, atau belum memberikan hasil, aplikasi menampilkan pesan atau kondisi kosong.
- Budget berasal dari input pengguna. Skema resep belum memuat harga. Input dan riwayat UI masih menggunakan penyimpanan sesi.
