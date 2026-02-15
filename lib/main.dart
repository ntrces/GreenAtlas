import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'theme_provider.dart';
import 'firebase_options.dart'; 
import './LoadingScreen/splash_sceen.dart'; 
import 'LandingPage_Mobile/landing_screen.dart';
import 'User_Mobile/user_dashboard.dart'; 
import 'Employee_Mobile/Employee_dashboard.dart'; 
import 'Login_Signup_Mobile/login_screen.dart'; 
import 'Web_Admin/Web_Dashboard/Admin_Dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Initialize Supabase
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

class EcoConservationApp extends StatefulWidget {
  const EcoConservationApp({super.key});

  @override
  State<EcoConservationApp> createState() => _EcoConservationAppState();
}

class _EcoConservationAppState extends State<EcoConservationApp> {
  
  @override
  void initState() {
    super.initState();

    // LISTEN FOR LOGIN: This ensures the token saves even if they log in later
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _updateFCMToken(session.user.id);
      }
    });

    // FOREGROUND LISTENER: Show a notification banner while the app is open
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${message.notification!.title}: ${message.notification!.body}"),
            backgroundColor: const Color(0xFF2D3E2D),
          ),
        );
      }
    });
  }

  // Logic to save the unique phone ID to your profiles table
  Future<void> _updateFCMToken(String userId) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      
      // Request permission (Required for Android 13+ and iOS)
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // RETRY LOGIC: Wait briefly for the database to create the new profile row
      await Future.delayed(const Duration(seconds: 2));

      String? token = await messaging.getToken();
      if (token != null) {
        debugPrint("Captured FCM Token: $token");
        
        // Update the 'fcm_token' column in your 'profiles' table
        final result = await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', userId)
            .select();

        if (result.isEmpty) {
          debugPrint("Token save failed: Profile row not found for ID $userId. Retrying...");
          // One final attempt if the first update failed
          await Future.delayed(const Duration(seconds: 3));
          await Supabase.instance.client
              .from('profiles')
              .update({'fcm_token': token})
              .eq('id', userId);
        } else {
          debugPrint("FCM Token successfully synced to database.");
        }
      }
    } catch (e) {
      debugPrint("Error updating token: $e");
    }
  }

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