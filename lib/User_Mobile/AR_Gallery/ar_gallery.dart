import 'package:flutter/material.dart';
import '../../theme_constants.dart';
import '../user_dashboard.dart';
import '../Report/report.dart';
import 'ar_camera.dart'; 
import '../notification.dart';
import '../../UserProfile/user_profile.dart';

class ARGalleryScreen extends StatefulWidget {
  const ARGalleryScreen({super.key});

  @override
  State<ARGalleryScreen> createState() => _ARGalleryScreenState();
}

class _ARGalleryScreenState extends State<ARGalleryScreen> {
  int _selectedIndex = 1;
  int _activeFilterIndex = 0; // Default to "All"

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const UserDashboard()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ReportScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA),
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
    // --- NOTIFICATION BELL WITH BADGE ---
    Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF2D3E2D), size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen())),
          ),
          Positioned(
            right: 8,
            top: 15,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Text(
                "2", 
                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ],
      ),
    ),
    // --- USER PROFILE ICON ---
    Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileScreen())),
        borderRadius: BorderRadius.circular(10),
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 2. SCREEN TITLE & PURPOSE ---
                  const Text(
                    "AR Botanical Gallery",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Explore life-size AR plant models with interactive information and educational content",
                    style: TextStyle(fontSize: 14, color: Colors.black45, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  // --- 3. SEARCH INPUT FIELD ---
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search plants...",
                      hintStyle: const TextStyle(color: Colors.black26),
                      prefixIcon: const Icon(Icons.search, color: Colors.black38),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- 4. CATEGORY FILTER TABS ---
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip("All", 0, null),
                        _buildFilterChip("Flowers", 1, Icons.local_florist_outlined),
                        _buildFilterChip("Ferns", 2, Icons.eco_outlined),
                        _buildFilterChip("Trees", 3, Icons.park_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // --- 5. PLANT LIST SECTION ---
          SliverList(
            delegate: SliverChildListDelegate([
              _buildPlantListItem("Philippine Orchid", "Zone A-3 • Endangered", "assets/logo1.png"),
              _buildPlantListItem("Mountain Fern", "Zone B-1 • Endangered", "assets/logo1.png"),
              _buildPlantListItem("Tropical Palm", "Zone C-2 • Endangered", "assets/logo1.png"),
              _buildPlantListItem("Jade Vine", "Zone A-1 • Endangered", "assets/logo1.png"),
            ]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
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
    );
  }

  // --- FILTER CHIP BUILDER ---
  Widget _buildFilterChip(String label, int index, IconData? icon) {
    bool isSelected = _activeFilterIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        showCheckmark: false,
        avatar: icon != null ? Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF4A634A)) : null,
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() => _activeFilterIndex = index);
        },
        selectedColor: const Color(0xFF4A634A),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF4A634A), 
          fontWeight: FontWeight.bold,
          fontSize: 13
        ),
        backgroundColor: const Color(0xFFD6E8D6),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // --- INDIVIDUAL PLANT LIST ITEM ---
  Widget _buildPlantListItem(String name, String status, String imgPath) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ARCameraScreen())),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              width: 55, height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(image: AssetImage(imgPath), fit: BoxFit.cover),
              ),
            ),
            title: Row(
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D), fontSize: 16)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF5D7A5D), borderRadius: BorderRadius.circular(6)),
                  child: const Text("AR", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.volume_up_outlined, size: 16, color: Colors.black38),
              ],
            ),
            subtitle: Text(status, style: const TextStyle(color: Colors.black38, fontSize: 13)),
            trailing: const Icon(Icons.chevron_right, color: Colors.black26),
          ),
          const Divider(height: 1, indent: 90, color: Color(0xFFF0F0F0)),
        ],
      ),
    );
  }
}