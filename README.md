# TemanRawat

Frontend Flutter untuk pendamping perawatan keluarga dengan alur terpadu:
1. Aplikasi langsung membuka **Beranda (Home)** tanpa navigasi bawah, menampilkan daftar orang yang sedang dirawat beserta status penyelesaian jadwalnya (**Jadwal Selesai** / **Belum Selesai**).
2. Tombol **`+`** di pojok kanan bawah membuka alur pengisian perawatan bertahap:
   - Input nama orang yang akan dirawat
   - Input kondisi kesehatan (`health_condition`) beserta opsi kepemilikan resep dokter
   - Input daftar resep dokter & form penambahan beberapa obat sekaligus (jika memiliki resep dokter)
   - Input alergi makanan, preferensi makanan, dan budget makanan
   - Pratinjau rekomendasi makanan hasil generate dari server API
   - Pembuatan jadwal minum obat dan makan beserta daftar resep lengkap

## Menjalankan Aplikasi

Jalankan dari folder proyek `smartmed`:

```powershell
flutter pub get
flutter devices
flutter run -d ID_PERANGKAT --dart-define=TEMANRAWAT_API_BASE_URL=http://10.0.2.2:8000
```

Variabel `--dart-define=TEMANRAWAT_API_URL=...` maupun `--dart-define=TEMANRAWAT_API_BASE_URL=...` keduanya didukung. Jika tidak disertakan, aplikasi otomatis menggunakan `http://10.0.2.2:8000` di Android Emulator atau `http://127.0.0.1:8000` di desktop/web, serta menyediakan pengaturan alamat server langsung dari ikon server di pojok kanan atas Beranda.

## Preview Web dengan Data Contoh

Jalankan `./run-local.ps1 -Demo` atau tambahkan `--dart-define=TEMANRAWAT_WEB_DEMO=true` pada perintah Flutter untuk Chrome guna menampilkan data contoh dan simulasi API secara langsung.
