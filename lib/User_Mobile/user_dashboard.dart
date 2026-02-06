import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme_constants.dart';

// --- ENSURE THESE IMPORTS MATCH YOUR FILE PATHS ---
import 'AR_Gallery/ar_gallery.dart'; 
import 'report.dart'; 
import 'user_profile.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  String _userName = "User";
  bool _isLoading = true;
  int _selectedIndex = 0; // Dashboard is active

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final data = await _supabase.from('profiles').select('full_name').eq('id', user.id).single();
        if (mounted) {
          setState(() {
            _userName = data['full_name']?.split(' ')[0] ?? "User"; 
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- NEW NAVIGATION HANDLER FOR BOTTOM NAV ---
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    if (index == 1) {
      // Go to AR Gallery
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ARGalleryScreen()));
    } else if (index == 2) {
      // Go to Report Issue
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportScreen()));
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
                // --- 1. SCROLLABLE APPBAR ---
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

                // --- 2. MAIN CONTENT AREA ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome, $_userName", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
                        const SizedBox(height: 12),
                        const Text("Explore the Cavite Protected Area through augmented reality and help us protect our ecosystem", style: TextStyle(fontSize: 15, color: Colors.black45, height: 1.4)),
                        const SizedBox(height: 24),

                        // STATS
                        Row(children: [
                          _buildStatCard(Icons.visibility_outlined, "89", "AR Models"),
                          const SizedBox(width: 16),
                          _buildStatCard(Icons.energy_savings_leaf_outlined, "156", "Species"),
                        ]),
                        const SizedBox(height: 24),

                        // QUICK ACCESS
                        const Text("QUICK ACCESS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 1)),
                        const SizedBox(height: 12),
                        // --- UPDATED QUICK ACCESS NAVIGATION ---
                        _buildQuickAccessItem(Icons.remove_red_eye_outlined, "AR Gallery", const ARGalleryScreen()),
                        _buildQuickAccessItem(Icons.report_problem_outlined, "Report Issue", const ReportScreen(), badge: "Quick"),
                        _buildQuickAccessItem(Icons.location_on_outlined, "Explore Area", const HomeScreen()), // Placeholder
                        
                        const SizedBox(height: 24),

                        // FEATURED PLANTS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("FEATURED PLANTS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 1)),
                            TextButton(onPressed: () {}, child: const Text("See all", style: TextStyle(color: Colors.black45, fontSize: 12))),
                          ],
                        ),
                        _buildPlantItem("Philippine Orchid", "Zone A-3 · Rare"),
                        _buildPlantItem("Mountain Fern", "Zone B-1 · Common"),
                        _buildPlantItem("Jade Vine", "Zone A-1 · Endangered"),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      // --- UPDATED BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Connect navigation function
        selectedItemColor: const Color(0xFF2D3E2D),
        unselectedItemColor: Colors.black38,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.visibility_outlined), activeIcon: Icon(Icons.visibility), label: "AR Gallery"),
          BottomNavigationBarItem(icon: Icon(Icons.report_problem_outlined), activeIcon: Icon(Icons.report_problem), label: "Report Issue"),
        ],
      ),
    );
  }

  // --- UPDATED HELPER WITH NAVIGATION ---
  Widget _buildQuickAccessItem(IconData icon, String label, Widget targetPage, {String? badge}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5))),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: Colors.black45, size: 22),
        title: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFE0ECE0), borderRadius: BorderRadius.circular(5)),
                child: Text(badge, style: const TextStyle(fontSize: 10, color: Color(0xFF5D7A5D), fontWeight: FontWeight.bold)),
              )
            ]
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black26),
        // --- ADDED NAVIGATION ON CLICK ---
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => targetPage)),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(children: [
          CircleAvatar(backgroundColor: const Color(0xFFF0F4F0), child: Icon(icon, color: Colors.black45, size: 20)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black38)),
          ])
        ]),
      ),
    );
  }

  Widget _buildPlantItem(String name, String zone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const Icon(Icons.eco_outlined, color: Colors.black45),
        title: Row(children: [
          Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF5D7A5D), borderRadius: BorderRadius.circular(5)),
            child: const Text("AR", style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ]),
        subtitle: Text(zone, style: const TextStyle(fontSize: 12, color: Colors.black38)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black26),
      ),
    );
  }
}