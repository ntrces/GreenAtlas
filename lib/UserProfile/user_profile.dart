import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart'; // REQUIRED for Theme Sync
import '../../theme_provider.dart'; // Ensure this matches your file path
import 'change_password.dart'; 
import '../UserProfile/edit_profile.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _supabase = Supabase.instance.client;
  
  // Dynamic User Data fetched from Supabase
  String _fullName = "Loading...";
  String _email = "user@example.com";
  String _phone = "0917-123-4567";
  String _location = "Cavite, Philippines";
  String _joinedDate = "Joined 2025-01-15";
  String? _avatarUrl; 
  bool _isLoading = true;

  // Notification States matching your design
  bool _emailNotif = true;
  bool _pushNotif = true;
  bool _reportUpdates = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // --- 1. DATABASE FETCH LOGIC ---
  Future<void> _fetchUserData() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
        
        if (mounted) {
          setState(() {
            _fullName = data['full_name'] ?? "User";
            _email = user.email ?? _email;
            _phone = data['phone'] ?? _phone;
            _location = data['location'] ?? "Cavite, Philippines";
            _avatarUrl = data['avatar_url']; // Link to "Profiles" bucket
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
        debugPrint("Error loading profile: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the global theme state
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return Scaffold(
      // Dynamic Background based on Toggle
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF2D3E2D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Profile", 
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 18)),
            const Text("Account settings • Preferences", 
              style: TextStyle(color: Colors.black38, fontSize: 11)),
          ],
        ),
        actions: [
          _buildNotificationBadge(isDark),
          _buildTopProfileIcon(isDark),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUserData,
        color: const Color(0xFF5D7A5D),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildProfileHeader(isDark),
              const SizedBox(height: 24),
              
              // --- PERSONAL INFO SECTION ---
              _buildSectionCard(
                title: "PERSONAL INFORMATION",
                isDark: isDark,
                children: [
                  _buildInfoRow(Icons.email_outlined, _email),
                  _buildInfoRow(Icons.phone_outlined, _phone),
                  _buildInfoRow(Icons.location_on_outlined, _location),
                  _buildInfoRow(Icons.calendar_today_outlined, _joinedDate),
                ],
              ),
              const SizedBox(height: 16),

              // --- NOTIFICATIONS SECTION ---
              _buildSectionCard(
                title: "NOTIFICATION SETTINGS",
                isDark: isDark,
                children: [
                  _buildSwitchRow(Icons.notifications_none, "Email Notifications", _emailNotif, (v) => setState(() => _emailNotif = v)),
                  _buildSwitchRow(Icons.notifications_active_outlined, "Push Notifications", _pushNotif, (v) => setState(() => _pushNotif = v)),
                  _buildSwitchRow(Icons.check_circle_outline, "Report Updates", _reportUpdates, (v) => setState(() => _reportUpdates = v)),
                ],
              ),
              const SizedBox(height: 16),

              // --- DISPLAY SETTINGS CARD ---
              _buildSectionCard(
                title: "DISPLAY SETTINGS",
                isDark: isDark,
                children: [
                  Row(
                    children: [
                      Icon(isDark ? Icons.dark_mode : Icons.light_mode, 
                        size: 20, color: const Color(0xFF5D7A5D)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text("Dark Mode", 
                          style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF2D3E2D)))
                      ),
                      Switch(
                        value: isDark,
                        onChanged: (value) => themeProvider.toggleTheme(value), // Global update
                        activeColor: Colors.white,
                        activeTrackColor: const Color(0xFF5D7A5D),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- SECURITY ACTIONS ---
              _buildSecurityButton(
                icon: Icons.lock_open_outlined, 
                label: "CHANGE PASSWORD", 
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()))
              ),
              const SizedBox(height: 12),

              // --- LOGOUT ACTION ---
              _buildLogoutButton(context),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENT BUILDERS ---

  Widget _buildProfileHeader(bool isDark) {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: isDark ? Colors.grey[800] : Colors.white,
              backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty) 
                  ? NetworkImage(_avatarUrl!) 
                  : null,
              child: (_avatarUrl == null) 
                  ? const Icon(Icons.person_outline, size: 45, color: Colors.black12) 
                  : null,
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: isDark ? Colors.grey[900] : Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.black12)),
                child: const Icon(Icons.camera_alt_outlined, size: 14, color: Colors.black38),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_fullName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2D3E2D))),
              Text(_email, style: const TextStyle(fontSize: 13, color: Colors.black38)),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            if (updated == true) _fetchUserData();
          },
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text("EDIT"),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF5D7A5D),
            side: const BorderSide(color: Colors.black12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A634A), letterSpacing: 0.5)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5D7A5D)),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    ),
  );

  Widget _buildSwitchRow(IconData icon, String label, bool value, Function(bool) onChanged) => Row(
    children: [
      Icon(icon, size: 20, color: const Color(0xFF5D7A5D)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
      Switch(value: value, onChanged: onChanged, activeColor: Colors.white, activeTrackColor: const Color(0xFF5D7A5D)),
    ],
  );

  Widget _buildSecurityButton({required IconData icon, required String label, required VoidCallback onTap}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2D3E2D),
          backgroundColor: const Color(0xFFD6E8D6).withOpacity(0.5),
          side: const BorderSide(color: Colors.black12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ),
  );

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout, size: 18, color: Colors.redAccent),
        label: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.redAccent.withOpacity(0.05),
          side: const BorderSide(color: Colors.redAccent, width: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              await _supabase.auth.signOut(); // Sign out from Supabase
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: const Text("LOGOUT", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBadge(bool isDark) => Stack(
    alignment: Alignment.center,
    children: [
      IconButton(icon: Icon(Icons.notifications_none, color: isDark ? Colors.white : const Color(0xFF2D3E2D)), onPressed: () {})
      
    ],
  );

  Widget _buildTopProfileIcon(bool isDark) => Padding(
    padding: const EdgeInsets.only(right: 16, left: 8),
    child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isDark ? Colors.grey[850] : const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.person_outline, color: isDark ? Colors.white70 : Colors.black54, size: 20)),
  );
}