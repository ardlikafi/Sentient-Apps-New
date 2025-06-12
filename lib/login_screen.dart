import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart'; // Uncomment jika Anda memiliki HomeScreen untuk navigasi
// Uncomment jika Anda menggunakan animated route

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ApiService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
    setState(() {
      _loading = false;
    });
    if (result != null && result['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', result['token']);
      print('Login Berhasil, token: ${result['token']}');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      setState(() {
        _error = 'Login gagal. Email/Username atau password salah.';
      });
    }
  }

  void _loginWithGoogle() {
    // TODO: Implement Google Sign-In
    print('Login with Google tapped');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google login not implemented yet.')),
    );
  }

  void _loginWithFacebook() {
    // TODO: Implement Facebook Sign-In
    print('Login with Facebook tapped');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Facebook login not implemented yet.')),
    );
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
              Color(0xFF000A26), // Dark blue at the top
              Color(0xFF001759),
              Color(0xFF001E73),
              Color(0xFF00258C), // Darker blue at the bottom
            ],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                child: IconButton(
                  icon: Image.asset('assets/icons/ic_back.png', height: 32),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          'Log In',
                          style: TextStyle(
                            fontFamily:
                                'Poppins', // Pastikan font Poppins ada di pubspec.yaml
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3576F6),
                          ),
                        ),
                        const SizedBox(height: 50),
                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(
                            color: Color(0xFF00258C),
                            fontFamily: 'Poppins',
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Email or Username',
                            hintStyle: TextStyle(
                              color: const Color(0xFF00258C).withOpacity(0.6),
                              fontFamily: 'Poppins',
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFE3F0FF),
                            prefixIcon: Padding(
                              padding: EdgeInsets.all(12),
                              child: Image.asset(
                                'assets/icons/ic_email.png',
                                height: 24,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18.0,
                              horizontal: 20.0,
                            ),
                          ),
                          validator:
                              (v) =>
                                  v == null || v.isEmpty
                                      ? 'Email or Username is required'
                                      : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            color: Color(0xFF00258C),
                            fontFamily: 'Poppins',
                            fontSize: 16,
                          ),
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
                              padding: EdgeInsets.all(12),
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
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18.0,
                              horizontal: 20.0,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password is required';
                            }
                            // if (v.length < 6) return 'Password must be at least 6 characters'; // Opsional
                            return null;
                          },
                        ),
                        const SizedBox(height: 25),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                ),
                                child: Text(
                                  'Or Log In With',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: _loginWithGoogle,
                              child: Image.asset(
                                'assets/icons/ic_google.png',
                                height: 44,
                              ),
                            ),
                            const SizedBox(width: 24),
                            InkWell(
                              onTap: _loginWithFacebook,
                              child: Image.asset(
                                'assets/icons/ic_facebook.png',
                                height: 44,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ), // Reduce space if error message is not shown
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10.0,
                              bottom: 10.0,
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(
                          height: 30,
                        ), // Space before Continue button if no error
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF0A1128,
                      ), // Dark button color
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    onPressed: _loading ? null : _login,
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
                              'Continue',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Image.asset(
          iconPath,
          height: 26,
          width: 26,
          errorBuilder: (context, error, stackTrace) {
            // Fallback icon jika asset tidak ditemukan
            String type = iconPath.contains('google') ? "G" : "F";
            return CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 13,
              child: Text(
                type,
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
