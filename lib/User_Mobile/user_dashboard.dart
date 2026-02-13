import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'AR_Gallery/ar_gallery.dart'; 
import 'Report/report.dart';
import 'Report/submit_report.dart';
import '../../UserProfile/user_profile.dart';
import 'notification.dart';
import 'AR_Gallery/ar_camera.dart'; 

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final _supabase = Supabase.instance.client;
  int _selectedIndex = 0; 
  int _activeFilterIndex = 0;

  String? get _userId => _supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadFilterPreference();
  }

  Future<void> _loadFilterPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _activeFilterIndex = prefs.getInt('activeFilterIndex') ?? 0;
      });
    }
  }

  Future<void> _saveFilterPreference(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('activeFilterIndex', index);
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ARGalleryScreen()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
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
          _buildSliverAppBar(),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabase.from('plants').stream(primaryKey: ['id']),
                  builder: (context, snapshot) {
                    final allPlants = snapshot.data ?? [];
                    final arCount = allPlants.where((p) => p['ar_model_url'] != null).length;
                    
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          _buildStatCard(arCount.toString(), "AR Models", Icons.visibility_outlined),
                          const SizedBox(width: 12),
                          _buildStatCard(allPlants.length.toString(), "Species", Icons.eco_outlined),
                        ],
                      ),
                    );
                  }
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      _buildFilterChip("All", 0, null),
                      _buildFilterChip("Plants", 1, Icons.eco_outlined),
                      _buildFilterChip("Activity", 2, Icons.history),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (_activeFilterIndex == 0) ...[
                  _buildSectionLabel("QUICK ACCESS"),
                  _buildListTile("AR Gallery", Icons.visibility_outlined, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ARGalleryScreen()))),
                  _buildListTile("Report Issue", Icons.error_outline, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitReportScreen())), tag: "Quick"),
                ],

                if (_activeFilterIndex == 0 || _activeFilterIndex == 1) ...[
                  _buildSectionLabelWithAction("FEATURED PLANTS", "See all", 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ARGalleryScreen()))),
                  
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _supabase.from('plants').stream(primaryKey: ['id']).limit(3),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF4A634A))));
                      final plants = snapshot.data!;
                      
                      return Column(
                        children: plants.map((plant) => _buildPlantTile(
                          plant, 
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => ARCameraScreen(plantData: plant)))
                        )).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                if (_activeFilterIndex == 0 || _activeFilterIndex == 2) ...[
                  _buildSectionLabel("RECENT ACTIVITY"),
                  
                  if (_userId == null)
                    const Padding(padding: EdgeInsets.all(20), child: Text("Log in to see your activity"))
                  else
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _supabase
                          .from('reports')
                          .stream(primaryKey: ['id'])
                          .eq('user_id', _userId!)
                          .limit(2),
                      builder: (context, snapshot) {
                        final userReports = snapshot.data ?? [];
                        
                        if (userReports.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text("No recent reports.", style: TextStyle(color: Colors.black26, fontSize: 13)),
                          );
                        }

                        return Column(
                          children: userReports.map((report) => _buildActivityTile(
                            "${report['incident_type']} reported", 
                            "Recent", 
                            Icons.error_outline, 
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen())), 
                            status: report['status']
                          )).toList(),
                        );
                      }
                    ),
                ],
                const SizedBox(height: 32), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- FIXED APPBAR WITH DYNAMIC NAME FETCHING ---
  Widget _buildSliverAppBar() => SliverAppBar(
    pinned: true, backgroundColor: Colors.white, surfaceTintColor: Colors.white,
    elevation: 0, toolbarHeight: 80, leadingWidth: 70,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: CircleAvatar(
        radius: 30, backgroundColor: Colors.white,
        child: Transform.scale(
          scale: 1.3,
          child: Image.asset('assets/logo2.png', fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Color(0xFF2D3E2D))),
        ),
      ),
    ),
    // FIXED: Using StreamBuilder to fetch first name from profiles table
    title: StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('profiles').stream(primaryKey: ['id']).eq('id', _userId ?? ''),
      builder: (context, snapshot) {
        String firstName = "User";
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final fullName = snapshot.data!.first['full_name'] ?? "User";
          firstName = fullName.split(' ')[0]; // Isolate first name
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome, $firstName", 
              style: const TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 22)),
            const Text("Explore the Cavite Protected Area", 
              style: TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        );
      }
    ),
    actions: [_buildNotificationIcon(), _buildProfileIcon()],
  );

  // (Remaining helper methods remain unchanged)
  Widget _buildNotificationIcon() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('reports').stream(primaryKey: ['id']).eq('user_id', _userId ?? ''),
      builder: (context, snapshot) {
        final reports = snapshot.data?.where((r) => r['status'] != 'Pending').toList() ?? [];
        final unreadCount = reports.length; 

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Color(0xFF2D3E2D), size: 28), 
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()))
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8, top: 12, 
                child: Container(
                  height: 8, width: 8,
                 
                )
              ),
          ],
        );
      }
    );
  }

  Widget _buildPlantTile(Map<String, dynamic> plant, VoidCallback onTap) {
    final imgUrl = plant['image_url'];
    return Material(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 50, height: 50, color: const Color(0xFFF0F4F0),
                child: (imgUrl != null && imgUrl.toString().isNotEmpty)
                  ? Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Colors.black12))
                  : const Icon(Icons.eco, color: Colors.black12),
              ),
            ),
            title: Row(
              children: [
                Text(plant['common_name'] ?? "Unknown", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF2D3E2D))),
                if (plant['ar_model_url'] != null) ...[
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF5D7A5D), borderRadius: BorderRadius.circular(6)), child: const Text("AR", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))
                ]
              ],
            ),
            subtitle: Text("${plant['location_zone']} • ${plant['conservation_status']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.black26),
          ),
          const Divider(height: 1, indent: 82, color: Color(0xFFF0F0F0)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String val, String label, IconData icon) => Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Row(children: [CircleAvatar(backgroundColor: const Color(0xFFF0F4F0), child: Icon(icon, color: const Color(0xFF5D7A5D), size: 20)), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54))])])));
  Widget _buildFilterChip(String label, int index, IconData? icon) { bool isSelected = _activeFilterIndex == index; return Padding(padding: const EdgeInsets.only(right: 8.0), child: FilterChip(showCheckmark: false, avatar: icon != null ? Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF4A634A)) : null, label: Text(label), selected: isSelected, onSelected: (bool selected) { setState(() => _activeFilterIndex = index); _saveFilterPreference(index); }, selectedColor: const Color(0xFF4A634A), labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF4A634A), fontWeight: FontWeight.bold, fontSize: 13), backgroundColor: const Color(0xFFD6E8D6), side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)))); }
  Widget _buildSectionLabel(String title) => Container(width: double.infinity, padding: const EdgeInsets.all(16), color: const Color(0xFFE8F3E8), child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4A634A), letterSpacing: 0.8)));
  Widget _buildSectionLabelWithAction(String title, String action, VoidCallback onAction) => Container(padding: const EdgeInsets.symmetric(horizontal: 16), color: const Color(0xFFE8F3E8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4A634A), letterSpacing: 0.8)), TextButton(onPressed: onAction, child: Text(action, style: const TextStyle(fontSize: 12, color: Colors.grey)))]));
  Widget _buildListTile(String title, IconData icon, VoidCallback onTap, {String? tag}) => Material(color: Colors.white, child: Column(children: [ListTile(onTap: onTap, leading: Icon(icon, color: const Color(0xFF2D3E2D), size: 22), title: Row(children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)), if (tag != null) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFE8F3E8), borderRadius: BorderRadius.circular(12)), child: Text(tag, style: const TextStyle(fontSize: 11, color: Color(0xFF5D7A5D), fontWeight: FontWeight.bold)))]]), trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.black26)), const Divider(height: 1, indent: 70, color: Color(0xFFF0F0F0))]));
  Widget _buildActivityTile(String title, String time, IconData icon, VoidCallback onTap, {String? status}) => Material(color: Colors.white, child: Column(children: [ListTile(onTap: onTap, leading: Icon(icon, color: Colors.black38, size: 22), title: Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))), if (status != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(12)), child: Text(status, style: TextStyle(color: status == 'Resolved' ? Colors.green : Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)))]), subtitle: Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)), trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.black26)), const Divider(height: 1, indent: 70, color: Color(0xFFF0F0F0))]));
  Widget _buildProfileIcon() => Padding(padding: const EdgeInsets.only(right: 16.0, left: 8), child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())), child: Container(height: 40, width: 40, decoration: BoxDecoration(color: const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)), child: const Icon(Icons.person_outline, color: Colors.black54))));
}