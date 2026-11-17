import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentient/core/services/firebase_service.dart';
import 'package:sentient/core/widgets/animated_route.dart';
import 'package:sentient/features/auth/login_screen.dart';
import 'package:sentient/features/auth/verify_email_screen.dart';
import 'package:sentient/main_navigation.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  final _usernameController = TextEditingController();

  File? _profileImage;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirmation = true;
  String? _error;

  // Validation getters
  bool get _hasEmailValid =>
      _emailController.text.contains('@') &&
      _emailController.text.contains('.');
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar =>
      _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onTextChanged);
    _emailController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onTextChanged);
    _emailController.removeListener(_onTextChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (pickedFile != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await File(
          pickedFile.path,
        ).copy('${directory.path}/$fileName');
        if (mounted) {
          setState(() {
            _profileImage = savedImage;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showPhotoPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: const Color(0xFFF5F2FF),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Profile Picture',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF3576F6),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.camera),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFE3D6FF),
                          radius: 32,
                          child: Image.asset(
                            'assets/icons/ic_take_photo.png',
                            height: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Take a Photo',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3576F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFE3D6FF),
                          radius: 32,
                          child: Image.asset(
                            'assets/icons/ic_add_gallery.png',
                            height: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Gallery',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3576F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9D9D9),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF3576F6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final username = _usernameController.text.trim();

      // Langsung panggil FirebaseService.register
      // Validasi ketersediaan username dilakukan otomatis di dalam register setelah sesi Auth aktif,
      // dan akan langsung di-rollback jika ternyata username sudah terpakai.
      final userCredential = await FirebaseService.register(
        username: username,
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        avatarFile: _profileImage,
      );

      if (userCredential != null) {
        debugPrint(
          'Firebase registration successful: ${userCredential.user?.uid}',
        );
      }

      // Do not fetch profile into UserProvider yet since email is pending verification

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        FadeRoute(page: const VerifyEmailScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Registration error: $e');
      if (e.toString().contains('not-initialized') ||
          e.toString().contains('apiKey')) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          FadeRoute(page: const MainNavigation()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        String cleanMessage = e.toString().replaceAll('Exception: ', '');
        if (cleanMessage.contains('permission-denied')) {
          cleanMessage =
              'Koneksi database ditolak. Pastikan izin Firestore Rules sudah di-publish.';
        } else if (cleanMessage.contains('network-request-failed')) {
          cleanMessage = 'Koneksi internet bermasalah. Periksa jaringan Anda.';
        }

        setState(() {
          _error = cleanMessage;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Widget _buildEmailChecklist() {
    final isValid = _hasEmailValid;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(
              isValid ? Icons.check_circle : Icons.circle_outlined,
              color: isValid ? const Color(0xFF3576F6) : Colors.white60,
              size: 15,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Example: user@gmail.com (Must contain @ and .com)',
              style: TextStyle(
                color: isValid ? const Color(0xFF3576F6) : Colors.white70,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordChecklist() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, left: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password Requirements (Auto-check):',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildCheckItem('Min. 8 Characters', _hasMinLength),
              _buildCheckItem('Uppercase (A-Z)', _hasUppercase),
              _buildCheckItem('Lowercase (a-z)', _hasLowercase),
              _buildCheckItem('Number (0-9)', _hasNumber),
              _buildCheckItem('Special Symbol (!@#...)', _hasSpecialChar),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String title, bool checked) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          checked ? Icons.check_circle : Icons.circle_outlined,
          color: checked ? const Color(0xFF3576F6) : Colors.white60,
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: checked ? const Color(0xFF3576F6) : Colors.white70,
            fontSize: 11,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000A26),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000A26),
              Color(0xFF001759),
              Color(0xFF001E73),
              Color(0xFF00258C),
            ],
            stops: [0.0, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Image.asset('assets/icons/ic_back.png', height: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 8),

                  // Header Title: Sign Up
                  const Center(
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3576F6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Profile Picture
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showPhotoPicker,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF3576F6),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF3576F6,
                                  ).withOpacity(0.35),
                                  blurRadius: 14,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              radius: 54,
                              child:
                                  _profileImage != null
                                      ? ClipOval(
                                        child: Image.file(
                                          _profileImage!,
                                          width: 108,
                                          height: 108,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                      : const Icon(
                                        Icons.add_a_photo_outlined,
                                        color: Color(0xFF3576F6),
                                        size: 38,
                                      ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Profile Picture',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Email Field
                  const Text(
                    'Email',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      color: Color(0xFF00258C),
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email cannot be empty';
                      }
                      if (!_hasEmailValid) {
                        return 'Please enter a valid email format (e.g. user@gmail.com)';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(
                        color: const Color(0xFF00258C).withOpacity(0.6),
                        fontFamily: 'Poppins',
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFE3F0FF),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/icons/ic_email.png',
                          height: 24,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF3576F6),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18.0,
                        horizontal: 20.0,
                      ),
                    ),
                  ),
                  _buildEmailChecklist(),
                  const SizedBox(height: 22),

                  // Create a Password Field
                  const Text(
                    'Create a Password',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                      color: Color(0xFF00258C),
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Password cannot be empty';
                      }
                      if (!_hasMinLength) {
                        return 'Password must be at least 8 characters';
                      }
                      if (!_hasUppercase) {
                        return 'Password must contain an uppercase letter';
                      }
                      if (!_hasLowercase) {
                        return 'Password must contain a lowercase letter';
                      }
                      if (!_hasNumber) {
                        return 'Password must contain a number';
                      }
                      if (!_hasSpecialChar) {
                        return 'Password must contain a special character';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: TextStyle(
                        color: const Color(0xFF00258C).withOpacity(0.6),
                        fontFamily: 'Poppins',
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFE3F0FF),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/icons/ic_password.png',
                          height: 24,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF3576F6).withOpacity(0.8),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF3576F6),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18.0,
                        horizontal: 20.0,
                      ),
                    ),
                  ),
                  _buildPasswordChecklist(),
                  const SizedBox(height: 22),

                  // Confirm Password Field
                  const Text(
                    'Confirm Password',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordConfirmationController,
                    obscureText: _obscurePasswordConfirmation,
                    style: const TextStyle(
                      color: Color(0xFF00258C),
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Confirm Password',
                      hintStyle: TextStyle(
                        color: const Color(0xFF00258C).withOpacity(0.6),
                        fontFamily: 'Poppins',
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFE3F0FF),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/icons/ic_password.png',
                          height: 24,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePasswordConfirmation
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF3576F6).withOpacity(0.8),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePasswordConfirmation =
                                !_obscurePasswordConfirmation;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF3576F6),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18.0,
                        horizontal: 20.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Username Field
                  const Text(
                    'Username',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameController,
                    style: const TextStyle(
                      color: Color(0xFF00258C),
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Username cannot be empty';
                      }
                      if (v.trim().length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                        return 'Username can only contain letters, numbers, and underscores';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Username',
                      hintStyle: TextStyle(
                        color: const Color(0xFF00258C).withOpacity(0.6),
                        fontFamily: 'Poppins',
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFE3F0FF),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/icons/ic_user.png',
                          height: 24,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF3576F6),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18.0,
                        horizontal: 20.0,
                      ),
                    ),
                  ),

                  // Error Display
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(top: 18),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1128),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      onPressed: _loading ? null : _register,
                      child:
                          _loading
                              ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                              : const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Back to Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeScaleRoute(page: const LoginScreen()),
                          );
                        },
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            color: Color(0xFF3576F6),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
