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
  
  // --- ⚙️ LAYOUT & FILTER STATES ---
  bool _isGridView = false; // Toggle between list and grid
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
                  'assets/logo2.png', // Ensure path is correct
                  width: 45, height: 45, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Color(0xFF2D3E2D), size: 30),
                ),
              ),
            ),
            title: const Text("Botanical Gallery", 
              style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 20)),
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
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // --- LAYOUT TOGGLE BUTTON ---
                      _buildIconButton(
                        icon: _isGridView ? Icons.format_list_bulleted : Icons.grid_view_rounded,
                        onPressed: () => setState(() => _isGridView = !_isGridView),
                      ),
                      const SizedBox(width: 10),
                      // --- FILTER BUTTON ---
                      _buildIconButton(
                        icon: Icons.tune,
                        onPressed: () => _openFilterSheet(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_activeType != "All Plants" || _activeStatus != "All Statuses")
                    Text("Filtering by: ${_activeType == "All Plants" ? "" : _activeType} ${_activeStatus == "All Statuses" ? "" : "• $_activeStatus"}",
                        style: const TextStyle(fontSize: 11, color: Color(0xFF4A634A), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),

          // --- 2. DYNAMIC FILTERED STREAM ---
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('plants').stream(primaryKey: ['id']).order('common_name'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: Color(0xFF2D3E2D)))));
              }
              
              final plants = snapshot.data?.where((p) {
                final matchesSearch = p['common_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
                final matchesType = _activeType == "All Plants" || p['category'] == _activeType;
                final matchesStatus = _activeStatus == "All Statuses" || p['conservation_status'] == _activeStatus;
                return matchesSearch && matchesType && matchesStatus;
              }).toList() ?? [];

              if (plants.isEmpty) {
                return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No species match your filter."))));
              }

              // --- SWITCHING LAYOUTS ---
              return _isGridView 
                ? _buildPlantGrid(plants) 
                : _buildPlantList(plants);
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
          BottomNavigationBarItem(icon: Icon(Icons.visibility_outlined), label: "Plants Gallery"),
          BottomNavigationBarItem(icon: Icon(Icons.report_problem_outlined), label: "Report Issue"),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildIconButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: IconButton(icon: Icon(icon, color: const Color(0xFF2D3E2D), size: 22), onPressed: onPressed),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
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
    );
  }

  // --- LIST VIEW LAYOUT ---
  Widget _buildPlantList(List<Map<String, dynamic>> plants) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildPlantListItem(plants[index]),
        childCount: plants.length,
      ),
    );
  }

  // --- GRID VIEW LAYOUT (2 COLUMNS) ---
  Widget _buildPlantGrid(List<Map<String, dynamic>> plants) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildPlantGridItem(plants[index]),
          childCount: plants.length,
        ),
      ),
    );
  }

  Widget _buildPlantListItem(Map<String, dynamic> plant) {
    final String name = plant['common_name'] ?? "Unknown";
    final String status = "${plant['location_zone'] ?? 'N/A'} • ${plant['conservation_status'] ?? 'Common'}";
    final String? imgUrl = plant['image_url'];

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ARCameraScreen(plantData: plant))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _buildThumbnail(imgUrl, 55),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D), fontSize: 15)),
            subtitle: Text(status, style: const TextStyle(color: Colors.black45, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, color: Colors.black12),
          ),
          const Divider(height: 1, indent: 85, color: Color(0xFFF0F0F0)),
        ],
      ),
    );
  }

  Widget _buildPlantGridItem(Map<String, dynamic> plant) {
    final String name = plant['common_name'] ?? "Unknown";
    final String status = plant['conservation_status'] ?? "Common";
    final String? imgUrl = plant['image_url'];

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ARCameraScreen(plantData: plant))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black.withOpacity(0.05))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: SizedBox(width: double.infinity, child: _buildThumbnail(imgUrl, double.infinity)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(status, style: TextStyle(color: status == "Endangered" ? Colors.redAccent : Colors.black38, fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? url, double size) {
    return (url != null && url.startsWith('http'))
        ? Image.network(url, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder(size))
        : _buildPlaceholder(size);
  }

  Widget _buildPlaceholder(double size) => Container(color: Colors.grey[100], width: size, height: size, child: const Icon(Icons.park_outlined, color: Colors.black12));

  Widget _buildNotificationIcon() => IconButton(icon: const Icon(Icons.notifications_none, color: Color(0xFF2D3E2D), size: 26), 
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())));

  Widget _buildProfileIcon() => Padding(
    padding: const EdgeInsets.only(right: 16.0, left: 8),
    child: InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
      child: Container(height: 36, width: 36, decoration: BoxDecoration(color: const Color(0xFFEAF7EA), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)), 
        child: const Icon(Icons.person_outline, color: Color(0xFF2D3E2D), size: 20)),
    ),
  );
}