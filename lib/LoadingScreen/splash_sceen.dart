import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../LandingPage_Mobile/landing_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirectToLanding();
  }

  Future<void> _redirectToLanding() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LandingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFD4E8D4), // Light Sage
              Color(0xFFEAF7EA), // Pale Mint
              Color(0xFFC8DBC8), // Soft Moss
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ⚪ THE LOGO CARD
            Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  )
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0), // Adjust padding for your logo
                  child: Image.asset(
  'logo2.png', 
  fit: BoxFit.contain,
  errorBuilder: (context, error, stackTrace) {
     // This helps you see if it's still failing
     return const Icon(Icons.broken_image, color: Colors.red);
  },
)
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "GreenAtlas",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3E2D),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Initializing GreenAtlas platform...",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 60),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF5D7A5D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}