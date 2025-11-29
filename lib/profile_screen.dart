import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'subscription_screen.dart';
import 'package:provider/provider.dart';
import 'package:sentient/liked_products_provider.dart';
import 'edit_profile_sheet.dart';
import 'account_info_sheet.dart';

const Color kDarkBlue = Color(0xFF000A26);
const Color kLightBlue = Color(0xFFA6C6D8);
const Color kVeryLightBlue = Color(0xFFD6E5F2);
const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kHeaderGradientStart = Color(0xFF000A26);
const Color kHeaderGradientMid = Color(0xFF001759);
const Color kHeaderGradientEnd = Color(0xFF00207B);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic>? user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final result = await FirebaseService.getCurrentUser();

    if (mounted) {
      setState(() {
        _loading = false;
        if (result != null) {
          user = result;
        } else {
          _error = 'Gagal mengambil data profile.';
        }
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseService.logout();
    if (mounted) {
      await Provider.of<LikedProductsProvider>(context, listen: false).syncLikesWithFirebase();
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  void _showProfilePicture() {
    final avatarUrl = user?['avatar'];
    if (avatarUrl == null || avatarUrl.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No profile picture to display.')),
      );
      return;
    }

    final imageProvider = NetworkImage(avatarUrl);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      backgroundColor: kVeryLightBlue,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
        onRefresh: _fetchProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 24),
              _buildSubscriptionCard(),
              const SizedBox(height: 24),
              _buildAccountSettings(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final double topPadding = MediaQuery.of(context).padding.top;
    final avatarUrl = user?['avatar'];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kHeaderGradientStart, kHeaderGradientMid, kHeaderGradientEnd],
          stops: [0.0, 0.66, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _showProfilePicture,
            borderRadius: BorderRadius.circular(60),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 52,
                backgroundColor: kLightBlue,
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? const Icon(Icons.person, size: 60, color: kDarkBlue)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user?['username'] ?? 'Username',
            style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            user?['email'] ?? 'email@example.com',
            style: TextStyle(fontSize: 15, color: kVeryLightBlue.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: kPrimaryBlue,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Upgrade Subscription', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Enjoy all the benefits', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: kPrimaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionScreen()));
                    },
                    child: const Text('Upgrade Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Image.asset('assets/images/ic_gem.png', height: 60, width: 60, errorBuilder: (c, e, s) => const Icon(Icons.workspace_premium, color: Colors.white, size: 60))
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(color: kLightBlue.withOpacity(0.4), borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: Icons.person_outline,
                title: 'Account Information',
                onTap: () {
                  if (user != null) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AccountInfoSheet(userData: user!),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User data is not available.')),
                    );
                  }
                },
              ),
              _buildSettingsItem(
                icon: Icons.lock_outline,
                title: 'Security',
                onTap: () {
                  List<String> providerIds = List<String>.from(user?['providerIds'] ?? []);
                  bool isSocial = providerIds.contains('google.com') || providerIds.contains('facebook.com');

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Padding(
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: ChangePasswordSheet(isSocialLogin: isSocial),
                    ),
                  );
                },
              ),
              _buildSettingsItem(
                icon: Icons.edit_outlined,
                title: 'Edit Profile',
                onTap: () async {
                  final result = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Padding(
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: const EditProfileSheet(),
                    ),
                  );
                  if (result == true) {
                    _fetchProfile();
                  }
                },
                hasDivider: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({required IconData icon, required String title, required VoidCallback onTap, bool hasDivider = true}) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            onTap: onTap,
            leading: Icon(icon, color: kPrimaryBlue),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: kDarkBlue)),
            trailing: const Icon(Icons.arrow_forward_ios, color: kPrimaryBlue, size: 16),
          ),
        ),
        if (hasDivider)
          Padding(
            padding: const EdgeInsets.only(left: 72.0),
            child: Divider(height: 1, color: kLightBlue.withOpacity(0.8)),
          ),
      ],
    );
  }

  Widget _buildDrawer() {
    final double topPadding = MediaQuery.of(context).padding.top;
    return Drawer(
      backgroundColor: const Color(0xFF07143B),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 20, 16, 16),
            child: const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(color: Colors.white24, height: 1, thickness: 1),
          ),
          const SizedBox(height: 18),
          _drawerMenuItem(Icons.notifications_none_rounded, 'Notifications'),
          const SizedBox(height: 10),
          _drawerMenuItem(Icons.language, 'Language'),
          const SizedBox(height: 10),
          _drawerMenuItem(Icons.credit_card, 'Subscription & Billing'),
          const SizedBox(height: 10),
          _drawerMenuItem(Icons.security, 'Privacy & Security'),
          const SizedBox(height: 10),
          _drawerMenuItem(Icons.help_outline, 'Help & Support'),
          const SizedBox(height: 10),
          _drawerMenuItem(Icons.info_outline, 'About the App', italic: true),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1128),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _logout,
              child: const Text('Logout', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _drawerMenuItem(IconData icon, String title, {bool italic = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
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
}

class ChangePasswordSheet extends StatefulWidget {
  final bool isSocialLogin;
  const ChangePasswordSheet({super.key, required this.isSocialLogin});

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: User not found or has no email.'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
      return;
    }

    final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text
    );

    try {
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'An error occurred. Please try again.';
        if (e.code == 'wrong-password') {
          errorMessage = 'The current password you entered is incorrect.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'The new password is too weak.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF00207B),
            Color(0xFF001759),
            Color(0xFF000A26),
          ],
          stops: [0.0, 0.33, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(25.0), topRight: Radius.circular(25.0)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Text('Security', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white24, height: 32),
            widget.isSocialLogin
                ? _buildSocialLoginMessage()
                : _buildChangePasswordForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildChangePasswordForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Change password', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Your password must be at least 6 characters.', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
          const SizedBox(height: 32),
          _buildPasswordField(
            controller: _currentPasswordController,
            hintText: 'Current password',
            obscureText: _obscureCurrent,
            toggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
            validator: (v) => (v == null || v.isEmpty) ? 'Please enter your current password.' : null,
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _newPasswordController,
            hintText: 'New password',
            obscureText: _obscureNew,
            toggleObscure: () => setState(() => _obscureNew = !_obscureNew),
            validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters.' : null,
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _confirmPasswordController,
            hintText: 'Re-type new password',
            obscureText: _obscureConfirm,
            toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
            validator: (v) => (v != _newPasswordController.text) ? 'Passwords do not match.' : null,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: _isLoading ? null : _changePassword,
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text('Confirm', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLoginMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: const Center(
        child: Text(
          'Your password is managed by your social account provider (Google/Facebook) and cannot be changed here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordField({required TextEditingController controller, required String hintText, required bool obscureText, required VoidCallback toggleObscure, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
          onPressed: toggleObscure,
        ),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimaryBlue, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
      ),
    );
  }
}