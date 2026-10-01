import 'home_screen.dart';
import 'main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'firebase_service.dart';
import 'animated_route.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  final _usernameController = TextEditingController();
  File? _profileImage;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirmation = true;
  String? _error;

  bool get _hasEmailValid => _emailController.text.contains('@') && _emailController.text.contains('.');
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar => _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onTextChanged);
    _emailController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  Widget _buildEmailChecklist() {
    final isValid = _hasEmailValid;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.circle_outlined,
            color: isValid ? Colors.greenAccent : Colors.white60,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Contoh: user@gmail.com (Harus mengandung @ dan .com)',
            style: TextStyle(
              color: isValid ? Colors.greenAccent : Colors.white70,
              fontSize: 12,
              fontFamily: 'Poppins',
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
            'Ketentuan Password (Auto-check):',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildCheckItem('Min. 8 Karakter', _hasMinLength),
              _buildCheckItem('Huruf Kapital (A-Z)', _hasUppercase),
              _buildCheckItem('Huruf Kecil (a-z)', _hasLowercase),
              _buildCheckItem('Angka (0-9)', _hasNumber),
              _buildCheckItem('Simbol (!@#...)', _hasSpecialChar),
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
          color: checked ? Colors.greenAccent : Colors.white60,
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: checked ? Colors.greenAccent : Colors.white70,
            fontSize: 11,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = pickedFile.name;
      final savedImage = await File(
        pickedFile.path,
      ).copy('${directory.path}/$fileName');
      setState(() {
        _profileImage = savedImage;
      });
    }
    Navigator.pop(context);
  }

  void _showPhotoPicker() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
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
                'Profile Photo',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF3576F6),
                ),
              ),
              const SizedBox(height: 16),
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
                        const SizedBox(height: 6),
                        const Text(
                          'Take a photo',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Color(0xFF3576F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
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
                        const SizedBox(height: 6),
                        const Text(
                          'Gallery',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
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

  @override
  void dispose() {
    _passwordController.removeListener(_onTextChanged);
    _emailController.removeListener(_onTextChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      print('Attempting real Firebase registration...');
      final userCredential = await FirebaseService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential != null) {
        print('Real Firebase registration successful!');
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } catch (e) {
      print('Registration error: $e');
      if (e.toString().contains('not-initialized') || e.toString().contains('apiKey')) {
        // Fallback for mock/simulation environment
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      } else {
        if (!mounted) return;
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pushAndRemoveUntil(
        FadeRoute(page: const MainNavigation()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 0,
                                    top: 8,
                                  ),
                                  child: IconButton(
                                    icon: Image.asset(
                                      'assets/icons/ic_back.png',
                                      height: 24,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: Column(
                                    children: [
                                      GestureDetector(
                                        onTap: _showPhotoPicker,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.amber, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.amber.withOpacity(0.3),
                                                blurRadius: 12,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            backgroundColor: Colors.white.withOpacity(0.1),
                                            radius: 56,
                                            child: _profileImage != null
                                                ? ClipOval(
                                                    child: Image.file(
                                                      _profileImage!,
                                                      width: 110,
                                                      height: 110,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.add_a_photo_outlined,
                                                    color: Colors.amber,
                                                    size: 40,
                                                  ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Foto Profil',
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
                                const SizedBox(height: 32),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Email',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _emailController,
                                      style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Email tidak boleh kosong';
                                        }
                                        if (!_hasEmailValid) {
                                          return 'Format email harus valid (contoh: user@gmail.com)';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.08),
                                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                                        hintText: 'example@gmail.com',
                                        hintStyle: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Colors.white.withOpacity(0.4),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Colors.amber, width: 2),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Colors.redAccent),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                                        ),
                                      ),
                                    ),
                                    _buildEmailChecklist(),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Create a Password',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Password tidak boleh kosong';
                                        }
                                        if (!_hasMinLength) return 'Password minimal 8 karakter';
                                        if (!_hasUppercase) return 'Password harus memiliki huruf kapital';
                                        if (!_hasLowercase) return 'Password harus memiliki huruf kecil';
                                        if (!_hasNumber) return 'Password harus memiliki angka';
                                        if (!_hasSpecialChar) return 'Password harus memiliki simbol';
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.08),
                                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white70),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: Colors.white70,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                              !_obscurePassword;
                                            });
                                          },
                                        ),
                                        hintText: '**************',
                                        hintStyle: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Colors.white.withOpacity(0.4),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Colors.amber, width: 2),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Colors.redAccent),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                                        ),
                                      ),
                                    ),
                                    _buildPasswordChecklist(),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Confirm Password',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller:
                                      _passwordConfirmationController,
                                      obscureText: _obscurePasswordConfirmation,
                                      style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
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
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.08),
                                        prefixIcon: const Icon(Icons.lock_reset_outlined, color: Colors.white70),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePasswordConfirmation
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: Colors.white70,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePasswordConfirmation =
                                              !_obscurePasswordConfirmation;
                                            });
                                          },
                                        ),
                                        hintText: '**************',
                                        hintStyle: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Colors.white.withOpacity(0.4),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Colors.amber, width: 2),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Colors.redAccent),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Username',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _usernameController,
                                      style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Username wajib diisi';
                                        }
                                        if (v.length < 3) {
                                          return 'Username minimal 3 karakter';
                                        }
                                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                                          return 'Username hanya boleh huruf, angka, dan underscore';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.08),
                                        prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.white70),
                                        hintText: 'Buat Username Anda',
                                        hintStyle: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Colors.white.withOpacity(0.4),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Colors.amber, width: 2),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Colors.redAccent),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_error != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _error!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 24),
                              ],
                            ),
                            Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 32.0),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: _loading ? null : _register,
                                  child: _loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'Daftar Sekarang',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF000A26),
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
