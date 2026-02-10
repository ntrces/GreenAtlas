import 'package:flutter/material.dart';
import 'package:flutter_eco_supabase/User_Mobile/Report/submit_report.dart';
import '../theme_constants.dart';
import 'AR_Gallery/ar_gallery.dart'; 
import 'Report/report.dart';
import 'UserProfile/user_profile.dart'; 

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0; 
  // THE FIX: Filter state (0 = All, 1 = Plants, 2 = Activity, 3 = Saved)
  int _activeFilterIndex = 0;

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ARGalleryScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ReportScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF2D3E2D),
        unselectedItemColor: Colors.black38,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.visibility_outlined), label: "AR Gallery"),
          BottomNavigationBarItem(icon: Icon(Icons.report_problem_outlined), label: "Report Issue"),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // --- 1. PINNED BRANDING HEADER ---
          SliverAppBar(
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            toolbarHeight: 80,
            leadingWidth: 70,
            leading: const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: CircleAvatar(
                backgroundColor: Color(0xFF5D7A5D),
                backgroundImage: AssetImage('assets/logo1.png'), 
              ),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome, User", 
                  style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 22)),
                Text("Explore the Cavite Protected Area", 
                  style: TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileScreen())),
                  borderRadius: BorderRadius.circular(10),
                  hoverColor: const Color(0xFFF1F8F1),
                  child: Container(
                    height: 40, width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Icon(Icons.person_outline, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 2. STAT CARDS ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildStatCard("89", "AR Models", Icons.visibility_outlined),
                      const SizedBox(width: 12),
                      _buildStatCard("156", "Species", Icons.eco_outlined),
                    ],
                  ),
                ),

                // --- 3. FILTER BUTTONS SECTION ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip("All", 0, null),
                        _buildFilterChip("Plants", 1, Icons.eco_outlined),
                        _buildFilterChip("Activity", 2, Icons.history),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // --- 4. QUICK ACCESS SECTION (Only shows on 'All') ---
                if (_activeFilterIndex == 0) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: const Color(0xFFE8F3E8), 
                    child: const Text("QUICK ACCESS", 
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A634A), letterSpacing: 0.5)),
                  ),
                  _buildListTile(
                    "AR Gallery", 
                    Icons.visibility_outlined, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ARGalleryScreen())), 
                  ),
                  _buildListTile(
                    "Report Issue", 
                    Icons.error_outline, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SubmitReportScreen())), 
                    tag: "Quick",
                  ),
                 
                ],

                // --- 5. FEATURED PLANTS SECTION (Shows on 'All' and 'Plants') ---
                if (_activeFilterIndex == 0 || _activeFilterIndex == 1) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: const Color(0xFFE8F3E8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("FEATURED PLANTS", 
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A634A), letterSpacing: 0.5)),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ARGalleryScreen())), 
                          style: TextButton.styleFrom(foregroundColor: Colors.grey),
                          child: const Text("See all", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500))
                        ),
                      ],
                    ),
                  ),
                  _buildPlantTile("Philippine Orchid", "Zone A-3 • Endangered", true, () {}),
                  _buildPlantTile("Mountain Fern", "Zone B-1 • Endangered", true, () {}),
                  _buildPlantTile("Jade Vine", "Zone A-1 • Endangered", true, () {}),
                  const SizedBox(height: 16),
                ],

                // --- 6. RECENT ACTIVITY SECTION (Shows on 'All' and 'Activity') ---
                if (_activeFilterIndex == 0 || _activeFilterIndex == 2) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: const Color(0xFFE8F3E8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("RECENT ACTIVITY", 
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A634A), letterSpacing: 0.5)),
                        const Icon(Icons.keyboard_arrow_up, size: 20, color: Color(0xFF4A634A)),
                      ],
                    ),
                  ),
                  _buildActivityTile("Illegal logging reported", "2 hours ago", Icons.error_outline, () {}, status: "Under Review"),
                  _buildActivityTile("Viewed Philippine Orchid in AR", "5 hours ago", Icons.camera_alt_outlined, () {}),
                ],
                
                const SizedBox(height: 32), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- FILTER CHIP BUILDER ---
  Widget _buildFilterChip(String label, int index, IconData? icon) {
    bool isSelected = _activeFilterIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        // THE FIX: Set this to false to hide the checkmark icon
        showCheckmark: false, 
        
        avatar: icon != null ? Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF4A634A)) : null,
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _activeFilterIndex = index;
          });
        },
        selectedColor: const Color(0xFF4A634A), // Solid dark green remains
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF4A634A), 
          fontWeight: FontWeight.bold,
          fontSize: 13
        ),
        backgroundColor: const Color(0xFFD6E8D6), // Light green background
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // --- REUSABLE UI BUILDERS ---

  Widget _buildStatCard(String val, String label, IconData icon) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          hoverColor: const Color(0xFFF1F8F1), 
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: const Color(0xFFF0F4F0), child: Icon(icon, color: const Color(0xFF5D7A5D), size: 20)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, VoidCallback onTap, {String? tag}) {
    return Material(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            onTap: onTap,
            hoverColor: const Color(0xFFF1F8F1), 
            leading: Icon(icon, color: const Color(0xFF2D3E2D), size: 22),
            title: Row(
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF2D3E2D))),
                if (tag != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFE8F3E8), borderRadius: BorderRadius.circular(12)),
                    child: Text(tag, style: const TextStyle(fontSize: 11, color: Color(0xFF5D7A5D), fontWeight: FontWeight.bold)),
                  )
                ]
              ],
            ),
            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.black26),
          ),
          const Divider(height: 1, indent: 70, color: Color(0xFFF0F0F0)),
        ],
      ),
    );
  }

  Widget _buildPlantTile(String name, String subtitle, bool hasAR, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            onTap: onTap,
            hoverColor: const Color(0xFFF1F8F1),
            leading: const Icon(Icons.eco_outlined, color: Color(0xFF5D7A5D), size: 24),
            title: Row(
              children: [
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF2D3E2D))),
                if (hasAR) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF5D7A5D), borderRadius: BorderRadius.circular(6)),
                    child: const Text("AR", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                ]
              ],
            ),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.black26),
          ),
          const Divider(height: 1, indent: 70, color: Color(0xFFF0F0F0)),
        ],
      ),
    );
  }

  Widget _buildActivityTile(String title, String time, IconData icon, VoidCallback onTap, {String? status}) {
    return Material(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            onTap: onTap,
            hoverColor: const Color(0xFFF1F8F1),
            leading: Icon(icon, color: Colors.black38, size: 22),
            title: Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2D3E2D)))),
                if (status != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(12)),
                    child: Text(status, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold)),
                  )
              ],
            ),
            subtitle: Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.black26),
          ),
          const Divider(height: 1, indent: 70, color: Color(0xFFF0F0F0)),
        ],
      ),
    );
  }
}