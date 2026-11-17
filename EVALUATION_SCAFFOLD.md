# 📐 Evaluasi Scaffold & Folder Structure — Sentient Chess

Dokumen ini menyajikan **evaluasi komprehensif terhadap struktur folder `lib/` saat ini**, identifikasi masalah arsitektur (*code smell* & *anti-pattern*), serta **rekomendasi scaffold baru (Feature-First Architecture)** beserta tabel pemetaan migrasi file secara detail.

---

## 1. Pemetaan Struktur Folder `lib/` Saat Ini

Saat ini, direktori `lib/` memiliki **0 subdirektori** dan menampung **25 file Dart** secara langsung pada root level (*Flat Architecture*):

| No | File Saat Ini | Ukuran (Lines) | Kategori Fungsi | Analisis Peran & Masalah |
| :---: | :--- | :---: | :--- | :--- |
| 1 | `account_info_sheet.dart` | 96 | UI (Profile) | BottomSheet metadata profil user (username, email, phone, created_at). |
| 2 | `animated_route.dart` | 53 | Navigation / Core | Custom PageRouteBuilder (`FadeRoute`, `SlideRightRoute`, `FadeScaleRoute`). |
| 3 | `api_service.dart` | 236 | Data / Network | Client REST API Laravel (`http`). Static methods, no typed models. |
| 4 | `article_detail_screen.dart` | 168 | UI (Article) | Layar detail artikel catur. Menggunakan `Map<String, dynamic>`. |
| 5 | `course_detail_screen.dart` | 265 | UI (Course) | Detail kurikulum kursus & video locked/free. Menggunakan `Map<String, dynamic>`. |
| 6 | `course_screen.dart` | 1148 | UI (Course) | **God File**: Berisi `CourseScreen`, `RecommendationSection`, `CourseFilterAndListSection`, `CourseCard`, dan `YouTubeDialog`. Memuat mock course inline. |
| 7 | `cta_screen.dart` | 98 | UI (Onboarding) | Layar Call-to-Action pengantar awal. |
| 8 | `edit_profile_sheet.dart` | 247 | UI (Profile) | BottomSheet form ubah profil & upload foto ke Firebase Storage. |
| 9 | `firebase_service.dart` | 359 | Data / BaaS | Service Firebase (Auth, Firestore `users`, `courses`, `products`, Storage). Static methods. |
| 10 | `home_screen.dart` | 2024 | UI (Home) | **Extreme God File**: Berisi `HomeScreen`, `HomeContent`, `HomeHeader`, `EventSection`, `CoursesSection`, `CourseCard`, `YouTubeVideoDialog`, `ShopSection`, `ProductCard`, `ArticleSection`, `ArticleCard`. Memuat duplikasi widget dan mock data internal. |
| 11 | `liked_products_provider.dart` | 65 | State (Shop) | ChangeNotifier Provider untuk sinkronisasi wishlist ke Firestore. |
| 12 | `liked_products_screen.dart` | 65 | UI (Shop) | Layar My Wishlist untuk menampilkan produk yang di-like. |
| 13 | `login_screen.dart` | 400 | UI (Auth) | Layar login email/password via Firebase Auth. |
| 14 | `main.dart` | 96 | Core / Entry | Inisialisasi Firebase, Provider root, rute named static, dan sisa boilerplate `MyHomePage`. |
| 15 | `mock_data.dart` | 8 | Data (Shop) | Statis array `allMockProducts` (`List<Map<String, dynamic>>`). |
| 16 | `product_card.dart` | 74 | UI (Shop) | Reusable widget card produk toko. |
| 17 | `product_detail_screen.dart` | 266 | UI (Shop) | Layar detail produk, ukuran varian, dan link launcher Tokopedia. |
| 18 | `profile_screen.dart` | 594 | UI (Profile) | Layar dashboard profil akun, drawer menu, dan dialog zoom avatar. |
| 19 | `shop_screen.dart` | 356 | UI (Shop) | Layar toko, live search bar, dan filter kategori. |
| 20 | `signup_choice_screen.dart` | 185 | UI (Auth) | Layar opsi pendaftaran (Sign up email vs Google). |
| 21 | `signup_screen.dart` | 616 | UI (Auth) | Layar form registrasi lengkap, validasi, dan camera/gallery picker. |
| 22 | `splash_screen.dart` | 88 | UI (Onboarding) | Splash animasi logo & auto auth checker. |
| 23 | `subscription_screen.dart` | 225 | UI (Subscription) | Layar paket keanggotaan (Pawn, Knight, Queen tier) & benefit. |
| 24 | `verify_email_screen.dart` | 175 | UI (Auth) | Layar polling verifikasi email Firebase & tombol resend. |
| 25 | `welcome_screen.dart` | 305 | UI (Onboarding) | Layar welcome, Google Sign-In button, dan mock language switcher. |

---

## 2. Identifikasi Masalah & Code Smells

### 1. Anti-Pattern: Flat Single-Directory (`lib/`)
Menempatkan 25 file di satu folder membuat batas tanggung jawab (*boundary*) antar modul tidak terlihat. Developer sulit mengisolasi apakah suatu file bertanggung jawab atas data, state, atau tampilan visual.

### 2. God Files & Widget Duplication
- `home_screen.dart` (2024 baris kode) bertindak sebagai *monolith*. Di dalamnya terdapat definisi kelas `CourseCard` dan `ProductCard` versi internal, padahal di `lib/` sudah ada `product_card.dart` dan di `course_screen.dart` ada `CourseCard` versi lain. Ini menyebabkan **duplikasi logika dan styling**.
- `course_screen.dart` (1148 baris) menggabungkan carousel autoscroll, overlay dropdown kustom, YouTube player, dan daftar kursus dalam satu file.

### 3. Ketiadaan Layer Data Models (Primitive Obsession)
Tidak ada kelas Model Dart (`class Course`, `class Product`). Kode bergantung 100% pada `Map<String, dynamic>` dengan key berupa literal string (`course['price']`, `product['name']`). Hal ini sangat rentan bug runtime (typo key, null-pointer exception saat parsing, atau perbedaan tipe `int` vs `double`).

### 4. Pelanggaran Dependency Rule (Tight Coupling UI ke Service)
Widget UI memanggil langsung `FirebaseService.login()` atau `FirebaseFirestore.instance` tanpa perantara Repository Interface. Jika tim ingin berpindah sepenuhnya dari Firebase ke REST API Laravel (atau sebaliknya), seluruh file UI harus diubah satu per satu.

### 5. Boilerplate Tersisa di `main.dart`
Di baris 51-96 `main.dart`, masih terdapat kode template bawaan Flutter (`class MyHomePage` dengan tombol counter) yang tidak pernah digunakan dalam alur aplikasi.

---

## 3. Rekomendasi Scaffold Folder Structure Baru (Feature-First)

Untuk memfasilitasi skalabilitas, clean architecture, dan kolaborasi yang rapi, struktur folder `lib/` direkomendasikan ditata ulang menggunakan pola **Feature-First**:

```text
lib/
├── core/                                   # Komponen global & utilitas lintas fitur
│   ├── constants/
│   │   ├── app_colors.dart                 # kDarkBlue, kPrimaryBlue, kLightBlue, dll.
│   │   ├── app_routes.dart                 # Definisi string rute ('/home', '/login', dll.)
│   │   └── api_constants.dart              # Base URL, endpoints, timeout duration
│   ├── errors/
│   │   ├── app_exception.dart              # Kelas exception terkustom
│   │   └── failure.dart                    # Objek Failure (ServerFailure, NetworkFailure)
│   ├── network/
│   │   ├── api_client.dart                 # HTTP client wrapper
│   │   └── firebase_client.dart            # Firebase initialization & instance wrapper
│   ├── theme/
│   │   └── app_theme.dart                  # ThemeData, Poppins Typography
│   ├── utils/
│   │   ├── animated_route.dart             # FadeRoute, SlideRightRoute, FadeScaleRoute
│   │   └── currency_formatter.dart         # Format Rupiah helper
│   └── widgets/
│       ├── custom_button.dart
│       ├── loading_indicator.dart
│       └── error_placeholder.dart
│
├── features/                               # Modul-modul fitur mandiri (Feature-First)
│   ├── auth/                               # Fitur Autentikasi & Akun
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_firebase_datasource.dart
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── auth_provider.dart
│   │       └── screens/
│   │           ├── login_screen.dart
│   │           ├── signup_choice_screen.dart
│   │           ├── signup_screen.dart
│   │           └── verify_email_screen.dart
│   │
│   ├── onboarding/                         # Fitur Splash & Welcome
│   │   └── presentation/
│   │       └── screens/
│   │           ├── splash_screen.dart
│   │           ├── cta_screen.dart
│   │           └── welcome_screen.dart
│   │
│   ├── home/                               # Fitur Dashboard Utama
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── home_screen.dart        # Hanya mengelola IndexedStack & BottomNav
│   │       └── widgets/
│   │           ├── home_header.dart
│   │           ├── home_event_carousel.dart
│   │           ├── home_courses_preview.dart
│   │           ├── home_shop_preview.dart
│   │           └── home_articles_preview.dart
│   │
│   ├── course/                             # Fitur Kursus & Pembelajaran
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── course_model.dart
│   │   │   └── repositories/
│   │   │       └── course_repository_impl.dart
│   │   ├── domain/
│   │   │   └── repositories/
│   │   │       └── course_repository.dart
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── course_provider.dart
│   │       ├── screens/
│   │       │   ├── course_screen.dart
│   │       │   └── course_detail_screen.dart
│   │       └── widgets/
│   │           ├── course_card.dart
│   │           ├── course_recommendation_carousel.dart
│   │           ├── course_filter_dropdown.dart
│   │           └── youtube_player_dialog.dart
│   │
│   ├── shop/                               # Fitur Toko Catur & Wishlist
│   │   ├── data/
│   │   │   ├── mock/
│   │   │   │   └── mock_products.dart
│   │   │   ├── models/
│   │   │   │   └── product_model.dart
│   │   │   └── repositories/
│   │   │       └── shop_repository_impl.dart
│   │   ├── domain/
│   │   │   └── repositories/
│   │   │       └── shop_repository.dart
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── wishlist_provider.dart  # (Eks LikedProductsProvider)
│   │       ├── screens/
│   │       │   ├── shop_screen.dart
│   │       │   ├── product_detail_screen.dart
│   │       │   └── wishlist_screen.dart    # (Eks LikedProductsScreen)
│   │       └── widgets/
│   │           ├── product_card.dart
│   │           └── shop_search_bar.dart
│   │
│   ├── article/                            # Fitur Artikel & Berita Catur
│   │   ├── data/
│   │   │   └── models/
│   │   │       └── article_model.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── article_detail_screen.dart
│   │       └── widgets/
│   │           └── article_card.dart
│   │
│   ├── profile/                            # Fitur Profil Pengguna
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── profile_screen.dart
│   │       └── widgets/
│   │           ├── account_info_sheet.dart
│   │           ├── edit_profile_sheet.dart
│   │           └── change_password_sheet.dart
│   │
│   └── subscription/                       # Fitur Keanggotaan & Tier
│       └── presentation/
│           ├── screens/
│           │   └── subscription_screen.dart
│           └── widgets/
│               └── subscription_tier_card.dart
│
└── main.dart                               # Entry point terisolasi & bersih
```

---

## 4. Matriks Migrasi File (1-to-1 File Mapping)

| File Asal di `lib/` | File Target yang Direkomendasikan | Aksi Refactoring yang Disarankan |
| :--- | :--- | :--- |
| `account_info_sheet.dart` | `lib/features/profile/presentation/widgets/account_info_sheet.dart` | Ubah parameter menjadi typed `UserModel`. |
| `animated_route.dart` | `lib/core/utils/animated_route.dart` | Pindahkan ke core utility. |
| `api_service.dart` | `lib/core/network/api_client.dart` & feature datasources | Pisahkan method auth dan course ke datasource masing-masing. |
| `article_detail_screen.dart`| `lib/features/article/presentation/screens/article_detail_screen.dart`| Ubah parameter menjadi `ArticleModel`. |
| `course_detail_screen.dart` | `lib/features/course/presentation/screens/course_detail_screen.dart` | Ubah parameter menjadi `CourseModel`. |
| `course_screen.dart` | `lib/features/course/presentation/screens/course_screen.dart` | Ekstrak subwidget (`CourseCard`, `YouTubeDialog`) ke folder `widgets/`. |
| `cta_screen.dart` | `lib/features/onboarding/presentation/screens/cta_screen.dart` | Pindahkan ke fitur onboarding. |
| `edit_profile_sheet.dart` | `lib/features/profile/presentation/widgets/edit_profile_sheet.dart` | Hubungkan data flow via `ProfileProvider`. |
| `firebase_service.dart` | `lib/features/auth/data/datasources/auth_firebase_datasource.dart` | Pecah service monolitik ke datasource per fitur. |
| `home_screen.dart` | `lib/features/home/presentation/screens/home_screen.dart` | Pecah `home_screen.dart` (2024 baris) menjadi 5 file widget kecil di `widgets/`. |
| `liked_products_provider.dart`| `lib/features/shop/presentation/controllers/wishlist_provider.dart` | Ganti nama agar lebih deskriptif (`WishlistProvider`). |
| `liked_products_screen.dart`| `lib/features/shop/presentation/screens/wishlist_screen.dart` | Pindahkan ke feature shop presentation. |
| `login_screen.dart` | `lib/features/auth/presentation/screens/login_screen.dart` | Pindahkan ke feature auth presentation. |
| `main.dart` | `lib/main.dart` | Hapus sisa boilerplate `MyHomePage` (baris 51-96). |
| `mock_data.dart` | `lib/features/shop/data/mock/mock_products.dart` | Pindahkan ke folder data mock. |
| `product_card.dart` | `lib/features/shop/presentation/widgets/product_card.dart` | Jadikan single source of truth untuk kartu produk. |
| `product_detail_screen.dart`| `lib/features/shop/presentation/screens/product_detail_screen.dart` | Ubah parameter menjadi `ProductModel`. |
| `profile_screen.dart` | `lib/features/profile/presentation/screens/profile_screen.dart` | Ekstrak `ChangePasswordSheet` ke file widget terpisah. |
| `shop_screen.dart` | `lib/features/shop/presentation/screens/shop_screen.dart` | Ekstrak search bar dan banner ke folder `widgets/`. |
| `signup_choice_screen.dart` | `lib/features/auth/presentation/screens/signup_choice_screen.dart` | Pindahkan ke feature auth. |
| `signup_screen.dart` | `lib/features/auth/presentation/screens/signup_screen.dart` | Pindahkan ke feature auth. |
| `splash_screen.dart` | `lib/features/onboarding/presentation/screens/splash_screen.dart` | Pindahkan ke feature onboarding. |
| `subscription_screen.dart` | `lib/features/subscription/presentation/screens/subscription_screen.dart` | Ekstrak `SubscriptionTierCard` ke file widget. |
| `verify_email_screen.dart` | `lib/features/auth/presentation/screens/verify_email_screen.dart` | Pindahkan ke feature auth. |
| `welcome_screen.dart` | `lib/features/onboarding/presentation/screens/welcome_screen.dart` | Pindahkan ke feature onboarding. |

---

## 5. Rencana Pelaksanaan Refactoring Bertahap (Zero Breaking Changes)

Agar refactoring tidak merusak fungsionalitas yang ada, lakukan secara bertahap dalam 4 fase:

### Fase 1: Pembentukan Core Foundation (Non-Breaking)
1. Buat folder `lib/core/constants/app_colors.dart` untuk memusatkan `kDarkBlue`, `kPrimaryBlue`, `kLightBlue`, `kVeryLightBlue` (saat ini terduplikasi di hampir setiap file screen).
2. Pindahkan `animated_route.dart` ke `lib/core/utils/animated_route.dart`.
3. Bersihkan kode mati `MyHomePage` di `main.dart`.

### Fase 2: Introduksi Typed Data Models
1. Buat `UserModel`, `CourseModel`, `ProductModel`, dan `ArticleModel` dengan constructor bertipe kuat dan method `fromJson`/`toJson`.
2. Secara bertahap ganti parameter `Map<String, dynamic>` di `ProductDetailScreen`, `CourseDetailScreen`, dan `ArticleDetailScreen` menjadi typed models.

### Fase 3: Pemecahan God Files (`home_screen.dart` & `course_screen.dart`)
1. Ekstrak `HomeHeader`, `EventSection`, `CoursesSection`, `ShopSection`, dan `ArticleSection` dari `home_screen.dart` menjadi file terpisah di `lib/features/home/presentation/widgets/`.
2. Hapus duplikasi deklarasi `ProductCard` dan `CourseCard` di `home_screen.dart` dan gunakan widget yang sudah terpusat.
3. Ekstrak `RecommendationSection` dan `CourseCard` dari `course_screen.dart`.

### Fase 4: Penataan Folder Menuju Feature-First
1. Buat folder `lib/features/` (auth, onboarding, home, course, shop, profile, subscription, article).
2. Pindahkan file-file layar ke folder tujuan masing-masing dan perbarui statement `import` secara serentak.
3. Jalankan `dart format .` dan `flutter analyze` untuk menjamin integritas kode 100% lulus tanpa error.
