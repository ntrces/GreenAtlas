import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../user_dashboard.dart';
import '../AR View/ar_view.dart';
import 'ar_camera.dart'; 
import '../notification.dart';
import '../../UserProfile/user_profile.dart';
import 'gallery_filtering.dart'; 
import '../../components/notification_badge.dart';

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

  // Helper to get the color based on conservation status
  Color _getConservationColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case 'Critically Endangered': return Colors.red;
      case 'Endangered': return Colors.orange;
      case 'Vulnerable': return Colors.amber;
      case 'Threatened': return Colors.orange;
      case 'Other Threatened Status': return Colors.amber;
      case 'Near Threatened': return Colors.lightGreen;
      case 'Not Threatened': return Colors.teal;
      case 'Least Concern (LC)': return Colors.green;
      case 'Data Deficient': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  // Helper to get the icon based on conservation status for LIST VIEW
  Widget _getConservationIcon(String? status) {
    if (status == null) return const SizedBox.shrink();
    switch (status) {
      case 'Critically Endangered':
        return const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 14);
      case 'Endangered':
        return const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 14);
      case 'Vulnerable':
        return const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 14);
      case 'Threatened':
        return const Icon(Icons.circle, color: Colors.orange, size: 10);
      case 'Other Threatened Status':
        return const Icon(Icons.circle, color: Colors.amber, size: 10);
      case 'Near Threatened':
        return const Icon(Icons.circle, color: Colors.lightGreen, size: 10);
      case 'Not Threatened':
        return const Icon(Icons.circle, color: Colors.teal, size: 10);
      case 'Least Concern (LC)':
        return const Icon(Icons.circle, color: Colors.green, size: 10);
      case 'Data Deficient':
        return const Icon(Icons.circle, color: Colors.blueGrey, size: 10);
      default:
        return const SizedBox.shrink();
    }
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
      appBar: _buildFixedAppBar(),
      body: Column(
        children: [
          _buildFixedSearchAndFilterSection(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildPlantDataStream(),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildFixedAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Transform.scale(
                scale: 1.3,
                child: Image.asset('assets/logo2.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Botanical Gallery", 
                  style: TextStyle(
                    fontFamily: 'Poppins-Bold',
                    fontSize: 18,
                    color: Color(0xFF303D32),
                    height: 1.2,
                  ),
                ),
                Text(
                  "Explore the Cavite Protected Area", 
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        const UserNotificationBadge(iconColor: Color(0xFF303D32)),
        _buildProfileIcon(),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildFixedSearchAndFilterSection() => Container(
    color: const Color(0xFFEAF7EA),
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
                    suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.black38, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = "");
                            },
                          )
                        : null,
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
        const SizedBox(height: 16), 
      ],
    ),
  );

  Widget _buildActiveFilters() {
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
          const Text(
            "Filter : ",
            style: TextStyle(fontSize: 14, color: Color(0xFF2D3E2D)),
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
            style: const TextStyle(color: Color(0xFF2D3E2D), fontSize: 13),
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
        childAspectRatio: 0.82
      ),
      delegate: SliverChildBuilderDelegate((context, i) => _buildGridItem(plants[i]), childCount: plants.length),
    ),
  );

  Widget _buildListItem(Map<String, dynamic> plant) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: Container(
            color: isHovered ? const Color(0xFFF8FFF8) : Colors.white,
            child: Column(
              children: [
                ListTile(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ARCameraScreen(plantData: plant))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImageThumb(plant['image_url'], 70),
                  ),
                  title: Text(
                    plant['common_name'] ?? "Unknown", 
                    style: TextStyle(
                      fontFamily: 'Poppins-Bold', 
                      fontSize: 16, 
                      color: isHovered ? _getConservationColor(plant['conservation_status']) : const Color(0xFF303D32)
                    ),
                  ),
                  subtitle: Text(
                    plant['scientific_name'] ?? "Unknown Species", 
                    style: TextStyle(
                      color: isHovered ? _getConservationColor(plant['conservation_status']) : Colors.black45, 
                      fontSize: 13, 
                      fontStyle: FontStyle.italic,
                      fontWeight: isHovered ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    Icons.chevron_right, 
                    color: isHovered ? _getConservationColor(plant['conservation_status']).withOpacity(0.5) : Colors.black12
                  ),
                ),
                const Divider(height: 1, indent: 102, color: Color(0xFFF0F0F0)),
              ],
            ),
          ),
        );
      }
    );
  }

  // UPDATED GRID VIEW DESIGN
  Widget _buildGridItem(Map<String, dynamic> plant) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ARCameraScreen(plantData: plant))),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(15), 
                border: Border.all(
                  color: isHovered 
                      ? _getConservationColor(plant['conservation_status']).withOpacity(0.3) 
                      : Colors.black.withOpacity(0.05),
                  width: isHovered ? 2 : 1,
                ),
                boxShadow: isHovered ? [
                  BoxShadow(
                    color: _getConservationColor(plant['conservation_status']).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ] : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)), 
                      child: Stack(
                        children: [
                          _buildImageThumb(plant['image_url'], double.infinity),
                          if (isHovered)
                            Positioned(
                              bottom: 8, 
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getConservationColor(plant['conservation_status']),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  plant['conservation_status'] ?? "Unknown",
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      )
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant['common_name'] ?? "Unknown", 
                          style: TextStyle(
                            fontFamily: 'Poppins-Bold', 
                            fontSize: 13, 
                            color: isHovered ? _getConservationColor(plant['conservation_status']) : const Color(0xFF303D32)
                          ), 
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isHovered 
                              ? plant['conservation_status'] ?? "" 
                              : plant['scientific_name'] ?? "",
                          style: TextStyle(
                            color: isHovered ? _getConservationColor(plant['conservation_status']) : Colors.black45, 
                            fontSize: 11,
                            fontWeight: isHovered ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildImageThumb(dynamic imageRaw, double size) {
    String? url;
    if (imageRaw is List && imageRaw.isNotEmpty) {
      url = imageRaw.first?.toString();
    } else if (imageRaw is String) {
      if (imageRaw.trim().startsWith('[')) {
        try {
          List<dynamic> parsedList = jsonDecode(imageRaw);
          if (parsedList.isNotEmpty) {
            url = parsedList.first?.toString();
          }
        } catch (e) {
          url = imageRaw;
        }
      } else {
        url = imageRaw;
      }
    }

    return Container(
      width: size, height: size, color: Colors.grey[100],
      child: (url != null && url.isNotEmpty) 
        ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.park_outlined, color: Colors.black12)) 
        : const Icon(Icons.park_outlined, color: Colors.black12),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onPressed}) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: IconButton(icon: Icon(icon, color: const Color(0xFF2D3E2D), size: 22), onPressed: onPressed),
  );

  Widget _buildProfileIcon() => Padding(
    padding: const EdgeInsets.only(right: 16.0, left: 8), 
    child: InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())), 
      child: Container(
        height: 40, width: 40, 
        decoration: BoxDecoration(color: const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)), 
        child: const Icon(Icons.person_outline, color: Color(0xFF303D32))
      )
    )
  );

  Widget _buildBottomNav() => Container(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0x1A000000), width: 0.5)),
    ),
    child: BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: const Color(0xFF517156),
      unselectedItemColor: Colors.black38,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: const TextStyle(fontFamily: 'Poppins-Bold', fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined), 
          activeIcon: Icon(Icons.home_rounded),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_stories_outlined), 
          activeIcon: Icon(Icons.auto_stories),
          label: "Plants",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.view_in_ar_outlined), 
          activeIcon: Icon(Icons.view_in_ar_rounded),
          label: "AR View",
        ), 
      ],
    ),
  );
}