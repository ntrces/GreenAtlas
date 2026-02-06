import 'package:flutter/material.dart';
import '../../../theme_constants.dart';
import '../user_dashboard.dart';
import '../report.dart';      // Ensure correct path
import '../user_profile.dart'; 

class ARGalleryScreen extends StatefulWidget {
  const ARGalleryScreen({super.key});

  @override
  State<ARGalleryScreen> createState() => _ARGalleryScreenState();
}

class _ARGalleryScreenState extends State<ARGalleryScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 1; // AR Gallery is active

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
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
  floating: false,        // Change to false for a stable pinned header
  pinned: true,           // THE FIX: This keeps the header in one place
  snap: false,            // Snap is not needed when pinned
  backgroundColor: Colors.white,
  surfaceTintColor: Colors.white, // Keeps it white during the scroll
  elevation: 0,
  toolbarHeight: 70,
  leading: const Padding(
    padding: EdgeInsets.only(left: 16.0),
    child: CircleAvatar(
      backgroundColor: Color(0xFF5D7A5D),
      child: Icon(Icons.eco, color: Colors.white, size: 24),
    ),
  ),
  title: const Text(
    "GreenAtlas", 
    style: TextStyle(
      color: Color(0xFF2D3E2D), 
      fontWeight: FontWeight.bold, 
      fontSize: 20
    )
  ),
  actions: [
  Padding(
    padding: const EdgeInsets.only(right: 16.0),
    child: InkWell( // Added InkWell for ripple effect and tap functionality
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserProfileScreen()),
        );
      },
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
          // --- 2. GALLERY CONTENT ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("AR Botanical Gallery", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
                  const SizedBox(height: 12),
                  const Text("Explore life-size AR plant models with interactive information", style: TextStyle(fontSize: 14, color: Colors.black45, height: 1.4)),
                  const SizedBox(height: 24),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(hintText: "Search plants...", prefixIcon: Icon(Icons.search, color: Colors.black26), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 15)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // --- 3. PLANT LIST ---
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      _buildGalleryItem("Philippine Orchid", "Zone A-3 · Rare", "https://images.unsplash.com/photo-1599388836511-8594ccbe34bb", showAudio: true),
                      _buildGalleryItem("Mountain Fern", "Zone B-1 · Common", "https://images.unsplash.com/photo-1525184203433-8594ccbe34bb", showAudio: true),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ]),
            ),
          ),
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

  // (Helper widgets: _buildFilterPill and _buildGalleryItem remain the same)
  Widget _buildGalleryItem(String name, String detail, String imageUrl, {required bool showAudio}) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, width: 60, height: 60, child: const Icon(Icons.image))),
        ),
        title: Row(children: [
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF5D7A5D), borderRadius: BorderRadius.circular(5)), child: const Text("AR", style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))),
        ]),
        subtitle: Text(detail, style: const TextStyle(fontSize: 13, color: Colors.black38)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black26),
      ),
    );
  }
}