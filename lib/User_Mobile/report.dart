import 'package:flutter/material.dart';
import '../theme_constants.dart';
import 'user_dashboard.dart';
import 'AR_Gallery/ar_gallery.dart';
import 'user_profile.dart'; 

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _selectedIndex = 2;
  // Added missing variable to prevent the red error
  bool _isLoading = false; 

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ARGalleryScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryForest))
          : CustomScrollView(
              slivers: [
                // --- 1. PERSISTENT BRANDING HEADER ---
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
                // --- 2. BODY CONTENT (Converted to Sliver) ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Submit a Report",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3E2D)),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Help us protect the Cavite Protected Area by reporting environmental concerns or illegal activities.",
                          style: TextStyle(
                              fontSize: 15, color: Colors.black54, height: 1.4),
                        ),
                        const SizedBox(height: 32),
                        _buildReportOption(Icons.warning_amber_rounded,
                            "Illegal Logging", "Report unauthorized cutting of trees"),
                        _buildReportOption(Icons.opacity, "Water Pollution",
                            "Report waste disposal in local waterways"),
                        _buildReportOption(Icons.local_fire_department,
                            "Wildfire Risk", "Report smoke or high-risk dry areas"),
                      ],
                    ),
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
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: "Dashboard"),
          BottomNavigationBarItem(
              icon: Icon(Icons.visibility_outlined), label: "AR Gallery"),
          BottomNavigationBarItem(
              icon: Icon(Icons.report_problem_outlined), label: "Report Issue"),
        ],
      ),
    );
  }

  Widget _buildReportOption(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.black12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF0F4F0),
          child: Icon(icon, color: Colors.redAccent),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black26),
        onTap: () {},
      ),
    );
  }
}