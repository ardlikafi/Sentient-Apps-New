# Dokumentasi Consume API Course

Dokumen ini menjelaskan cara melakukan consume (mengambil data) API untuk resource `course` pada backend, baik menggunakan Flutter (Dart) maupun web (HTML/JavaScript).

---

## 1. Endpoint API

```
GET /api/courses
```

- **Base URL:** `http://192.168.1.5:8000/api`
- **Full URL:** `http://192.168.1.5:8000/api/courses`

---

## 2. Contoh Response

```json
[
  {
    "id": 1,
    "title": "Mastering Chess Fundamentals",
    "description": "Learn the complete basics of chess with this comprehensive guide.",
    "category": "Beginner",
    "price": 100000,
    "rating": 4.5,
    "reviewCount": 50
  },
  ...
]
```

---

## 3. Consume API di Flutter (Dart)

### a. Service Method

Sudah tersedia di `lib/api_service.dart`:

```dart
static Future<List<Map<String, dynamic>>> fetchCourses() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/courses'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
  } catch (e) {
    return [];
  }
}
```

### b. Contoh Penggunaan di Widget

```dart
List<Map<String, dynamic>> _courses = [];
bool _isLoading = true;

@override
void initState() {
  super.initState();
  fetchData();
}

Future<void> fetchData() async {
  setState(() => _isLoading = true);
  final data = await ApiService.fetchCourses();
  setState(() {
    _courses = data;
    _isLoading = false;
  });
}
```

---

## 4. Consume API di Web (HTML/JavaScript)

### a. Contoh Sederhana (lihat `web/consume_course_api.html`)

```html
<script>
const baseUrl = 'http://192.168.1.5:8000/api';
async function fetchCourses() {
  const res = await fetch(`${baseUrl}/courses`);
  const data = await res.json();
  // proses data
}
fetchCourses();
</script>
```

---

## 5. Catatan
- Pastikan backend dapat diakses dari perangkat/browser Anda.
- Jika menggunakan emulator/device, sesuaikan IP backend (`baseUrl`).
- Untuk autentikasi (jika diperlukan), tambahkan header Authorization.

---

**File ini khusus dokumentasi consume API course.** 
