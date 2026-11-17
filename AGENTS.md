# 🤖 AGENTS.md — AI Agent & Contributor Operational Manual

Panduan operasional dan aturan keterlibatan (*rules of engagement*) bagi AI Agent (Antigravity, Cursor, Copilot, dll.) dan kontributor manusia yang bekerja pada codebase **Sentient Chess**.

---

## 1. Langkah Wajib Sebelum Menulis / Mengubah Kode

Sebelum melakukan manipulasi file, penulisan kode, atau refactoring, **SETIAP AGENT WAJIB**:
1. **Membaca Dokumen Arsitektur Inti**:
   - Baca [Architecture-essentials.md](file:///d:/Project/Sentient-Apps-New/Architecture-essentials.md) untuk memahami golden rules, batasan data access, dan konvensi penamaan.
   - Baca [Architecture.md](file:///d:/Project/Sentient-Apps-New/Architecture.md) untuk memahami arsitektur sistem dan detail teknis komponen yang sudah ada.
   - Baca [PRD.md](file:///d:/Project/Sentient-Apps-New/PRD.md) untuk memastikan fitur yang dikembangkan sesuai dengan cakupan produk v1 dan tidak melanggar batasan *Explicitly Not Doing*.
2. **Pahami Lokasi & Batasan Codebase**:
   - Jangan menambahkan dependensi eksternal di `pubspec.yaml` tanpa alasan arsitektural yang kuat.
   - Pahami bahwa saat ini direktori `lib/` masih memiliki struktur flat monolitik dan sedang diarahkan menuju Feature-First.

---

## 2. Aturan Modifikasi File (File Modification Rules)

### ⛔ Larangan Keras:
1. **Dilarang memodifikasi file auto-generated secara manual!**
   - File dengan ekstensi `*.g.dart`, `*.freezed.dart`, atau file di bawah folder `.dart_tool/`, `build/`, `android/.gradle/`, dan `ios/Pods/`.
   - Jika perlu mengubah model yang menggunakan generator, ubah file sumber aslinya lalu jalankan generator build (`dart run build_runner build`).
2. **Dilarang menghapus dokumentasi atau comment penting** yang menjelaskan domain logic yang sudah berjalan, kecuali kode tersebut memang dihapus/digantikan.
3. **Dilarang menaruh raw mock data di dalam file UI baru**. Simpan mock data atau seed data di direktori tersendiri (misal: `lib/features/<feature>/data/mock/` atau `lib/core/mock/`).
4. **Dilarang melakukan hardcoding API base URL di sembarang tempat**. Gunakan konfigurasi terpusat (misal: `ApiService.baseUrl` atau `lib/core/constants/api_constants.dart`).

### ✅ Praktik yang Diharuskan:
- Gunakan import absolut berbasis package: `import 'package:sentient/...';` alih-alih `import '../../...';` yang relatif dan rentan pecah saat pemindahan file.
- Setiap kali membuat widget publik baru, sertakan `Key? key` dan gunakan `const` constructor jika seluruh propertinya immutable.

---

## 3. Aturan Pembuatan Fitur Baru (Feature-First Architecture)

Setiap penambahan fitur baru **TIDAK BOLEH** diletakkan langsung di root `lib/`. Fitur baru **WAJIB** mengikuti struktur folder **Feature-First**:

```text
lib/
└── features/
    └── [nama_fitur]/
        ├── data/
        │   ├── datasources/
        │   │   ├── [nama_fitur]_remote_datasource.dart
        │   │   └── [nama_fitur]_local_datasource.dart
        │   ├── models/
        │   │   └── [nama_fitur]_model.dart
        │   └── repositories/
        │       └── [nama_fitur]_repository_impl.dart
        ├── domain/
        │   ├── entities/
        │   │   └── [nama_fitur].dart
        │   └── repositories/
        │       └── [nama_fitur]_repository.dart
        └── presentation/
            ├── controllers/          # Provider / StateNotifier
            │   └── [nama_fitur]_provider.dart
            ├── screens/              # Full page screen widgets
            │   ├── [nama_fitur]_screen.dart
            │   └── [nama_fitur]_detail_screen.dart
            └── widgets/              # Reusable sub-components spesifik fitur
                ├── [nama_fitur]_card.dart
                └── [nama_fitur]_header.dart
```

### Shared / Cross-Cutting Concerns:
Kode yang digunakan bersama oleh lebih dari 1 fitur wajib diletakkan di `lib/core/`:
- `lib/core/constants/` (Warna, string, URL API)
- `lib/core/network/` (HTTP client, interceptor, Firebase wrapper)
- `lib/core/errors/` (Failure, Exceptions)
- `lib/core/theme/` (ThemeData, Typography)
- `lib/core/widgets/` (Global Buttons, Loading Dialogs, Error Views)

---

## 4. Perintah Verifikasi Wajib (Verification Commands)

Setelah menulis, mengubah, atau merapikan kode, agent **WAJIB** menjalankan langkah verifikasi berikut menggunakan terminal:

### 1. Format Kode:
```bash
dart format .
```
> Memastikan seluruh file Dart terformat rapi sesuai panduan gaya resmi Dart (panjang baris, indentasi, koma penutup).

### 2. Static Analysis:
```bash
flutter analyze
```
> Menemukan error statis, warning, unused imports, missing null checks, atau aturan linting yang dilanggar. Tidak boleh ada error analisis yang tersisa!

### 3. Testing (Jika tersedia):
```bash
flutter test
```
> Menjalankan seluruh unit test dan widget test untuk menjamin tidak ada regresi pada logika yang sudah ada.

### Catatan Khusus Lingkungan Dev (SDK Constraints):
Jika `flutter analyze` mengalami kegagalan *version solving* akibat constraint SDK (`Because sentient requires SDK version ^3.7.2, version solving failed`), pastikan baris environment di `pubspec.yaml` disesuaikan:
```yaml
environment:
  sdk: ">=3.7.0 <4.0.0"
```
Lalu jalankan `flutter pub get` sebelum menganalisis ulang.
