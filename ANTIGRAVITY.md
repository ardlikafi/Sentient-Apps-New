# 🌌 ANTIGRAVITY.md — Antigravity Workspace Instruction & Agent Rules

File konfigurasi khusus dan instruksi utama untuk **Antigravity AI Assistant** dalam mengelola, menganalisis, dan memodifikasi codebase **Sentient Chess** (`d:\Project\Sentient-Apps-New`).

---

## 1. Primary Directives & Context References

Saat bekerja pada workspace ini, Antigravity **WAJIB** merujuk dan mematuhi dokumen-dokumen pedoman berikut:

- **@AGENTS.md**: Panduan operasional agen, larangan file modifikasi, dan perintah verifikasi.
- **@Architecture-essentials.md**: Cheat-sheet aturan teknis, state management, pemanggilan data, dan error handling.
- **@Architecture.md**: Arsitektur sistem lengkap, status tech stack, data models, dan data flow.
- **@PRD.md**: Ruang lingkup produk, persona pengguna, fitur v1, dan batasan eksplisit.
- **@EVALUATION_SCAFFOLD.md**: Pemetaan struktur folder riil dan peta jalan refactoring.

---

## 2. Workspace & Environment Profile

- **Project Root**: `d:\Project\Sentient-Apps-New`
- **Operating System**: Windows (Host Shell: PowerShell).
- **Core Technology**: Flutter 3.x, Dart SDK `>=3.7.0 <4.0.0`, Firebase Suite, Provider, Laravel API (`sentient-api/`).
- **Primary Package Name**: `sentient`

---

## 3. Operational Rules for Antigravity Assistant

### 3.1 Navigasi & Modifikasi Kode
1. **Never Assume — Always Check**: Sebelum mengubah widget atau service, periksa implementasi aktualnya dengan `view_file` atau `grep_search`.
2. **Preserve Legacy Comments**: Pertahankan komentar dan dokumentasi asli kode jika tidak berkaitan langsung dengan modifikasi.
3. **Strict Type Safety**: Saat membuat atau mengedit service/fitur baru, hindari penggunaan `Map<String, dynamic>` di tingkat UI; selalu buat atau gunakan typed model class.
4. **No Direct BaaS Calling in UI**: Jangan pernah menambahkan pemanggilan `FirebaseFirestore.instance` atau `http.get()` langsung di dalam class turunan `Widget` atau `State`.

### 3.2 Terminal & Verification Rules (PowerShell)
1. **Always format code after editing**:
   ```powershell
   dart format .
   ```
2. **Always verify static analysis**:
   ```powershell
   flutter analyze
   ```
3. **PowerShell Path Compatibility**:
   - Gunakan path Windows yang valid dengan tanda kutip jika terdapat spasi.
   - Jangan pernah mengajukan perintah `cd` terpisah; gunakan parameter `Cwd`.

---

## 4. Safety Bounds & Prohibitions
- ❌ **Dilarang keras** memodifikasi file `.g.dart` atau file di dalam `build/` secara manual.
- ❌ **Dilarang keras** mengubah konfigurasi kunci Firebase (`google-services.json`, `GoogleService-Info.plist`) tanpa instruksi eksplisit pengguna.
- ❌ **Dilarang keras** menulis placeholder / TODO kosong untuk logika inti aplikasi. Tulis implementasi nyata atau tangani secara graceful dengan Fallback UI.
