import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme_constants.dart';
import '../User_Mobile/UserProfile/user_profile.dart'; // Correct relative path

// --- IMPORT YOUR SPECIFIC EMPLOYEE DARTS ---
import 'Employee_FieldDiary.dart';
import 'Employee_Photodocs.dart';
import 'Employee_Meetings.dart';
import 'Employee_More.dart';

class EmployeePortal extends StatefulWidget {
  const EmployeePortal({super.key});

  @override
  State<EmployeePortal> createState() => _EmployeePortalState();
}

class _EmployeePortalState extends State<EmployeePortal> {
  int _selectedIndex = 0;

  // --- TAB BODY CONTENT ---
  final List<Widget> _pages = [
    const EmployeeDashboardContent(), 
    const FieldDiaryScreen(),         
    const PhotoDocsScreen(),          
    const MeetingsScreen(),           
    const MoreSettingsScreen(),       
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF2D3E2D),
        unselectedItemColor: Colors.black38,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: "Field Diary"),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt_outlined), label: "Photo Docs"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: "Meetings"),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "More"),
        ],
      ),
    );
  }
}

// --- UPDATED DASHBOARD CONTENT WIDGET WITH FILTERS ---
class EmployeeDashboardContent extends StatefulWidget {
  const EmployeeDashboardContent({super.key});

  @override
  State<EmployeeDashboardContent> createState() => _EmployeeDashboardContentState();
}

class _EmployeeDashboardContentState extends State<EmployeeDashboardContent> {
  // 0 = All, 1 = Plants, 2 = Activity
  int _activeFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 70,
          leading: const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: CircleAvatar(
              backgroundColor: Color(0xFF5D7A5D),
              child: Icon(Icons.eco, color: Colors.white, size: 24),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                height: 40, width: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.person_outline, color: Colors.black54, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserProfileScreen()),
                    );
                  }, 
                ),
              ),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Field Officer Dashboard", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
                const Text("Monitor Cavite Protected Area data", style: TextStyle(fontSize: 14, color: Colors.black45)),
                const SizedBox(height: 24),

                // --- GRID METRICS (Always visible or toggleable based on preference) ---
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.3,
                  children: [
                    _buildStatCard(Icons.menu_book_rounded, "28", "Diary Entries"),
                    _buildStatCard(Icons.camera_alt_outlined, "142", "Photos"),
                  ],
                ),
                const SizedBox(height: 24),

                // --- FILTER CHIPS SECTION (Matched to Image) ---
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("All", 0, null), // 'All' often has no icon in your reference
                      _buildFilterChip("Plants", 1, Icons.eco_outlined),
                      _buildFilterChip("Activity", 2, Icons.history),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // --- QUICK ACCESS (Visible only in "All") ---
                if (_activeFilterIndex == 0) ...[
                  const Text("QUICK ACCESS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  _buildQuickAccessCard("AR Gallery", Icons.visibility_outlined),
                  _buildQuickAccessCard("Report Issue", Icons.error_outline, tag: "Quick"),
                  _buildQuickAccessCard("Explore Area", Icons.location_on_outlined),
                  const SizedBox(height: 32),
                ],

                // --- PROTECTED SPECIES (Visible in "All" and "Plants") ---
                if (_activeFilterIndex == 0 || _activeFilterIndex == 1) ...[
                  const Text("PROTECTED SPECIES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  _buildEntryTile(Icons.eco, "Philippine Orchid", "Zone A-3 · Endangered", status: "Critical", isGreen: false),
                  _buildEntryTile(Icons.eco, "Jade Vine", "Zone B-1 · Vulnerable", status: "Stable", isGreen: true),
                  const SizedBox(height: 32),
                ],

                // --- RECENT ENTRIES (Visible in "All" and "Activity") ---
                if (_activeFilterIndex == 0 || _activeFilterIndex == 2) ...[
                  const Text("RECENT ENTRIES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  _buildEntryTile(Icons.check_circle_outline, "Oak Tree Health Check", "Zone A-3 · 2 hours ago", status: "Validated", isGreen: true),
                  _buildEntryTile(Icons.access_time, "Fern Species Survey", "Zone B-1 · 5 hours ago", status: "Pending", isGreen: false),
                ],
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- FILTER CHIP BUILDER ---
  Widget _buildFilterChip(String label, int index, IconData? icon) {
    bool isSelected = _activeFilterIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        avatar: icon != null ? Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF4A634A)) : null,
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() => _activeFilterIndex = index);
        },
        selectedColor: const Color(0xFF4A634A), // Dark green for 'All' selected
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF4A634A), 
          fontWeight: FontWeight.bold,
          fontSize: 13
        ),
        backgroundColor: const Color(0xFFE8F3E8), // Light green background
        side: BorderSide.none, // Removes the border to match image
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: const Color(0xFF5D7A5D), size: 24),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black38)),
      ]),
    );
  }

  Widget _buildQuickAccessCard(String title, IconData icon, {String? tag}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2D3E2D)),
        title: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            if (tag != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(4)),
                child: Text(tag, style: const TextStyle(fontSize: 10, color: Color(0xFF5D7A5D), fontWeight: FontWeight.bold)),
              )
            ]
          ],
        ),
        trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.black26),
      ),
    );
  }

  Widget _buildEntryTile(IconData icon, String title, String subtitle, {required String status, required bool isGreen}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isGreen ? Colors.green : Colors.orange),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: isGreen ? const Color(0xFFE0ECE0) : Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
        child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isGreen ? const Color(0xFF5D7A5D) : Colors.orange.shade800)),
      ),
    );
  }
}