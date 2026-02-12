import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../user_dashboard.dart';
import '../Report/report.dart';
import 'ar_camera.dart'; 
import '../notification.dart';
import '../../UserProfile/user_profile.dart';
import 'gallery_filtering.dart'; 

class ARGalleryScreen extends StatefulWidget {
  const ARGalleryScreen({super.key});

  @override
  State<ARGalleryScreen> createState() => _ARGalleryScreenState();
}

class _ARGalleryScreenState extends State<ARGalleryScreen> {
  final _supabase = Supabase.instance.client;
  int _selectedIndex = 1;
  final TextEditingController _searchController = TextEditingController();
  
  // --- ⚙️ FILTER STATES ---
  String _searchQuery = ""; 
  String _activeType = "All Plants";
  String _activeStatus = "All Statuses";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserDashboard()));
    if (index == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA),
      body: CustomScrollView(
        slivers: [
          // --- 1. BRANDING HEADER ---
          SliverAppBar(
            floating: false, pinned: true,
            backgroundColor: Colors.white, elevation: 0,
            toolbarHeight: 70, leadingWidth: 70,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Center(
                child: Image.asset(
                  'logo2.png',
                  width: 45, height: 45, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Color(0xFF2D3E2D), size: 30),
                ),
              ),
            ),
            title: const Text("Botanical Gallery", 
              style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 22)),
            actions: [
              _buildNotificationIcon(),
              _buildProfileIcon(),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Search plants...",
                            hintStyle: const TextStyle(color: Colors.black26, fontSize: 15),
                            prefixIcon: const Icon(Icons.search, color: Colors.black38),
                            filled: true, fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: IconButton(
                          icon: const Icon(Icons.tune, color: Color(0xFF2D3E2D)),
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => GalleryFilterSheet(
                              currentType: _activeType,
                              currentStatus: _activeStatus,
                              currentSort: "Default Order",
                              onApply: (type, status, sort) {
                                setState(() {
                                  _activeType = type;
                                  _activeStatus = status;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_activeType != "All Plants" || _activeStatus != "All Statuses")
                    Text("Filtering by: ${_activeType == "All Plants" ? "" : _activeType} ${_activeStatus == "All Statuses" ? "" : "• $_activeStatus"}",
                        style: const TextStyle(fontSize: 12, color: Color(0xFF4A634A), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),

          // --- 2. DYNAMIC FILTERED STREAM ---
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('plants').stream(primaryKey: ['id']).order('common_name'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              }
              
              final plants = snapshot.data?.where((p) {
                final matchesSearch = p['common_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
                final matchesType = _activeType == "All Plants" || p['category'] == _activeType;
                final matchesStatus = _activeStatus == "All Statuses" || p['conservation_status'] == _activeStatus;

                return matchesSearch && matchesType && matchesStatus;
              }).toList() ?? [];

              if (plants.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No species match your filter."))),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final plant = plants[index];
                    return _buildPlantListItem(plant); // Pass the whole map to the helper
                  },
                  childCount: plants.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.visibility_outlined), label: "AR Gallery"),
          BottomNavigationBarItem(icon: Icon(Icons.report_problem_outlined), label: "Report Issue"),
        ],
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildPlantListItem(Map<String, dynamic> plant) {
    final String name = plant['common_name'] ?? "Unknown";
    final String status = "${plant['location_zone'] ?? 'N/A'} • ${plant['conservation_status'] ?? 'Common'}";
    final String? imgUrl = plant['image_url'];

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            // FIXED: Passing plant data map to the AR Camera
            onTap: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => ARCameraScreen(plantData: plant))
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imgUrl != null && imgUrl.startsWith('http')
                ? Image.network(
                    imgUrl, 
                    width: 55, height: 55, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
            ),
            title: Row(
              children: [
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D), fontSize: 16), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF4A634A), borderRadius: BorderRadius.circular(6)),
                  child: const Text("AR", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(status, style: const TextStyle(color: Colors.black45, fontSize: 13)),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.black26),
          ),
          const Divider(height: 1, indent: 85, color: Color(0xFFF0F0F0)),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() => Container(
    color: Colors.grey[200], width: 55, height: 55, 
    child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 20)
  );

  Widget _buildNotificationIcon() => Stack(
    alignment: Alignment.center,
    children: [
      IconButton(icon: const Icon(Icons.notifications_none, color: Color(0xFF2D3E2D), size: 28), 
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()))),
      Positioned(right: 8, top: 12, child: Container(padding: const EdgeInsets.all(4), 
        decoration: const BoxDecoration(color: Color(0xFF5D7A5D), shape: BoxShape.circle), 
        child: const Text("2", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
    ],
  );

  Widget _buildProfileIcon() => Padding(
    padding: const EdgeInsets.only(right: 16.0, left: 8),
    child: InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
      child: Container(height: 38, width: 38, decoration: BoxDecoration(color: const Color(0xFFEAF7EA), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)), 
        child: const Icon(Icons.person_outline, color: Color(0xFF2D3E2D))),
    ),
  );
}