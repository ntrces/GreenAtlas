import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';
import '../../UserProfile/user_profile.dart';
import '../Employee_Mobile/Field_Diary/Employee_FieldDiary.dart';
import '../Employee_Mobile/EmployeeMeeting/Employee_Meetings.dart';

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
      const FieldDiaryScreen(),
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
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF5D7A5D),
        unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: "Field Diary"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: "Meetings"),
        ],
      ),
    );
  }
}

class EmployeeDashboardContent extends StatelessWidget {
  final Function(int) onNavigate;
  // FIXED: Removed const because this class uses dynamic Supabase instance calls
  EmployeeDashboardContent({super.key, required this.onNavigate});

  final _supabase = Supabase.instance.client;
  String? get _userId => _supabase.auth.currentUser?.id;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    if (_userId == null) return const Center(child: Text("Please login."));

    return CustomScrollView(
      slivers: [
        _buildResponsiveHeader(context, isDark),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildLiveStatGrid(isDark),
              const SizedBox(height: 24),
              _buildSectionHeader("QUICK ACTIONS", isDark),
              _buildLiveDiaryAction(isDark),
              _buildLiveMeetingAction(isDark),
              const SizedBox(height: 24),
              _buildSectionHeader("RECENT ENTRIES", isDark, trailing: "See all"),
              _buildRecentEntriesList(isDark),
              const SizedBox(height: 24),
              _buildSectionHeader("UPCOMING MEETINGS", isDark),
              _buildUpcomingMeetingsList(isDark),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  // --- DYNAMIC COMPONENTS WITH FIXED FILTERS ---

  Widget _buildLiveStatGrid(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // FIXED: Streams only support one .eq() natively on some versions; 
      // added 'user_id' filter and handled status locally
      stream: _supabase.from('field_entries').stream(primaryKey: ['id']).eq('user_id', _userId!),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard(Icons.menu_book, "${entries.length}", "Diary Entries", isDark),
            _buildStatCard(Icons.check_circle_outline, "${entries.where((e) => e['status'] == 'Validated').length}", "Validated", isDark),
            _buildStatCard(Icons.eco, "12", "Plant Species", isDark),
            _buildStatCard(Icons.history, "${entries.where((e) => e['status'] == 'Pending').length}", "Pending", isDark),
          ],
        );
      },
    );
  }

  Widget _buildLiveDiaryAction(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // FIXED: Handled multi-filter logic inside the builder
      stream: _supabase.from('field_entries').stream(primaryKey: ['id']).eq('user_id', _userId!),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data?.where((e) => e['status'] == 'Pending').length ?? 0;
        return _buildDetailedAction(
          context: context,
          icon: Icons.menu_book_outlined,
          title: "Field Diary",
          subtitle: "Document observations",
          badge: pendingCount > 0 ? "$pendingCount Pending" : null,
          badgeColor: Colors.orange,
          isDark: isDark,
          onTap: () => onNavigate(1),
        );
      }
    );
  }

  Widget _buildLiveMeetingAction(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // FIXED: .contains() is not supported on streams; filtered locally
      stream: _supabase.from('meetings').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        final meetings = snapshot.data?.where((m) {
          final List roles = m['target_roles'] ?? [];
          return roles.contains('Field Officer');
        }).toList() ?? [];
        
        return _buildDetailedAction(
          context: context,
          icon: Icons.calendar_month_outlined,
          title: "Meetings",
          subtitle: "View schedule & RSVP",
          badge: meetings.isNotEmpty ? "${meetings.length} New" : null,
          badgeColor: const Color(0xFF5D7A5D),
          isDark: isDark,
          onTap: () => onNavigate(2),
        );
      }
    );
  }

  Widget _buildRecentEntriesList(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('field_entries').stream(primaryKey: ['id']).eq('user_id', _userId!).limit(3),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) return const Text("No recent entries", style: TextStyle(fontSize: 12, color: Colors.grey));
        return Column(
          children: entries.map((e) => _buildEntryCard(
            e['plant_name'] ?? "Observation", 
            "${e['location']} • Just now", 
            e['status'] ?? "Pending", 
            e['status'] == 'Validated' ? Colors.green : Colors.orange, 
            isDark
          )).toList(),
        );
      }
    );
  }

  Widget _buildUpcomingMeetingsList(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('meetings').stream(primaryKey: ['id']).order('meeting_date').limit(2),
      builder: (context, snapshot) {
        final meetings = snapshot.data?.where((m) {
          final List roles = m['target_roles'] ?? [];
          return roles.contains('Field Officer');
        }).toList() ?? [];
        
        if (meetings.isEmpty) return const Text("No upcoming meetings", style: TextStyle(fontSize: 12, color: Colors.grey));
        return Column(
          children: meetings.map((m) => _buildMeetingRow(
            m['title'], m['meeting_date'], m['status'] ?? "Scheduled", const Color(0xFF5D7A5D), isDark
          )).toList(),
        );
      }
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildResponsiveHeader(BuildContext context, bool isDark) => SliverAppBar(
    pinned: true,
    backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
    elevation: 0, toolbarHeight: 70,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: CircleAvatar(
        radius: 30, backgroundColor: Colors.white,
        child: Transform.scale(scale: 1.3, child: Image.asset('assets/logo2.png', fit: BoxFit.contain)),
      ),
    ),
    title: Text("Field Diary", style: TextStyle(color: isDark ? Colors.white : const Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 20)),
    actions: [_buildProfileIcon(context, isDark)],
  );

  Widget _buildProfileIcon(BuildContext context, bool isDark) => Padding(
    padding: const EdgeInsets.only(right: 16.0),
    child: InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
      child: Container(
        height: 40, width: 40,
        decoration: BoxDecoration(color: isDark ? Colors.white10 : const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
        child: const Icon(Icons.person_outline, color: Colors.black54, size: 20),
      ),
    ),
  );

  Widget _buildSectionHeader(String title, bool isDark, {String? trailing}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1.2)),
        if (trailing != null) Text(trailing, style: const TextStyle(fontSize: 11, color: Color(0xFF5D7A5D), fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _buildStatCard(IconData icon, String value, String label, bool isDark) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: isDark ? const Color(0xFF1F1F1F) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : Colors.transparent)),
    child: Row(children: [
      CircleAvatar(radius: 18, backgroundColor: isDark ? Colors.white10 : const Color(0xFFF0F4F0), child: Icon(icon, color: const Color(0xFF5D7A5D), size: 18)),
      const SizedBox(width: 12),
      Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        Text(label, style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.black38)),
      ]),
    ]),
  );

  Widget _buildDetailedAction({required BuildContext context, required IconData icon, required String title, required String subtitle, required bool isDark, required VoidCallback onTap, String? badge, Color? badgeColor}) => Container(
    decoration: BoxDecoration(color: isDark ? const Color(0xFF1F1F1F) : Colors.white, border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFF0F0F0)))),
    child: ListTile(
      onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Icon(icon, color: isDark ? Colors.white70 : const Color(0xFF2D3E2D), size: 20),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
      trailing: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
        if (badge != null) Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: badgeColor!.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold))),
        const Icon(Icons.chevron_right, size: 16, color: Colors.black12),
      ]),
    ),
  );

  Widget _buildEntryCard(String title, String subtitle, String status, Color color, bool isDark) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(status == "Validated" ? Icons.check_circle_outline : Icons.access_time, color: color, size: 24),
    title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
    subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
    trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
  );

  Widget _buildMeetingRow(String title, String date, String status, Color color, bool isDark) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(Icons.calendar_today_outlined, color: isDark ? Colors.white24 : Colors.black26, size: 20),
    title: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
    subtitle: Text(date, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
    trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.black12),
  );
}