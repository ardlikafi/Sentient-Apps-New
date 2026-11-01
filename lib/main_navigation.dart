import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:sentient/core/providers/user_provider.dart';
import 'package:sentient/features/home/home_screen.dart';
import 'package:sentient/features/profile/profile_screen.dart';
import 'package:sentient/features/chess/chess_menu_screen.dart';
import 'package:sentient/features/courses/course_screen.dart';
import 'package:sentient/features/shop/shop_screen.dart';
import 'package:sentient/core/services/language_service.dart';
import 'package:sentient/core/services/notification_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with WidgetsBindingObserver {
  int _currentIndex = 0;
  
  late final List<Widget> _screens = [
    HomeScreen(
      onNavigateToTab: (index) {
        if (mounted) {
          setState(() {
            _currentIndex = index;
          });
        }
      },
    ),
    const CourseScreen(),
    const ChessMenuScreen(),
    const ShopScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LanguageService.languageNotifier.addListener(_onLanguageChanged);

    // Start presence heartbeat, sync FCM token & global notifications listener
    NotificationService.startPresenceSystem();
    NotificationService.syncUserFCMToken();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Consume any pending payload from cold start notification tap
      NotificationService.consumePendingPayload(context);

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final uid = userProvider.userData?['id']?.toString() ??
          FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        NotificationService.startGlobalListeners(uid);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      NotificationService.startPresenceSystem();
      NotificationService.syncUserFCMToken();
      NotificationService.consumePendingPayload(context);
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.inactive ||
               state == AppLifecycleState.detached) {
      NotificationService.stopPresenceSystem();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LanguageService.languageNotifier.removeListener(_onLanguageChanged);
    NotificationService.stopPresenceSystem();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  DateTime? _lastBackPressTime;

  void _handleBackPress() {
    // 1. Jika sedang di tab selain Beranda (Courses, Chess, Shop, Profile), kembali ke Beranda (Home)
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return;
    }

    // 2. Jika sudah di Beranda (Home), minta konfirmasi klik back 2 kali dalam 2 detik untuk keluar
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;

      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 24, left: 36, right: 36),
          backgroundColor: const Color(0xFF001759),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Colors.amber, width: 1.2),
          ),
          duration: const Duration(seconds: 2),
          content: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.exit_to_app_rounded, color: Colors.amber, size: 20),
              SizedBox(width: 10),
              Text(
                'Press back again to exit',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Klik back kedua kali dalam waktu <= 2 detik: keluar dari aplikasi secara aman
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService.languageNotifier.value;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000A26),
              Color(0xFF001759),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.amber,
          unselectedItemColor: Colors.white70,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          iconSize: 24,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _currentIndex == 0 
                      ? Colors.amber.withValues(alpha: 0.2) 
                      : Colors.transparent,
                ),
                child: const Icon(Icons.home),
              ),
              label: LanguageService.translate('home', languageCode: lang),
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _currentIndex == 1 
                      ? Colors.amber.withValues(alpha: 0.2) 
                      : Colors.transparent,
                ),
                child: const Icon(Icons.school),
              ),
              label: LanguageService.translate('courses', languageCode: lang),
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _currentIndex == 2 
                      ? Colors.amber.withValues(alpha: 0.2) 
                      : Colors.transparent,
                ),
                child: const Icon(Icons.extension),
              ),
              label: LanguageService.translate('chess', languageCode: lang),
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _currentIndex == 3 
                      ? Colors.amber.withValues(alpha: 0.2) 
                      : Colors.transparent,
                ),
                child: const Icon(Icons.shopping_bag),
              ),
              label: LanguageService.translate('shop', languageCode: lang),
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _currentIndex == 4 
                      ? Colors.amber.withValues(alpha: 0.2) 
                      : Colors.transparent,
                ),
                child: const Icon(Icons.person),
              ),
              label: LanguageService.translate('profile', languageCode: lang),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
