import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';
import '../../User_Mobile/UserProfile/user_profile.dart';
import 'Attendance.dart'; // Verified path

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  int _activeFilterIndex = 0;
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: Color(0xFF5D7A5D),
            child: Icon(Icons.eco, color: Colors.white, size: 24),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Meetings & RSVP", 
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 20)),
            const Text("View invitations and submit confirmations", style: TextStyle(color: Colors.black38, fontSize: 11)),
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
      // --- REAL-TIME COORDINATION ---
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('meetings').stream(primaryKey: ['id']).order('date', ascending: true),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Sync Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final meetings = snapshot.data!;
          
          // COORDINATED KPI STATS
          final upcomingCount = meetings.length;
          final attendingCount = meetings.where((m) => m['user_status'] == 'Attending').length;
          final rsvpNeeded = meetings.where((m) => m['user_status'] == 'RSVP' || m['user_status'] == null).length;

          // FILTERING LOGIC
          final filteredMeetings = meetings.where((m) {
            if (_activeFilterIndex == 1) return m['user_status'] == 'Attending';
            return true;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI GRID
                Row(
                  children: [
                    Expanded(child: _buildStatCard(Icons.calendar_today_outlined, "$upcomingCount", "Upcoming", isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatCard(Icons.check_circle_outline, "$attendingCount", "Attending", isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatCard(Icons.error_outline, "$rsvpNeeded", "Need RSVP", isDark, iconColor: Colors.orange)),
                  ],
                ),
                const SizedBox(height: 24),

                // FILTER CHIPS
                Row(
                  children: [
                    _buildFilter("Upcoming", 0, Icons.calendar_today, isDark),
                    const SizedBox(width: 8),
                    _buildFilter("Attending", 1, Icons.check_circle_outline, isDark),
                  ],
                ),
                const SizedBox(height: 24),

                Text(_activeFilterIndex == 0 ? "UPCOMING MEETINGS" : "MY ATTENDANCE", 
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 1.2)),
                const SizedBox(height: 12),

                if (filteredMeetings.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No meetings scheduled.")))
                else
                  ...filteredMeetings.map((m) => InkWell(
                    // --- NAVIGATION COORDINATION ---
                    onTap: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => MeetingAttendanceScreen(meeting: m))
                    ),
                    child: _buildMeetingTile(
                      title: m['title'] ?? "Untitled Meeting",
                      date: m['date'] ?? "Date TBD",
                      location: m['location'] ?? "Location TBD",
                      attendingCount: "${m['attending_total'] ?? 0}/${m['capacity'] ?? 0} attending",
                      isDark: isDark,
                      tag: m['is_mandatory'] == true ? "Required" : null,
                      status: m['user_status'] ?? "RSVP",
                      statusColor: m['user_status'] == 'Attending' ? Colors.green : Colors.orange,
                    ),
                  )).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI DETAIL HELPERS ---
  Widget _buildStatCard(IconData icon, String value, String label, bool isDark, {Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1F1F1F) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 16, backgroundColor: isDark ? Colors.white10 : const Color(0xFFF0F4F0), child: Icon(icon, color: iconColor ?? const Color(0xFF5D7A5D), size: 16)),
        const SizedBox(height: 12),
        Row(children: [Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 9, color: Colors.black38, fontWeight: FontWeight.w500))])
      ]),
    );
  }

  Widget _buildFilter(String label, int index, IconData icon, bool isDark) {
    bool isSelected = _activeFilterIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeFilterIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF5D7A5D) : (isDark ? Colors.white10 : const Color(0xFFE8F3E8)), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF5D7A5D)), const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF5D7A5D)))]),
      ),
    );
  }

  Widget _buildMeetingTile({required String title, required String date, required String location, required String attendingCount, required bool isDark, String? tag, required String status, required Color statusColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1F1F1F) : Colors.white, border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)))),
      child: Column(children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          title: Row(children: [
            Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black))),
            if (tag != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(tag, style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold))),
            const SizedBox(width: 8), const Icon(Icons.chevron_right, size: 16, color: Colors.black12),
          ]),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 6),
            Row(children: [const Icon(Icons.calendar_today, size: 12, color: Colors.black26), const SizedBox(width: 6), Text(date, style: const TextStyle(fontSize: 11))]),
            const SizedBox(height: 4),
            Row(children: [const Icon(Icons.location_on_outlined, size: 12, color: Colors.black26), const SizedBox(width: 6), Text(location, style: const TextStyle(fontSize: 11))]),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(attendingCount, style: const TextStyle(fontSize: 11, color: Colors.black38)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Row(children: [Icon(status == "Attending" ? Icons.check_circle_outline : Icons.access_time, size: 12, color: statusColor), const SizedBox(width: 4), Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold))])),
          ]),
        )
      ]),
    );
  }
}