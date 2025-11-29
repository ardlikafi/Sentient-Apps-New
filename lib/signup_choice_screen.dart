import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentient/liked_products_provider.dart';
import 'package:sentient/firebase_service.dart';
import 'package:sentient/home_screen.dart';
import 'signup_screen.dart';
import 'animated_route.dart';

class SignUpChoiceScreen extends StatefulWidget {
  const SignUpChoiceScreen({super.key});

  @override
  State<SignUpChoiceScreen> createState() => _SignUpChoiceScreenState();
}

class _SignUpChoiceScreenState extends State<SignUpChoiceScreen> {
  bool _loading = false;
  String? _error;

  void _loginWithGoogle() async {
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
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
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
      if (mounted) {
        setState(() {
          _error = 'An error occurred: ${e.toString()}';
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

  void _loginWithFacebook() {
    print('Login with Facebook tapped');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Facebook login not implemented yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // <-- TAMBAHKAN INI
                children: [
                  // --- TAMBAHKAN WIDGET INI ---
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                    child: IconButton(
                      icon: Image.asset('assets/icons/ic_back.png', height: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  // --- AKHIR PENAMBAHAN ---
                  const Center( // <-- BUNGKUS TEXT DENGAN CENTER
                    child: Text(
                      'Create Your Account',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3576F6),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/img_splash_screen.png',
                          height: 370,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3576F6),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _loading
                            ? null
                            : () {
                          Navigator.of(
                            context,
                          ).push(
                            FadeScaleRoute(page: const SignUpScreen()),
                          );
                        },
                        child: const Text(
                          'Sign Up with Email',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Colors.white24)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Or Continue With',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white24)),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}