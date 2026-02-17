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

// 1. Create a Global Key to show Snackbars without a direct context
final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

// 2. REQUIRED: Top-level background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Background Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Supabase
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

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _updateFCMToken(session.user.id);
      }
    });

    // FIXED: Using messengerKey instead of context inside initState
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text("${message.notification!.title}: ${message.notification!.body}"),
            backgroundColor: const Color(0xFF2D3E2D),
          ),
        );
      }
    });
  }

  Future<void> _updateFCMToken(String userId) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      String? token = await messaging.getToken();
      if (token != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', userId);
      }
    } catch (e) {
      debugPrint("Error updating token: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      // 3. ATTACH THE KEY HERE
      scaffoldMessengerKey: messengerKey, 
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