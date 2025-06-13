# API Documentation: Public Course Endpoint

## Endpoint

```
GET /api/public-courses
```

- **Description:**
  Mengambil daftar semua course yang tersedia secara publik. Endpoint ini dapat diakses tanpa autentikasi dan dapat digunakan oleh aplikasi/web/pihak ketiga.

- **Base URL:**
  `http://domain.com/api/public-courses`

## Response Example

```json
[
  {
    "id": 1,
    "title": "Mastering Chess Fundamentals",
    "category": "Beginner",
    "price": 100000,
    "rating": 4.5,
    "reviewCount": 50,
    "description": "Learn the complete basics of chess...",
    "content": "Fundamental chess concepts...",
    "youtube_url": "https://www.youtube.com/watch?v=NAIQyoPcjNM"
  },
  ...
]
```

## Parameters
- Tidak ada parameter khusus.

## Catatan
- Endpoint ini **tidak membutuhkan autentikasi**.
- Data dapat diakses dan digunakan oleh aplikasi/web lain.
- Untuk filter, pagination, atau fitur lain, silakan hubungi pengelola API.

## Cara Konsumsi API `/api/public-courses`

### 1. Menggunakan JavaScript (fetch)
```js
fetch('https://6a0d-110-138-170-251.ngrok-free.app/api/public-courses')
  .then(res => res.json())
  .then(data => console.log(data));
```

### 2. Menggunakan Flutter (Dart)
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> fetchCourses() async {
  final response = await http.get(Uri.parse('https://6a0d-110-138-170-251.ngrok-free.app/api/public-courses'));
  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    print(data);
  } else {
    print('Failed to load courses');
  }
}
```

### 3. Menggunakan Postman
- Buka Postman
- Pilih method **GET**
- Masukkan URL: `https://6a0d-110-138-170-251.ngrok-free.app/api/public-courses`
- Klik **Send**
- Lihat hasil di tab Response

### 4. Catatan
- Endpoint ini dapat diakses siapa saja tanpa autentikasi.
<<<<<<< HEAD
- Response berupa array JSON berisi data course.

## Contoh Penggunaan JWT di Postman

### 1. Register User (POST)
- **URL:** `http://127.0.0.1:8000/api/register`
- **Body (JSON):**
```json
{
  "username": "user1",
  "email": "user1@email.com",
  "password": "password",
  "password_confirmation": "password"
}
```
- **Response:** Akan mendapatkan token JWT di field `token`.

### 2. Login User (POST)
- **URL:** `http://127.0.0.1:8000/api/login`
- **Body (JSON):**
```json
{
  "email": "user1@email.com",
  "password": "password"
}
```
- **Response:** Akan mendapatkan token JWT di field `token`.

### 3. Akses Endpoint Terproteksi (GET)
- **URL:** `http://127.0.0.1:8000/api/profile` (atau endpoint lain yang diproteksi)
- **Headers:**
  - `Authorization: Bearer <token>`
- **Langkah di Postman:**
  1. Copy token dari response login/register.
  2. Pilih tab **Authorization** di Postman.
  3. Pilih **Bearer Token** dan paste token.
  4. Atau, di tab **Headers** tambahkan:
     - Key: `Authorization`
     - Value: `Bearer <token>`
  5. Klik **Send**.
- **Response:** Data user atau data lain sesuai endpoint.

### 4. Catatan
- Token JWT harus dikirim di header setiap request ke endpoint yang diproteksi.
- Jika token salah/expired, response akan 401 Unauthorized.
- Endpoint public (misal `/api/public-courses`) tidak butuh token.

## Daftar Endpoint API Utama

### 1. Register
- **POST** `/api/register`
- **Body:**
  ```json
  {
    "username": "user1",
    "email": "user1@email.com",
    "password": "password",
    "password_confirmation": "password"
  }
  ```
- **Response:**
  - 201 Created, field `token` berisi JWT

### 2. Login
- **POST** `/api/login`
- **Body:**
  ```json
  {
    "email": "user1@email.com",
    "password": "password"
  }
  ```
- **Response:**
  - 200 OK, field `token` berisi JWT
  - 401 Unauthorized jika email/password salah

### 3. Profile (Protected)
- **GET** `/api/profile`
- **Headers:** `Authorization: Bearer <token>`
- **Response:**
  - 200 OK, data user
  - 401 Unauthorized jika token salah/expired

### 4. Logout (Protected)
- **POST** `/api/logout`
- **Headers:** `Authorization: Bearer <token>`
- **Response:**
  - 200 OK, pesan sukses logout

### 5. Refresh Token (Protected)
- **POST** `/api/refresh`
- **Headers:** `Authorization: Bearer <token>`
- **Response:**
  - 200 OK, field `token` berisi JWT baru

### 6. Public Courses
- **GET** `/api/public-courses`
- **Response:**
  - 200 OK, array data course (tanpa autentikasi)

### 7. Courses (CRUD, Protected kecuali index/show)
- **GET** `/api/courses` (public, semua course)
- **GET** `/api/courses/{id}` (public, detail course)
- **POST** `/api/courses` (protected, tambah course)
- **PUT/PATCH** `/api/courses/{id}` (protected, edit course)
- **DELETE** `/api/courses/{id}` (protected, hapus course)
- **Headers (protected):** `Authorization: Bearer <token>`

## Contoh Error Response
```json
{
  "status": "error",
  "message": "Invalid credentials"
}
```

```json
{
  "status": "error",
  "message": "Unauthenticated."
}
```

## Catatan Umum
- Endpoint protected **WAJIB** mengirim header `Authorization: Bearer <token>`
- Token JWT didapat dari endpoint login/register
- Endpoint public tidak butuh token
- Jika token salah/expired, response 401 Unauthorized
- Semua response dalam format JSON
