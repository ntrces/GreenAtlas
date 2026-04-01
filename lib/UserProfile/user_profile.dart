import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';
import 'change_password.dart'; 
import '../UserProfile/edit_profile.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _supabase = Supabase.instance.client;
  
  // Dynamic User Data
  String _fullName = "Loading...";
  String _email = "user@example.com";
  String _phone = "Not provided"; 
  String _location = "Loading location...";
  String _joinedDate = "Joined --";
  String? _avatarUrl; 
  bool _isLoading = true;

  // Notification Preference States
  bool _emailNotif = true;
  bool _pushNotif = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // --- 🔄 DATABASE SYNC: UPDATE PREFERENCES ---
  Future<void> _updateNotificationPreference(String column, bool value) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('profiles')
          .update({column: value})
          .eq('id', user.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${column.split('_')[0].toUpperCase()} preference updated!"),
            duration: const Duration(milliseconds: 800),
            backgroundColor: const Color(0xFF5D7A5D),
          ),
        );
      }
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }

  // --- 📥 DATABASE FETCH: LOAD USER DATA ---
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
            _phone = (data['phone'] != null && data['phone'].isNotEmpty) ? data['phone'] : "Add phone number";
            
            _emailNotif = data['email_notifications_enabled'] ?? true;
            _pushNotif = data['push_notifications_enabled'] ?? true;

            String muni = data['municipality'] ?? "";
            String city = data['city'] ?? "";
            _location = (muni.isNotEmpty || city.isNotEmpty) ? "$muni, $city" : "Location not set";

            if (data['created_at'] != null) {
              DateTime dt = DateTime.parse(data['created_at']);
              List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
              _joinedDate = "Joined ${months[dt.month - 1]} ${dt.year}";
            }

            _avatarUrl = data['avatar_url'];
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
        debugPrint("Load Error: $e");
      }
    }
  }

  // --- 🚪 LOGOUT CONFIRMATION DIALOG ---
  void _showLogoutDialog(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            "Logout Confirmation",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black, 
              fontWeight: FontWeight.bold
            ),
          ),
          content: Text(
            "Are you sure you want to log out of your account?",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "CANCEL", 
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _supabase.auth.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0,
        title: const Text("Profile Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUserData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildProfileHeader(isDark),
              const SizedBox(height: 24),
              
              _buildSectionCard(
                title: "PERSONAL INFORMATION",
                isDark: isDark,
                children: [
                  _buildInfoRow(Icons.email_outlined, _email),
                  _buildInfoRow(Icons.phone_android_outlined, _phone),
                  _buildInfoRow(Icons.map_outlined, _location),
                  _buildInfoRow(Icons.calendar_month_outlined, _joinedDate),
                ],
              ),
              const SizedBox(height: 16),

              _buildSectionCard(
                title: "NOTIFICATION PREFERENCES",
                isDark: isDark,
                children: [
                  _buildSwitchRow(
                    Icons.notifications_active_outlined, 
                    "Push Notifications (Mobile)", 
                    _pushNotif, 
                    (v) {
                      setState(() => _pushNotif = v);
                      _updateNotificationPreference('push_notifications_enabled', v);
                    }
                  ),
                  _buildSwitchRow(
                    Icons.email_outlined, 
                    "Email Alerts", 
                    _emailNotif, 
                    (v) {
                      setState(() => _emailNotif = v);
                      _updateNotificationPreference('email_notifications_enabled', v);
                    }
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildSectionCard(
                title: "DISPLAY",
                isDark: isDark,
                children: [
                  _buildSwitchRow(
                    Icons.dark_mode_outlined, 
                    "Dark Mode", 
                    isDark, 
                    (v) => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(v)
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSecurityButton(
                icon: Icons.lock_reset, 
                label: "CHANGE PASSWORD", 
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()))
              ),
              const SizedBox(height: 12),
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget _buildProfileHeader(bool isDark) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.white,
          backgroundImage: (_avatarUrl != null) ? NetworkImage(_avatarUrl!) : null,
          child: (_avatarUrl == null) ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_fullName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              Text(_email, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF5D7A5D), size: 30),
          onPressed: () async {
            final updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            if (updated == true) _fetchUserData();
          },
        )
      ],
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white, 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF5D7A5D), letterSpacing: 1.0)),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF5D7A5D)),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    ),
  );

  Widget _buildSwitchRow(IconData icon, String label, bool value, Function(bool) onChanged) => Row(
    children: [
      Icon(icon, size: 18, color: const Color(0xFF5D7A5D)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
      Switch(value: value, onChanged: onChanged, activeTrackColor: const Color(0xFF5D7A5D)),
    ],
  );

  Widget _buildSecurityButton({required IconData icon, required String label, required VoidCallback onTap}) => 
    SizedBox(
      width: double.infinity, 
      height: 50, 
      child: OutlinedButton.icon(
        onPressed: onTap, 
        icon: Icon(icon, size: 18), 
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), 
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black, 
          side: const BorderSide(color: Colors.black12), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
        )
      )
    );

  Widget _buildLogoutButton(BuildContext context) => 
    SizedBox(
      width: double.infinity, 
      height: 50, 
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context), // Trigger the confirmation popup
        icon: const Icon(Icons.logout), 
        label: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold)), 
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent, 
          foregroundColor: Colors.white, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
          elevation: 0
        )
      )
    );
}