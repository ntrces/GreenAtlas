import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme_constants.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _supabase = Supabase.instance.client;
  String _fullName = "Loading...";
  String _email = "...";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final data = await _supabase.from('profiles').select().eq('id', user.id).single();
      if (mounted) {
        setState(() {
          _fullName = data['full_name'] ?? "User";
          _email = user.email ?? "";
        });
      }
    }
  }

  // --- 1. LOGOUT CONFIRMATION POPUP ---
  Future<void> _showLogoutConfirmation() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Are you sure you want to logout from GreenAtlas?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _handleLogout(); // Execute logout
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Logout", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // --- 2. UPDATED LOGOUT HANDLER ---
  Future<void> _handleLogout() async {
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        // Navigates to the very first page ('/') and removes everything from history
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error logging out: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("My Profile", style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF2D3E2D)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFF5D7A5D),
              child: const Icon(Icons.person, size: 80, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Text(_fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
          Text(_email, style: const TextStyle(fontSize: 14, color: Colors.black45)),
          const SizedBox(height: 40),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: ListView(
                padding: const EdgeInsets.only(top: 30),
                children: [
                  _buildProfileTile(Icons.edit_outlined, "Edit Profile"),
                  _buildProfileTile(Icons.notifications_none_rounded, "Notifications"),
                  _buildProfileTile(Icons.shield_outlined, "Privacy & Security"),
                  const Divider(height: 40, color: Colors.black12),
                  ListTile(
                    onTap: _showLogoutConfirmation, // Changed to show popup
                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.black26),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF5D7A5D)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26),
      onTap: () {},
    );
  }
}