import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../LandingPage_Mobile/landing_screen.dart';
import '../../Employee_Mobile/Employee_Dashboard.dart';
import '../../User_Mobile/user_dashboard.dart';
import '../../IntroPages/completeprofile.dart';
import '../../IntroPages/intro1.dart';

import '../../services/user_session_service.dart';

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
    if (!mounted) return;

    try {
      final supabase = Supabase.instance.client;

      // Safely wait for auth state restoration without hanging offline
      try {
        await supabase.auth.onAuthStateChange
            .take(1)
            .first
            .timeout(const Duration(milliseconds: 1500));
      } catch (_) {
        // Offline or timed out - continue to evaluate local and cached state
      }

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final currentUser = supabase.auth.currentUser;
      Map<String, dynamic>? userData;

      // If we have an active user, attempt to fetch fresh profile from Supabase
      if (currentUser != null) {
        try {
          userData = await supabase
              .from('profiles')
              .select('role, is_first_time')
              .eq('id', currentUser.id)
              .maybeSingle()
              .timeout(const Duration(seconds: 3));

          if (userData != null) {
            final fetchedRole =
                userData['role']?.toString().toLowerCase().trim() ?? 'user';
            final fetchedIsFirstTime = userData['is_first_time'] ?? false;
            await UserSessionService.saveSession(
              userId: currentUser.id,
              role: fetchedRole,
              email: currentUser.email,
              isFirstTime: fetchedIsFirstTime,
            );
          }
        } catch (netErr) {
          debugPrint('Offline or error fetching fresh profile: $netErr');
        }
      }

      final role = (userData?['role']?.toString().toLowerCase().trim()) ??
          UserSessionService.currentUserRole?.toLowerCase().trim() ??
          'user';
      final isFirstTime = (userData?['is_first_time'] as bool?) ??
          UserSessionService.isFirstTime;
      final isEmployee =
          role == 'employee' || role == 'admin' || UserSessionService.isEmployee;
      final hasActiveSession = currentUser != null || UserSessionService.isLoggedIn;

      if (!mounted) return;

      if (hasActiveSession) {
        if (isEmployee) {
          // Employee / Admin session restored (online or offline)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EmployeePortal()),
          );
        } else if (isFirstTime && role == 'user') {
          // First-time regular user
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Intro1Screen()),
          );
        } else {
          // Regular user dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserDashboard()),
          );
        }
      } else {
        // No user logged in - go to landing page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LandingScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      if (mounted) {
        if (UserSessionService.isEmployee) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EmployeePortal()),
          );
        } else if (UserSessionService.isLoggedIn) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LandingScreen()),
          );
        }
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