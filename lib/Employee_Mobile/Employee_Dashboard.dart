import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';
import '../theme_constants.dart';
import '../../UserProfile/user_profile.dart';
// Import specialized employee screens
import '../Employee_Mobile/Field_Diary/Employee_FieldDiary.dart';
import '../Employee_Mobile/EmployeeMeeting/Employee_Meetings.dart';

class EmployeePortal extends StatefulWidget {
  const EmployeePortal({super.key});

  @override
  State<EmployeePortal> createState() => _EmployeePortalState();
}

class _EmployeePortalState extends State<EmployeePortal> {
  int _selectedIndex = 0;

  // These indexes match the BottomNavigationBar
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
  const EmployeeDashboardContent({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return CustomScrollView(
      slivers: [
        // --- DETAILED HEADER SECTION ---
        SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            toolbarHeight: 70,
            leading: Padding( // Removed 'const' from here
  padding: const EdgeInsets.only(left: 16.0),
  child: CircleAvatar(
    radius: 30,
    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
    child: Transform.scale(
      scale:1.3, // 0.5 makes it half the size of the circle
      child: Image.asset(
        'assets/logo2.png', 
        fit: BoxFit.contain,
      ),
    ),
  ),
),
            title: const Text(
              "Field Diary", 
              style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 20)
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserProfileScreen()),
                    );
                  },
                  child: Container(
                    height: 40, width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Icon(Icons.person_outline, color: Colors.black54, size: 20),
                  ),
                ),
              ),
            ],
          ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // --- 1. SUMMARY GRID (2x2) ---
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(Icons.menu_book, "28", "Diary Entries", isDark),
                  _buildStatCard(Icons.camera_alt, "142", "Photos", isDark),
                  _buildStatCard(Icons.calendar_today, "3", "Meetings", isDark),
                  _buildStatCard(Icons.eco, "12", "Active Actions", isDark),
                ],
              ),
              const SizedBox(height: 24),

              // --- 2. QUICK ACTIONS LIST ---
              _buildSectionHeader("QUICK ACTIONS", isDark),
              _buildDetailedAction(
                context: context,
                icon: Icons.menu_book_outlined,
                title: "Field Diary",
                subtitle: "Document observations",
                badge: "5 Pending",
                badgeColor: Colors.orange,
                isDark: isDark,
                onTap: () => onNavigate(1), // Navigates to Field Diary Tab
              ),
              
              _buildDetailedAction(
                context: context,
                icon: Icons.auto_graph_outlined,
                title: "Recovery Tracker",
                subtitle: "Monitor interventions",
                isDark: isDark,
                onTap: () {}, // Placeholder for tracker
              ),
              _buildDetailedAction(
                context: context,
                icon: Icons.calendar_month_outlined,
                title: "Meetings",
                subtitle: "View schedule & RSVP",
                badge: "3 New",
                badgeColor: const Color(0xFF5D7A5D),
                isDark: isDark,
                onTap: () => onNavigate(2), // Navigates to Meetings Tab
              ),
              const SizedBox(height: 24),

              // --- 3. RECENT ENTRIES ---
              _buildSectionHeader("RECENT ENTRIES", isDark, trailing: "See all"),
              _buildEntryCard("Oak Tree Health Check", "Zone A-3 · 2 hours ago", "Validated", Colors.green, isDark),
              _buildEntryCard("Fern Species Survey", "Zone B-1 · 5 hours ago", "Pending", Colors.orange, isDark),
              _buildEntryCard("Wildlife Observation", "Zone C-2 · 1 day ago", "Validated", Colors.green, isDark),
              const SizedBox(height: 24),

              // --- 4. UPCOMING MEETINGS ---
              _buildSectionHeader("UPCOMING MEETINGS", isDark, hasDropdown: true),
              _buildMeetingRow("Monthly Field Review", "Feb 5, 2026", "Pending", Colors.orange, isDark),
              _buildMeetingRow("Training: New AR Tools", "Feb 8, 2026", "Confirmed", Colors.green, isDark),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  // --- UI DETAIL HELPERS ---

  Widget _buildSectionHeader(String title, bool isDark, {String? trailing, bool hasDropdown = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1.2)),
              if (hasDropdown) Icon(Icons.keyboard_arrow_down, size: 14, color: isDark ? Colors.white38 : Colors.black38),
            ],
          ),
          if (trailing != null) Text(trailing, style: const TextStyle(fontSize: 11, color: Color(0xFF5D7A5D), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark ? Colors.white10 : const Color(0xFFF0F4F0),
            child: Icon(icon, color: const Color(0xFF5D7A5D), size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAction({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFF0F0F0))),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(icon, color: isDark ? Colors.white70 : const Color(0xFF2D3E2D), size: 20),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: badgeColor!.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            Icon(Icons.chevron_right, size: 16, color: isDark ? Colors.white24 : Colors.black12),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(String title, String subtitle, String status, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFF8F8F8))),
      ),
      child: ListTile(
        leading: Icon(status == "Validated" ? Icons.check_circle_outline : Icons.access_time, color: color, size: 24),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: Colors.black12),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingRow(String title, String date, String status, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFF8F8F8))),
      ),
      child: ListTile(
        leading: Icon(Icons.calendar_today_outlined, color: isDark ? Colors.white24 : Colors.black26, size: 20),
        title: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
        subtitle: Text(date, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: Colors.black12),
          ],
        ),
      ),
    );
  }
}