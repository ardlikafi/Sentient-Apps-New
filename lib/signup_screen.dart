import 'home_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'api_service.dart';
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
      final result = await ApiService.register(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmationController.text,
        avatar: _profileImage,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
            'Koneksi ke server timeout. Pastikan server berjalan dan dapat diakses.',
          );
        },
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      if (result != null) {
        if (result['status'] == 'success') {
          // Tampilkan snackbar sukses
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrasi berhasil! Silakan login.'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate ke login
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          setState(() {
            _error =
                result['message'] ?? 'Registrasi gagal. Silakan coba lagi.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_error ?? 'Terjadi kesalahan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _error = 'Terjadi kesalahan pada server. Silakan coba lagi.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error ?? 'Terjadi kesalahan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on TimeoutException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Koneksi timeout'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Terjadi kesalahan: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_error ?? 'Terjadi kesalahan'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error during register: $e');
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Proses pendaftaran
      // _profileImage berisi file foto profil jika ada
      Navigator.of(context).pushAndRemoveUntil(
        FadeRoute(page: const HomeScreen()),
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
                      padding: const EdgeInsets.symmetric(horizontal: 36.0),
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
                                      height: 32,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Profile Photo
                                Center(
                                  child: Column(
                                    children: [
                                      GestureDetector(
                                        onTap: _showPhotoPicker,
                                        child: CircleAvatar(
                                          backgroundColor: const Color(
                                            0xFFE3D6FF,
                                          ),
                                          radius: 56,
                                          child:
                                              _profileImage != null
                                                  ? ClipOval(
                                                    child: Image.file(
                                                      _profileImage!,
                                                      width: 100,
                                                      height: 100,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                  : Image.asset(
                                                    'assets/icons/ic_add_photo.png',
                                                    height: 72,
                                                  ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Profile Photo',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF3576F6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Email
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Email',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF3576F6),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _emailController,
                                      validator:
                                          (v) =>
                                              v == null || !v.contains('@')
                                                  ? 'Email tidak valid'
                                                  : null,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: const Color(0xFFE3F0FF),
                                        prefixIcon: const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Image(
                                            image: AssetImage(
                                              'assets/icons/ic_email.png',
                                            ),
                                            height: 24,
                                          ),
                                        ),
                                        hintText: 'example@gmail.com',
                                        hintStyle: const TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Color(0xFF3576F6),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Password
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Create a Password',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF3576F6),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      validator:
                                          (v) =>
                                              v == null || v.length < 6
                                                  ? 'Password minimal 6 karakter'
                                                  : null,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: const Color(0xFFE3F0FF),
                                        prefixIcon: const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Image(
                                            image: AssetImage(
                                              'assets/icons/ic_password.png',
                                            ),
                                            height: 24,
                                          ),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: const Color(0xFF3576F6),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                        hintText: '**************',
                                        hintStyle: const TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Color(0xFF3576F6),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Password Confirmation
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Confirm Password',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF3576F6),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller:
                                          _passwordConfirmationController,
                                      obscureText: _obscurePasswordConfirmation,
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
                                        fillColor: const Color(0xFFE3F0FF),
                                        prefixIcon: const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Image(
                                            image: AssetImage(
                                              'assets/icons/ic_password.png',
                                            ),
                                            height: 24,
                                          ),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePasswordConfirmation
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: const Color(0xFF3576F6),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePasswordConfirmation =
                                                  !_obscurePasswordConfirmation;
                                            });
                                          },
                                        ),
                                        hintText: '**************',
                                        hintStyle: const TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Color(0xFF3576F6),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Username
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Username',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF3576F6),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _usernameController,
                                      validator:
                                          (v) =>
                                              v == null || v.isEmpty
                                                  ? 'Username wajib diisi'
                                                  : null,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: const Color(0xFFE3F0FF),
                                        prefixIcon: const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Image(
                                            image: AssetImage(
                                              'assets/icons/ic_user.png',
                                            ),
                                            height: 24,
                                          ),
                                        ),
                                        hintText: 'Create Your Username',
                                        hintStyle: const TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Color(0xFF3576F6),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: BorderSide.none,
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
                            // Create Account Button
                            Padding(
                              padding: const EdgeInsets.only(bottom: 32.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: _loading ? null : _register,
                                  child:
                                      _loading
                                          ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                          : const Text(
                                            'Create Account',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
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
