import 'package:flutter/material.dart';

class MeetingsScreen extends StatelessWidget {
  const MeetingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Field Meetings", style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildMeetingTile("Weekly Ecosystem Review", "Feb 09, 2026 · 9:00 AM", "Confirmed", Colors.green),
          _buildMeetingTile("AR Tool Training", "Feb 12, 2026 · 2:00 PM", "Pending", Colors.orange),
        ],
      ),
    );
  }

  Widget _buildMeetingTile(String title, String date, String status, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Color(0xFF5D7A5D)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(date),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
        ),
      ),
    );
  }
}