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
            crossAxisAlignment: CrossAxisAlignment.center, 
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // * Top spacer to keep things balanced
              const Spacer(flex: 2), 
              
              Center(
                child: Container(
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
              ),
              const SizedBox(height: 30),
              
              // * Headline Text centered by splitting widgets
              Column(
                children: [
                  Text(
                    "Explore Nature",
                    style: textTheme.headlineMedium?.copyWith(
                      color: primaryForest,
                      fontFamily: 'Poppins-Bold',
                    ),
                  ),
                  Text(
                    "Responsibly",
                    style: textTheme.headlineMedium?.copyWith(
                      color: primaryForest,
                      fontFamily: 'Poppins-Bold',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              // * Body text centered by splitting widgets
              Column(
                children: [
                  Text(
                    "Join a community dedicated to the",
                    style: textTheme.bodyLarge?.copyWith(color: Colors.black54, fontFamily: 'Inter'),
                  ),
                  Text(
                    "preservation of our natural world.",
                    style: textTheme.bodyLarge?.copyWith(color: Colors.black54, fontFamily: 'Inter'),
                  ),
                ],
              ),
              
              // * Bottom spacer - adjusting this flex can also move buttons higher
              const Spacer(flex: 1), 

              // * Smaller "Get Started" Button
              SizedBox(
                width: 280, 
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryForest,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: Text(
                    "Get Started",
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.white, 
                      fontSize: 18,
                      fontFamily: 'Poppins-Bold',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // * Smaller "Log In" Button
              SizedBox(
                width: 280,
                height: 55,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryForest, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: Text(
                    "Log In",
                    style: textTheme.titleLarge?.copyWith(
                      color: primaryForest, 
                      fontSize: 18,
                      fontFamily: 'Poppins-Bold',
                    ),
                  ),
                ),
              ),

              // * FIXED: Increased height from 40 to 80 to push the buttons higher up
              const SizedBox(height: 180), 
            ],
          ),
        ),
      ),
    );
  }
}