// File: lib/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart';

// Definisikan konstanta warna
const Color kDarkBlue = Color(0xFF000A26);
const Color kLightBlue = Color(0xFFA6C6D8);
const Color kVeryLightBlue = Color(0xFFD6E5F2);
const Color kPrimaryBlue = Color(0xFF0F52BA);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  Map<String, dynamic>? profile;
  bool _loading = true;
  String? _error;
  File? _profileImageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  // --- SEMUA FUNGSI LOGIKA (fetch, logout, pickImage) TIDAK DIUBAH ---
  Future<void> _fetchProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      setState(() {
        _error = 'Token tidak ditemukan. Silakan login ulang.';
        _loading = false;
      });
      return;
    }
    final result = await ApiService.getProfile(token);
    if (mounted) {
      setState(() {
        _loading = false;
        if (result != null && result['user'] != null) {
          user = result['user'];
        } else {
          _error = 'Gagal mengambil data profile.';
        }
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _profileImageFile = File(pickedFile.path);
      });
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        final avatarPath = await ApiService.uploadAvatar(
          token: token,
          avatar: _profileImageFile!,
        );
        if (avatarPath != null) {
          await _fetchProfile();
          // Simpan path lokal ke SharedPreferences
          await prefs.setString('avatar_path', _profileImageFile!.path);
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      }
    }
  }

  Widget _buildDrawer() {
    // ... (kode drawer tidak diubah)
    return Drawer(
      backgroundColor: const Color(0xFF07143B),
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF07143B)),
                margin: EdgeInsets.only(bottom: 0),
                padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(color: Colors.white24, height: 1, thickness: 1),
              ),
              const SizedBox(height: 18),
              _drawerMenuItem(
                Icons.notifications_none_rounded,
                'Notifications',
              ),
              const SizedBox(height: 10),
              _drawerMenuItem(Icons.language, 'Language'),
              const SizedBox(height: 10),
              _drawerMenuItem(
                Icons.credit_card,
                'Subscription & Billing',
                icon2: Icons.star,
                icon2Color: Color(0xFFF7B801),
              ),
              const SizedBox(height: 10),
              _drawerMenuItem(Icons.security, 'Privacy & Security'),
              const SizedBox(height: 10),
              _drawerMenuItem(Icons.help_outline, 'Help & Support'),
              const SizedBox(height: 10),
              _drawerMenuItem(
                Icons.info_outline,
                'About the App',
                italic: true,
              ),
              const SizedBox(height: 80),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A1128),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _logout,
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerMenuItem(
    IconData icon,
    String title, {
    IconData? icon2,
    Color? icon2Color,
    bool italic = false,
  }) {
    // ... (kode helper drawer tidak diubah)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          if (icon2 != null) ...[
            const SizedBox(width: 2),
            Icon(icon2, color: icon2Color ?? Colors.white, size: 16),
          ],
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // =======================================================================
  // ### FOKUS UTAMA: Perubahan pada `build` dan pembuatan `_buildProfileHeader` ###
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      backgroundColor: kVeryLightBlue, // Menggunakan warna dari konstanta
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Panggil widget header baru
                    _buildProfileHeader(),
                    const SizedBox(height: 24),

                    // Konten di bawah header tidak diubah
                    _buildSubscriptionCard(),
                    const SizedBox(height: 24),
                    _buildAccountSettings(),
                    const SizedBox(height: 32),
                    _buildLogoutButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
    );
  }

  // WIDGET BARU UNTUK HEADER PROFIL
  Widget _buildProfileHeader() {
    final double topPadding = MediaQuery.of(context).padding.top;

    ImageProvider? profileImage;
    if (_profileImageFile != null) {
      profileImage = FileImage(_profileImageFile!);
    } else if (profile?['avatar'] != null &&
        profile!['avatar'].toString().isNotEmpty) {
      final avatarUrl = profile!['avatar'].toString();
      profileImage = NetworkImage(
        avatarUrl.startsWith('http')
            ? avatarUrl
            : 'http://${ApiService.serverIP}:${ApiService.serverPort}/storage/$avatarUrl',
      );
    }

    return Container(
      width: double.infinity,
      // Padding di dalam container utama
      padding: EdgeInsets.only(
        top: topPadding, // Jarak aman dari status bar
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF000A26), Color(0xFF0F52BA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          // Baris untuk Tombol Menu
          Row(
            children: [
              Builder(
                builder:
                    (context) => IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
              ),
            ],
          ),
          // Avatar, Nama, dan Email
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(60),
                child: Tooltip(
                  message: 'Ganti foto profil',
                  child:
                      _profileImageFile != null
                          ? CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor: kLightBlue,
                              backgroundImage: FileImage(_profileImageFile!),
                            ),
                          )
                          : ((profile?.containsKey('avatar') == true &&
                                  (profile?['avatar'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                              ? (() {
                                final avatarPath =
                                    (profile?['avatar'] ?? '').toString();
                                if (avatarPath.startsWith('http') ||
                                    avatarPath.startsWith('https')) {
                                  return CircleAvatar(
                                    radius: 55,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 52,
                                      backgroundColor: kLightBlue,
                                      backgroundImage: NetworkImage(avatarPath),
                                    ),
                                  );
                                } else {
                                  return CircleAvatar(
                                    radius: 55,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 52,
                                      backgroundColor: kLightBlue,
                                      backgroundImage: FileImage(
                                        File(avatarPath),
                                      ),
                                    ),
                                  );
                                }
                              })()
                              : CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 52,
                                  backgroundColor: kLightBlue,
                                  child: const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: kDarkBlue,
                                  ),
                                ),
                              )),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.edit, size: 20, color: kPrimaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user?['username'] ?? 'Username',
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?['email'] ?? 'email@example.com',
            style: TextStyle(
              fontSize: 15,
              color: kVeryLightBlue.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget helper untuk merapikan kode build ---
  Widget _buildSubscriptionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD6E9FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFB3D6F6)),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: const [
                Icon(
                  Icons.workspace_premium,
                  color: Color(0xFF3576F6),
                  size: 28,
                ),
                SizedBox(width: 8),
                Text(
                  'Premium',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF07143B),
                  ),
                ),
              ],
            ),
            // ... (sisa konten kartu subscription tidak diubah)
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.calendar_today, size: 18, color: Color(0xFF3576F6)),
                SizedBox(width: 4),
                Text(
                  'Active until: June 20, 2025',
                  style: TextStyle(fontSize: 13, color: Color(0xFF07143B)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.auto_awesome, color: Color(0xFFF7B801), size: 20),
                SizedBox(width: 4),
                Text(
                  'Benefits:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF07143B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(left: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Unlimited access to all courses',
                    style: TextStyle(color: Color(0xFF07143B)),
                  ),
                  Text(
                    '• Exclusive articles',
                    style: TextStyle(color: Color(0xFF07143B)),
                  ),
                  Text(
                    '• Special discounts in the shop',
                    style: TextStyle(color: Color(0xFF07143B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3576F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {},
                icon: const Icon(Icons.flash_on, color: Colors.white),
                label: const Text(
                  'Renew Subscription',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(
                Icons.person_outline,
                color: Color(0xFF3576F6),
              ),
              title: const Text('Account Information'),
              onTap: () {},
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Color(0xFF3576F6)),
              title: const Text('Security'),
              onTap: () {},
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF3576F6)),
              title: const Text('Edit Profile'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text(
            'LOGOUT',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0A1128),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: const Color(0xFF0A1128).withOpacity(0.18),
          ),
          onPressed: _logout,
        ),
      ),
    );
  }
}
