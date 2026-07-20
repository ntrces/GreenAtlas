import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Botanical_Gallery/ar_gallery.dart'; 
import 'AR View/ar_view.dart'; 
import '../../UserProfile/user_profile.dart';
import 'notification.dart';
import 'Botanical_Gallery/ar_camera.dart'; 
import '../../components/notification_badge.dart';

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
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Ar_View()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0x1A000000), width: 0.5), 
          ),
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
      ),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // Center contents
              children: [
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabase.from('plants').stream(primaryKey: ['id']),
                  builder: (context, snapshot) {
                    final allPlants = snapshot.data ?? [];
                    final arCount = allPlants.where((p) => p['ar_model_url'] != null).length;
                    
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatCard(
                            arCount.toString(), 
                            "AR Models", 
                            Icons.visibility_outlined,
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ARGalleryScreen())),
                          ),
                          _buildStatCard(
                            allPlants.length.toString(), 
                            "Species", 
                            Icons.eco_outlined,
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ARGalleryScreen())),
                          ),
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
                  _buildListTile("View Plants Gallery", Icons.visibility_outlined, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ARGalleryScreen()))),
                  _buildListTile("View AR Garden", Icons.view_in_ar_outlined, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Ar_View())), tag: "Quick"),
                  _buildListTile("View Profile", Icons.person_outline, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen()))),
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
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => ARCameraScreen(plantData: plant))),
                        )).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                if (_activeFilterIndex == 0 || _activeFilterIndex == 2) ...[
                  _buildSectionLabelWithAction("RECENT ACTIVITY", "See all", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()))),
                  
                  if (_userId == null)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Log in to see activity")))
                  else
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _supabase
                          .from('audit_logs_with_roles')
                          .stream(primaryKey: ['id'])
                          .eq('user_id', _userId!)
                          .order('created_at', ascending: false),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF4A634A))));
                        }

                        final rawNotifs = snapshot.data?.where((n) => 
                          n['user_id'] == _userId &&
                          n['user_role'] != 'admin'
                        ).toList() ?? [];

                        final recentNotifs = rawNotifs.where((notif) {
                          final text = '${notif['title']} ${notif['message'] ?? notif['description']} ${notif['type'] ?? notif['category']} ${notif['action']}'.toLowerCase();
                          return text.contains('profile') || text.contains('plant');
                        }).take(3).toList();
                        
                        if (recentNotifs.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text("No recent activity.", style: TextStyle(color: Colors.black26, fontSize: 13)),
                            ),
                          );
                        }

                        return Column(
                          children: recentNotifs.map((notif) {
                            String type = notif['type'] ?? notif['category'] ?? 'general';
                            IconData icon = Icons.notifications_none;
                            if (type == 'plant_added') icon = Icons.local_library_rounded;
                            else if (type == 'security' || type == 'profile_update') icon = Icons.person_outline_rounded;

                            return _buildActivityTile(
                              notif['title'] ?? "Notification", 
                              notif['message'] ?? notif['description'] ?? "", 
                              icon, 
                              () {
                                final text = '${notif['title']} ${notif['message'] ?? notif['description']} ${notif['type'] ?? notif['category']} ${notif['action']}'.toLowerCase();
                                if (text.contains('plant')) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ARGalleryScreen()));
                                } else if (text.contains('profile') || text.contains('security')) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen()));
                                }
                              }, 
                            );
                          }).toList(),
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
    title: StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('profiles').stream(primaryKey: ['id']).eq('id', _userId ?? ''),
      builder: (context, snapshot) {
        String firstName = "User";
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final fullName = snapshot.data!.first['full_name'] ?? "User";
          firstName = fullName.split(' ')[0];
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, $firstName", 
              style: const TextStyle(
                fontFamily: 'Poppins-Bold',
                fontSize: 18,
                color: Color(0xFF303D32),
                height: 1.2,
              ),
            ),
            const Text("Explore the Cavite Protected Area", 
              style: TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        );
      }
    ),
    actions: [
      const UserNotificationBadge(iconColor: Color(0xFF303D32)),
      _buildProfileIcon()
    ],
  );

  Widget _buildStatCard(String val, String label, IconData icon, VoidCallback onTap) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 86.59,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x26303D32), width: 1.32),
        ), 
        child: Row(
          children: [
            CircleAvatar(backgroundColor: const Color(0xFFF0F4F0), child: Icon(icon, color: const Color(0xFF5D7A5D), size: 20)), 
            const SizedBox(width: 12), 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(val, style: const TextStyle(fontFamily: 'Poppins-Bold', fontSize: 18, color: Color(0xFF303D32))), 
                Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black54))
              ]
            )
          ]
        )
      ),
    ),
  );

  Widget _buildFilterChip(String label, int index, IconData? icon) { 
    bool isSelected = _activeFilterIndex == index; 
    return Padding(
      padding: const EdgeInsets.only(right: 8.0), 
      child: FilterChip(
        showCheckmark: false, 
        avatar: icon != null ? Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF4A634A)) : null, 
        label: Text(label), 
        selected: isSelected, 
        onSelected: (bool selected) { setState(() => _activeFilterIndex = index); _saveFilterPreference(index); }, 
        selectedColor: const Color(0xFF4A634A), 
        labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF4A634A), fontSize: 13), 
        backgroundColor: const Color(0xFFD6E8D6), 
        side: BorderSide.none, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
      )
    ); 
  }

  Widget _buildSectionLabel(String title) => Container(
    width: double.infinity, 
    padding: const EdgeInsets.all(16), 
    color: const Color(0xFFE8F3E8), 
    child: Text(
      title.toUpperCase(), 
      style: const TextStyle(
        fontFamily: 'Poppins-Bold',
        fontSize: 12,
        letterSpacing: 0.3,
        color: Color(0xFF517156),
      ),
    ),
  );

  Widget _buildSectionLabelWithAction(String title, String action, VoidCallback onAction) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16), 
    color: const Color(0xFFE8F3E8), 
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        Text(
          title.toUpperCase(), 
          style: const TextStyle(
            fontFamily: 'Poppins-Bold',
            fontSize: 12,
            letterSpacing: 0.3,
            color: Color(0xFF517156),
          ),
        ), 
        TextButton(onPressed: onAction, child: Text(action, style: const TextStyle(fontSize: 12, color: Colors.grey)))
      ]
    )
  );

  Widget _buildListTile(String title, IconData icon, VoidCallback onTap, {String? tag}) => Material(
    color: Colors.white, 
    child: Column(
      children: [
        ListTile(
          onTap: onTap, 
          leading: Icon(icon, color: const Color(0xFF517156), size: 22), 
          title: Row(
            children: [
              Text(
                title, 
                style: const TextStyle(
                  fontFamily: 'Poppins-Bold',
                  fontSize: 12,
                  color: Color(0xFF303D32),
                ),
              ), 
              if (tag != null) ...[
                const SizedBox(width: 8), 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
                  decoration: BoxDecoration(color: const Color(0xFFE8F3E8), borderRadius: BorderRadius.circular(12)), 
                  child: Text(
                    tag, 
                    style: const TextStyle(fontSize: 11, color: Color(0xFF5D7A5D)),
                  ),
                ),
              ]
            ]
          ), 
          trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.black26)
        ), 
        const Divider(height: 1, indent: 70, color: Color(0xFFF0F0F0))
      ]
    )
  );

  Widget _buildPlantTile(Map<String, dynamic> plant, VoidCallback onTap) {
    dynamic rawImg = plant['image_url'];
    String? imgUrl;
    
    if (rawImg is List && rawImg.isNotEmpty) {
      imgUrl = rawImg.first.toString();
    } else if (rawImg is String && rawImg.isNotEmpty) {
      if (rawImg.trim().startsWith('[')) {
        try {
          List<dynamic> parsed = jsonDecode(rawImg);
          if (parsed.isNotEmpty) {
            imgUrl = parsed.first.toString();
          }
        } catch (_) {
          imgUrl = rawImg;
        }
      } else {
        imgUrl = rawImg;
      }
    }

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
                child: (imgUrl != null && imgUrl.isNotEmpty)
                  ? Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Colors.black12))
                  : const Icon(Icons.eco, color: Colors.black12),
              ),
            ),
            title: Row(
              children: [
                Text(
                  plant['common_name'] ?? "Unknown", 
                  style: const TextStyle(
                    fontFamily: 'Inter', 
                    fontSize: 14, 
                    color: Color(0xFF303D32),
                  ),
                ),
                if (plant['ar_model_url'] != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                    decoration: BoxDecoration(color: const Color(0xFF5D7A5D), borderRadius: BorderRadius.circular(6)), 
                    child: const Text("AR", style: TextStyle(color: Colors.white, fontSize: 10))
                  )
                ]
              ],
            ),
            subtitle: Text(plant['scientific_name'] ?? "Unknown", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.black26),
          ),
          const Divider(height: 1, indent: 82, color: Color(0xFFF0F0F0)),
        ],
      ),
    );
  }

  Widget _buildActivityTile(String title, String time, IconData icon, VoidCallback onTap, {String? status}) => Material(
    color: Colors.white, 
    child: Column(
      children: [
        ListTile(
          onTap: onTap, 
          leading: Icon(icon, color: Colors.black38, size: 22), 
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title, 
                  style: const TextStyle(
                    fontFamily: 'Inter', 
                    fontSize: 14, 
                    color: Color(0xFF303D32),
                  ),
                ),
              ), 
              if (status != null) 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
                  decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(12)), 
                  child: Text(status, style: TextStyle(color: status == 'Resolved' ? Colors.green : Colors.black54, fontSize: 10))
                )
            ]
          ), 
          subtitle: Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)), 
          trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.black26)
        ), 
        const Divider(height: 1, indent: 70, color: Color(0xFFF0F0F0))
      ]
    )
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
}