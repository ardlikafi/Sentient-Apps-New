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
- Response berupa array JSON berisi data course. 
