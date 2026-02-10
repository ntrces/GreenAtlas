import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- PROJECT IMPORTS ---
import 'theme_constants.dart';
import 'LandingPage_Mobile/landing_screen.dart';
import 'User_Mobile/user_dashboard.dart'; // Verified path
import 'Employee_Mobile/Employee_dashboard.dart'; 
import 'Login_Signup_Mobile/login_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://ffczaraasatwduvenghj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZmY3phcmFhc2F0d2R1dmVuZ2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwODk2MTgsImV4cCI6MjA4NTY2NTYxOH0.8NAUxIy4C21VtGe6FD5CeoNKHwc3gYXMM97t8BUhArs', 
    authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );
  
  runApp(const EcoConservationApp());
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
      if (mounted) {
        setState(() {
          _user = user;
          _role = 'user';
          _isInitialLoading = false;
        });
      }
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Green Atlas',
      theme: ThemeData(
        useMaterial3: true, 
        primaryColor: primaryForest,
        scaffoldBackgroundColor: const Color(0xFFEAF7EA),
      ),
      home: _isInitialLoading 
          ? const Scaffold(body: Center(child: CircularProgressIndicator(color: primaryForest)))
          : (_user == null ? const LandingScreen() : _getRoleBasedHome(_role)),
      
      routes: {
        '/login': (context) => const LoginScreen(),
        // FIX: Removed 'const' and updated to UserDashboard
        '/home': (context) => UserDashboard(), 
      },
    );
  }

  Widget _getRoleBasedHome(String? role) {
    if (role == 'employee') {
      return const EmployeePortal(); 
    }
    // FIX: Removed 'const' and updated to UserDashboard
    return UserDashboard(); 
  }
}