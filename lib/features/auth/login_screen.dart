import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentient/core/providers/liked_products_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sentient/core/services/firebase_service.dart';
import 'package:sentient/core/widgets/animated_route.dart';
import 'package:sentient/features/auth/verify_email_screen.dart';
import 'package:sentient/main_navigation.dart';

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

  void _forgotPassword() async {
    final emailController = TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF000A26), Color(0xFF001759)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reset Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Enter your email address to receive a password reset link.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Poppins',
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                    decoration: InputDecoration(
                      hintText: 'user@example.com',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.amber,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: const Color(0xFF000A26),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          var email = emailController.text.trim();
                          if (!email.contains('@')) {
                            final resolved =
                                await FirebaseService.getEmailByUsername(email);
                            if (resolved != null) {
                              email = resolved;
                            }
                          }
                          if (email.isEmpty || !email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter a valid email address!',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context);

                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(
                              email: email,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password reset email sent! Please check your inbox.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to send reset email: $e',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Send',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final input =
          _emailController.text.trim(); // Controller input username/email
      final password = _passwordController.text;

      String targetEmail = input;

      // 🔍 JIKA INPUT BUKAN EMAIL (BERARTI USER MENGETIK USERNAME)
      if (!input.contains('@')) {
        final emailFound = await FirebaseService.getEmailFromUsername(input);
        if (emailFound == null) {
          setState(() {
            _error = 'Username "$input" tidak ditemukan.';
            _loading = false;
          });
          return;
        }
        targetEmail = emailFound;
      }

      // Login ke Firebase Auth menggunakan email yang ditemukan
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: targetEmail, password: password);

      if (userCredential.user != null) {
        final user = userCredential.user;
        if (user != null) {
          try {
            await user.reload();
          } catch (_) {}
          final freshUser = FirebaseAuth.instance.currentUser;
          if (freshUser != null && !freshUser.emailVerified) {
            // Belum verifikasi -> Jangan beri akses ke Home, arahkan ke VerifyEmailScreen
            try {
              await freshUser.sendEmailVerification();
            } catch (_) {}
            if (!mounted) return;
            setState(() {
              _loading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Silakan verifikasi email Anda terlebih dahulu.',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.of(context).pushAndRemoveUntil(
              FadeRoute(page: const VerifyEmailScreen()),
              (route) => false,
            );
            return;
          }
        }

        // Navigasi ke MainNavigation / HomeScreen
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found' ||
            e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          _error = 'Email/Username atau password salah.';
        } else {
          _error = e.message ?? 'Login gagal. Silakan coba lagi.';
        }
      });
    } catch (e) {
      print('Firebase login exception: $e');
      if (e.toString().contains('not-initialized') ||
          e.toString().contains('apiKey')) {
        // Fallback for mock environment
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
          (route) => false,
        );
      } else {
        setState(() {
          _error =
              'Terjadi kesalahan: ${e.toString().replaceAll('Exception: ', '')}';
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

  void _loginWithGoogle() async {
    // Fungsi ini tidak perlu diubah
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userCredential = await FirebaseService.signInWithGoogle();

      if (userCredential != null) {
        await Provider.of<LikedProductsProvider>(
          context,
          listen: false,
        ).syncLikesWithFirebase();

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
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
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      24.0,
                      0.0,
                      24.0,
                      bottomInset > 0 ? bottomInset + 16.0 : 20.0,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            'Log In',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3576F6),
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _emailController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(
                              color: Color(0xFF00258C),
                              fontFamily: 'Poppins',
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Email atau Username',
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
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 18.0,
                                horizontal: 20.0,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter your email or username';
                              }
                              if (v.trim().length < 3) {
                                return 'Email or username must be at least 3 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _loading ? null : _login(),
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
                                  color: const Color(
                                    0xFF3576F6,
                                  ).withOpacity(0.8),
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
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Color(0xFF3576F6),
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
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
      ),
    );
  }
}
