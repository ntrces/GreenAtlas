import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme_constants.dart';

class EmployeePortal extends StatelessWidget {
  const EmployeePortal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softGreen,
      appBar: AppBar(
        title: const Text("Field Operations", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey, // Distinct color for Employees
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async => await Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            "Daily Tasks",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryForest),
          ),
          const SizedBox(height: 16),
          _taskCard("Record New Plant", "Log botanical data from the field", Icons.add_a_photo),
          _taskCard("Sync Offline Data", "Upload local records to Supabase", Icons.sync),
          _taskCard("View Schedule", "See assigned conservation zones", Icons.calendar_today),
        ],
      ),
    );
  }

  Widget _taskCard(String title, String subtitle, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(backgroundColor: softGreen, child: Icon(icon, color: primaryForest)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}