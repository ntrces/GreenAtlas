import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../user_dashboard.dart';
import '../Botanical_Gallery/ar_gallery.dart';
import '../../UserProfile/user_profile.dart';
import '../notification.dart'; 
import '../../components/notification_badge.dart';

class Ar_View extends StatefulWidget {
  const Ar_View({super.key});

  @override
  State<Ar_View> createState() => _Ar_ViewState();
}

class _Ar_ViewState extends State<Ar_View> {
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserDashboard()));
    if (index == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ARGalleryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      // --- HEADER MATCHED TO DASHBOARD ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Transform.scale(
              scale: 1.3,
              child: Image.asset('assets/logo2.png', fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Color(0xFF2D3E2D))),
            ),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "AR View", 
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
        actions: [
          const UserNotificationBadge(iconColor: Color(0xFF303D32)),
          _buildProfileIcon(),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          ModelViewer(
            backgroundColor: const Color(0xFF0A0A0A),
            src: 'assets/red_rose.glb',
            alt: "A 3D Red Rose",
            ar: true,
            autoRotate: true,
            cameraControls: true,
            arModes: const ['scene-viewer', 'webxr-ar-module', 'quick-look'],
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  "AR Camera Active", 
                  style: TextStyle(fontFamily: 'Poppins-Bold', color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 50),
                  child: Center(
                    child: Text(
                      "Tap the cube icon to place the Red Rose in your space",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // --- BOTTOM NAV MATCHED TO DASHBOARD ---
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
    );
  }

  Widget _buildProfileIcon() => Padding(
    padding: const EdgeInsets.only(right: 16.0, left: 8), 
    child: InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())), 
      child: Container(
        height: 40, width: 40, 
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F0), 
          borderRadius: BorderRadius.circular(10), 
          border: Border.all(color: Colors.black12)
        ), 
        child: const Icon(Icons.person_outline, color: Color(0xFF303D32))
      )
    )
  );
}