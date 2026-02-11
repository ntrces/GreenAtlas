import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';

class MeetingAttendanceScreen extends StatelessWidget {
  final Map<String, dynamic> meeting;

  const MeetingAttendanceScreen({super.key, required this.meeting});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(meeting['title'] ?? "Meeting Details", 
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(meeting['id'] ?? "MTG-001", 
              style: const TextStyle(color: Colors.black38, fontSize: 11)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP STATUS TAGS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTag(Icons.access_time, "RSVP Required", const Color(0xFFE8F3E8), const Color(0xFF5D7A5D)),
                _buildTag(null, "Mandatory", const Color(0xFFFFEBEE), Colors.redAccent),
              ],
            ),
            const SizedBox(height: 16),

            // --- PRIMARY INFO BOX (GREEN) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE1ECE1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildIconRow(Icons.calendar_today, "2026-02-05", subText: "10:00 AM - 12:00 PM"),
                  const SizedBox(height: 16),
                  _buildIconRow(Icons.location_on_outlined, "DENR Cavite Office"),
                  const SizedBox(height: 16),
                  _buildIconRow(Icons.people_outline, "12 / 25 attending"),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- ORGANIZED BY CARD ---
            _buildInfoCard(
              isDark: isDark,
              label: "Organized by",
              value: "Admin Team",
            ),
            const SizedBox(height: 16),

            // --- ABOUT SECTION ---
            _buildInfoCard(
              isDark: isDark,
              label: "About this meeting",
              value: "Review monthly conservation activities, field reports, and upcoming initiatives. Attendance is mandatory for all field officers.",
            ),
            const SizedBox(height: 32),

            // --- ATTENDANCE BUTTONS ---
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Logic to update Supabase status to 'Attending'
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                label: const Text("I will attend", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D7A5D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel_outlined, color: Colors.black45, size: 20),
                label: const Text("Cannot attend", style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENT HELPERS ---

  Widget _buildTag(IconData? icon, String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 14, color: textColor),
          if (icon != null) const SizedBox(width: 6),
          Text(label, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildIconRow(IconData icon, String text, {String? subText}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5D7A5D)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
            if (subText != null) Text(subText, style: const TextStyle(fontSize: 11, color: Colors.black38)),
          ],
        )
      ],
    );
  }

  Widget _buildInfoCard({required bool isDark, required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black38)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF2D3E2D))),
        ],
      ),
    );
  }
}