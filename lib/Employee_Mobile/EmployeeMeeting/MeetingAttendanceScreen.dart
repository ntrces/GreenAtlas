import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../theme_provider.dart';
import 'cannotattend.dart';

class MeetingAttendanceScreen extends StatelessWidget {
  final Map<String, dynamic> meeting;
  const MeetingAttendanceScreen({super.key, required this.meeting});

  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);
  final Color lightGreenBG = const Color(0xFFEAF7EA);

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final rawDate = meeting['meeting_date'] ?? DateTime.now().toString();
    final formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(rawDate));
    final String time = meeting['meeting_time'] ?? "N/A";
    final String location = meeting['location'] ?? "N/A";
    final String meetingId = (meeting['id'] ?? "000").toString().substring(0, 3).toUpperCase();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : lightGreenBG,
      appBar: AppBar(
        backgroundColor: darkGreen, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Column(children: [Text(meeting['title'] ?? "Meeting", style: const TextStyle(color: Colors.white, fontSize: 16)), Text("MTG-$meetingId", style: const TextStyle(color: Colors.white70, fontSize: 10))]),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: forestGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text("Attending", style: TextStyle(color: forestGreen, fontSize: 12))),
              ]),
              const SizedBox(height: 24),
              _buildWhiteCard([Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildIconDetail(Icons.calendar_today_outlined, "Date", formattedDate), _buildIconDetail(Icons.access_time, "Time", time), _buildIconDetail(Icons.location_on_outlined, "Location", location)])]),
              const Text("Agenda Description", style: TextStyle(color: Colors.black38, fontSize: 12)),
              const SizedBox(height: 8),
              Text(meeting['agenda'] ?? "No agenda description.", style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: forestGreen.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: forestGreen.withOpacity(0.2))),
                child: Row(children: [
                  CircleAvatar(radius: 12, backgroundColor: forestGreen, child: const Icon(Icons.check, color: Colors.white, size: 14)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("You're attending", style: TextStyle(color: forestGreen, fontSize: 14)),
                    const Text("See you there!", style: TextStyle(color: Colors.black38, fontSize: 11)),
                  ]),
                ]),
              ),
            ]),
          )),
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Want to change your response?", style: TextStyle(color: Colors.black38, fontSize: 12)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: ElevatedButton(onPressed: null, style: ElevatedButton.styleFrom(disabledBackgroundColor: forestGreen.withOpacity(0.1), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0), child: Text("Attending (confirmed)", style: TextStyle(color: forestGreen, fontSize: 13)))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CannotAttendScreen(meeting: meeting))), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Colors.redAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("Cannot Attend", style: TextStyle(color: Colors.redAccent, fontSize: 13)))),
            ]),
          ])),
        ],
      ),
    );
  }

  Widget _buildWhiteCard(List<Widget> children) => Container(width: double.infinity, padding: const EdgeInsets.all(20), margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children));
  Widget _buildIconDetail(IconData icon, String label, String value) => Column(children: [Icon(icon, color: forestGreen, size: 20), const SizedBox(height: 8), Text(label, style: const TextStyle(color: Colors.black38, fontSize: 10)), Text(value, style: const TextStyle(color: Colors.black87, fontSize: 12))]);
}