# 🔥 Firebase Setup untuk Sentient Chess

## 📋 Langkah-langkah Setup Firebase

### 1. **Buat Project Firebase**
1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Klik "Create a project" atau "Add project"
3. Masukkan nama project: `sentient-chess-app`
4. Pilih "Enable Google Analytics" (opsional)
5. Klik "Create project"

### 2. **Setup Authentication**
1. Di Firebase Console, pilih project Anda
2. Klik "Authentication" di sidebar
3. Klik "Get started"
4. Pilih tab "Sign-in method"
5. Enable "Email/Password"
6. Klik "Save"

### 3. **Setup Firestore Database**
1. Klik "Firestore Database" di sidebar
2. Klik "Create database"
3. Pilih "Start in test mode" (untuk development)
4. Pilih lokasi database (pilih yang terdekat)
5. Klik "Done"

### 4. **Setup Storage**
1. Klik "Storage" di sidebar
2. Klik "Get started"
3. Pilih "Start in test mode"
4. Pilih lokasi storage (sama dengan Firestore)
5. Klik "Done"

### 5. **Setup Android App**
1. Klik ikon Android di project overview
2. Masukkan package name: `com.example.sentient_new`
3. Masukkan app nickname: `Sentient Chess`
4. Klik "Register app"
5. Download file `google-services.json`
6. Letakkan file di `android/app/google-services.json`

### 6. **Setup iOS App** (jika diperlukan)
1. Klik ikon iOS di project overview
2. Masukkan bundle ID: `com.example.sentientNew`
3. Masukkan app nickname: `Sentient Chess`
4. Klik "Register app"
5. Download file `GoogleService-Info.plist`
6. Letakkan file di `ios/Runner/GoogleService-Info.plist`

### 7. **Update Security Rules**

#### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public courses
    match /courses/{courseId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Course enrollments
    match /enrollments/{enrollmentId} {
      allow read, write: if request.auth != null && 
        enrollmentId.matches(request.auth.uid + '.*');
    }
    
    // Public products
    match /products/{productId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Public articles
    match /articles/{articleId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

#### Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can upload their own avatars
    match /avatars/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Course images
    match /courses/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### 8. **Install Dependencies**
```bash
flutter pub get
```

### 9. **Test Setup**
```bash
flutter run
```

## 📊 Struktur Database Firestore

### Collections yang Dibutuhkan:

#### 1. **users**
```json
{
  "uid": "user123",
  "username": "john_doe",
  "email": "john@example.com",
  "avatar": "https://firebasestorage.googleapis.com/...",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

#### 2. **courses**
```json
{
  "id": "course123",
  "title": "Mastering Chess Fundamentals",
  "content": "Learn the complete basics...",
  "youtube_url": "https://www.youtube.com/watch?v=...",
  "price": 100000,
  "rating": 4.5,
  "reviewCount": 50,
  "category": "popular",
  "imageUrl": "assets/images/course1.png",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

#### 3. **enrollments**
```json
{
  "id": "user123_course123",
  "user_id": "user123",
  "course_id": "course123",
  "status": "in_progress",
  "progress": 0,
  "enrolled_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

#### 4. **products**
```json
{
  "id": "product123",
  "name": "Beautiful Metal Chess Set",
  "subtitle": "Chess Board",
  "price": 99999,
  "category": "Chess",
  "description": "Rasakan nuansa modern...",
  "imageUrl": "assets/images/product1.png",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

#### 5. **articles**
```json
{
  "id": "article123",
  "title": "Strategi Pembukaan Catur",
  "content": "Artikel tentang strategi...",
  "imageUrl": "assets/images/article1.png",
  "author": "Chess Master",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

## 🔧 Troubleshooting

### Error: "No Firebase App '[DEFAULT]' has been created"
- Pastikan `Firebase.initializeApp()` dipanggil di `main()`
- Pastikan file konfigurasi Firebase sudah benar

### Error: "Permission denied"
- Periksa Firestore Security Rules
- Pastikan user sudah login

### Error: "Network error"
- Periksa koneksi internet
- Pastikan Firebase project sudah aktif

## 📱 Testing

### Test Authentication
1. Register user baru
2. Login dengan user tersebut
3. Cek profile data

### Test Database
1. Buat course baru
2. Enroll ke course
3. Cek enrollment data

### Test Storage
1. Upload avatar
2. Cek file tersimpan di Firebase Storage

## 🚀 Deployment

### Production Setup
1. Update Security Rules untuk production
2. Setup proper authentication methods
3. Configure Firebase Analytics
4. Setup Firebase Crashlytics

### Environment Variables
- Gunakan different Firebase projects untuk development dan production
- Update `google-services.json` dan `GoogleService-Info.plist` sesuai environment 