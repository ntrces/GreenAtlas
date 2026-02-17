import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';
import '../../UserProfile/user_profile.dart'; 
import 'Attendance.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});
  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  final _supabase = Supabase.instance.client;
  int _activeFilterIndex = 0; // 0: All, 1: Attending, 2: Not Attending

  String? get _userId => _supabase.auth.currentUser?.id;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    if (_userId == null) return const Scaffold(body: Center(child: Text("Please sign in.")));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Transform.scale(
              scale: 1.3,
              child: Image.asset('assets/logo2.png', fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Color(0xFF2D3E2D))),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Meetings & RSVP", 
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 18)),
            const Text("View invitations and submit confirmations", style: TextStyle(color: Colors.black38, fontSize: 10)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileScreen())),
              child: Container(
                height: 40, width: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF0F4F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black12),
                ),
                child: const Icon(Icons.person_outline, color: Colors.black54, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('meetings').stream(primaryKey: ['id']).order('meeting_date', ascending: true),
        builder: (context, meetingSnapshot) {
          if (meetingSnapshot.hasError) return Center(child: Text("Sync Error: ${meetingSnapshot.error}"));
          if (!meetingSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF5D7A5D)));
          
          final meetings = meetingSnapshot.data!.where((m) {
            final List roles = m['target_roles'] ?? [];
            return roles.contains('Field Officer');
          }).toList();

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('meeting_rsvps').stream(primaryKey: ['id']).eq('user_id', _userId!),
            builder: (context, rsvpSnapshot) {
              final userRSVPs = rsvpSnapshot.data ?? [];
              
              final List<Map<String, dynamic>> consolidatedData = meetings.map((m) {
                final rsvp = userRSVPs.firstWhere((r) => r['meeting_id'] == m['id'], orElse: () => {});
                return {
                  ...m,
                  'user_status': rsvp['status'], 
                };
              }).toList();

              final upcomingCount = consolidatedData.length;
              final attendingCount = consolidatedData.where((m) => m['user_status'] == 'Accepted').length;
              final rsvpNeeded = consolidatedData.where((m) => m['user_status'] == null).length;

              // FIXED: Added Logic for new filters
              final filteredMeetings = consolidatedData.where((m) {
                if (_activeFilterIndex == 1) return m['user_status'] == 'Accepted';
                if (_activeFilterIndex == 2) return m['user_status'] == 'Declined';
                return true;
              }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKPIRow(upcomingCount, attendingCount, rsvpNeeded, isDark),
                    const SizedBox(height: 24),
                    _buildFilterRow(isDark), // Now supports 3 options
                    const SizedBox(height: 24),
                    
                    Text(_getTitleForFilter(), 
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 1.2)),
                    const SizedBox(height: 12),

                    if (filteredMeetings.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No meetings found.")))
                    else
                      ...filteredMeetings.map((m) => _buildMeetingCard(m, isDark)).toList(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- UI COMPONENTS ---

  String _getTitleForFilter() {
    if (_activeFilterIndex == 1) return "MY ATTENDANCE";
    if (_activeFilterIndex == 2) return "DECLINED MEETINGS";
    return "UPCOMING MEETINGS";
  }
  
  Widget _buildKPIRow(int up, int at, int rs, bool d) => Row(children: [
    Expanded(child: _statCard("$up", "Upcoming", d, Colors.blue)),
    const SizedBox(width: 10),
    Expanded(child: _statCard("$at", "Attending", d, Colors.green)),
    const SizedBox(width: 10),
    Expanded(child: _statCard("$rs", "Pending", d, Colors.orange)),
  ]);

  Widget _statCard(String v, String l, bool d, Color c) => Container(
    padding: const EdgeInsets.all(12), 
    decoration: BoxDecoration(
      color: d ? const Color(0xFF1F1F1F) : Colors.white, 
      borderRadius: BorderRadius.circular(12), 
      border: Border.all(color: Colors.black.withOpacity(0.05))
    ), 
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CircleAvatar(radius: 14, backgroundColor: c.withOpacity(0.1), child: Icon(Icons.circle, size: 8, color: c)), 
      const SizedBox(height: 8), 
      Text(v, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: d ? Colors.white : Colors.black)), 
      Text(l, style: const TextStyle(fontSize: 10, color: Colors.black38))
    ])
  );

  // FIXED: Filter Row now includes Not Attending
  Widget _buildFilterRow(bool d) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: [
      _filtBtn("Upcoming", 0, d), 
      const SizedBox(width: 8), 
      _filtBtn("Attending", 1, d),
      const SizedBox(width: 8),
      _filtBtn("Not Attending", 2, d),
    ]),
  );

  Widget _filtBtn(String l, int i, bool d) => ChoiceChip(
    label: Text(l), selected: _activeFilterIndex == i, 
    onSelected: (s) => setState(() => _activeFilterIndex = i), 
    selectedColor: const Color(0xFF5D7A5D), 
    labelStyle: TextStyle(color: _activeFilterIndex == i ? Colors.white : Colors.black54),
    backgroundColor: d ? Colors.white10 : Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    showCheckmark: false,
  );

  Widget _buildMeetingCard(Map<String, dynamic> m, bool isDark) {
    final status = m['user_status'];
    final bool isAttending = status == 'Accepted';
    final bool isDeclined = status == 'Declined';
    
    String label = "RSVP";
    Color color = Colors.orange;

    if (isAttending) {
      label = "Attending";
      color = Colors.green;
    } else if (isDeclined) {
      label = "Declined";
      color = Colors.red;
    }

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeetingAttendanceScreen(meeting: m))),
      child: _buildMeetingTile(
        title: m['title'] ?? "Meeting",
        date: m['meeting_date'] ?? "",
        location: m['location'] ?? "",
        attendingCount: "${m['max_attendees'] ?? 0} capacity", 
        isDark: isDark,
        status: label,
        statusColor: color,
        hasAttachment: m['attachment_url'] != null, 
      ),
    );
  }

  Widget _buildMeetingTile({required String title, required String date, required String location, required String attendingCount, required bool isDark, required String status, required Color statusColor, required bool hasAttachment}) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white, 
      borderRadius: BorderRadius.circular(12), 
      border: Border.all(color: Colors.black.withOpacity(0.05))
    ),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), 
          child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold))
        ),
      ])
    ]),
  );
}