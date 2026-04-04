import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../user_dashboard.dart';
import '../AR View/ar_view.dart';
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
  
  bool _isGridView = false; 
  String _searchQuery = ""; 

  Set<String> _activeTypes = {"All Plants"};
  Set<String> _activeStatuses = {"All Statuses"};
  String _activeSort = "Ascending (A-Z)";

  List<Map<String, dynamic>> _allPlantsRaw = [];

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

  Map<String, int> _calculateCounts() {
    return {
      'Total': _allPlantsRaw.length,
      'Flowering Plants': _allPlantsRaw.where((p) => p['plant_type'] == 'Flowering Plants').length,
      'Ferns': _allPlantsRaw.where((p) => p['plant_type'] == 'Ferns').length,
      'Trees': _allPlantsRaw.where((p) => p['plant_type'] == 'Trees').length,
      'Critically Endangered': _allPlantsRaw.where((p) => p['conservation_status'] == 'Critically Endangered').length,
      'Endangered': _allPlantsRaw.where((p) => p['conservation_status'] == 'Endangered').length,
      'Vulnerable': _allPlantsRaw.where((p) => p['conservation_status'] == 'Vulnerable').length,
      'Threatened': _allPlantsRaw.where((p) => p['conservation_status'] == 'Threatened').length,
      'Other Threatened Status': _allPlantsRaw.where((p) => p['conservation_status'] == 'Other Threatened Status').length,
      'Near Threatened': _allPlantsRaw.where((p) => p['conservation_status'] == 'Near Threatened').length,
      'Not Threatened': _allPlantsRaw.where((p) => p['conservation_status'] == 'Not Threatened').length,
      'Least Concern (LC)': _allPlantsRaw.where((p) => p['conservation_status'] == 'Least Concern (LC)').length,
      'Data Deficient': _allPlantsRaw.where((p) => p['conservation_status'] == 'Data Deficient').length,
    };
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GalleryFilterSheet(
        initialTypes: _activeTypes,
        initialStatuses: _activeStatuses,
        initialSort: _activeSort,
        counts: _calculateCounts(),
        onApply: (types, statuses, sort) {
          setState(() {
            _activeTypes = types;
            _activeStatuses = statuses;
            _activeSort = sort;
          });
        },
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserDashboard()));
    if (index == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Ar_View()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          _buildSearchAndFilterRow(),
          _buildPlantDataStream(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildActiveFilters() {
    final textTheme = Theme.of(context).textTheme;
    List<Widget> chips = [];
    
    for (var type in _activeTypes) {
      if (type != "All Plants") {
        chips.add(_buildFilterChip(type, () {
          setState(() {
            _activeTypes.remove(type);
            if (_activeTypes.isEmpty) _activeTypes.add("All Plants");
          });
        }));
      }
    }

    for (var status in _activeStatuses) {
      if (status != "All Statuses") {
        chips.add(_buildFilterChip(status, () {
          setState(() {
            _activeStatuses.remove(status);
            if (_activeStatuses.isEmpty) _activeStatuses.add("All Statuses");
          });
        }));
      }
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Filter : ",
            style: textTheme.labelLarge?.copyWith(
              fontSize: 14, 
              color: const Color(0xFF2D3E2D),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: chips),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D3E2D).withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label, 
            style: textTheme.labelMedium?.copyWith(color: const Color(0xFF2D3E2D), fontSize: 13),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDeleted,
            child: const Icon(Icons.close, size: 16, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterRow() => SliverToBoxAdapter(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search plants...",
                    prefixIcon: const Icon(Icons.search, color: Colors.black38),
                    filled: true, fillColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildIconButton(
                icon: _isGridView ? Icons.format_list_bulleted : Icons.grid_view_rounded, 
                onPressed: () => setState(() => _isGridView = !_isGridView)
              ),
              const SizedBox(width: 10),
              _buildIconButton(icon: Icons.tune, onPressed: _openFilterSheet),
            ],
          ),
        ),
        _buildActiveFilters(), 
      ],
    ),
  );

  Widget _buildPlantDataStream() => StreamBuilder<List<Map<String, dynamic>>>(
    stream: _supabase.from('plants').stream(primaryKey: ['id']),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: Color(0xFF2D3E2D)))));
      
      _allPlantsRaw = snapshot.data!;

      var plants = _allPlantsRaw.where((p) {
        final matchesSearch = p['common_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesType = _activeTypes.contains("All Plants") || _activeTypes.contains(p['plant_type']);
        final matchesStatus = _activeStatuses.contains("All Statuses") || _activeStatuses.contains(p['conservation_status']);
        return matchesSearch && matchesType && matchesStatus;
      }).toList();

      plants.sort((a, b) {
        int cmp = (a['common_name'] ?? "").compareTo(b['common_name'] ?? "");
        return _activeSort == "Ascending (A-Z)" ? cmp : -cmp;
      });

      if (plants.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No species match your criteria."))));

      return _isGridView ? _buildGrid(plants) : _buildList(plants);
    },
  );

  Widget _buildSliverAppBar() {
    final textTheme = Theme.of(context).textTheme;
    return SliverAppBar(
      pinned: true, backgroundColor: Colors.white, elevation: 0,
      toolbarHeight: 70, leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(child: Image.asset('assets/logo2.png', width: 45, height: 45)),
      ),
      title: Text(
        "Botanical Gallery", 
        style: textTheme.titleLarge?.copyWith(color: const Color(0xFF2D3E2D), fontSize: 20),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_none, color: Color(0xFF2D3E2D)), 
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()))),
        _buildProfileIcon(),
      ],
    );
  }

  Widget _buildList(List<Map<String, dynamic>> plants) => SliverList(
    delegate: SliverChildBuilderDelegate((context, i) => _buildListItem(plants[i]), childCount: plants.length),
  );

  Widget _buildGrid(List<Map<String, dynamic>> plants) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    sliver: SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, 
        mainAxisSpacing: 16, 
        crossAxisSpacing: 16, 
        childAspectRatio: 0.85
      ),
      delegate: SliverChildBuilderDelegate((context, i) => _buildGridItem(plants[i]), childCount: plants.length),
    ),
  );

  Widget _buildListItem(Map<String, dynamic> plant) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ARCameraScreen(plantData: plant))),
            leading: _buildImageThumb(plant['image_url'], 55),
            title: Text(
              plant['common_name'] ?? "Unknown", 
              style: textTheme.titleSmall?.copyWith(fontSize: 15),
            ),
            subtitle: Text(
              "${plant['location_zone']} • ${plant['conservation_status']}", 
              style: textTheme.labelSmall?.copyWith(color: Colors.black45),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.black12),
          ),
          const Divider(height: 1, indent: 85, color: Color(0xFFF0F0F0)),
        ],
      ),
    );
  }

  Widget _buildGridItem(Map<String, dynamic> plant) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ARCameraScreen(plantData: plant))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(15), 
          border: Border.all(color: Colors.black.withOpacity(0.05))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(15)), child: _buildImageThumb(plant['image_url'], double.infinity))),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                plant['common_name'] ?? "Unknown", 
                style: textTheme.titleSmall?.copyWith(fontSize: 13), 
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumb(String? url, double size) => Container(
    width: size, height: size, color: Colors.grey[100],
    child: (url != null && url.isNotEmpty) 
      ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.park_outlined, color: Colors.black12)) 
      : const Icon(Icons.park_outlined, color: Colors.black12),
  );

  Widget _buildIconButton({required IconData icon, required VoidCallback onPressed}) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: IconButton(icon: Icon(icon, color: const Color(0xFF2D3E2D), size: 22), onPressed: onPressed),
  );

  Widget _buildProfileIcon() => Padding(
    padding: const EdgeInsets.only(right: 16, left: 8),
    child: InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())), 
      child: Container(
        height: 36, width: 36, 
        decoration: BoxDecoration(color: const Color(0xFFEAF7EA), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)), 
        child: const Icon(Icons.person_outline, size: 20)
      )
    ),
  );

  Widget _buildBottomNav() => BottomNavigationBar(
    currentIndex: _selectedIndex, onTap: _onItemTapped,
    selectedItemColor: const Color(0xFF2D3E2D), unselectedItemColor: Colors.black38,
    type: BottomNavigationBarType.fixed,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
      BottomNavigationBarItem(icon: Icon(Icons.visibility_outlined), label: "Gallery"),
      BottomNavigationBarItem(icon: Icon(Icons.view_in_ar_outlined), label: "AR View"),
    ],
  );
}