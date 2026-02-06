import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme_constants.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softGreen,
      appBar: AppBar(
        title: const Text("Admin Panel", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent, // Distinct color for Admins
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async => await Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Management Overview",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryForest),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _adminTile(Icons.people, "Manage Users", Colors.blue),
                  _adminTile(Icons.eco, "Plant Database", Colors.green),
                  _adminTile(Icons.analytics, "Activity Logs", Colors.orange),
                  _adminTile(Icons.settings, "System Settings", Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminTile(IconData icon, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}