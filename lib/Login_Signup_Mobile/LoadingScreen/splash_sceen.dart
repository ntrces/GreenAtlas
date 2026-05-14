import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../LandingPage_Mobile/landing_screen.dart';
import '../../Employee_Mobile/Employee_Dashboard.dart';
import '../../User_Mobile/user_dashboard.dart';
import '../../IntroPages/completeprofile.dart';
import '../../IntroPages/intro1.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirectToAppropriateScreen();
  }

  Future<void> _redirectToAppropriateScreen() async {
    // Wait for splash to show briefly
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      if (currentUser != null) {
        // User is already logged in, check their profile
        final userData = await supabase
            .from('profiles')
            .select('role, is_first_time')
            .eq('id', currentUser.id)
            .maybeSingle();

        if (mounted) {
          if (userData == null) {
            // No profile exists yet - go to complete profile
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
            );
          } else {
            final role = userData['role'] ?? 'user';
            final isFirstTime = userData['is_first_time'] ?? true;

            if (isFirstTime && role == 'user') {
              // User needs to see intro pages first
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Intro1Screen()),
              );
            } else if (role == 'employee') {
              // Go to employee dashboard
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const EmployeePortal()),
              );
            } else {
              // Go to user dashboard
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const UserDashboard()),
              );
            }
          }
        }
      } else {
        // No user logged in - go to landing page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LandingScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      // On error, redirect to landing page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LandingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                  padding: const EdgeInsets.all(20.0),
                  child: Image.asset(
                    'assets/logo2.png', 
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, color: Colors.red, size: 40);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "GreenAtlas",
              style: textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF2D3E2D),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Initializing GreenAtlas platform...",
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.black45,
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