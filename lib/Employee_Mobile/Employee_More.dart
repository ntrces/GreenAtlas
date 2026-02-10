import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MoreSettingsScreen extends StatelessWidget {
  const MoreSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("More Options", style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSettingsTile(Icons.person_outline, "Account Profile"),
          _buildSettingsTile(Icons.sync, "Sync Offline Data"),
          _buildSettingsTile(Icons.help_outline, "Help & Support"),
          const Divider(height: 40),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () async => await Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF5D7A5D)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26),
      onTap: () {},
    );
  }
}