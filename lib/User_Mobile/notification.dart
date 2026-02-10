import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA), // Thematic mint background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3E2D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text("Mark all as read", style: TextStyle(color: Color(0xFF5D7A5D), fontSize: 12)),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("TODAY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildNotifTile(
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            title: "Report Resolved",
            body: "Your report RPT-001 (Illegal Logging) has been marked as resolved. Thank you!",
            time: "2h ago",
            isUnread: true,
          ),
          _buildNotifTile(
            icon: Icons.info_outline,
            iconColor: Colors.orange,
            title: "Investigation Update",
            body: "A Forest Ranger is currently on-site investigating your report in Zone A-2.",
            time: "5h ago",
            isUnread: true,
          ),
          const SizedBox(height: 20),
          const Text("YESTERDAY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildNotifTile(
            icon: Icons.assignment_turned_in_outlined,
            iconColor: const Color(0xFF5D7A5D),
            title: "Report Submitted",
            body: "Your report regarding Water Pollution has been successfully received.",
            time: "1d ago",
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _buildNotifTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? Colors.white : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isUnread ? const Color(0xFF5D7A5D).withOpacity(0.2) : Colors.black12),
        boxShadow: [
          if (isUnread) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3E2D))),
                    Text(time, style: const TextStyle(fontSize: 11, color: Colors.black38)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                ),
              ],
            ),
          ),
          if (isUnread)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4),
              child: Container(height: 8, width: 8, decoration: const BoxDecoration(color: Color(0xFF5D7A5D), shape: BoxShape.circle)),
            ),
        ],
      ),
    );
  }
}