import 'package:flutter/material.dart';
import 'animated_route.dart';
import 'welcome_screen.dart';

class CTAScreen extends StatelessWidget {
  const CTAScreen({super.key});

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
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Logo Sentient di tengah atas
              Center(
                child: Image.asset(
                  'assets/images/img_logo.png', // pastikan path asset benar
                  height: 56,
                ),
              ),
              const SizedBox(height: 32),
              // Splash illustration di tengah
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/images/img_splash_screen.png',
                    height: 370, // atur sesuai kebutuhan
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'All Your Chess Needs\nin One App',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Get Started Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 24,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A1128),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).push(FadeScaleRoute(page: const WelcomeScreen()));
                    },
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
