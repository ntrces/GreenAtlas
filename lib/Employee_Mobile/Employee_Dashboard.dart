import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../theme_provider.dart';
import '../../UserProfile/user_profile.dart';
import '../Employee_Mobile/Field_Diary/Employee_FieldDiary.dart';
import '../Employee_Mobile/EmployeeMeeting/Employee_Meetings.dart';
import '../Employee_Mobile/EmployeeNotification/employeenotif.dart'; 

class EmployeePortal extends StatefulWidget {
  final int initialIndex; 
  const EmployeePortal({super.key, this.initialIndex = 0});

  @override
  State<EmployeePortal> createState() => _EmployeePortalState();
}

class _EmployeePortalState extends State<EmployeePortal> {
  late int _selectedIndex;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    
    _pages = [
      EmployeeDashboardContent(onNavigate: (index) => _onItemTapped(index)),
      const FieldObservationScreen(),
      const MeetingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color(0xFF5D7A5D),
          unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
          backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Dashboard"),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: "Field Diary"),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: "Meetings"),
          ],
        ),
      ),
    );
  }
}

// --- DASHBOARD CONTENT ---
class EmployeeDashboardContent extends StatefulWidget {
  final Function(int) onNavigate;
  const EmployeeDashboardContent({super.key, required this.onNavigate});

  @override
  State<EmployeeDashboardContent> createState() => _EmployeeDashboardContentState();
}

class _EmployeeDashboardContentState extends State<EmployeeDashboardContent> {
  final _supabase = Supabase.instance.client;
  String? get _userId => _supabase.auth.currentUser?.id;
  
  bool _isMeetingsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textTheme = Theme.of(context).textTheme;

    if (_userId == null) {
      return const Center(
        child: Text("Access Denied. Please Login.")
      );
    }

    return CustomScrollView(
      slivers: [
        _buildResponsiveHeader(context, isDark, textTheme),
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildLiveStatGrid(isDark, textTheme),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader("QUICK ACTIONS", isDark, textTheme),
              _buildLiveDiaryAction(isDark, textTheme),
              _buildLiveMeetingAction(isDark, textTheme),
              _buildProfileAction(context, isDark, textTheme),
              const SizedBox(height: 24),
              
              _buildSectionHeader(
                "RECENT ENTRIES", 
                isDark, 
                textTheme,
                trailing: "See all",
                onTrailingTap: () => widget.onNavigate(1),
              ),
              _buildRecentEntriesList(isDark, textTheme),
              const SizedBox(height: 24),
              
              _buildSectionHeader(
                "UPCOMING MEETINGS", 
                isDark, 
                textTheme,
                hasDropdown: true, 
                isExpanded: _isMeetingsExpanded,
                onDropdownTap: () => setState(() => _isMeetingsExpanded = !_isMeetingsExpanded),
              ),
              if (_isMeetingsExpanded) _buildUpcomingMeetingsList(isDark, textTheme),
              
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveStatGrid(bool isDark, TextTheme textTheme) {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('field_entries').stream(primaryKey: ['id']).eq('user_id', _userId!),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return _buildLargeStatCard(Icons.menu_book_outlined, "$count", "Diary Entries", isDark, textTheme, onTap: () => widget.onNavigate(1));
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('meetings').stream(primaryKey: ['id']),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return _buildLargeStatCard(Icons.calendar_month_outlined, "$count", "Meetings", isDark, textTheme, onTap: () => widget.onNavigate(2));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLargeStatCard(IconData icon, String value, String label, bool isDark, TextTheme textTheme, {VoidCallback? onTap}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))]
      ),
      child: Column(children: [
          Container(
            padding: const EdgeInsets.all(10), 
            decoration: BoxDecoration(color: isDark ? Colors.white10 : const Color(0xFFF0F4F0), shape: BoxShape.circle), 
            child: Icon(icon, color: isDark ? Colors.white70 : Colors.black45, size: 24)
          ),
          const SizedBox(height: 12),
          Text(
            value, 
            style: textTheme.displaySmall?.copyWith(color: isDark ? Colors.white : Colors.black),
          ),
          Text(
            label, 
            style: textTheme.bodySmall?.copyWith(color: isDark ? Colors.white38 : Colors.black54),
          ),
      ]),
    ),
  );

  Widget _buildRecentEntriesList(bool isDark, TextTheme textTheme) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('field_entries').stream(primaryKey: ['id']).eq('user_id', _userId!).order('created_at', ascending: false).limit(3),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState(isDark, "No recent entries", textTheme);
        return Column(children: snapshot.data!.map((e) {
            final status = e['status'] ?? 'Pending';
            final date = DateTime.parse(e['created_at']);
            return _buildStatusRow(e['taxon'] ?? 'Observation', "${e['location'] ?? 'Area'} • ${DateFormat('jm').format(date)}", status, status == 'Validated' ? Colors.green : Colors.orange, isDark, true, textTheme, onTap: () => widget.onNavigate(1));
        }).toList());
      },
    );
  }

  Widget _buildUpcomingMeetingsList(bool isDark, TextTheme textTheme) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('meetings').stream(primaryKey: ['id']).order('meeting_date', ascending: true).limit(2),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState(isDark, "No meetings found", textTheme);
        return Column(children: snapshot.data!.map((m) {
            final date = DateTime.parse(m['meeting_date']);
            return _buildStatusRow(m['title'] ?? 'Meeting', DateFormat('MMM d, yyyy').format(date), m['status'] ?? 'Scheduled', const Color(0xFF5D7A5D), isDark, false, textTheme, onTap: () => widget.onNavigate(2));
        }).toList());
      },
    );
  }

  Widget _buildLiveDiaryAction(bool isDark, TextTheme textTheme) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('field_entries').stream(primaryKey: ['id']).eq('user_id', _userId!),
      builder: (context, snapshot) {
        final pending = snapshot.data?.where((e) => e['status'] == 'Pending').length ?? 0;
        return _buildDetailedAction(icon: Icons.menu_book_outlined, title: "Field Diary", subtitle: "Document observations", badge: pending > 0 ? "$pending Pending" : null, badgeColor: Colors.orange, isDark: isDark, textTheme: textTheme, onTap: () => widget.onNavigate(1));
      }
    );
  }

  Widget _buildLiveMeetingAction(bool isDark, TextTheme textTheme) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('meetings').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return _buildDetailedAction(icon: Icons.calendar_today_outlined, title: "Meetings", subtitle: "View schedule & RSVP", badge: count > 0 ? "$count New" : null, badgeColor: const Color(0xFF5D7A5D), isDark: isDark, textTheme: textTheme, onTap: () => widget.onNavigate(2));
      }
    );
  }

  Widget _buildEmptyState(bool isDark, String msg, TextTheme textTheme) => Container(
    width: double.infinity, 
    padding: const EdgeInsets.all(20), 
    color: isDark ? const Color(0xFF1F1F1F) : Colors.white, 
    child: Text(
      msg, 
      style: textTheme.bodySmall?.copyWith(color: Colors.grey),
    )
  );

  Widget _buildResponsiveHeader(BuildContext context, bool isDark, TextTheme textTheme) => SliverAppBar(
    pinned: true,
    backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
    elevation: 0, toolbarHeight: 80, leadingWidth: 70,
    leading: Padding(padding: const EdgeInsets.only(left: 16.0), child: Image.asset('assets/logo2.png', fit: BoxFit.contain)),
    title: Text(
      "Dashboard", 
      style: textTheme.titleLarge?.copyWith(color: isDark ? Colors.white : const Color(0xFF2D3E2D), fontSize: 22),
    ),
    actions: [_buildNotificationIcon(context, isDark, textTheme), _buildTopProfileIcon(context, isDark), const SizedBox(width: 16)],
  );

  Widget _buildNotificationIcon(BuildContext context, bool isDark, TextTheme textTheme) => Stack(alignment: Alignment.center, children: [
      IconButton(icon: Icon(Icons.notifications_none_outlined, color: isDark ? Colors.white70 : Colors.black87, size: 28), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EmployeeNotifications()))),
      Positioned(
        right: 8, top: 18, 
        child: Container(
          padding: const EdgeInsets.all(4), 
          decoration: const BoxDecoration(color: Color(0xFF5D7A5D), shape: BoxShape.circle), 
          child: Text(
            "2", 
            style: textTheme.labelSmall?.copyWith(color: Colors.white, fontSize: 9),
          )
        )
      )
  ]);

  Widget _buildTopProfileIcon(BuildContext context, bool isDark) => InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())), child: Container(height: 40, width: 40, decoration: BoxDecoration(color: isDark ? Colors.white10 : const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)), child: const Icon(Icons.person_outline, color: Colors.black54, size: 22)));

  Widget _buildSectionHeader(String title, bool isDark, TextTheme textTheme, {String? trailing, VoidCallback? onTrailingTap, bool hasDropdown = false, bool isExpanded = true, VoidCallback? onDropdownTap}) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(
        title, 
        style: textTheme.labelSmall?.copyWith(color: isDark ? Colors.white38 : Colors.black54, letterSpacing: 0.5),
      ),
      if (trailing != null) 
        InkWell(
          onTap: onTrailingTap, 
          child: Text(
            trailing, 
            style: textTheme.labelLarge?.copyWith(color: const Color(0xFF5D7A5D)),
          )
        ),
      if (hasDropdown) IconButton(onPressed: onDropdownTap, constraints: const BoxConstraints(), padding: EdgeInsets.zero, icon: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20, color: Colors.black45)),
    ]),
  );

  Widget _buildProfileAction(BuildContext context, bool isDark, TextTheme textTheme) => _buildDetailedAction(icon: Icons.person_outline, title: "View Profile", subtitle: "", isDark: isDark, textTheme: textTheme, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())));

  Widget _buildDetailedAction({required IconData icon, required String title, required String subtitle, required bool isDark, required TextTheme textTheme, required VoidCallback onTap, String? badge, Color? badgeColor}) => Container(
    margin: const EdgeInsets.only(bottom: 1), width: double.infinity,
    decoration: BoxDecoration(color: isDark ? const Color(0xFF1F1F1F) : Colors.white),
    child: ListTile(
      onTap: onTap, 
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), 
      leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black45, size: 22), 
      title: Text(
        title, 
        style: textTheme.titleSmall?.copyWith(color: isDark ? Colors.white : Colors.black87, fontSize: 15),
      ), 
      subtitle: subtitle.isEmpty ? null : Text(
        subtitle, 
        style: textTheme.bodySmall?.copyWith(color: isDark ? Colors.white38 : Colors.black38),
      ), 
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (badge != null) 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
            decoration: BoxDecoration(color: badgeColor!.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), 
            child: Text(
              badge, 
              style: textTheme.labelSmall?.copyWith(color: badgeColor, fontSize: 10),
            )
          ), 
        const SizedBox(width: 8), 
        const Icon(Icons.chevron_right, size: 20, color: Colors.black26)
      ])
    ),
  );

  Widget _buildStatusRow(String title, String subtitle, String status, Color color, bool isDark, bool isEntry, TextTheme textTheme, {VoidCallback? onTap}) => Container(
    margin: const EdgeInsets.only(bottom: 1), width: double.infinity,
    decoration: BoxDecoration(color: isDark ? const Color(0xFF1F1F1F) : Colors.white),
    child: ListTile(
      onTap: onTap, 
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), 
      leading: Icon(isEntry ? (status == "Validated" ? Icons.check_circle_outline : Icons.access_time) : Icons.calendar_month_outlined, color: isEntry ? color : (isDark ? Colors.white24 : Colors.black26), size: 24), 
      title: Text(
        title, 
        style: textTheme.titleSmall?.copyWith(color: isDark ? Colors.white : Colors.black87, fontSize: 15),
      ), 
      subtitle: Text(
        subtitle, 
        style: textTheme.bodySmall?.copyWith(color: isDark ? Colors.white38 : Colors.black38),
      ), 
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), 
          child: Text(
            status, 
            style: textTheme.labelSmall?.copyWith(color: color, fontSize: 11),
          )
        ), 
        const SizedBox(width: 8), 
        const Icon(Icons.chevron_right, size: 20, color: Colors.black12)
      ])
    ),
  );
}