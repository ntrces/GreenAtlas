import 'package:flutter/material.dart';

class MeetingCoordinationView extends StatelessWidget {
  const MeetingCoordinationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("MEETING COORDINATION", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text("Schedule field briefings • Manage staff RSVP", style: TextStyle(fontSize: 13, color: Colors.black38)),
              ],
            ),
            ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text("NEW MEETING")),
          ],
        ),
        const SizedBox(height: 32),
        _meetingCard("Weekly Reforestation Update", "Tomorrow, 09:00 AM", "Cavite Main Hub", "12 Staff Confirmed"),
        _meetingCard("Illegal Logging Incident Review", "Feb 15, 02:00 PM", "Zoom / Virtual", "4 Pending RSVP"),
      ],
    );
  }

  Widget _meetingCard(String title, String time, String loc, String rsvp) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
    child: Row(
      children: [
        const CircleAvatar(backgroundColor: Color(0xFFF0F4F0), child: Icon(Icons.calendar_today, size: 18, color: Color(0xFF4D6D4D))),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("$time • $loc", style: const TextStyle(color: Colors.black45, fontSize: 12)),
            ],
          ),
        ),
        Text(rsvp, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4D6D4D), fontSize: 13)),
        const SizedBox(width: 20),
        const Icon(Icons.chevron_right, color: Colors.black26),
      ],
    ),
  );
}