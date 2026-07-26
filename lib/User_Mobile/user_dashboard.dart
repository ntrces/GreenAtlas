import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../theme_constants.dart';
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
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: getScaffoldBg(isDark),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: isDark ? Colors.white12 : const Color(0x1A000000), width: 0.5), 
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: isDark ? leafAccent : const Color(0xFF517156),
          unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
          backgroundColor: getCardBg(isDark),
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
          _buildSliverAppBar(isDark),

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
                            isDark,
                          ),
                          _buildStatCard(
                            allPlants.length.toString(), 
                            "Species", 
                            Icons.eco_outlined,
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ARGalleryScreen())),
                            isDark,
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
                      _buildFilterChip("All", 0, null, isDark),
                      _buildFilterChip("Plants", 1, Icons.eco_outlined, isDark),
                      _buildFilterChip("Activity", 2, Icons.history, isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (_activeFilterIndex == 0) ...[
                  _buildSectionLabel("QUICK ACCESS", isDark),
                  _buildListTile("View Plants Gallery", Icons.visibility_outlined, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ARGalleryScreen())), isDark),
                  _buildListTile("View AR Garden", Icons.view_in_ar_outlined, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Ar_View())), isDark, tag: "Quick"),
                  _buildListTile("View Profile", Icons.person_outline, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())), isDark),
                ],

                if (_activeFilterIndex == 0 || _activeFilterIndex == 1) ...[
                  _buildSectionLabelWithAction("FEATURED PLANTS", "See all", 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ARGalleryScreen())), isDark),
                  
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _supabase.from('plants').stream(primaryKey: ['id']).limit(3),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF4A634A))));
                      final plants = snapshot.data!;
                      
                      return Column(
                        children: plants.map((plant) => _buildPlantTile(
                          plant, 
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => ARCameraScreen(plantData: plant))),
                          isDark,
                        )).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTopContributorsSection(isDark),
                ],

                if (_activeFilterIndex == 0 || _activeFilterIndex == 2) ...[
                  _buildSectionLabelWithAction("RECENT ACTIVITY", "See all", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())), isDark),
                  
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
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text("No recent activity.", style: TextStyle(color: getSubtextColor(isDark), fontSize: 13)),
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
                              isDark,
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

  Widget _buildSliverAppBar(bool isDark) => SliverAppBar(
    pinned: true, backgroundColor: isDark ? const Color(0xFF1E261F) : Colors.white, surfaceTintColor: isDark ? const Color(0xFF1E261F) : Colors.white,
    elevation: 0, toolbarHeight: 80, leadingWidth: 70,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: CircleAvatar(
        radius: 30, backgroundColor: isDark ? const Color(0xFF253326) : Colors.white,
        child: Transform.scale(
          scale: 1.3,
          child: Image.asset('assets/logo2.png', fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(Icons.eco, color: isDark ? leafAccent : const Color(0xFF2D3E2D))),
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
              style: TextStyle(
                fontFamily: 'Poppins-Bold',
                fontSize: 18,
                color: getTextColor(isDark),
                height: 1.2,
              ),
            ),
            Text("Explore the Cavite Protected Area", 
              style: TextStyle(color: getSubtextColor(isDark), fontSize: 12)),
          ],
        );
      }
    ),
    actions: [
      UserNotificationBadge(iconColor: isDark ? Colors.white : const Color(0xFF303D32)),
      _buildProfileIcon(isDark)
    ],
  );

  Widget _buildStatCard(String val, String label, IconData icon, VoidCallback onTap, bool isDark) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 86.59,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: getCardBg(isDark), 
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? Colors.white12 : const Color(0x26303D32), width: 1.32),
        ), 
        child: Row(
          children: [
            CircleAvatar(backgroundColor: isDark ? const Color(0xFF2B3A2C) : const Color(0xFFF0F4F0), child: Icon(icon, color: isDark ? leafAccent : const Color(0xFF5D7A5D), size: 20)), 
            const SizedBox(width: 12), 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(val, style: TextStyle(fontFamily: 'Poppins-Bold', fontSize: 18, color: getTextColor(isDark))), 
                Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: getSubtextColor(isDark)))
              ]
            )
          ]
        )
      ),
    ),
  );

  Widget _buildFilterChip(String label, int index, IconData? icon, bool isDark) { 
    bool isSelected = _activeFilterIndex == index; 
    return Padding(
      padding: const EdgeInsets.only(right: 8.0), 
      child: FilterChip(
        showCheckmark: false, 
        avatar: icon != null ? Icon(icon, size: 16, color: isSelected ? Colors.white : (isDark ? leafAccent : const Color(0xFF4A634A))) : null, 
        label: Text(label), 
        selected: isSelected, 
        onSelected: (bool selected) { setState(() => _activeFilterIndex = index); _saveFilterPreference(index); }, 
        selectedColor: isDark ? leafAccent : const Color(0xFF4A634A), 
        labelStyle: TextStyle(color: isSelected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white70 : const Color(0xFF4A634A)), fontSize: 13), 
        backgroundColor: isDark ? const Color(0xFF253326) : const Color(0xFFD6E8D6), 
        side: BorderSide.none, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
      )
    ); 
  }

  Widget _buildSectionLabel(String title, bool isDark) => Container(
    width: double.infinity, 
    padding: const EdgeInsets.all(16), 
    color: isDark ? const Color(0xFF182219) : const Color(0xFFE8F3E8), 
    child: Text(
      title.toUpperCase(), 
      style: TextStyle(
        fontFamily: 'Poppins-Bold',
        fontSize: 12,
        letterSpacing: 0.3,
        color: isDark ? leafAccent : const Color(0xFF517156),
      ),
    ),
  );

  Widget _buildSectionLabelWithAction(String title, String action, VoidCallback onAction, bool isDark) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16), 
    color: isDark ? const Color(0xFF182219) : const Color(0xFFE8F3E8), 
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        Text(
          title.toUpperCase(), 
          style: TextStyle(
            fontFamily: 'Poppins-Bold',
            fontSize: 12,
            letterSpacing: 0.3,
            color: isDark ? leafAccent : const Color(0xFF517156),
          ),
        ), 
        TextButton(onPressed: onAction, child: Text(action, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey)))
      ]
    )
  );

  Widget _buildListTile(String title, IconData icon, VoidCallback onTap, bool isDark, {String? tag}) => Material(
    color: getCardBg(isDark), 
    child: Column(
      children: [
        ListTile(
          onTap: onTap, 
          leading: Icon(icon, color: isDark ? leafAccent : const Color(0xFF517156), size: 22), 
          title: Row(
            children: [
              Text(
                title, 
                style: TextStyle(
                  fontFamily: 'Poppins-Bold',
                  fontSize: 12,
                  color: getTextColor(isDark),
                ),
              ), 
              if (tag != null) ...[
                const SizedBox(width: 8), 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF253326) : const Color(0xFFE8F3E8), borderRadius: BorderRadius.circular(12)), 
                  child: Text(
                    tag, 
                    style: TextStyle(fontSize: 11, color: isDark ? leafAccent : const Color(0xFF5D7A5D)),
                  ),
                ),
              ]
            ]
          ), 
          trailing: Icon(Icons.chevron_right, size: 20, color: isDark ? Colors.white38 : Colors.black26)
        ), 
        Divider(height: 1, indent: 70, color: isDark ? Colors.white12 : const Color(0xFFF0F0F0))
      ]
    )
  );

  Widget _buildPlantTile(Map<String, dynamic> plant, VoidCallback onTap, bool isDark) {
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
      color: getCardBg(isDark),
      child: Column(
        children: [
          ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 50, height: 50, color: isDark ? const Color(0xFF2B3A2C) : const Color(0xFFF0F4F0),
                child: (imgUrl != null && imgUrl.isNotEmpty)
                  ? Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.eco, color: isDark ? Colors.white24 : Colors.black12))
                  : Icon(Icons.eco, color: isDark ? Colors.white24 : Colors.black12),
              ),
            ),
            title: Row(
              children: [
                Text(
                  plant['common_name'] ?? "Unknown", 
                  style: TextStyle(
                    fontFamily: 'Inter', 
                    fontSize: 14, 
                    color: getTextColor(isDark),
                  ),
                ),
                if (plant['ar_model_url'] != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                    decoration: BoxDecoration(color: isDark ? leafAccent : const Color(0xFF5D7A5D), borderRadius: BorderRadius.circular(6)), 
                    child: Text("AR", style: TextStyle(color: isDark ? Colors.black : Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                  )
                ]
              ],
            ),
            subtitle: Text(plant['scientific_name'] ?? "Unknown", style: TextStyle(fontSize: 12, color: getSubtextColor(isDark))),
            trailing: Icon(Icons.chevron_right, size: 20, color: isDark ? Colors.white38 : Colors.black26),
          ),
          Divider(height: 1, indent: 82, color: isDark ? Colors.white12 : const Color(0xFFF0F0F0)),
        ],
      ),
    );
  }

  Widget _buildActivityTile(String title, String time, IconData icon, VoidCallback onTap, bool isDark, {String? status}) => Material(
    color: getCardBg(isDark), 
    child: Column(
      children: [
        ListTile(
          onTap: onTap, 
          leading: Icon(icon, color: isDark ? Colors.white54 : Colors.black38, size: 22), 
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title, 
                  style: TextStyle(
                    fontFamily: 'Inter', 
                    fontSize: 14, 
                    color: getTextColor(isDark),
                  ),
                ),
              ), 
              if (status != null) 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
                  decoration: BoxDecoration(color: isDark ? Colors.white10 : const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(12)), 
                  child: Text(status, style: TextStyle(color: status == 'Resolved' ? Colors.greenAccent : (isDark ? Colors.white70 : Colors.black54), fontSize: 10))
                )
            ]
          ), 
          subtitle: Text(time, style: TextStyle(fontSize: 12, color: getSubtextColor(isDark))), 
          trailing: Icon(Icons.chevron_right, size: 20, color: isDark ? Colors.white38 : Colors.black26)
        ), 
        Divider(height: 1, indent: 70, color: isDark ? Colors.white12 : const Color(0xFFF0F0F0))
      ]
    )
  );

  Widget _buildProfileIcon(bool isDark) => Padding(
    padding: const EdgeInsets.only(right: 16.0, left: 8), 
    child: InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())), 
      child: Container(
        height: 40, width: 40, 
        decoration: BoxDecoration(color: isDark ? const Color(0xFF2B3A2C) : const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(10), border: Border.all(color: isDark ? Colors.white24 : Colors.black12)), 
        child: Icon(Icons.person_outline, color: getTextColor(isDark))
      )
    )
  );

  Widget _buildTopContributorsSection(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('profiles').stream(primaryKey: ['id']).limit(20),
      builder: (context, profileSnapshot) {
        if (!profileSnapshot.hasData || profileSnapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final profiles = profileSnapshot.data!;

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _supabase.from('field_entries').stream(primaryKey: ['id']),
          builder: (context, entrySnapshot) {
            final allEntries = entrySnapshot.data ?? [];

            // Calculate observation count per user
            final Map<String, int> entryCounts = {};
            for (final entry in allEntries) {
              final uid = entry['user_id']?.toString();
              if (uid != null) {
                entryCounts[uid] = (entryCounts[uid] ?? 0) + 1;
              }
            }

            // Map and sort contributors
            final List<Map<String, dynamic>> contributors = profiles.map((p) {
              final uid = p['id'].toString();
              final count = entryCounts[uid] ?? 0;
              return {
                'profile': p,
                'count': count,
              };
            }).toList();

            // Sort by highest contribution count
            contributors.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel("TOP CONTRIBUTORS", isDark),
                const SizedBox(height: 12),
                SizedBox(
                  height: 155,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: contributors.length,
                    itemBuilder: (context, index) {
                      final item = contributors[index];
                      final p = item['profile'] as Map<String, dynamic>;
                      final count = item['count'] as int;
                      final name = p['full_name'] ?? p['first_name'] ?? "Contributor";
                      final avatarUrl = p['avatar_url']?.toString();
                      final rank = index + 1;

                      String badgeEmoji = "";
                      Color rankColor = isDark ? leafAccent : const Color(0xFF5D7A5D);
                      if (rank == 1) { badgeEmoji = "🥇"; rankColor = const Color(0xFFFFD700); }
                      else if (rank == 2) { badgeEmoji = "🥈"; rankColor = const Color(0xFFC0C0C0); }
                      else if (rank == 3) { badgeEmoji = "🥉"; rankColor = const Color(0xFFCD7F32); }

                      return GestureDetector(
                        onTap: () => _showContributorProfileModal(context, p, count, rank, isDark),
                        child: Container(
                          width: 115,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: getCardBg(isDark),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: rank <= 3 ? rankColor.withOpacity(0.6) : (isDark ? Colors.white12 : const Color(0x26303D32)),
                              width: rank <= 3 ? 1.8 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: isDark ? const Color(0xFF253326) : const Color(0xFFF0F4F0),
                                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                                    child: (avatarUrl == null || avatarUrl.isEmpty)
                                        ? Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : "?",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontFamily: 'Poppins-Bold',
                                              color: isDark ? leafAccent : const Color(0xFF5D7A5D),
                                            ),
                                          )
                                        : null,
                                  ),
                                  if (badgeEmoji.isNotEmpty)
                                    Positioned(
                                      bottom: -2, right: -2,
                                      child: Text(badgeEmoji, style: const TextStyle(fontSize: 14)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Poppins-Bold',
                                  fontSize: 12,
                                  color: getTextColor(isDark),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "$count entries",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: getSubtextColor(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  void _showContributorProfileModal(BuildContext context, Map<String, dynamic> profile, int entryCount, int rank, bool isDark) {
    final name = profile['full_name'] ?? profile['first_name'] ?? "Contributor Profile";
    final avatarUrl = profile['avatar_url']?.toString();
    final muni = profile['municipality'] ?? "";
    final city = profile['city'] ?? "";
    final location = (muni.isNotEmpty || city.isNotEmpty) ? "$muni, $city" : "Cavite Protected Area";
    final role = (profile['role'] ?? 'Contributor').toString().toUpperCase();

    showModalBottomSheet(
      context: context,
      backgroundColor: getCardBg(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: isDark ? const Color(0xFF253326) : const Color(0xFFF0F4F0),
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: TextStyle(fontSize: 28, fontFamily: 'Poppins-Bold', color: isDark ? leafAccent : const Color(0xFF5D7A5D)))
                  : null,
            ),
            const SizedBox(height: 12),
            Text(name, style: TextStyle(fontFamily: 'Poppins-Bold', fontSize: 18, color: getTextColor(isDark))),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF253326) : const Color(0xFFE8F3E8), borderRadius: BorderRadius.circular(12)),
              child: Text("RANK #$rank • $role", style: TextStyle(fontSize: 11, fontFamily: 'Poppins-Bold', color: isDark ? leafAccent : const Color(0xFF5D7A5D))),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildModalStatItem("LOCATION", location, Icons.map_outlined, isDark),
                _buildModalStatItem("OBSERVATIONS", "$entryCount Entries", Icons.eco_outlined, isDark),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModalStatItem(String label, String value, IconData icon, bool isDark) => Column(
    children: [
      Icon(icon, size: 22, color: isDark ? leafAccent : const Color(0xFF5D7A5D)),
      const SizedBox(height: 6),
      Text(label, style: TextStyle(fontSize: 10, color: getSubtextColor(isDark), fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 12, color: getTextColor(isDark), fontFamily: 'Poppins-Bold')),
    ],
  );
}