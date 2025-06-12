import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Konfigurasi server
  // static const String serverIP = '10.0.2.2'; // IP untuk Android Emulator
  static const String serverIP = '192.168.1.5'; // IP untuk device fisik
  static const int serverPort = 8000;
  static const String baseUrl = 'http://$serverIP:$serverPort/api';

  // Helper untuk menangani response
  static Map<String, dynamic>? _handleResponse(http.Response response) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data;
        } else {
          print('API Error: ${data['message']}');
          return null;
        }
      } else {
        print('API Error: ${response.statusCode}');
        print('Response body: ${response.body}');

        // Try to parse error message
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            print('Error message: ${errorData['message']}');
          }
        } catch (e) {
          print('Could not parse error message');
        }

        return null;
      }
    } catch (e) {
      print('Error parsing response: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
    File? avatar,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final result = _handleResponse(response);

      if (result != null && result['authorization']?['token'] != null) {
        // Simpan token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', result['authorization']['token']);
      }

      return result;
    } catch (e) {
      print('Error during register: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final result = _handleResponse(response);

      if (result != null && result['authorization']?['token'] != null) {
        // Simpan token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', result['authorization']['token']);
      }

      return result;
    } catch (e) {
      print('Error during login: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getProfile(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));
      print('PROFILE status: \\${response.statusCode}');
      print('PROFILE body: \\${response.body}');
      return _handleResponse(response);
    } catch (e) {
      print('Error during get profile: $e');
      return null;
    }
  }

  static Future<String?> uploadAvatar({
    required String token,
    required File avatar,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/avatar');
      var request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('avatar', avatar.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']?['avatar'];
      } else {
        print('Upload avatar failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error during upload avatar: $e');
      return null;
    }
  }

  // Tambahan method untuk logout
  static Future<bool> logout(String token) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/logout'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Hapus token
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        return true;
      }
      return false;
    } catch (e) {
      print('Error during logout: $e');
      return false;
    }
  }

  // Tambahan method untuk refresh token
  static Future<Map<String, dynamic>?> refreshToken(String token) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/refresh'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      final result = _handleResponse(response);

      if (result != null && result['authorization']?['token'] != null) {
        // Update token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', result['authorization']['token']);
      }

      return result;
    } catch (e) {
      print('Error during token refresh: $e');
      return null;
    }
  }

  // Ambil data course dari backend
  static Future<List<Map<String, dynamic>>> fetchCourses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/courses'));
      print('HTTP status: \\${response.statusCode}');
      print('HTTP body: \\${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('Gagal fetch courses: \\${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Network error: $e');
      return [];
    }
  }
}
