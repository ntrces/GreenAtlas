import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme_provider.dart';
import '../../UserProfile/user_profile.dart';
import '../Employee_Mobile/Field_Diary/Employee_FieldDiary.dart';
import '../Employee_Mobile/EmployeeMeeting/Employee_Meetings.dart';
// ADD THIS IMPORT (Adjust path if necessary)
import '../Employee_Mobile/EmployeeNotification/employeenotif.dart'; 

class EmployeePortal extends StatefulWidget {
  const EmployeePortal({super.key});

  @override
  State<EmployeePortal> createState() => _EmployeePortalState();
}

class _EmployeePortalState extends State<EmployeePortal> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
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

class EmployeeDashboardContent extends StatelessWidget {
  final Function(int) onNavigate;
  EmployeeDashboardContent({super.key, required this.onNavigate});

  final _supabase = Supabase.instance.client;
  String? get _userId => _supabase.auth.currentUser?.id;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    if (_userId == null) return const Center(child: Text("Access Denied. Please Login."));

    return CustomScrollView(
      slivers: [
        _buildResponsiveHeader(context, isDark),
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildLiveStatGrid(isDark),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader("QUICK ACTIONS", isDark),
              _buildLiveDiaryAction(isDark),
              _buildLiveMeetingAction(isDark),
              _buildProfileAction(context, isDark),
              const SizedBox(height: 24),
              _buildSectionHeader("RECENT ENTRIES", isDark, trailing: "See all"),
              _buildRecentEntriesList(isDark),
              const SizedBox(height: 24),
              _buildSectionHeader("UPCOMING MEETINGS", isDark, hasDropdown: true),
              _buildUpcomingMeetingsList(isDark),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  // --- UPDATED STAT GRID ---
  Widget _buildLiveStatGrid(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('field_entries').stream(primaryKey: ['id']).eq('user_id', _userId!),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return _buildLargeStatCard(Icons.menu_book_outlined, "$count", "Diary Entries", isDark);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('meetings').stream(primaryKey: ['id']),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return _buildLargeStatCard(Icons.calendar_month_outlined, "$count", "Meetings", isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLargeStatCard(IconData icon, String value, String label, bool isDark) => Container(
    padding: const EdgeInsets.symmetric(vertical: 24),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white, 
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: isDark ? Colors.white10 : const Color(0xFFF0F4F0), shape: BoxShape.circle),
          child: Icon(icon, color: isDark ? Colors.white70 : Colors.black45, size: 24),
        ),
        const SizedBox(height: 12),
        Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black54)),
      ],
    ),
  );

  Widget _buildRecentEntriesList(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('field_entries').stream(primaryKey: ['id']).eq('user_id', _userId!).order('created_at', ascending: false).limit(3),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState(isDark, "No recent entries");
        return Column(
          children: snapshot.data!.map((e) {
            final status = e['status'] ?? 'Pending';
            final date = DateTime.parse(e['created_at']);
            return _buildStatusRow(
              e['plant_name'] ?? 'Observation',
              "${e['location'] ?? 'Area'} • ${DateFormat('jm').format(date)}",
              status,
              status == 'Validated' ? Colors.green : Colors.orange,
              isDark,
              true,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildUpcomingMeetingsList(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('meetings').stream(primaryKey: ['id']).order('meeting_date', ascending: true).limit(2),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState(isDark, "No meetings found");
        return Column(
          children: snapshot.data!.map((m) {
            final date = DateTime.parse(m['meeting_date']);
            return _buildStatusRow(
              m['title'] ?? 'Meeting',
              DateFormat('MMM d, yyyy').format(date),
              m['status'] ?? 'Scheduled',
              const Color(0xFF5D7A5D),
              isDark,
              false,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLiveDiaryAction(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('field_entries').stream(primaryKey: ['id']).eq('user_id', _userId!),
      builder: (context, snapshot) {
        final pending = snapshot.data?.where((e) => e['status'] == 'Pending').length ?? 0;
        return _buildDetailedAction(
          icon: Icons.menu_book_outlined,
          title: "Field Diary",
          subtitle: "Document observations",
          badge: pending > 0 ? "$pending Pending" : null,
          badgeColor: Colors.orange,
          isDark: isDark,
          onTap: () => onNavigate(1),
        );
      }
    );
  }

  Widget _buildLiveMeetingAction(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('meetings').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return _buildDetailedAction(
          icon: Icons.calendar_today_outlined,
          title: "Meetings",
          subtitle: "View schedule & RSVP",
          badge: count > 0 ? "$count New" : null,
          badgeColor: const Color(0xFF5D7A5D),
          isDark: isDark,
          onTap: () => onNavigate(2),
        );
      }
    );
  }

  Widget _buildEmptyState(bool isDark, String msg) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
    child: Text(msg, style: const TextStyle(fontSize: 12, color: Colors.grey)),
  );

  // --- FIXED HEADER NAVIGATION ---
  Widget _buildResponsiveHeader(BuildContext context, bool isDark) => SliverAppBar(
    pinned: true,
    backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
    elevation: 0,
    toolbarHeight: 80,
    leadingWidth: 70,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Image.asset('assets/logo2.png', fit: BoxFit.contain), 
    ),
    title: Text("Dashboard", style: TextStyle(color: isDark ? Colors.white : const Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 22)),
    actions: [
      _buildNotificationIcon(context, isDark), // Pass context here
      _buildTopProfileIcon(context, isDark),
      const SizedBox(width: 16),
    ],
  );

  // --- FIXED NOTIFICATION BUTTON ---
  Widget _buildNotificationIcon(BuildContext context, bool isDark) => Stack(
    alignment: Alignment.center,
    children: [
      IconButton(
        icon: Icon(Icons.notifications_none_outlined, color: isDark ? Colors.white70 : Colors.black87, size: 28), 
        onPressed: () {
          // Navigate to Notifications Screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EmployeeNotifications()),
          );
        }
      ),
      Positioned(
        right: 8, 
        top: 18, 
        child: Container(
          padding: const EdgeInsets.all(4), 
          decoration: const BoxDecoration(color: Color(0xFF5D7A5D), shape: BoxShape.circle), 
          child: const Text("2", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))
        )
      ),
    ],
  );

  Widget _buildTopProfileIcon(BuildContext context, bool isDark) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
    child: Container(height: 40, width: 40, decoration: BoxDecoration(color: isDark ? Colors.white10 : const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)), child: const Icon(Icons.person_outline, color: Colors.black54, size: 22)),
  );

  Widget _buildSectionHeader(String title, bool isDark, {String? trailing, bool hasDropdown = false}) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black54, letterSpacing: 0.5)),
      if (trailing != null) Text(trailing, style: const TextStyle(fontSize: 12, color: Color(0xFF5D7A5D), fontWeight: FontWeight.bold)),
      if (hasDropdown) const Icon(Icons.keyboard_arrow_up, size: 20, color: Colors.black45),
    ]),
  );

  Widget _buildProfileAction(BuildContext context, bool isDark) => _buildDetailedAction(icon: Icons.person_outline, title: "View Profile", subtitle: "", isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())));

  Widget _buildDetailedAction({required IconData icon, required String title, required String subtitle, required bool isDark, required VoidCallback onTap, String? badge, Color? badgeColor}) => Container(
    margin: const EdgeInsets.only(bottom: 1),
    width: double.infinity,
    decoration: BoxDecoration(color: isDark ? const Color(0xFF1F1F1F) : Colors.white),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black45, size: 22),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
      subtitle: subtitle.isEmpty ? null : Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (badge != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: badgeColor!.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold))),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, size: 20, color: Colors.black26),
      ]),
    ),
  );

  Widget _buildStatusRow(String title, String subtitle, String status, Color color, bool isDark, bool isEntry) => Container(
    margin: const EdgeInsets.only(bottom: 1),
    width: double.infinity,
    decoration: BoxDecoration(color: isDark ? const Color(0xFF1F1F1F) : Colors.white),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(isEntry ? (status == "Validated" ? Icons.check_circle_outline : Icons.access_time) : Icons.calendar_month_outlined, color: isEntry ? color : (isDark ? Colors.white24 : Colors.black26), size: 24),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, size: 20, color: Colors.black12),
      ]),
    ),
  );
}