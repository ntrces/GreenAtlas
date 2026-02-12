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

  String? get _userId => _supabase.auth.currentUser?.id;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    if (_userId == null) return const Scaffold(body: Center(child: Text("Please sign in.")));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // FIXED: Stream the 'meetings' table directly so every meeting is visible
        stream: _supabase.from('meetings').stream(primaryKey: ['id']).order('meeting_date', ascending: true),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Sync Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF5D7A5D)));
          
          final meetings = snapshot.data!;

          // Fetch RSVPs for this user to determine 'user_status'
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('meeting_rsvps').stream(primaryKey: ['id']).eq('user_id', _userId!),
            builder: (context, rsvpSnapshot) {
              final userRSVPs = rsvpSnapshot.data ?? [];
              
              // Map RSVP status to meetings locally
              final fullMeetingData = meetings.map((m) {
                final rsvp = userRSVPs.firstWhere((r) => r['meeting_id'] == m['id'], orElse: () => {});
                return {
                  ...m,
                  'user_status': rsvp['status'], // Will be 'Accepted', 'Declined', or null
                };
              }).toList();

              // KPI Calculations
              final upcomingCount = fullMeetingData.length;
              final attendingCount = fullMeetingData.where((m) => m['user_status'] == 'Accepted').length;
              final rsvpNeeded = fullMeetingData.where((m) => m['user_status'] == null).length;

              final filteredMeetings = fullMeetingData.where((m) {
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
                    
                    if (filteredMeetings.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No meetings found.")))
                    else
                      ...filteredMeetings.map((m) => _buildMeetingCard(m, isDark)).toList(),
                  ],
                ),
              );
            }
          );
        },
      ),
    );
  }

  Widget _buildMeetingCard(Map<String, dynamic> m, bool isDark) {
    final String status = m['user_status'] == 'Accepted' ? "Attending" : "RSVP"; 
    final Color statusCol = m['user_status'] == 'Accepted' ? Colors.green : Colors.orange;

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeetingAttendanceScreen(meeting: m))),
      child: _buildMeetingTile(
        title: m['title'] ?? "Meeting",
        date: m['meeting_date'] ?? "",
        location: m['location'] ?? "",
        // Note: Global attending count still comes from your database summary if needed
        attendingCount: "${m['max_attendees'] ?? 0} capacity", 
        isDark: isDark,
        status: status,
        statusColor: statusCol,
        hasAttachment: m['attachment_url'] != null,
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget _buildHeader(bool d) => Text("Meetings & RSVP", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: d ? Colors.white : const Color(0xFF2D3E2D)));
  
  Widget _buildKPIRow(int up, int at, int rs, bool d) => Row(children: [
    Expanded(child: _statCard("$up", "Upcoming", d, Colors.blue)),
    const SizedBox(width: 10),
    Expanded(child: _statCard("$at", "Attending", d, Colors.green)),
    const SizedBox(width: 10),
    Expanded(child: _statCard("$rs", "Pending", d, Colors.orange)),
  ]);

  Widget _statCard(String v, String l, bool d, Color c) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: d ? const Color(0xFF1F1F1F) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.05))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [CircleAvatar(radius: 14, backgroundColor: c.withOpacity(0.1), child: Icon(Icons.circle, size: 8, color: c)), const SizedBox(height: 8), Text(v, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: d ? Colors.white : Colors.black)), Text(l, style: const TextStyle(fontSize: 10, color: Colors.black38))]));

  Widget _buildFilterRow(bool d) => Row(children: [_filtBtn("Upcoming", 0, d), const SizedBox(width: 8), _filtBtn("Attending", 1, d)]);

  Widget _filtBtn(String l, int i, bool d) => ChoiceChip(label: Text(l), selected: _activeFilterIndex == i, onSelected: (s) => setState(() => _activeFilterIndex = i), selectedColor: const Color(0xFF5D7A5D), labelStyle: TextStyle(color: _activeFilterIndex == i ? Colors.white : Colors.black54));

  Widget _buildMeetingTile({required String title, required String date, required String location, required String attendingCount, required bool isDark, required String status, required Color statusColor, required bool hasAttachment}) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: isDark ? const Color(0xFF1F1F1F) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.05))),
    child: Column(children: [
      Row(children: [
        Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black))),
        if (hasAttachment) const Icon(Icons.attach_file, size: 14, color: Colors.black26),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, size: 16, color: Colors.black26),
      ]),
      const SizedBox(height: 4),
      Row(children: [Text("$date • $location", style: const TextStyle(fontSize: 12, color: Colors.black45))]),
      const Divider(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(attendingCount, style: const TextStyle(fontSize: 11, color: Colors.black38)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold))),
      ])
    ]),
  );
}