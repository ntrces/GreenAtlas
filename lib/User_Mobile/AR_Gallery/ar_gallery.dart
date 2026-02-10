import 'package:flutter/material.dart';
import '../../theme_constants.dart';
import '../user_dashboard.dart';
import '../report.dart';
import 'ar_camera.dart'; // Ensure this file exists for the AR button

class ARGalleryScreen extends StatefulWidget {
  const ARGalleryScreen({super.key});

  @override
  State<ARGalleryScreen> createState() => _ARGalleryScreenState();
}

class _ARGalleryScreenState extends State<ARGalleryScreen> {
  int _selectedIndex = 1;

  // --- NAVIGATION LOGIC ---
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
      backgroundColor: const Color(0xFFEAF7EA), // Matches dashboard background
      body: CustomScrollView(
        slivers: [
          // --- 1. PINNED BRANDING HEADER ---
          SliverAppBar(
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            toolbarHeight: 70,
            leading: const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: CircleAvatar(
                backgroundColor: Color(0xFF5D7A5D),
                backgroundImage: AssetImage('assets/logo1.png'), // Standardized logo path
              ),
            ),
            title: const Text(
              "AR Gallery", 
              style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 20)
            ),
          ),

          // --- 2. SEARCH & FILTER SECTION ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search plants or species...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("EXPLORE SPECIES", 
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),

          // --- 3. AR PLANT GRID ---
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildListDelegate([
                _buildPlantCard("Philippine Orchid", "Vanda sanderiana", "assets/logo1.png"),
                _buildPlantCard("Jade Vine", "Strongylodon macrobotrys", "assets/logo1.png"),
                _buildPlantCard("Mountain Fern", "Cyathea contaminans", "assets/logo1.png"),
                _buildPlantCard("Narra Tree", "Pterocarpus indicus", "assets/logo1.png"),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
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

  // --- PLANT CARD BUILDER ---
  Widget _buildPlantCard(String name, String scientificName, String imgPath) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F0),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Center(child: Icon(Icons.eco, color: Colors.black12, size: 50)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(scientificName, style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to the camera view
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ARCameraScreen()));
                    },
                    icon: const Icon(Icons.view_in_ar, size: 16, color: Colors.white),
                    label: const Text("VIEW AR", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D7A5D),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}