import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditional imports for web compatibility
import 'dart:html' as html;
import 'dart:typed_data' show Uint8List;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<UserCredential?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting to register user: $email, username: $username');
      
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      print('User created successfully: ${userCredential.user?.uid}');

      // Verifikasi email akan dikirim untuk production
      // await userCredential.user?.sendEmailVerification();

      // Save user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'avatar': null,
        'phone': null,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

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

  static Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error during login: $e');
      return null;
    }
  }

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
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
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: $e');
      return null;
    } catch (e) {
      print('Error during Google sign-in: $e');
      return null;
    }
  }

  static Future<bool> isUsernameTaken(String username) async {
    try {
      print('Checking username availability for: $username');
      
      final result = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      bool isTaken = result.docs.isNotEmpty;
      print('Username "$username" is taken: $isTaken');
      print('Found ${result.docs.length} documents');
      
      return isTaken;
    } catch (e) {
      print("Error checking username: $e");
      // Return false on error to allow registration
      // Better to allow duplicate username than block valid registration
      return false;
    }
  }

  static Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    final userId = getCurrentUserId();
    if (userId == null) return false;

    try {
      data['updated_at'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).update(data);
      return true;
    } catch (e) {
      print("Error updating user profile: $e");
      return false;
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
          return {
            'id': user.uid,
            'email': user.email,
            'username': userData['username'],
            'avatar': userData['avatar'],
            'phone': userData['phone'],
            'created_at': userData['created_at'],
            'updated_at': userData['updated_at'],
            'liked_products': (userData['liked_products'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
            'providerIds': providerIds,
          };
        }
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  static Future<String?> uploadAvatar(dynamic avatarFile) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      if (kIsWeb) {
        // Web implementation with FileReader
        final reader = html.FileReader();
        reader.readAsDataUrl(avatarFile);
        await reader.onLoad.first;
        
        // For web, we'll just return a placeholder URL
        return 'https://via.placeholder.com/150';
      } else {
        // Mobile implementation
        final file = File(avatarFile);
        final snapshot = await _storage
            .ref('avatar_${user.uid}_${DateTime.now().millisecondsSinceEpoch}')
            .putFile(file);
        
        String downloadUrl = await snapshot.ref.getDownloadURL();
        await _firestore.collection('users').doc(user.uid).update({
          'avatar': downloadUrl,
          'updated_at': FieldValue.serverTimestamp(),
        });

        return downloadUrl;
      }
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllCourses() async {
    try {
      QuerySnapshot querySnapshot =
      await _firestore
          .collection('courses')
          .orderBy('created_at', descending: true)
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
          .orderBy('created_at', descending: true)
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
          .orderBy('created_at', descending: true)
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
}