import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../theme_constants.dart';
import 'change_password.dart'; 
import '../UserProfile/edit_profile.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _supabase = Supabase.instance.client;
  
  String _fullName = "Loading...";
  String _email = "user@example.com";
  String _phone = "Not provided"; 
  String _location = "Loading location...";
  String _joinedDate = "Joined --";
  String? _avatarUrl; 
  bool _isLoading = true;

  bool _emailNotif = true;
  bool _pushNotif = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

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

  void _showLogoutDialog(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            "Logout Confirmation",
            style: textTheme.titleLarge?.copyWith(
              color: isDark ? Colors.white : Colors.black, 
            ),
          ),
          content: Text(
            "Are you sure you want to log out of your account?",
            style: textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "CANCEL", 
                style: textTheme.labelLarge?.copyWith(color: Colors.grey),
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
              child: Text("LOGOUT", style: textTheme.labelLarge),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0,
        title: Text(
          "Profile Settings", 
          style: textTheme.titleMedium?.copyWith(fontSize: 18),
        ),
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
                  _buildInfoRow(Icons.email_outlined, _email, isDark),
                  _buildInfoRow(Icons.phone_android_outlined, _phone, isDark),
                  _buildInfoRow(Icons.map_outlined, _location, isDark),
                  _buildInfoRow(Icons.calendar_month_outlined, _joinedDate, isDark),
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
                    },
                    isDark,
                  ),
                  _buildSwitchRow(
                    Icons.email_outlined, 
                    "Email Alerts", 
                    _emailNotif, 
                    (v) {
                      setState(() => _emailNotif = v);
                      _updateNotificationPreference('email_notifications_enabled', v);
                    },
                    isDark,
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
                    (v) => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(v),
                    isDark,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSecurityButton(
                icon: Icons.lock_reset, 
                label: "CHANGE PASSWORD", 
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen())),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    final textTheme = Theme.of(context).textTheme;
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
              Text(
                _fullName, 
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 20, 
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(_email, style: textTheme.bodySmall?.copyWith(color: Colors.grey)),
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
    final textTheme = Theme.of(context).textTheme;
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
          Text(
            title, 
            style: textTheme.labelSmall?.copyWith(
              color: const Color(0xFF5D7A5D), 
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Row(
      children: [
        Icon(icon, size: 18, color: isDark ? leafAccent : const Color(0xFF5D7A5D)),
        const SizedBox(width: 12),
        Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: getTextColor(isDark))),
      ],
    ),
  );

  Widget _buildSwitchRow(IconData icon, String label, bool value, Function(bool) onChanged, bool isDark) => Row(
    children: [
      Icon(icon, size: 18, color: isDark ? leafAccent : const Color(0xFF5D7A5D)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: getTextColor(isDark)))),
      Switch(value: value, onChanged: onChanged, activeColor: isDark ? leafAccent : const Color(0xFF5D7A5D)),
    ],
  );

  Widget _buildSecurityButton({required IconData icon, required String label, required VoidCallback onTap, required bool isDark}) => 
    SizedBox(
      width: double.infinity, 
      height: 50, 
      child: OutlinedButton.icon(
        onPressed: onTap, 
        icon: Icon(icon, size: 18, color: isDark ? leafAccent : Colors.black), 
        label: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: isDark ? Colors.white : Colors.black)), 
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : Colors.black, 
          side: BorderSide(color: isDark ? Colors.white24 : Colors.black12), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
        )
      )
    );

  Widget _buildLogoutButton(BuildContext context) => 
    SizedBox(
      width: double.infinity, 
      height: 50, 
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context), 
        icon: const Icon(Icons.logout), 
        label: Text("LOGOUT", style: Theme.of(context).textTheme.labelLarge), 
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent, 
          foregroundColor: Colors.white, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
          elevation: 0
        )
      )
    );
}