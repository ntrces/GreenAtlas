import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- ADD THESE IMPORTS TO FIX THE RED SQUIGGLES ---
import 'theme_constants.dart';
import 'LandingPage_Mobile/landing_screen.dart';
import 'User_Mobile/user_dashboard.dart';
import 'Admin_Mobile/admin_dashboard.dart';
import 'Employee_Mobile/employee_portal.dart';
import 'User_Mobile/AR_Gallery/ar_gallery.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ffczaraasatwduvenghj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZmY3phcmFhc2F0d2R1dmVuZ2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwODk2MTgsImV4cCI6MjA4NTY2NTYxOH0.8NAUxIy4C21VtGe6FD5CeoNKHwc3gYXMM97t8BUhArs', 
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
    _setupAuthListener();
  }

  void _setupAuthListener() {
    supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        try {
          final profile = await supabase.from('profiles').select('role').eq('id', session.user.id).single();
          if (mounted) {
            setState(() {
              _user = session.user;
              _role = profile['role'];
              _isInitialLoading = false;
            });
          }
        } catch (e) {
          if (mounted) setState(() { _user = session.user; _role = 'user'; _isInitialLoading = false; });
        }
      } else {
        if (mounted) setState(() { _user = null; _role = null; _isInitialLoading = false; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, primaryColor: primaryForest),
      home: _isInitialLoading 
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (_user == null ? const LandingScreen() : _getRoleBasedHome(_role)),
    );
  }

  Widget _getRoleBasedHome(String? role) {
    switch (role) {
      case 'admin': return const AdminDashboard();
      case 'employee': return const EmployeePortal();
      default: return const HomeScreen();
    }
  }
}