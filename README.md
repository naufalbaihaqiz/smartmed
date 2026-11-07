# TemanRawat

Prototipe Flutter untuk pendamping perawatan keluarga, dengan tampilan Hijau–Merah yang mengacu pada desain Figma. Kode Dart yang sama dapat dijalankan di Android dan dipratinjau di browser.

## Jalankan lokal di Windows

Flutter SDK yang disiapkan dalam workspace berada di `D:\Hackathon\flutter-sdk`.

Dari PowerShell:

```powershell
cd D:\Hackathon\smartmed
D:\Hackathon\flutter-sdk\bin\flutter.bat pub get
D:\Hackathon\flutter-sdk\bin\flutter.bat run -d chrome --web-port 5173
```

Atau jalankan `./run-local.ps1` untuk membuka preview di Chrome.

Untuk Android, jalankan `flutter devices`, lalu `flutter run -d <device-id>` dengan Flutter SDK di atas. Android SDK dan perangkat/emulator diperlukan.

## Yang bisa dicoba

- Layar pembuka: isi profil pendamping atau pilih salah satu dari dua skenario fiktif melalui **Coba Demo**.
- Hari Ini: progress, filter agenda, detail kegiatan, konfirmasi dan koreksi catatan, tambah kegiatan.
- Menu Hari Ini: tiga menu demo, resep, daftar belanja, ubah budget, tinjau dan setujui jadwal contoh.
- Riwayat: kegiatan tercatat, jejak perubahan sesi, dan kendala.
- Profil: mode Rawat Keluarga / Rawat Diri. Pergantian mode mereset data sesi.

Semua data fiktif dan tersimpan dalam memori. Refresh atau restart akan meresetnya. AI, backend, database permanen, dan notifikasi perangkat belum dihubungkan. Tidak membutuhkan API key maupun backend untuk preview.

Tanggal ditetapkan 7 November 2026 untuk konsistensi skenario demo. Harga adalah estimasi contoh; biaya dihitung dari data lokal.

## Pemeriksaan

```powershell
D:\Hackathon\flutter-sdk\bin\flutter.bat analyze
D:\Hackathon\flutter-sdk\bin\flutter.bat test
```
