# Amikom Student

Aplikasi mobile client modern untuk portal mahasiswa Universitas Amikom Purwokerto yang dibangun menggunakan Flutter, Riverpod, dan prinsip arsitektur yang bersih.

---

## Tentang Aplikasi

Amikom Student dirancang untuk memberikan kemudahan, kecepatan, dan kenyamanan bagi mahasiswa Universitas Amikom Purwokerto dalam mengakses data akademik langsung dari smartphone. Aplikasi ini terhubung langsung dengan sistem portal resmi universitas (`student.amikompurwokerto.ac.id`), memproses dan menampilkan jadwal perkuliahan, riwayat nilai, presensi kehadiran, serta kartu rencana studi secara terstruktur dan terintegrasi.

---

## Fitur Utama

- **Otentikasi & Keamanan**
  - Masuk menggunakan Nomor Pokok Mahasiswa (NPM) dan kata sandi portal akademik.
  - Dukungan otentikasi biometrik (Sidik Jari dan Face ID) menggunakan `local_auth`.
  - Penyimpanan data kredensial terenkripsi lokal menggunakan `flutter_secure_storage`.
  - Pengelolaan sesi dan siklus hidup cookie secara otomatis.

- **Dasbor Akademik**
  - Ringkasan komprehensif data akademik: Indeks Prestasi Kumulatif (IPK), total perolehan SKS, dan semester aktif.
  - Navigasi cepat dan indikator kelas kuliah terdekat.

- **Jadwal Kuliah & Jadwal Ujian**
  - Jadwal kuliah harian dan mingguan lengkap dengan ruang kelas serta dosen pengampu.
  - Pelacakan jadwal ujian semester secara terpadu.

- **Rekapitulasi Presensi Kehadiran**
  - Pemantauan tingkat kehadiran per mata kuliah secara real-time.
  - Peringatan batas minimal persentase kehadiran untuk syarat kelayakan ujian.

- **Kartu Rencana Studi (KRS) & Kartu Hasil Studi (KHS)**
  - Tinjauan daftar mata kuliah dan beban SKS yang diambil pada semester aktif.
  - Tampilan Indeks Prestasi Semester (IPS) berkala dan transkrip nilai kumulatif.

- **Kenyamanan Antarmuka & Personalisasi**
  - Dukungan tema otomatis Mode Terang (Light Mode) dan Mode Gelap (Dark Mode).
  - Indikator pemuatan animasi dengan efek Shimmer.
  - Mekanisme penyimpanan cache lokal untuk menjaga akses data saat koneksi lambat.

- **Pembaruan Otomatis Aplikasi (In-App Update)**
  - Deteksi ketersediaan versi rilis terbaru secara otomatis langsung dari GitHub Releases API.
  - Unduh berkas APK di latar belakang dengan indikator persentase progres.
  - Pemasangan pembaruan instan terintegrasi dengan penginstal paket Android (Package Installer).
  - Opsi pengecekan pembaruan manual langsung dari menu Pengaturan Profil.

---

## Teknologi & Arsitektur

- **Kerangka Kerja**: [Flutter](https://flutter.dev) (Dart SDK ^3.11.0)
- **Manajemen State**: [Riverpod](https://riverpod.dev) (`flutter_riverpod`)
- **Jaringan & Sesi**: [Dio](https://pub.dev/packages/dio), `dio_cookie_manager`, `cookie_jar`
- **Ekstraksi Data**: `html` parser
- **Penyimpanan Lokal & Keamanan**: `flutter_secure_storage`, `shared_preferences`, `local_auth`
- **Tipografi & Ikon**: `google_fonts`, `lucide_icons`

### Struktur Direktori Proyek

```text
lib/
├── core/
│   ├── models/        # Model data (Profil Mahasiswa, Jadwal, Nilai, Presensi)
│   ├── network/       # Klien HTTP, Pengelola Cookie, dan Parser Portal
│   ├── providers/     # State global dan Riverpod providers
│   ├── storage/       # Penyimpanan terenkripsi dan preferensi lokal
│   ├── theme/         # Token desain, palet warna, dan tipografi
│   └── widgets/       # Komponen UI bersama dan tata letak
├── features/
│   ├── dashboard_screen.dart
│   ├── jadwal/        # Komponen dan tampilan jadwal kuliah/ujian
│   ├── presensi/      # Rekapitulasi kehadiran dan modal validasi
│   ├── krs_screen.dart
│   ├── nilai_screen.dart
│   ├── login_screen.dart
│   ├── profile_screen.dart
│   └── splash_screen.dart
└── main.dart          # Titik masuk utama aplikasi
```

---

## Panduan Instalasi

### Unduh Langsung Berkas APK (Android)

Bagi pengguna yang ingin langsung memasang aplikasi di perangkat Android tanpa perlu mengompilasi dari kode sumber:

1. Unduh berkas APK rilis terbaru melalui tautan resmi:
   **[Unduh Berkas APK Versi Terbaru (GitHub Releases)](https://github.com/Nipon3284/Amikom-Student-App/releases/latest)**
2. Buka berkas `.apk` yang telah selesai diunduh pada ponsel Android Anda.
3. Apabila muncul notifikasi keamanan sistem, berikan izin pada opsi **Izinkan penginstalan aplikasi dari sumber ini** (*Install unknown apps*).
4. Lanjutkan proses pemasangan hingga selesai.
5. Buka aplikasi **Amikom Student**, lalu masuk menggunakan NPM dan kata sandi portal akademik Anda.

---

## Panduan Pengembangan & Kompilasi Sumber

Bagian ini ditujukan untuk pengembang yang ingin memodifikasi atau membangun aplikasi langsung dari kode sumber:

### Prasyarat Sistem

- Flutter SDK (versi 3.19 atau yang lebih baru)
- Dart SDK (^3.11.0)
- Android Studio atau Visual Studio Code dengan ekstensi Flutter
- Android SDK (API level minimal 21)

### Langkah Kompilasi

1. Gandakan repositori ini ke komputer lokal Anda:
   ```bash
   git clone https://github.com/Nipon3284/Amikom-Student-App.git
   cd Amikom-Student-App
   ```

2. Pasang paket dependensi:
   ```bash
   flutter pub get
   ```

3. Jalankan aplikasi pada perangkat atau emulator:
   ```bash
   flutter run
   ```

4. Buat paket instalasi APK Release mandiri:
   ```bash
   flutter build apk --release
   ```
   Berkas APK hasil kompilasi akan tersedia pada direktori:
   `build/app/outputs/flutter-apk/app-release.apk`

---

## Batasan & Penafian

Aplikasi ini merupakan proyek independen dari komunitas mahasiswa untuk mahasiswa Universitas Amikom Purwokerto dan tidak berafiliasi secara langsung, disponsori, atau dikelola secara resmi oleh pihak Universitas Amikom Purwokerto. Hak cipta atas sistem portal dan data akademik sepenuhnya milik universitas terkait.

---

## Lisensi

Proyek ini dirilis di bawah naungan Lisensi MIT. Silakan merujuk pada berkas [LICENSE](LICENSE) untuk informasi lebih lanjut.
