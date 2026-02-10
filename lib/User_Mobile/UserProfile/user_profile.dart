import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile.dart'; // Fixed import path
import 'change_password.dart'; // Fixed typo 'mport' and path

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _supabase = Supabase.instance.client;
  String _fullName = "Loading...";
  String _email = "user@example.com";
  String _phone = "0917-123-4567";
  String _location = "Cavite, Philippines";
  String _joinedDate = "Joined 2025-01-15";
  String? _avatarUrl; 
  bool _isLoading = true;

  bool _emailNotif = true;
  bool _pushNotif = true;
  bool _reportUpdates = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // --- FETCH DATA FROM DATABASE ---
  Future<void> _fetchUserData() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = await _supabase.from('profiles').select().eq('id', user.id).single();
        if (mounted) {
          setState(() {
            _fullName = data['full_name'] ?? "User";
            _email = user.email ?? _email;
            _phone = data['phone'] ?? _phone;
            _location = data['location'] ?? "Cavite, Philippines";
            _avatarUrl = data['avatar_url']; 
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3E2D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Profile", style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Account settings • Preferences", style: TextStyle(color: Colors.black38, fontSize: 11)),
          ],
        ),
        actions: [
          _buildNotificationBadge(),
          _buildTopProfileIcon(),
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
              _buildProfileHeader(),
              const SizedBox(height: 24),
              _buildSectionCard(
                title: "PERSONAL INFORMATION",
                children: [
                  _buildInfoRow(Icons.email_outlined, _email),
                  _buildInfoRow(Icons.phone_outlined, _phone),
                  _buildInfoRow(Icons.location_on_outlined, _location),
                  _buildInfoRow(Icons.calendar_today_outlined, _joinedDate),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: "NOTIFICATION SETTINGS",
                children: [
                  _buildSwitchRow(Icons.notifications_none, "Email Notifications", _emailNotif, (v) => setState(() => _emailNotif = v)),
                  _buildSwitchRow(Icons.notifications_active_outlined, "Push Notifications", _pushNotif, (v) => setState(() => _pushNotif = v)),
                  _buildSwitchRow(Icons.check_circle_outline, "Report Updates", _reportUpdates, (v) => setState(() => _reportUpdates = v)),
                ],
              ),
              const SizedBox(height: 24),

              // --- SECURITY SECTION ---
              _buildSecurityButton(
                Icons.lock_open_outlined, 
                "CHANGE PASSWORD", 
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
            
            ],
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENT HELPERS ---

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                  ? NetworkImage(_avatarUrl!)
                  : null,
              child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                  ? const Icon(Icons.person_outline, size: 45, color: Colors.black12)
                  : null,
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  shape: BoxShape.circle, 
                  border: Border.all(color: Colors.black12)
                ),
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
              Text(_fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
              Text(_email, style: const TextStyle(fontSize: 13, color: Colors.black38)),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final bool? updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            if (updated == true) _fetchUserData(); 
          },
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text("EDIT"),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF5D7A5D), 
            side: const BorderSide(color: Colors.black12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A634A), letterSpacing: 0.5)),
        const SizedBox(height: 20),
        ...children,
      ]),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(children: [Icon(icon, size: 20, color: const Color(0xFF5D7A5D)), const SizedBox(width: 12), Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF2D3E2D)))]),
  );

  Widget _buildSwitchRow(IconData icon, String label, bool value, Function(bool) onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5D7A5D)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF2D3E2D)))),
        Switch(value: value, onChanged: onChanged, activeColor: Colors.white, activeTrackColor: const Color(0xFF5D7A5D)),
      ],
    ),
  );

  Widget _buildSecurityButton(IconData icon, String label, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: SizedBox(
      width: double.infinity, height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap, icon: Icon(icon, size: 18), label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2D3E2D), 
          backgroundColor: const Color(0xFFD6E8D6).withOpacity(0.5),
          side: const BorderSide(color: Colors.black12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
        ),
      ),
    ),
  );

  Widget _buildNotificationBadge() => Stack(alignment: Alignment.center, children: [
    IconButton(icon: const Icon(Icons.notifications_none, color: Color(0xFF2D3E2D)), onPressed: () {}),
    Positioned(right: 8, top: 12, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Text("2", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
  ]);

  Widget _buildTopProfileIcon() => Padding(
    padding: const EdgeInsets.only(right: 16, left: 8), 
    child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.person_outline, color: Colors.black54, size: 20))
  );
}