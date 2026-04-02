import 'package:flutter/material.dart';
import '../theme_constants.dart';
import '../Login_Signup_Mobile/signup_screen.dart';
import '../Login_Signup_Mobile/login_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: softGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    )
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/logo1.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, color: Colors.red, size: 40);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Use a Center widget to handle positioning
              Center(
                child: Text(
                  "Explore Nature\nResponsibly",
                  style: textTheme.headlineMedium?.copyWith(
                    color: primaryForest,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Center(
                child: Text(
                  "Join a community dedicated to the preservation of our natural world.",
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryForest,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    "Get Started",
                    style: textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryForest, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    "Log In",
                    style: textTheme.titleLarge?.copyWith(color: primaryForest),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}