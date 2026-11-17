# ⚡ Architecture Essentials — Sentient Chess Cheat-Sheet

Dokumen ini adalah **ringkasan aturan teknis singkat (scannable cheat-sheet)** yang wajib dipatuhi oleh seluruh developer dan AI agent sebelum menulis atau memodifikasi kode di repository **Sentient Chess**.

---

## 1. Golden Rules (Aturan Utama)

1. **Dilarang memanggil Firebase atau HTTP langsung dari Widget UI!** Semua pemanggilan data wajib melalui layer **Repository**.
2. **Dilarang menggunakan `Map<String, dynamic>` mentah untuk entitas domain!** Wajib buat typed class Model (`fromJson`/`toJson`).
3. **Dilarang silent failure (`catch (e) => return null;`)!** Wajib tangani error dan kembalikan objek `Result<T>` atau `Failure`.
4. **Pisahkan UI menjadi file modular!** Dilarang membuat file widget monolitik > 300 baris kode dalam satu file.

---

## 2. Aturan State Management

Aplikasi menggunakan **Provider** (`ChangeNotifierProvider`, `Consumer`, `context.read/watch`).

| Jenis State | Mekanisme yang Diizinkan | Contoh Penggunaan |
| :--- | :--- | :--- |
| **Global State** | `ChangeNotifier` + `Provider` | Status autentikasi user, item wishlist (`LikedProductsProvider`), cart, tema. |
| **Feature / Page State** | `ChangeNotifier` / `ValueNotifier` | Filter kursus, form edit profil, pagination list produk. |
| **Ephemeral / Local UI State** | `StatefulWidget` (`setState`) | Toggle show/hide password, tab index animasi, status loading lokal tombol. |

### Aturan Khusus Provider:
- Gunakan `context.read<T>()` untuk memicu method/event (di dalam callback tombol/gesture).
- Gunakan `context.watch<T>()` atau `Consumer<T>` hanya pada sub-tree widget terkecil yang membutuhkan render ulang.
- Hindari meletakkan `context.watch<T>()` di root build method layar besar untuk mencegah rebuild seluruh halaman.

---

## 3. Aturan Pemanggilan Data (Data Access Layer)

Setiap fitur wajib mengikuti hierarki data:

```text
[UI / Widget]
      ↓
[Provider / Controller]
      ↓
[Repository Interface & Impl]
      ↓
[DataSources: Remote (Firebase / REST API) & Local (SharedPreferences / Cache)]
```

### ✅ Yang BENAR:
```dart
// Di dalam UI atau Controller:
final result = await context.read<CourseProvider>().fetchPopularCourses();

// Di dalam Repository:
class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSource remoteDataSource;
  CourseRepositoryImpl(this.remoteDataSource);

  @override
  Future<Result<List<CourseModel>>> getCourses() async {
    try {
      final courses = await remoteDataSource.fetchCourses();
      return Result.success(courses);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}
```

### ❌ Yang DILARANG:
```dart
// DILARANG: Memanggil Firestore / HTTP langsung di dalam Widget!
class _MyWidgetState extends State<MyWidget> {
  void load() async {
    final snapshot = await FirebaseFirestore.instance.collection('courses').get(); // ❌ PELANGGARAN
    final res = await http.get(Uri.parse('...'));                                   // ❌ PELANGGARAN
  }
}
```

---

## 4. Aturan Error Handling (Failure / Result Pattern)

Untuk menjaga kestabilan aplikasi dan mempermudah presentasi error kepada pengguna, setiap operasi data wajib mengembalikan objek `Result<T>` atau melempar `AppException` yang tertangani:

```dart
// 1. Definisi Abstraksi Result
sealed class Result<T> {
  const Result();
  factory Result.success(T data) = Success<T>;
  factory Result.failure(Failure failure) = Error<T>;
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Error<T> extends Result<T> {
  final Failure failure;
  const Error(this.failure);
}

// 2. Definisi Failure
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Terjadi kesalahan pada server']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Koneksi internet bermasalah']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Autentikasi gagal']);
}
```

### Pola Konsumsi di UI:
```dart
final result = await courseRepository.getCourses();
switch (result) {
  case Success(data: final courses):
    _displayCourses(courses);
  case Error(failure: final failure):
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failure.message)),
    );
}
```

---

## 5. Konvensi Penamaan (Naming Conventions)

Konsistensi penamaan wajib dijaga di seluruh repository:

| Elemen | Format Penamaan | Contoh Benar | Contoh Salah |
| :--- | :--- | :--- | :--- |
| **File (.dart)** | `snake_case.dart` | `course_detail_screen.dart`, `api_service.dart` | `CourseDetail.dart`, `courseDetailScreen.dart` |
| **Folder / Direktori** | `snake_case` | `features/auth/`, `core/constants/` | `Features/Auth/`, `coreConstants/` |
| **Class / Enum / Extension** | `PascalCase` | `CourseDetailScreen`, `FirebaseService`, `CourseModel` | `course_detail_screen`, `apiService` |
| **Method / Fungsi** | `camelCase` | `fetchCourses()`, `signInWithGoogle()`, `toggleLike()` | `FetchCourses()`, `fetch_courses()` |
| **Variabel / Property** | `camelCase` | `isLoading`, `filteredCourses`, `currentUser` | `IsLoading`, `filtered_courses` |
| **Konstanta Warna / Style** | `kCamelCase` | `kDarkBlue`, `kPrimaryBlue`, `kVeryLightBlue` | `DARK_BLUE`, `darkBlue`, `Color_Blue` |
| **Konstanta Umum** | `kCamelCase` atau `UPPER_SNAKE` | `kDefaultTimeout`, `BASE_URL` | `base_url`, `Timeout` |

---

## 6. Template Fitur Baru (New Feature Checklist)
Sebelum commit atau merge PR untuk fitur baru, pastikan telah memenuhi checklist berikut:
- [ ] Folder diletakkan di bawah `lib/features/<nama_fitur>/`.
- [ ] Model data didefinisikan dengan type-safety lengkap (`<nama_fitur>_model.dart`).
- [ ] Ada abstraksi `Repository` dan pemanggilan DataSource terisolasi.
- [ ] UI dipisah menjadi sub-komponen terukur (masing-masing < 250 baris).
- [ ] Lulus validasi `dart format .` dan `flutter analyze`.
