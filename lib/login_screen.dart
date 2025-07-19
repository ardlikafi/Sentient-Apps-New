import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentient/liked_products_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';
import 'home_screen.dart';
import 'verify_email_screen.dart';

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

    try {
      // --- Perubahan Utama di Sini ---
      // Logika untuk memeriksa username atau email dihapus.
      // Sekarang langsung menggunakan input sebagai email.
      final userCredential = await FirebaseService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // --- Akhir Perubahan Utama ---

      if (userCredential != null) {
        final user = userCredential.user;
        await user?.reload(); // Selalu reload untuk mendapatkan status terbaru

        if (user != null && !user.emailVerified) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
            );
          }
          return; // Hentikan proses jika email belum diverifikasi
        }

        // Jika email sudah terverifikasi, lanjutkan
        await Provider.of<LikedProductsProvider>(context, listen: false).syncLikesWithFirebase();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', user!.uid);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage;
      // Pesan error disederhanakan
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = "Invalid email or password.";
      } else {
        errorMessage = "An error occurred. Please try again.";
      }
      setState(() { _error = errorMessage; });
    } catch (e) {
      setState(() { _error = "An unexpected error occurred."; });
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  void _loginWithGoogle() async {
    // Fungsi ini tidak perlu diubah
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userCredential = await FirebaseService.signInWithGoogle();

      if (userCredential != null) {
        await Provider.of<LikedProductsProvider>(context, listen: false)
            .syncLikesWithFirebase();

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Google Sign-In failed. Please try again.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred during Google Sign-In.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _loginWithFacebook() {
    // Fungsi ini tidak perlu diubah
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
              Color(0xFF000A26),
              Color(0xFF001759),
              Color(0xFF001E73),
              Color(0xFF00258C),
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
                  icon: Image.asset('assets/icons/ic_back.png', height: 24),
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
                            fontFamily: 'Poppins',
                            fontSize: 30,
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
                            // --- Diubah ---
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
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18.0,
                              horizontal: 20.0,
                            ),
                          ),
                          validator: (v) {
                            // --- Diubah ---
                            if (v == null || v.isEmpty || !v.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
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
                              onTap: _loading ? null : _loginWithGoogle,
                              child: Image.asset(
                                'assets/icons/ic_google.png',
                                height: 44,
                              ),
                            ),
                            const SizedBox(width: 24),
                            InkWell(
                              onTap: _loading ? null : _loginWithFacebook,
                              child: Image.asset(
                                'assets/icons/ic_facebook.png',
                                height: 44,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
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
                        const SizedBox(height: 30),
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
                      backgroundColor: const Color(0xFF0A1128),
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
}