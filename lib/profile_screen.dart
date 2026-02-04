import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';
import 'subscription_screen.dart';
import 'package:provider/provider.dart';
import 'package:sentient/liked_products_provider.dart';
import 'edit_profile_sheet.dart';
import 'account_info_sheet.dart';
import 'language_service.dart';

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
  Map<String, dynamic>? user;
  bool _loading = true;
  String? _error;
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final lang = await LanguageService.getCurrentLanguage();
    print('DEBUG: Loaded language: $lang');
    if (mounted) {
      setState(() {
        _currentLanguage = lang;
        print('DEBUG: Set current language to: $_currentLanguage');
      });
    }
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
              _buildAccountSection(),
              const SizedBox(height: 24),
              _buildPreferencesSection(),
              const SizedBox(height: 24),
              _buildSupportSection(),
              const SizedBox(height: 24),
              _buildLogoutSection(),
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
            Image.asset('assets/images/img_logo.png', height: 60, width: 60, errorBuilder: (c, e, s) => const Icon(Icons.workspace_premium, color: Colors.white, size: 60))
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return _buildSection(
      title: 'Account',
      icon: Icons.person,
      items: [
        _buildMenuItem(
          icon: Icons.person_outline,
          title: 'Account Information',
          subtitle: 'View your account details',
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
        _buildMenuItem(
          icon: Icons.edit_outlined,
          title: 'Edit Profile',
          subtitle: 'Update your profile information',
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
        ),
        _buildMenuItem(
          icon: Icons.lock_outline,
          title: 'Security',
          subtitle: 'Password and security settings',
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
          hasDivider: false,
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return _buildSection(
      title: 'Preferences',
      icon: Icons.settings,
      items: [
        _buildMenuItem(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Manage notification preferences',
          onTap: () => _showNotificationSettings(),
        ),
        _buildMenuItem(
          icon: Icons.language_outlined,
          title: 'Language',
          subtitle: 'Change app language',
          onTap: () => _showLanguageDialog(),
        ),
        _buildMenuItem(
          icon: Icons.workspace_premium_outlined,
          title: 'My Subscription',
          subtitle: 'View and manage subscription',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionScreen()));
          },
          hasDivider: false,
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _buildSection(
      title: 'Support',
      icon: Icons.help,
      items: [
        _buildMenuItem(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          subtitle: 'Read our privacy policy',
          onTap: () => _showPrivacyPolicy(),
        ),
        _buildMenuItem(
          icon: Icons.help_outline,
          title: 'Help & Support',
          subtitle: 'Get help and support',
          onTap: () => _showHelpSupport(),
        ),
        _buildMenuItem(
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'Learn more about Sentient Apps',
          onTap: () => _showAbout(),
          hasDivider: false,
        ),
      ],
    );
  }

  Widget _buildLogoutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          onTap: () => _showLogoutDialog(),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.logout, color: Colors.red, size: 20),
          ),
          title: Text(
            'Logout',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          subtitle: Text(
            'Sign out from your account',
            style: TextStyle(
              color: Colors.red.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.red.withOpacity(0.5),
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kPrimaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: kPrimaryBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kDarkBlue,
                    ),
                  ),
                ],
              ),
            ),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool hasDivider = true,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            onTap: onTap,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kPrimaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: kPrimaryBlue, size: 20),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: kDarkBlue,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                color: kDarkBlue.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: kDarkBlue.withOpacity(0.5),
              size: 16,
            ),
          ),
        ),
        if (hasDivider)
          Padding(
            padding: const EdgeInsets.only(left: 72.0),
            child: Divider(height: 1, color: kLightBlue.withOpacity(0.3)),
          ),
      ],
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LanguageService.translate('notification_settings', languageCode: _currentLanguage)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text(LanguageService.translate('push_notifications', languageCode: _currentLanguage)),
              subtitle: Text(LanguageService.translate('receive_push_notifications', languageCode: _currentLanguage)),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text(LanguageService.translate('email_notifications', languageCode: _currentLanguage)),
              subtitle: Text(LanguageService.translate('receive_email_updates', languageCode: _currentLanguage)),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text(LanguageService.translate('course_updates', languageCode: _currentLanguage)),
              subtitle: Text(LanguageService.translate('get_notified_about_new_courses', languageCode: _currentLanguage)),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LanguageService.translate('cancel', languageCode: _currentLanguage)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings saved')),
              );
            },
            child: Text(LanguageService.translate('save', languageCode: _currentLanguage)),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() async {
    final currentLanguage = await LanguageService.getCurrentLanguage();
    print('DEBUG: Current language in dialog: $currentLanguage');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LanguageService.translate('select_language', languageCode: _currentLanguage)),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: LanguageService.getAvailableLanguages().map((lang) {
                return RadioListTile<String>(
                  title: Text(lang['name']!),
                  value: lang['code']!,
                  groupValue: currentLanguage,
                  onChanged: (String? value) async {
                    if (value != null) {
                      print('DEBUG: User selected language: $value');
                      await LanguageService.setLanguage(value);
                      print('DEBUG: Language saved to storage: $value');
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${LanguageService.translate('language_changed', languageCode: value)} ${lang['name']}'),
                        ),
                      );
                      // Refresh the screen to update language
                      if (mounted) {
                        setState(() {
                          _currentLanguage = value;
                          print('DEBUG: Updated UI language to: $_currentLanguage');
                        });
                        // Force rebuild of entire widget
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {});
                          }
                        });
                      }
                    }
                  },
                );
              }).toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LanguageService.translate('cancel', languageCode: _currentLanguage)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LanguageService.translate('privacy_policy', languageCode: _currentLanguage)),
        content: SingleChildScrollView(
          child: Text(
            LanguageService.translate('privacy_policy_content', languageCode: _currentLanguage),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LanguageService.translate('cancel', languageCode: _currentLanguage)),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LanguageService.translate('help_support', languageCode: _currentLanguage)),
        content: Text(
          LanguageService.translate('help_support_content', languageCode: _currentLanguage),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LanguageService.translate('cancel', languageCode: _currentLanguage)),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.extension, color: kPrimaryBlue),
            const SizedBox(width: 8),
            Text(LanguageService.translate('about', languageCode: _currentLanguage)),
          ],
        ),
        content: Text(
          LanguageService.translate('about_content', languageCode: _currentLanguage),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LanguageService.translate('cancel', languageCode: _currentLanguage)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
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
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

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
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Change Password',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (widget.isSocialLogin)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are logged in with a social account. Password change is not available.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Change Password'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Fungsi ubah password akan diimplementasikan di sini
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
