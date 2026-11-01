import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:sentient/core/providers/liked_products_provider.dart';
import 'package:sentient/features/auth/splash_screen.dart';
import 'package:sentient/features/home/cta_screen.dart';
import 'package:sentient/features/auth/signup_screen.dart';
import 'package:sentient/features/auth/login_screen.dart';
import 'package:sentient/features/profile/profile_screen.dart';
import 'package:sentient/features/auth/welcome_screen.dart';
import 'package:sentient/features/auth/signup_choice_screen.dart';
import 'main_navigation.dart';
import 'firebase_options.dart';
import 'package:sentient/core/services/language_service.dart';
import 'package:sentient/core/services/seed_service.dart';
import 'package:sentient/core/services/notification_service.dart';
import 'package:sentient/core/providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dynamic localization service
  await LanguageService.init();
  
  // Debug: Print Firebase options
  final options = DefaultFirebaseOptions.currentPlatform;
  print('Firebase API Key: ${options.apiKey}');
  print('Firebase App ID: ${options.appId}');
  
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: options,
      );
    }
    // Initialize FCM notifications & token sync
    await NotificationService.initialize();
    
    // Seed initial data if necessary
    SeedService.seedDatabase();
  } catch (e) {
    print('Firebase initialization bypassed/failed: $e');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LikedProductsProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.languageNotifier,
      builder: (context, langCode, _) {
        return MaterialApp(
          key: ValueKey(langCode),
          navigatorKey: NotificationService.navigatorKey,
          title: 'Sentient Chess',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/cta': (context) => const CTAScreen(),
            '/welcome': (context) => const WelcomeScreen(),
            '/signup-choice': (context) => const SignUpChoiceScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/login': (context) => const LoginScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/home': (context) => const MainNavigation(),
          },
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
