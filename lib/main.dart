import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'theme_provider.dart';
import './LoadingScreen/splash_sceen.dart'; // IMPORT YOUR NEW SPLASH SCREEN
import 'LandingPage_Mobile/landing_screen.dart';
import 'User_Mobile/user_dashboard.dart'; 
import 'Employee_Mobile/Employee_dashboard.dart'; 
import 'Login_Signup_Mobile/login_screen.dart'; 
import './Web_Admin/Admin_Dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://ffczaraasatwduvenghj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZmY3phcmFhc2F0d2R1dmVuZ2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwODk2MTgsImV4cCI6MjA4NTY2NTYxOH0.8NAUxIy4C21VtGe6FD5CeoNKHwc3gYXMM97t8BUhArs', 
    authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const EcoConservationApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class EcoConservationApp extends StatelessWidget {
  const EcoConservationApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Green Atlas',
      themeMode: themeProvider.themeMode, 
      theme: ThemeData(
        useMaterial3: true, 
        brightness: Brightness.light,
        primaryColor: const Color(0xFF2D3E2D),
        scaffoldBackgroundColor: const Color(0xFFEAF7EA),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      
      // --- UPDATED ENTRY POINT ---
      // This ensures the SplashScreen always shows first
      home: const SplashScreen(), 
      
      routes: {
        '/login': (context) => const LoginScreen(),
        '/landing': (context) => const LandingScreen(),
        '/home': (context) => const UserDashboard(), 
        '/admin': (context) => const AdminDashboardView(),
        '/employee': (context) => const EmployeePortal(),
      },
    );
  }
}