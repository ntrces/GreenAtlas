import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../../theme_provider.dart';
import '../../UserProfile/user_profile.dart';
import '../EmployeeNotification/employeenotif.dart';
import '../EmployeeMeeting/required_meetingview.dart'; // Ensure this matches your actual file name
import '../Field_Diary/Employee_FieldDiary.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});
  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  final _supabase = Supabase.instance.client;
  int _activeFilterIndex = 0; 
  String _searchQuery = ""; 

  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);
  final Color lightGreenBG = const Color(0xFFEAF7EA);
  final Color errorRed = const Color(0xFFD32F2F);
  final Color accentOrange = const Color(0xFFF2994A);

  String? get _userId => _supabase.auth.currentUser?.id;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textTheme = Theme.of(context).textTheme;

    if (_userId == null) return const Scaffold(body: Center(child: Text("Please sign in.")));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : lightGreenBG,
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, isDark, textTheme),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('meetings').stream(primaryKey: ['id']).order('meeting_date'),
            builder: (context, meetingSnapshot) {
              if (meetingSnapshot.hasError) return const SliverFillRemaining(child: Center(child: Text("Sync Error")));
              if (!meetingSnapshot.hasData) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));

              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: _supabase.from('meeting_rsvps').stream(primaryKey: ['id']).eq('user_id', _userId!),
                builder: (context, rsvpSnapshot) {
                  final userRSVPs = rsvpSnapshot.data ?? [];
                  final meetings = meetingSnapshot.data!;

                  // Logic: Joining Meeting details with User's RSVP status (attending/declined)
                  final consolidated = meetings.where((m) {
                    String rolesString = (m['target_roles'] ?? '').toString().toLowerCase().replaceAll(' ', '');
                    bool matchesRole = rolesString.contains('fieldofficer');
                    bool matchesSearch = _searchQuery == "" || (m['title'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
                    return matchesRole && matchesSearch;
                  }).map((m) {
                    final rsvp = userRSVPs.firstWhere((r) => r['meeting_id'] == m['id'], orElse: () => <String, dynamic>{});
                    return { ...m, 'user_status': rsvp['status'] };
                  }).toList();

                  // KPI Logic: Calculating totals based on the attendance declaration
                  final upCount = consolidated.length;
                  final atCount = consolidated.where((m) => m['user_status'] == 'attending').length;
                  final rsCount = consolidated.where((m) => m['user_status'] == null).length;

                  // Tab Logic: Filtering the list based on the declared status
                  final filtered = consolidated.where((m) {
                    if (_activeFilterIndex == 1) return m['user_status'] == null; // Pending
                    if (_activeFilterIndex == 2) return m['user_status'] == 'attending'; // Declared Attending
                    if (_activeFilterIndex == 3) return m['user_status'] == 'declined'; // Declared Not Attending
                    return true; // All Upcoming
                  }).toList();

                  return SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildKPIRow(upCount, atCount, rsCount, isDark),
                        const SizedBox(height: 25),
                        _buildFilterRow(isDark),
                        const SizedBox(height: 25),
                        _buildSectionHeader(_getFilterTitle(), isDark, textTheme),
                        if (filtered.isEmpty)
                          const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text("No entries found for this category.")))
                        else
                          ...filtered.map((m) => _buildMeetingCard(m, isDark)).toList(),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader(BuildContext context, bool isDark, TextTheme textTheme) => SliverAppBar(
    pinned: true,
    backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
    elevation: 0,
    toolbarHeight: 70,
    leadingWidth: 70,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Image.asset('assets/logo2.png', fit: BoxFit.contain, errorBuilder: (c,e,s) => Icon(Icons.eco, color: forestGreen)), 
    ),
    title: Text("Meetings", style: textTheme.titleLarge?.copyWith(color: isDark ? Colors.white : darkGreen, fontSize: 20)),
    actions: [
      _buildNotificationIcon(context, isDark, textTheme),
      _buildProfileIcon(context, isDark),
      const SizedBox(width: 16),
    ],
  );

  Widget _buildNotificationIcon(BuildContext context, bool isDark, TextTheme textTheme) => Stack(
    alignment: Alignment.center,
    children: [
      IconButton(
        icon: Icon(Icons.notifications_none_outlined, color: isDark ? Colors.white70 : Colors.black87, size: 26),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeNotifications())),
      ),
      Positioned(
        right: 8, top: 18,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: forestGreen, shape: BoxShape.circle),
          child: Text("2", style: textTheme.labelSmall?.copyWith(color: Colors.white, fontSize: 8)),
        ),
      )
    ],
  );

  Widget _buildProfileIcon(BuildContext context, bool isDark) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
    child: Container(
      height: 36, width: 36,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF0F4F0), 
        borderRadius: BorderRadius.circular(8), 
        border: Border.all(color: Colors.black12)
      ),
      child: const Icon(Icons.person_outline, color: Colors.black54, size: 20),
    ),
  );

  Widget _buildKPIRow(int up, int at, int rs, bool d) => Row(children: [
    Expanded(child: _statCard("$up", "Upcoming", d, Colors.blue)),
    const SizedBox(width: 10),
    Expanded(child: _statCard("$at", "Attending", d, forestGreen)),
    const SizedBox(width: 10),
    Expanded(child: _statCard("$rs", "Need RSVP", d, accentOrange)),
  ]);

  Widget _statCard(String val, String lbl, bool d, Color c) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: d ? const Color(0xFF1F1F1F) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(val, style: TextStyle(fontSize: 22, color: c)),
      Text(lbl, style: const TextStyle(fontSize: 10, color: Colors.black38)),
    ]),
  );

  Widget _buildFilterRow(bool d) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: [
      _filtBtn("Upcoming", 0, d), const SizedBox(width: 8),
      _filtBtn("Pending", 1, d), const SizedBox(width: 8),
      _filtBtn("Attending", 2, d), const SizedBox(width: 8),
      _filtBtn("Not Attending", 3, d),
    ]),
  );

  Widget _filtBtn(String l, int i, bool d) => ChoiceChip(
    label: Text(l), selected: _activeFilterIndex == i,
    onSelected: (s) => setState(() => _activeFilterIndex = i),
    selectedColor: forestGreen,
    labelStyle: TextStyle(fontSize: 12, color: _activeFilterIndex == i ? Colors.white : Colors.black54),
    backgroundColor: d ? Colors.white10 : Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    showCheckmark: false,
  );

  Widget _buildSectionHeader(String title, bool isDark, TextTheme textTheme) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(title, style: textTheme.labelSmall?.copyWith(color: isDark ? Colors.white38 : Colors.black54, letterSpacing: 1.1)),
  );

  Widget _buildMeetingCard(Map<String, dynamic> m, bool d) {
    final status = m['user_status'];
    final bool isMandatory = m['is_mandatory'] == true;

    // Badge Logic: Declaring text and colors based on RSVP status
    String badgeTxt = status == 'attending' ? "Attending" : (status == 'declined' ? "Declined" : "RSVP Required");
    Color badgeCol = status == 'attending' ? forestGreen : (status == 'declined' ? errorRed : accentOrange);

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeetingViewScreen(meeting: m))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: d ? const Color(0xFF1F1F1F) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(m['title'] ?? "Meeting", style: const TextStyle(fontSize: 15, color: Colors.black87))),
              const Icon(Icons.chevron_right, size: 20, color: Colors.black26),
            ]),
            const SizedBox(height: 5),
            Text("${m['meeting_date']} • ${m['meeting_time'] ?? ''} • ${m['location']}", style: const TextStyle(fontSize: 11, color: Colors.black38)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(height: 1, thickness: 0.5)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  if (isMandatory)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: errorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text("Required", style: TextStyle(color: errorRed, fontSize: 10)),
                    ),
                  const Text("12/25 Capacity Limit", style: TextStyle(fontSize: 11, color: Colors.black45)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: badgeCol.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(badgeTxt, style: TextStyle(color: badgeCol, fontSize: 10)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  

  String _getFilterTitle() => ["UPCOMING MEETINGS", "PENDING RSVP", "MY ATTENDANCE", "DECLINED MEETINGS"][_activeFilterIndex];
}