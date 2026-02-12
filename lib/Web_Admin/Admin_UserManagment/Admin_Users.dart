import 'package:flutter/material.dart';

class UserManagementView extends StatelessWidget {
  const UserManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("USER MANAGEMENT", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const Text("Access control • Staff roles • Account security", style: TextStyle(fontSize: 13, color: Colors.black38)),
        const SizedBox(height: 32),
        Wrap(
          spacing: 24, runSpacing: 24,
          children: [
            _userStat("2,401", "Citizen Users"),
            _userStat("15", "Field Rangers"),
            _userStat("3", "System Admins"),
          ],
        ),
        const SizedBox(height: 32),
        // Add a table or list of users here...
      ],
    );
  }

  Widget _userStat(String count, String label) => Container(
    width: 200, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
    child: Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4D6D4D))),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black38, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}