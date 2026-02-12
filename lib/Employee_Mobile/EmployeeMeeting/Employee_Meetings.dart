import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';
import 'Attendance.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});
  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  final _supabase = Supabase.instance.client;
  int _activeFilterIndex = 0;

  // Get current user ID to isolate their choices
  String? get _userId => _supabase.auth.currentUser?.id;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // FIXED: Filtering the stream so it only shows RSVP data for THIS user
        stream: _supabase
            .from('meeting_user_details')
            .stream(primaryKey: ['meeting_id'])
            .eq('user_id', _userId ?? '') // Isolate personal input
            .order('meeting_date', ascending: true),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final meetings = snapshot.data!;
          
          // Personalized KPI calculations
          final upcomingCount = meetings.length;
          final attendingCount = meetings.where((m) => m['user_status'] == 'Accepted').length;
          final rsvpNeeded = meetings.where((m) => m['user_status'] == null).length;

          final filteredMeetings = meetings.where((m) {
            if (_activeFilterIndex == 1) return m['user_status'] == 'Accepted';
            return true;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDark),
                const SizedBox(height: 24),
                _buildKPIRow(upcomingCount, attendingCount, rsvpNeeded, isDark),
                const SizedBox(height: 24),
                _buildFilterRow(isDark),
                const SizedBox(height: 24),
                ...filteredMeetings.map((m) => _buildMeetingCard(m, isDark)).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeetingCard(Map<String, dynamic> m, bool isDark) {
    final String status = m['user_status'] ?? "RSVP"; // Individual choice
    final Color statusCol = status == 'Accepted' ? Colors.green : Colors.orange;

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeetingAttendanceScreen(meeting: m))),
      child: _buildMeetingTile(
        title: m['title'] ?? "Meeting",
        date: m['meeting_date'] ?? "",
        location: m['location'] ?? "",
        attendingCount: "${m['accepted_count'] ?? 0}/${m['max_attendees'] ?? 0} attending",
        isDark: isDark,
        status: status == 'Accepted' ? 'Attending' : 'RSVP',
        statusColor: statusCol,
      ),
    );
  }

  // (Helper methods for header, KPI, and Filter remain consistent with your design)
  // Ensure _buildMeetingTile uses the dynamic 'status' and 'statusColor' passed above.
  
  Widget _buildMeetingTile({required String title, required String date, required String location, required String attendingCount, required bool isDark, required String status, required Color statusColor}) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: isDark ? const Color(0xFF1F1F1F) : Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$date • $location"),
        trailing: const Icon(Icons.chevron_right),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(attendingCount, style: const TextStyle(fontSize: 11, color: Colors.black38)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
          )
        ],
      )
    ]),
  );

  Widget _buildHeader(bool isDark) => const Text("Meetings & RSVP", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
  Widget _buildKPIRow(int up, int at, int rs, bool d) => Row(children: [Expanded(child: _statCard("$up", "Upcoming", d)), const SizedBox(width: 8), Expanded(child: _statCard("$at", "Attending", d)), const SizedBox(width: 8), Expanded(child: _statCard("$rs", "Need RSVP", d))]);
  Widget _statCard(String v, String l, bool d) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: d ? Colors.white10 : Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(l, style: const TextStyle(fontSize: 10))]));
  Widget _buildFilterRow(bool d) => Row(children: [ChoiceChip(label: const Text("Upcoming"), selected: _activeFilterIndex == 0, onSelected: (s) => setState(() => _activeFilterIndex = 0)), const SizedBox(width: 8), ChoiceChip(label: const Text("Attending"), selected: _activeFilterIndex == 1, onSelected: (s) => setState(() => _activeFilterIndex = 1))]);
}