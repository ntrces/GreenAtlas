import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../../theme_provider.dart';
import '../../UserProfile/user_profile.dart';
import '../EmployeeNotification/employeenotif.dart';
import '../../components/notification_badge.dart';
import '../EmployeeMeeting/required_meetingview.dart';
import '../Field_Diary/Employee_FieldDiary.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});
  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  final _supabase = Supabase.instance.client;
  int _activeFilterIndex = 4; // Default to Upcoming (Index 4) so upcoming meetings display first
  String _searchQuery = ""; 

  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);
  final Color lightGreenBG = const Color(0xFFEAF7EA);
  final Color errorRed = const Color(0xFFD32F2F);
  final Color accentOrange = const Color(0xFFF2994A);

  String? get _userId => _supabase.auth.currentUser?.id;

  bool _isMeetingDone(Map<String, dynamic> m) {
    if (m['is_completed'] == true) return true;
    final String status = (m['status'] ?? '').toString().toUpperCase();
    if (status == 'COMPLETED' || status == 'DONE') return true;

    try {
      final mDate = DateTime.parse(m['meeting_date']);
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      return mDate.isBefore(startOfToday);
    } catch (_) {}
    return false;
  }

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

                  // Consolidated Meetings
                  final consolidated = meetings.where((m) {
                    // Role Filtering
                    String rolesString = (m['target_roles'] ?? '').toString().toLowerCase().replaceAll(' ', '');
                    bool matchesRole = rolesString.contains('fieldofficer') || rolesString.contains('all') || rolesString.isEmpty;

                    // Search Filtering
                    bool matchesSearch = _searchQuery == "" || (m['title'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());

                    return matchesRole && matchesSearch;
                  }).map((m) {
                    final rsvp = userRSVPs.firstWhere((r) => r['meeting_id'] == m['id'], orElse: () => <String, dynamic>{});
                    return { ...m, 'user_status': rsvp['status'] };
                  }).toList();

                  // Separate Upcoming vs Completed
                  final futureMeetings = consolidated.where((m) => !_isMeetingDone(m)).toList();
                  final completedMeetings = consolidated.where((m) => _isMeetingDone(m)).toList();

                  final upCount = futureMeetings.length;
                  final reCount = futureMeetings.where((m) => m['is_mandatory'] == true).length;

                  // Tab Logic: Filtering the list
                  final filtered = consolidated.where((m) {
                    final bool isDone = _isMeetingDone(m);

                    if (_activeFilterIndex == 0) return true; // All Meetings
                    if (_activeFilterIndex == 4) return !isDone; // Upcoming Meetings (Default)
                    if (_activeFilterIndex == 1) return !isDone && m['is_mandatory'] == true; // Upcoming Required
                    if (_activeFilterIndex == 2) return !isDone && m['user_status'] == 'attending'; // Upcoming Attending
                    if (_activeFilterIndex == 3) return !isDone && m['user_status'] == 'declined'; // Upcoming Declined
                    if (_activeFilterIndex == 5) return isDone; // Completed / Done Meetings

                    return true;
                  }).toList();

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildKPIRow(upCount, reCount, isDark),
                        const SizedBox(height: 20),
                        _buildFilterRow(isDark),
                        const SizedBox(height: 20),
                        _buildSectionHeader(_getFilterTitle(), isDark, textTheme),
                        if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48), 
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.event_busy_outlined, size: 56, color: isDark ? Colors.white30 : Colors.black26),
                                  const SizedBox(height: 12),
                                  Text(
                                    _activeFilterIndex == 5 ? "No completed meetings found." : "No upcoming meetings scheduled.",
                                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          )
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
    elevation: 0.5,
    toolbarHeight: 70,
    leadingWidth: 70,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Image.asset('assets/logo2.png', fit: BoxFit.contain, errorBuilder: (c,e,s) => Icon(Icons.eco, color: forestGreen, size: 32)), 
    ),
    title: Text(
      "Meetings", 
      style: textTheme.titleLarge?.copyWith(
        color: isDark ? Colors.white : darkGreen, 
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      )
    ),
    actions: [
      _buildNotificationIcon(context, isDark, textTheme),
      _buildProfileIcon(context, isDark),
      const SizedBox(width: 16),
    ],
  );

  Widget _buildNotificationIcon(BuildContext context, bool isDark, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: EmployeeNotificationBadge(iconColor: isDark ? Colors.white70 : Colors.black87),
    );
  }

  Widget _buildProfileIcon(BuildContext context, bool isDark) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
    child: Container(
      height: 38, width: 38,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF0F4F0), 
        borderRadius: BorderRadius.circular(10), 
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 1),
      ),
      child: Icon(Icons.person_outline_rounded, color: isDark ? Colors.white70 : Colors.black54, size: 22),
    ),
  );

  Widget _buildKPIRow(int up, int rs, bool d) => Row(children: [
    Expanded(child: _statCard("$up", "Upcoming", d, forestGreen, Icons.event_available_rounded, 4)),
    const SizedBox(width: 14),
    Expanded(child: _statCard("$rs", "Required", d, accentOrange, Icons.priority_high_rounded, 1)),
  ]);

  Widget _statCard(String val, String lbl, bool d, Color c, IconData icon, int index) {
    bool isActive = _activeFilterIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeFilterIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: isActive 
              ? LinearGradient(
                  colors: d 
                      ? [c.withOpacity(0.25), c.withOpacity(0.12)]
                      : [c.withOpacity(0.12), c.withOpacity(0.04)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : (d ? const Color(0xFF1F1F1F) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? c.withOpacity(0.6) : (d ? Colors.white10 : Colors.black12), width: isActive ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: isActive ? c.withOpacity(0.12) : Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: c, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(val, style: TextStyle(fontSize: 22, color: d ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                Text(lbl, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(bool d) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: const BouncingScrollPhysics(),
    child: Row(children: [
      _filtBtn("Upcoming", 4, Icons.schedule_rounded, d), const SizedBox(width: 8),
      _filtBtn("Required", 1, Icons.stars_rounded, d), const SizedBox(width: 8),
      _filtBtn("Attending", 2, Icons.check_circle_outline_rounded, d), const SizedBox(width: 8),
      _filtBtn("Not Attending", 3, Icons.cancel_outlined, d), const SizedBox(width: 8),
      _filtBtn("Completed", 5, Icons.task_alt_rounded, d),
    ]),
  );

  Widget _filtBtn(String l, int i, IconData icon, bool d) {
    final bool isSel = _activeFilterIndex == i;
    return InkWell(
      onTap: () => setState(() => _activeFilterIndex = i),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? forestGreen : (d ? const Color(0xFF1F1F1F) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? forestGreen : (d ? Colors.white12 : Colors.black12), width: 1),
          boxShadow: isSel
              ? [BoxShadow(color: forestGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSel ? Colors.white : (d ? Colors.white70 : Colors.black54)),
            const SizedBox(width: 6),
            Text(
              l,
              style: TextStyle(
                fontSize: 12, 
                color: isSel ? Colors.white : (d ? Colors.white70 : Colors.black87),
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, TextTheme textTheme) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 14),
    child: Row(
      children: [
        Container(
          width: 4, height: 14,
          decoration: BoxDecoration(color: forestGreen, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          title, 
          style: textTheme.labelSmall?.copyWith(
            color: isDark ? Colors.white70 : const Color(0xFF2D3E2D), 
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          )
        ),
      ],
    ),
  );

  Widget _buildMeetingCard(Map<String, dynamic> m, bool d) {
    final status = m['user_status'];
    final bool isMandatory = m['is_mandatory'] == true;
    final bool hasMom = (m['minutes'] != null && m['minutes'].toString().trim().isNotEmpty) ||
        (m['mom_attachment_url'] != null && m['mom_attachment_url'].toString().trim().isNotEmpty);

    final bool isDone = _isMeetingDone(m);

    String badgeTxt = status == 'attending' ? "Attending" : (status == 'declined' ? "Declined" : "RSVP Required");
    Color badgeCol = status == 'attending' ? forestGreen : (status == 'declined' ? errorRed : accentOrange);
    IconData badgeIcon = status == 'attending' ? Icons.check_circle_rounded : (status == 'declined' ? Icons.cancel_rounded : Icons.pending_actions_rounded);

    if (isDone) {
      badgeTxt = "Meeting Done";
      badgeCol = Colors.grey;
      badgeIcon = Icons.task_alt_rounded;
    }

    final Color accentStripColor = isDone ? Colors.grey : (isMandatory ? accentOrange : forestGreen);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: d ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: d ? Colors.white10 : Colors.black.withOpacity(0.06), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(d ? 0.2 : 0.04), 
            blurRadius: 12, 
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Strip
              Container(width: 5, color: accentStripColor),
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeetingViewScreen(meeting: m))),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                m['title'] ?? "Meeting", 
                                style: TextStyle(
                                  fontSize: 16, 
                                  color: d ? Colors.white : const Color(0xFF2D3E2D),
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 22, color: d ? Colors.white38 : Colors.black26),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 12, color: d ? Colors.white54 : Colors.black45),
                            const SizedBox(width: 4),
                            Text("${m['meeting_date']}", style: TextStyle(fontSize: 11, color: d ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w500)),
                            if (m['meeting_time'] != null && m['meeting_time'].toString().isNotEmpty) ...[
                              Text("  •  ", style: TextStyle(fontSize: 11, color: d ? Colors.white30 : Colors.black26)),
                              Icon(Icons.access_time_rounded, size: 12, color: d ? Colors.white54 : Colors.black45),
                              const SizedBox(width: 4),
                              Text("${m['meeting_time']}", style: TextStyle(fontSize: 11, color: d ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w500)),
                            ],
                          ],
                        ),
                        if (m['location'] != null && m['location'].toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 12, color: d ? Colors.white54 : Colors.black45),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "${m['location']}", 
                                  style: TextStyle(fontSize: 11, color: d ? Colors.white54 : Colors.black45),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (hasMom) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  forestGreen.withOpacity(d ? 0.2 : 0.08),
                                  forestGreen.withOpacity(d ? 0.08 : 0.02),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: forestGreen.withOpacity(d ? 0.3 : 0.2)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: forestGreen.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.assignment_turned_in_outlined, size: 14, color: forestGreen),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Minutes of Meeting (MoM)", 
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: forestGreen),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _getMomPreviewText(m['minutes']),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 11, color: d ? Colors.white70 : Colors.black87, height: 1.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              if (isMandatory)
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: errorRed.withOpacity(0.1), 
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: errorRed.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.stars_rounded, size: 10, color: errorRed),
                                      const SizedBox(width: 3),
                                      Text("Required", style: TextStyle(color: errorRed, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              if (hasMom)
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1), 
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.attachment_rounded, size: 10, color: Colors.blue),
                                      SizedBox(width: 3),
                                      Text("MoM Ready", style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                            ]),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: badgeCol.withOpacity(0.12), 
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: badgeCol.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(badgeIcon, size: 11, color: badgeCol),
                                  const SizedBox(width: 4),
                                  Text(badgeTxt, style: TextStyle(color: badgeCol, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMomPreviewText(dynamic minutesRaw) {
    if (minutesRaw == null) return "Official MoM document attached.";
    final str = minutesRaw.toString().trim();
    if (str.isEmpty) return "Official MoM document attached.";
    if (str.startsWith('{')) {
      try {
        final decoded = jsonDecode(str);
        if (decoded is Map<String, dynamic>) {
          final topics = decoded['topics']?.toString().trim();
          final decisions = decoded['decisions']?.toString().trim();
          if (topics != null && topics.isNotEmpty) return topics;
          if (decisions != null && decisions.isNotEmpty) return decisions;
        }
      } catch (_) {}
    }
    return str;
  }

  String _getFilterTitle() {
    switch (_activeFilterIndex) {
      case 0:
        return "ALL MEETINGS";
      case 1:
        return "UPCOMING REQUIRED MEETINGS";
      case 2:
        return "UPCOMING ATTENDING MEETINGS";
      case 3:
        return "UPCOMING DECLINED MEETINGS";
      case 4:
        return "UPCOMING MEETINGS";
      case 5:
        return "COMPLETED MEETINGS";
      default:
        return "UPCOMING MEETINGS";
    }
  }
}