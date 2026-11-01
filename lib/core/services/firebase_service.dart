import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentient/core/services/simulated_order_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show File;
import 'dart:convert';
import 'package:sentient/core/services/notification_service.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<UserCredential?> register({
    required String username,
    required String email,
    required String password,
    dynamic avatarFile,
  }) async {
    try {
      print('Attempting to register user: $email, username: $username');
      
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      print('User created successfully: ${userCredential.user?.uid}');

      try { await userCredential.user?.sendEmailVerification(); print('Verification email sent to: $email'); } catch (e) { print('Warning sending verification email: $e'); }

      try {
        await userCredential.user?.updateDisplayName(username);
      } catch (_) {}

      // Simpan sementara di pending_registrations (TIDAK di collection users sebelum verifikasi)
      final cleanUsername = username.trim();
      await _firestore.collection('pending_registrations').doc(userCredential.user!.uid).set({
        'username': cleanUsername,
        'username_lowercase': cleanUsername.toLowerCase(),
        'email': email.trim().toLowerCase(),
        'email_verified': false,
        'avatar': null,
        'phone': null,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (avatarFile != null) {
        try {
          await uploadAvatar(avatarFile);
        } catch (uploadErr) {
          print('Avatar upload error during registration: $uploadErr');
        }
      }

      print('User data saved to Firestore successfully');
      return userCredential;
    } catch (e) {
      print('Error during registration: $e');
      print('Error type: ${e.runtimeType}');
      
      // Provide more specific error messages
      String errorMessage = 'Registration failed';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'Password is too weak (minimum 6 characters)';
            break;
          case 'email-already-in-use':
            errorMessage = 'Email is already registered';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email format';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Email/password accounts are not enabled';
            break;
          case 'network-request-failed':
            errorMessage = 'Network error. Please check your connection';
            break;
          default:
            errorMessage = 'Registration failed: ${e.message}';
        }
      }
      
      print('User-friendly error message: $errorMessage');
      throw Exception(errorMessage);
    }
  }

  /// Mencari email pengguna berdasarkan username (case-insensitive)
  static Future<String?> getEmailByUsername(String username) async {
    final clean = username.trim().toLowerCase();
    if (clean.isEmpty) return null;

    try {
      // 1. Cek pada username_lowercase
      var snap = await _firestore
          .collection('users')
          .where('username_lowercase', isEqualTo: clean)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        // 2. Fallback cek username asli
        snap = await _firestore
            .collection('users')
            .where('username', isEqualTo: username.trim())
            .limit(1)
            .get();
      }

      if (snap.docs.isNotEmpty) {
        final email = snap.docs.first.data()['email']?.toString();
        if (email != null && email.isNotEmpty) {
          return email;
        }
      }
    } catch (e) {
      debugPrint('Error finding email for username $username: $e');
    }
    return null;
  }

  /// Login mendukung input Email maupun Username
  static Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    final input = email.trim();
    String targetEmail = input;

    // If input does not contain '@', look up email by username
    if (!input.contains('@')) {
      final foundEmail = await getEmailByUsername(input);
      if (foundEmail == null || foundEmail.isEmpty) {
        throw Exception('Username "$input" is not registered.');
      }
      targetEmail = foundEmail;
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: targetEmail,
        password: password,
      );

      // Ensure username_lowercase is saved for existing accounts
      if (credential.user != null) {
        try {
          final doc = await _firestore.collection('users').doc(credential.user!.uid).get();
          if (doc.exists && doc.data()?['username_lowercase'] == null) {
            final uName = doc.data()?['username']?.toString() ?? credential.user!.displayName ?? '';
            if (uName.isNotEmpty) {
              await _firestore.collection('users').doc(credential.user!.uid).set({
                'username_lowercase': uName.toLowerCase().trim(),
              }, SetOptions(merge: true));
            }
          }
        } catch (_) {}
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during login: ${e.code} - ${e.message}');
      if (e.code == 'user-not-found') {
        throw Exception('Account not found. Please check your email or username.');
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Incorrect password. Please try again.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email format.');
      } else if (e.code == 'user-disabled') {
        throw Exception('This account has been disabled.');
      } else if (e.code == 'too-many-requests') {
        throw Exception('Too many failed attempts. Please try again later.');
      } else {
        throw Exception(e.message ?? 'Login failed. Please check your credentials.');
      }
    } catch (e) {
      debugPrint('Error during login: $e');
      rethrow;
    }
  }

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return null;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'username': userCredential.user!.displayName ?? 'No Name',
          'email': userCredential.user!.email,
          'avatar': userCredential.user!.photoURL,
          'phone': userCredential.user!.phoneNumber,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      return userCredential;
    } catch (e) {
      print('Official Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Cek apakah username sudah dipakai (case-insensitive)
  static Future<void> completeRegistrationAfterVerification(User user) async {
    try {
      final pendingDoc = await _firestore.collection('pending_registrations').doc(user.uid).get();
      Map<String, dynamic> userData = {};
      if (pendingDoc.exists) {
        userData = pendingDoc.data() ?? {};
      }

      final username = userData['username'] ?? user.displayName ?? 'User';
      final cleanUsername = username.toString().trim();

      // Buat akun resmi di collection 'users' HANYA setelah email terverifikasi
      await _firestore.collection('users').doc(user.uid).set({
        'username': cleanUsername,
        'username_lowercase': cleanUsername.toLowerCase(),
        'email': user.email?.trim().toLowerCase() ?? '',
        'email_verified': true,
        'avatar': userData['avatar'],
        'phone': userData['phone'],
        'created_at': userData['created_at'] ?? FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Hapus data sementara di pending_registrations
      try {
        await _firestore.collection('pending_registrations').doc(user.uid).delete();
      } catch (_) {}

      // Sinkronisasi FCM token pengguna terverifikasi secara instan
      NotificationService.syncUserFCMToken();

      debugPrint('Account officially created in users collection for verified user: ${user.uid}');
    } catch (e) {
      debugPrint('Error completing registration: $e');
    }
  }

  static Future<void> deleteUnverifiedAccount(User user) async {
    try {
      final uid = user.uid;
      // 1. Hapus dari pending_registrations
      try {
        await _firestore.collection('pending_registrations').doc(uid).delete();
      } catch (_) {}

      // 2. Hapus dari users jika sempat terbuat
      try {
        await _firestore.collection('users').doc(uid).delete();
      } catch (_) {}

      // 3. Hapus akun dari Firebase Authentication
      await user.delete();
      debugPrint('Successfully deleted unverified user from Auth & Firestore: $uid');
    } catch (e) {
      debugPrint('Error deleting unverified user: $e');
      try {
        await _auth.signOut();
      } catch (_) {}
    }
  }

  static Future<bool> isUsernameTaken(String username, {String? excludeUserId}) async {
    final clean = username.trim().toLowerCase();
    if (clean.isEmpty) return false;

    try {
      debugPrint('Checking username availability for: $clean');

      // 1. Cek pada username_lowercase (case-insensitive)
      final snapLower = await _firestore
          .collection('users')
          .where('username_lowercase', isEqualTo: clean)
          .limit(2)
          .get();

      for (var doc in snapLower.docs) {
        if (excludeUserId != null && doc.id == excludeUserId) continue;
        return true;
      }

      // 2. Fallback cek username asli jika ada dokumen lama tanpa username_lowercase
      final snapExact = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .limit(2)
          .get();

      for (var doc in snapExact.docs) {
        if (excludeUserId != null && doc.id == excludeUserId) continue;
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("Error checking username: $e");
      return false;
    }
  }

  static Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    final userId = getCurrentUserId();
    if (userId == null) return false;

    // If username is changed, validate whether it is already taken
    if (data.containsKey('username')) {
      final newUsername = data['username']?.toString().trim() ?? '';
      if (newUsername.isNotEmpty) {
        final isTaken = await isUsernameTaken(newUsername, excludeUserId: userId);
        if (isTaken) {
          throw Exception('Username "$newUsername" is already taken by another user.');
        }
        data['username'] = newUsername;
        data['username_lowercase'] = newUsername.toLowerCase();
      }
    }

    try {
      data['updated_at'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).update(data);
      return true;
    } catch (e) {
      debugPrint("Error updating user profile: $e");
      rethrow;
    }
  }

  static Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
      await _auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('avatar_path');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  static Future<void> likeProduct(String productId) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    final userDocRef = _firestore.collection('users').doc(userId);
    await userDocRef.update({
      'liked_products': FieldValue.arrayUnion([productId])
    });
  }

  static Future<void> unlikeProduct(String productId) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    final userDocRef = _firestore.collection('users').doc(userId);
    await userDocRef.update({
      'liked_products': FieldValue.arrayRemove([productId])
    });
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc =
        await _firestore.collection('users').doc(user.uid).get();
        List<String> providerIds = user.providerData.map((userInfo) => userInfo.providerId).toList();

        if (doc.exists) {
          Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
          
          // Read premium status from Firestore or fallback to local SharedPreferences
          bool isPremium = userData['is_premium'] ?? false;
          String? tier = userData['subscription_tier']?.toString();
          if (!isPremium) {
            try {
              final prefs = await SharedPreferences.getInstance();
              isPremium = prefs.getBool('is_premium_${user.uid}') ?? false;
              tier ??= prefs.getString('subscription_tier_${user.uid}');
            } catch (_) {}
          }
          SimulatedOrderService.togglePremium(isPremium, tier: tier);

          // Determine avatar cleanly:
          // 1. If Firestore has a valid remote URL or Base64 string, use it.
          String? avatar = userData['avatar']?.toString();
          // If it was an old local file path that no longer exists on disk, ignore it.
          if (avatar != null && !avatar.startsWith('http') && !avatar.startsWith('data:image')) {
            try {
              if (!File(avatar).existsSync()) {
                avatar = null;
              }
            } catch (_) {
              avatar = null;
            }
          }
          // 2. If null or empty, fallback to user's Google photoURL
          if (avatar == null || avatar.trim().isEmpty) {
            avatar = user.photoURL;
          }
          // 3. Fallback to cached local path in SharedPreferences if available
          if (avatar == null || avatar.trim().isEmpty) {
            try {
              final prefs = await SharedPreferences.getInstance();
              final localPath = prefs.getString('avatar_path_${user.uid}');
              if (localPath != null && File(localPath).existsSync()) {
                avatar = localPath;
              }
            } catch (_) {}
          }

          return {
            'id': user.uid,
            'email': user.email,
            'username': userData['username'] ?? user.displayName ?? 'No Name',
            'avatar': avatar,
            'phone': userData['phone'] ?? user.phoneNumber,
            'is_premium': isPremium,
            'created_at': userData['created_at'],
            'updated_at': userData['updated_at'],
            'liked_products': (userData['liked_products'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
            'providerIds': providerIds,
          };
        } else {
          // Document does not exist yet, let's auto-create it
          try {
            await _firestore.collection('users').doc(user.uid).set({
              'username': user.displayName ?? 'User',
              'email': user.email,
              'avatar': user.photoURL,
              'phone': user.phoneNumber,
              'created_at': FieldValue.serverTimestamp(),
              'updated_at': FieldValue.serverTimestamp(),
            });
          } catch (e) {
            print('Error auto-creating Firestore user document: $e');
          }
          return {
            'id': user.uid,
            'email': user.email,
            'username': user.displayName ?? 'User',
            'avatar': user.photoURL,
            'phone': user.phoneNumber,
            'created_at': Timestamp.now(),
            'updated_at': Timestamp.now(),
            'liked_products': <String>[],
            'providerIds': providerIds,
          };
        }
      }
      
      // High-fidelity mock user profile for simulation
      print('Firebase user is null. Returning mock user details.');
      return {
        'id': 'mock_user_123',
        'email': 'tes123@gmail.com',
        'username': 'Ardli',
        'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        'phone': '+628123456789',
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
        'liked_products': <String>[],
        'providerIds': ['password'],
      };
    } catch (e) {
      print('Error getting current user: $e. Returning mock user.');
      return {
        'id': 'mock_user_123',
        'email': 'tes123@gmail.com',
        'username': 'Ardli',
        'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        'phone': '+628123456789',
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
        'liked_products': <String>[],
        'providerIds': ['password'],
      };
    }
  }

  static Future<String?> uploadAvatar(dynamic avatarFile) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      if (kIsWeb) {
        // For web, we'll just return a placeholder URL without importing dart:html
        return 'https://via.placeholder.com/150';
      } else {
        // Mobile implementation
        final File file = (avatarFile is File) ? avatarFile : File(avatarFile.toString());
        if (!file.existsSync()) {
          print('Avatar file does not exist on disk: ${file.path}');
          return null;
        }

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('avatar_path_${user.uid}', file.path);
        } catch (_) {}

        try {
          print('Attempting to upload avatar to Firebase Storage...');
          final snapshot = await _storage
              .ref('avatar_${user.uid}_${DateTime.now().millisecondsSinceEpoch}')
              .putFile(file);
          
          String downloadUrl = await snapshot.ref.getDownloadURL();
          print('Firebase Storage upload successful: $downloadUrl');
          
          await _firestore.collection('users').doc(user.uid).update({
            'avatar': downloadUrl,
            'updated_at': FieldValue.serverTimestamp(),
          });

          // Clean up any old local path from SharedPreferences
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('avatar_path_${user.uid}');
          } catch (_) {}

          return downloadUrl;
        } catch (storageError) {
          print('Firebase Storage unavailable: $storageError. Falling back to compressed Base64 in Firestore.');
          
          try {
            final bytes = await file.readAsBytes();
            
            // Limit to 500 KB to be strictly safe within Firestore 1 MB document limit
            if (bytes.length > 500 * 1024) {
              print('Image size is too large for Firestore Base64: ${bytes.length} bytes (Limit: 500 KB)');
              return null;
            }

            String base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
            
            await _firestore.collection('users').doc(user.uid).update({
              'avatar': base64Image,
              'updated_at': FieldValue.serverTimestamp(),
            });
            print('Base64 avatar successfully saved to Firestore! Size: ${bytes.length} bytes');

            // Clean up any old local path from SharedPreferences
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('avatar_path_${user.uid}');
            } catch (_) {}

            return base64Image;
          } catch (e) {
            print('Failed to save Base64 avatar to Firestore: $e');
            return null;
          }
        }
      }
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }

  static Future<bool> resetAvatarToDefault() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      // Revert to Google's photoURL if present, otherwise set to empty string
      final defaultAvatar = user.photoURL ?? '';
      await _firestore.collection('users').doc(user.uid).update({
        'avatar': defaultAvatar,
        'updated_at': FieldValue.serverTimestamp(),
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('avatar_path_${user.uid}');
      } catch (_) {}

      print('Avatar successfully reset to account default (${defaultAvatar.isNotEmpty ? "Google photo" : "No photo"})');
      return true;
    } catch (e) {
      print('Error resetting avatar to default: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllCourses() async {
    try {
      QuerySnapshot querySnapshot =
      await _firestore
          .collection('courses')
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      print('Error getting courses: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getCourseById(String courseId) async {
    try {
      DocumentSnapshot doc =
      await _firestore.collection('courses').doc(courseId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }
      return null;
    } catch (e) {
      print('Error getting course: $e');
      return null;
    }
  }

  static Future<bool> enrollInCourse(String courseId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('enrollments')
          .doc('${user.uid}_$courseId')
          .set({
        'user_id': user.uid,
        'course_id': courseId,
        'status': 'in_progress',
        'progress': 0,
        'enrolled_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error enrolling in course: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getCourseProgress(
      String courseId,
      ) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot doc =
      await _firestore
          .collection('enrollments')
          .doc('${user.uid}_$courseId')
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }
      return null;
    } catch (e) {
      print('Error getting course progress: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      QuerySnapshot querySnapshot =
      await _firestore
          .collection('products')
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getProductById(String productId) async {
    try {
      DocumentSnapshot doc =
      await _firestore.collection('products').doc(productId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllArticles() async {
    try {
      QuerySnapshot querySnapshot =
      await _firestore
          .collection('articles')
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      print('Error getting articles: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getArticleById(String articleId) async {
    try {
      DocumentSnapshot doc =
      await _firestore.collection('articles').doc(articleId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }
      return null;
    } catch (e) {
      print('Error getting article: $e');
      return null;
    }
  }

  static bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  static Future<bool> updatePremiumStatus(
    bool value, {
    String? tierName,
    String? duration,
  }) async {
    try {
      User? user = _auth.currentUser;
      final prefs = await SharedPreferences.getInstance();

      final now = DateTime.now();
      DateTime activeUntil = now.add(const Duration(days: 30));
      if (duration != null) {
        if (duration.contains('3')) {
          activeUntil = now.add(const Duration(days: 90));
        } else if (duration.contains('6')) {
          activeUntil = now.add(const Duration(days: 180));
        } else if (duration.contains('12') || duration.toLowerCase().contains('year')) {
          activeUntil = now.add(const Duration(days: 365));
        }
      }

      final tier = tierName ?? 'Queen Tier';
      final dur = duration ?? '6 Month';

      // 1. Immediately update in-memory status & broadcast stream so all screens unlock with ZERO delay!
      SimulatedOrderService.togglePremium(value, tier: tier);

      if (user != null) {
        // 2. Immediately cache in SharedPreferences
        await prefs.setBool('is_premium_${user.uid}', value);
        await prefs.setString('subscription_tier_${user.uid}', tier);
        await prefs.setString('subscription_active_until_${user.uid}', activeUntil.toIso8601String());

        final updateData = {
          'is_premium': value,
          'subscription_tier': tier,
          'subscription_duration': dur,
          'subscription_active_until': Timestamp.fromDate(activeUntil),
          'updated_at': FieldValue.serverTimestamp(),
        };

        // 3. Persist to Firestore asynchronously
        try {
          await _firestore.collection('users').doc(user.uid).update(updateData);
        } catch (firestoreError) {
          print('Error updating premium status in firestore: $firestoreError');
          await _firestore.collection('users').doc(user.uid).set(updateData, SetOptions(merge: true));
        }
      } else {
        // Fallback for guest testing
        await prefs.setBool('is_premium_local', value);
        await prefs.setString('subscription_tier_local', tier);
        await prefs.setString('subscription_active_until_local', activeUntil.toIso8601String());
      }

      return true;
    } catch (e) {
      print('Error updating premium status: $e');
      return false;
    }
  }
}

