import 'package:flutter/material.dart';
import '../theme_constants.dart';
import '../Login_Signup_Mobile/signup_screen.dart';
import '../Login_Signup_Mobile/login_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const CircleAvatar(
                radius: 45,
                backgroundColor: primaryForest,
                child: Icon(Icons.eco_rounded, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 30),
              const Text(
                "Explore Nature\nResponsibly",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryForest, height: 1.2),
              ),
              const SizedBox(height: 15),
              const Text(
                "Join a community dedicated to the preservation of our natural world.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryForest,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text("Get Started", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryForest, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text("Log In", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryForest)),
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