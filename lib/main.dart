import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'theme_provider.dart';
import 'LandingPage_Mobile/landing_screen.dart';
import 'User_Mobile/user_dashboard.dart'; 
import 'Employee_Mobile/Employee_dashboard.dart'; 
import 'Login_Signup_Mobile/login_screen.dart'; 
import './Web_Admin/Admin_Dashboard.dart'; // REQUIRED IMPORT

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

class EcoConservationApp extends StatefulWidget {
  const EcoConservationApp({super.key});
  @override
  State<EcoConservationApp> createState() => _EcoConservationAppState();
}

class _EcoConservationAppState extends State<EcoConservationApp> {
  User? _user;
  String? _role;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _checkInitialSession();
    _setupAuthListener();
  }

  Future<void> _checkInitialSession() async {
    final session = supabase.auth.currentSession;
    if (session != null) {
      await _fetchUserRole(session.user);
    } else {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _fetchUserRole(User user) async {
    try {
      final profile = await supabase.from('profiles').select('role').eq('id', user.id).maybeSingle();
      if (mounted) {
        setState(() {
          _user = user;
          _role = profile?['role'] ?? 'user';
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  void _setupAuthListener() {
    supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        await _fetchUserRole(session.user);
      } else {
        if (mounted) {
          setState(() {
            _user = null;
            _role = null;
            _isInitialLoading = false;
          });
        }
      }
    });
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
      home: _isInitialLoading 
          ? const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF5D7A5D))))
          : (_user == null ? const LandingScreen() : _getRoleBasedHome(_role)),
      
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const UserDashboard(), 
      },
    );
  }

  // --- UPDATED ROLE NAVIGATION ---
  Widget _getRoleBasedHome(String? role) {
    if (role == 'admin') {
      return const AdminDashboardView(); // Route to Web Interface
    } else if (role == 'employee') {
      return const EmployeePortal(); // Route to Employee App
    }
    return const UserDashboard(); // Standard User
  }
}