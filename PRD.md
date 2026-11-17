# ♟️ Product Requirements Document (PRD) — Sentient Chess

## 1. Executive Summary & Problem Statement

### 1.1 Deskripsi Singkat
**Sentient Chess** (`sentient`) adalah platform mobile all-in-one yang dirancang untuk menjadi pusat ekosistem catur modern bagi komunitas, pemain pemula hingga mahir, dan antusias catur. Dengan slogan **"All Your Chess Needs in One App"**, Sentient Chess menyatukan video pembelajaran terstruktur (*course*), katalog perlengkapan catur kurasi (*shop*), artikel taktik & berita catur (*articles*), serta sistem langganan anggota (*membership tiers*).

### 1.2 Masalah yang Diselesaikan
1. **Fragmentasi Ekosistem Catur**: Penggemar catur saat ini harus berpindah-pindah aplikasi antara platform belajar (YouTube/website terpisah), e-commerce umum untuk membeli papan atau jam catur (tanpa kurasi standar turnamen), dan portal berita untuk membaca strategi catur.
2. **Kurasi Materi Belajar yang Lemah**: Pemula sering bingung mencari jalur belajar yang tepat dari nol, sementara video catur di internet tersebar tanpa filter level (Beginner, Intermediate, Expert) yang jelas.
3. **Penyediaan Alat Standar FIDE yang Terpercaya**: Pemain klub dan turnamen membutuhkan peralatan catur berspesifikasi presisi (jam catur digital dengan delay/bonus FIDE, papan kayu/marmer/vinyl berbobot standar) yang sulit ditemukan dengan kurasi terfokus.
4. **Sentient Chess Solusi**: Menyatukan *learning hub*, *curated chess shop*, *wishlist management*, dan *knowledge hub* dalam satu antarmuka mobile modern bertema dark-blue elegan.

---

## 2. Target Pengguna (Who It Is For)

| Persona | Profil & Kebutuhan Utama | Nilai Tambah di Sentient |
| :--- | :--- | :--- |
| **Chess Beginner (Pemula)** | Orang yang baru mulai menyukai catur; membutuhkan pemahaman aturan dasar, taktik pemula, dan bimbingan video ringkas tanpa istilah rumit. | Kursus dasar gratis, modul video bertahap, dan artikel pengantar strategi. |
| **Club & Tournament Player (Pemain Klub / Kompetitif)** | Pemain aktif yang mengasah opening repertoire, endgame calculation, dan membutuhkan jam catur digital serta set catur berstandar turnamen. | Masterclass berbayar, jam catur digital FIDE standard, analisis mendalam, dan event catur. |
| **Chess Collector & Enthusiast (Kolektor)** | Penggemar estetika catur yang mencari set catur mewah (kayu Sheesham/Boxwood, batu marmer asli, logam presisi tinggi, atau kaca minimalis). | Katalog produk premium dengan galeri foto mendetail, deskripsi spesifikasi bahan, dan direct buy link. |
| **Chess Content Consumers** | Pemain kasual yang gemar menonton ulasan Masterclass (Magnus Carlsen, Hikaru Nakamura, GothamChess) dan membaca artikel analisis terkini. | In-app YouTube streaming dialog, event banner interaktif, dan artikel strategi harian. |

---

## 3. Fitur Utama (Features Scope)

### 3.1 Fitur yang Sudah Ada (Current Implementation - Must Do v1)

#### A. Onboarding & Multi-Authentication
- **Splash Screen**: Animasi intro logo (Fade & Elastic Scale transition) dengan pengecekan sesi login pengguna secara otomatis via Firebase Auth.
- **CTA Screen (Call to Action)**: Visual hero intro *"All Your Chess Needs in One App"* dengan tombol transisi mulus ke alur pendaftaran.
- **Welcome Hub**: Pusat pilihan masuk dengan opsi Sign Up, Log In, Google Sign-In, serta selektor bahasa (UI selector "En").
- **Email & Password Authentication**:
  - Registrasi pengguna dengan username, email, password, konfirmasi password, dan upload foto profil langsung (Kamera / Galeri).
  - Pengecekan username unik di Firestore.
  - Alur **Verifikasi Email Wajib** (`VerifyEmailScreen`): Polling otomatis status verifikasi pengguna dan tombol kirim ulang email dengan interval cooldown 15 detik.
- **Google OAuth Sign-In**: Integrasi satu ketuk melalui Google Sign-In yang otomatis menyinkronkan data pengguna baru ke koleksi Firestore `users`.

#### B. Home Dashboard (Super-App Hub)
- **Home Header**: Profil pengguna (avatar, sapaan username, status membership/rank).
- **Event Recommendation Carousel**: Auto-scrolling carousel berisi pengumuman event ("Masterclass with Magnus", "Study with Hikaru", "GothamChess Bootcamp").
- **Courses Section**: Showcase daftar kursus populer dengan tab filter dinamis ("All Course", "Populer", "Free"), harga (IDR), rating bintang, dan jumlah ulasan.
- **Embedded YouTube Player Dialog**: Memutar preview video kursus catur langsung di dalam aplikasi melalui modal dialog tanpa harus keluar ke aplikasi pihak ketiga.
- **Shop Showcase**: Carousel produk catur unggulan dengan harga terformat Rupiah (`NumberFormat.decimalPattern`) dan indikator status *liked* (wishlist).
- **Article Section**: Daftar artikel strategi dan berita catur dengan kartu horizontal berisi tanggal, thumbnail, dan ringkasan singkat.
- **Bottom Navigation Bar**: Persistent 4-tab bar dengan dekorasi sudut lengkung melengkung (`Home`, `Course`, `Shop`, `Profile`).

#### C. Course & Learning Center
- **Recommendation Auto-Scroll Banner**: Banner penawaran kursus eksklusif dengan indikator dot pagination aktif.
- **Filter Berjenjang**: Filter berdasarkan tipe ("All Course", "Popular", "Paid") serta filter level ("Beginner", "Intermediate", "Expert") dengan custom dropdown overlay.
- **Course Detail Screen**: Menampilkan thumbnail berukuran besar, deskripsi kurikulum, daftar episode video pembelajaran dengan status penanda *Locked (Premium)* vs *Play*.

#### D. E-Commerce & Curated Shop
- **Pencarian Realtime**: Input field pencarian live yang menyaring katalog produk secara instan berdasarkan nama produk.
- **Kategori Filter**: Pemisahan produk berdasarkan kategori ("All Product", "Chess", "Items").
- **Wishlist / Liked Products**:
  - Global state management menggunakan `LikedProductsProvider`.
  - Sinkronisasi realtime dua arah dengan Cloud Firestore (`users.liked_products` array union/remove).
  - Halaman khusus `My Wishlist` (`LikedProductsScreen`) dengan grid 2-kolom dan empty state informatif.
- **Product Detail**: Menampilkan galeri foto produk, selector varian ukuran papan (25 cm, 50 cm, 75 cm), toggle like, serta tombol CTA *"Buy Now"* yang mengintegrasikan URL eksternal Tokopedia resmi toko.

#### E. Profil Pengguna & Keanggotaan
- **Profile Dashboard**: Menampilkan foto profil bulat resolusi tinggi (dengan fitur zoom fullscreen via `InteractiveViewer`), nama, email, dan statistik akun.
- **Edit Profile Modal**: Bottom sheet untuk mengubah username, nomor handphone, serta mengganti foto avatar profil yang diunggah ke Firebase Storage.
- **Account Info Sheet**: Tampilan ringkas detail metadata akun (username, email, nomor kontak, dan tanggal pembuatan akun via Firestore timestamp).
- **Subscription Tiers Screen**:
  - Halaman penawaran paket langganan berjenjang:
    - **Pawn Tier** (1 Bulan)
    - **Knight Tier** (3 Bulan)
    - **Queen Tier** (6 Bulan)
  - Daftar benefit langganan: *Unlimited access to all courses*, *Exclusive articles*, *Special discounts in the shop*.

---

## 4. Batasan & Hal yang Tidak Dibuat di v1 (Explicitly NOT Doing in v1)

Agar pengembangan produk tetap terfokus dan stabil pada fondasi yang ada saat ini, hal-hal berikut **secara eksplisit ditunda** untuk rilis versi berikutnya (v2+):

| Fitur | Status v1 | Rencana Rilis Mendatang |
| :--- | :--- | :--- |
| **Interactive Chess Board (Chess Engine / Stockfish)** | **Tidak ada** (Hanya katalog video belajar, tidak ada papan interaktif untuk bermain catur langsung di layar). | v2.0 (Integrasi catur AI Stockfish & PGN viewer). |
| **Realtime Online Multiplayer Matchmaking** | **Tidak ada** (Belum ada socket game / server matchmaking PvP). | v2.5 (PVP online rating ELO). |
| **Payment Gateway In-App Native (Midtrans / Xendit / Google Play Billing)** | **Tidak ada** (Pembelian produk fisik diarahkan via Tokopedia eksternal; tombol langganan masih bersifat mock/TODO). | v1.5 (Integrasi payment gateway lokal Indonesia). |
| **Turnamen & Leaderboard Dinamis** | **Tidak ada** (Event banner hanya bersifat display statis/mock). | v2.0 (Sistem registrasi turnamen catur komunitas). |
| **Facebook OAuth Login** | **Nonaktif** (Menampilkan snackbar *"Facebook login not implemented yet"*). | v1.2 (Konfigurasi Facebook Developer SDK). |
| **Sistem Chat / Forum Komunitas** | **Tidak ada** (Belum ada fitur pesan antar pemain atau forum diskusi). | v2.0. |
| **Multi-Language Penuh (i18n)** | **Hanya mockup bahasa** (Selector bahasa hanya menampilkan ikon bendera & label "En" tanpa pergantian string dinamis). | v1.3 (Integrasi `flutter_localizations` & ARB file). |

---

## 5. Metrik Keberhasilan (Success Metrics)
1. **User Retention**: > 40% pengguna membuka tab Course atau membaca artikel dalam 7 hari pertama.
2. **Engagement**: Pengguna memutar video YouTube pembelajaran minimal 1x per sesi aktif.
3. **Wishlist Conversion**: > 20% pengguna menyimpan setidaknya 1 produk ke Wishlist.
4. **App Stability**: Crash-free rate > 99% pada perangkat Android dan iOS.
