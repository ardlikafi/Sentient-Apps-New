import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentient/core/providers/user_provider.dart';
import 'package:sentient/core/services/firebase_service.dart';
import 'package:sentient/core/widgets/animated_route.dart';
import 'package:sentient/features/auth/login_screen.dart';
import 'package:sentient/main_navigation.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with WidgetsBindingObserver {
  bool _isChecking = false;
  int _cooldownSeconds = 0;
  Timer? _checkTimer;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initial check
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateHome();
      });
    } else {
      _startVerificationTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkEmailVerified(manual: false);
    }
    super.didChangeAppLifecycleState(state);
  }

  void _startVerificationTimer() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkEmailVerified(manual: false);
    });
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        if (mounted) {
          setState(() => _cooldownSeconds--);
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkEmailVerified({bool manual = false}) async {
    if (_isChecking) return;
    if (manual) {
      setState(() => _isChecking = true);
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (manual) {
          _navigateHome();
        }
        return;
      }

      await user.reload();
      final freshUser = FirebaseAuth.instance.currentUser;

      if (freshUser != null && freshUser.emailVerified) {
        _checkTimer?.cancel();

        // Buat akun resmi di collection 'users' sekarang karena email sudah verified!
        try {
          await FirebaseService.completeRegistrationAfterVerification(freshUser);
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Email verified successfully! Welcome to Sentient.',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              backgroundColor: Colors.green,
            ),
          );
          _navigateHome();
        }
      } else {
        if (manual && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Email is not verified yet. Please check your inbox and click the verification link.',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking email verification: $e');
    } finally {
      if (manual && mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (_cooldownSeconds > 0) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        _startCooldown();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Verification email resent! Please check your inbox.',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              backgroundColor: Color(0xFF3576F6),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to resend email: ${e.toString().replaceAll('Exception: ', '')}',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _navigateHome() async {
    _checkTimer?.cancel();
    if (mounted) {
      try {
        await Provider.of<UserProvider>(context, listen: false).fetchUser();
      } catch (_) {}

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        FadeRoute(page: const MainNavigation()),
        (route) => false,
      );
    }
  }

  Future<void> _signOutOnly() async {
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _cancelAndDiscardRegistration() async {
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        // Hapus akun dari Auth & Firestore agar tidak ada akun palsu/sampah yang tersimpan
        await FirebaseService.deleteUnverifiedAccount(user);
      } else {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showCancelConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF001759),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Email Verification',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: const Text(
          'Your email is not verified yet. You can stay and verify, log out, or discard this registration to use a different email/username.',
          style: TextStyle(
            color: Colors.white70,
            fontFamily: 'Poppins',
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Stay & Verify',
              style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _signOutOnly();
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.amber, fontFamily: 'Poppins'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _cancelAndDiscardRegistration();
            },
            child: const Text(
              'Discard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final emailText = user?.email ?? 'your email';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showCancelConfirmDialog();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF000A26),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Row: Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Image.asset(
                      'assets/icons/ic_back.png',
                      height: 24,
                    ),
                    onPressed: _showCancelConfirmDialog,
                  ),
                ),
                const SizedBox(height: 24),

                // Glowing Verification Icon Container
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3576F6).withOpacity(0.12),
                    border: Border.all(
                      color: const Color(0xFF3576F6),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3576F6).withOpacity(0.35),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      size: 52,
                      color: Color(0xFF3576F6),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Subtitle
                Text(
                  'We have sent an activation link to:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),

                // Email Pill Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F0FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        color: Color(0xFF00258C),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          emailText,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00258C),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Instruction Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInstructionStep(
                        number: '1',
                        text: 'Open your email inbox.',
                      ),
                      const SizedBox(height: 12),
                      _buildInstructionStep(
                        number: '2',
                        text: 'Click the verification link from Sentient.',
                      ),
                      const SizedBox(height: 12),
                      _buildInstructionStep(
                        number: '3',
                        text:
                            'Return here — your account will be activated automatically!',
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3576F6).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF3576F6),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Can't find the email? Check your Spam or Junk folder.",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Listening Status Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF3576F6)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Waiting for verification...',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Primary Button: "I Have Verified"
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3576F6), Color(0xFF1E52D9)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3576F6).withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isChecking
                        ? null
                        : () => _checkEmailVerified(manual: true),
                    child: _isChecking
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'I Have Verified My Email',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                // Secondary Button: Resend Email
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _cooldownSeconds > 0
                            ? Colors.white24
                            : const Color(0xFF3576F6),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(
                      Icons.send_rounded,
                      size: 18,
                      color: _cooldownSeconds > 0
                          ? Colors.white38
                          : const Color(0xFF3576F6),
                    ),
                    label: Text(
                      _cooldownSeconds > 0
                          ? 'Resend Email (${_cooldownSeconds}s)'
                          : 'Resend Verification Email',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _cooldownSeconds > 0
                            ? Colors.white38
                            : Colors.white,
                      ),
                    ),
                    onPressed:
                        _cooldownSeconds > 0 ? null : _sendVerificationEmail,
                  ),
                ),
                const SizedBox(height: 16),

                // Change Email / Logout Link
                TextButton(
                  onPressed: _showCancelConfirmDialog,
                  child: Text(
                    'Wrong email? Log Out / Change Email',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildInstructionStep({required String number, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF3576F6),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
