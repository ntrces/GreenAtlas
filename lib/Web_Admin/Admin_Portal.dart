import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- PROJECT MODULE IMPORTS ---
// Ensure these files exist and the class names match
import 'Admin_Dashboard.dart'; 
import 'Validation/Admin_ValidationQueue.dart';
import 'Plant_Database/Admin_PlantDatabase.dart';
import '../Login_Signup_Mobile/login_screen.dart'; 

class AdminWebPortal extends StatefulWidget {
  const AdminWebPortal({super.key});

  @override
  State<AdminWebPortal> createState() => _AdminWebPortalState();
}

class _AdminWebPortalState extends State<AdminWebPortal> {
  int _selectedIndex = 0;
  bool _isSidebarVisible = true; // State for toggling sidebar visibility
  
  // Properly initialize the Supabase client for session management
  final SupabaseClient _supabase = Supabase.instance.client; 

  // --- MODULE NAVIGATION LIST ---
  // Maps the Sidebar index to the specific view
  final List<Widget> _adminModules = [
    const AdminDashboardView(),
    const ValidationQueueView(),
    const PlantDatabaseView(),
    const Center(child: Text("Public Enforcement Module")),
    const Center(child: Text("Audit & Compliance Logs")),
    const Center(child: Text("Meeting Coordination")),
    const Center(child: Text("User Management")),
  ];

  // --- 🔒 LOGOUT LOGIC ---
  Future<void> _handleLogout() async {
    try {
      // Correctly access the auth property to terminate session
      await _supabase.auth.signOut(); 
      
      if (mounted) {
        // Redirect to Login and clear all previous routes for security
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, 
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logout failed: $e"), 
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Confirmation Dialog to prevent accidental sign-outs
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to sign out of the GreenAtlas Admin Portal?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _handleLogout(); // Execute logout
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, 
              foregroundColor: Colors.white,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // --- 🔝 TOP WHITE HEADER ---
          _buildWebHeader(),
          
          Expanded(
            child: Row(
              children: [
                // --- 🟢 SIDEBAR (Toggleable) ---
                if (_isSidebarVisible)
                  NavigationRail(
                    backgroundColor: const Color(0xFF4D6D4D),
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                    labelType: NavigationRailLabelType.none,
                    indicatorColor: const Color(0xFF384D38),
                    
                    // Permanent Logout Button at Sidebar Bottom
                    trailing: Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: IconButton(
                            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                            tooltip: 'Sign Out',
                            onPressed: _showLogoutDialog,
                          ),
                        ),
                      ),
                    ),
                    
                    destinations: [
                      _buildDestination(Icons.home_outlined, Icons.home, 'Dashboard'),
                      _buildDestination(Icons.verified_user_outlined, Icons.verified_user, 'Validation'),
                      _buildDestination(Icons.storage_outlined, Icons.storage, 'Plants'),
                      _buildDestination(Icons.warning_amber_rounded, Icons.warning_amber, 'Enforcement'),
                      _buildDestination(Icons.assignment_outlined, Icons.assignment, 'Audit'),
                      _buildDestination(Icons.calendar_today_outlined, Icons.calendar_today, 'Meetings'),
                      _buildDestination(Icons.people_outline, Icons.people, 'Users'),
                    ],
                  ),
                
                // --- 🖥 MAIN CONTENT AREA ---
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8F9FA),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: _adminModules[_selectedIndex],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NavigationRailDestination helper: Using selectedIcon for correct Material behavior
  NavigationRailDestination _buildDestination(IconData icon, IconData selected, String label) {
    return NavigationRailDestination(
      icon: Icon(icon, color: Colors.white),
      selectedIcon: Icon(selected, color: Colors.white), 
      label: Text(label),
    );
  }

  // Branding and Action Header
  Widget _buildWebHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white, 
        border: Border(bottom: BorderSide(color: Colors.black12))
      ),
      child: Row(
        children: [
          // ☰ Hamburger Toggle to show/hide the sidebar
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black54),
            onPressed: () => setState(() => _isSidebarVisible = !_isSidebarVisible),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.eco, color: Color(0xFF4D6D4D)),
          const SizedBox(width: 12),
          const Text("GreenAtlas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text(" • Cavite Protected Area", style: TextStyle(fontSize: 14, color: Colors.black38)),
          const Spacer(),
          // Profile/User Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F0), 
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.person_outline, size: 18, color: Colors.black54),
                SizedBox(width: 8),
                Text("DENR Admin", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}