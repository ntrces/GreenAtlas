import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../user_dashboard.dart';
import '../Botanical_Gallery/ar_gallery.dart';
import '../../UserProfile/user_profile.dart';
import '../notification.dart'; 

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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        centerTitle: false, 
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: Image.asset('assets/logo2.png', width: 45, height: 45, fit: BoxFit.contain),
          ),
        ),
        title: Text(
          "AR View", 
          style: textTheme.titleLarge?.copyWith(color: const Color(0xFF2D3E2D), fontSize: 20),
        ),
        actions: [
          _buildNotificationIcon(), 
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
                Text(
                  "AR Camera Active", 
                  style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Center(
                    child: Text(
                      "Tap the cube icon to place the Red Rose in your space",
                      style: textTheme.bodySmall?.copyWith(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          BottomNavigationBarItem(icon: Icon(Icons.visibility_outlined), label: "Plants"),
          BottomNavigationBarItem(icon: Icon(Icons.view_in_ar_outlined), label: "AR View"),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    final textTheme = Theme.of(context).textTheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Color(0xFF2D3E2D), size: 26),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
          },
        ),
        Positioned(
          right: 10,
          top: 14,
          child: IgnorePointer( 
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Color(0xFF5D7A5D), shape: BoxShape.circle),
              child: Text(
                '2', 
                style: textTheme.labelSmall?.copyWith(color: Colors.white, fontSize: 8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileIcon() => GestureDetector(
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen()));
    },
    child: Padding(
      padding: const EdgeInsets.only(right: 8, left: 8),
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7EA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12)),
        child: const Icon(Icons.person_outline, color: Color(0xFF2D3E2D), size: 20),
      ),
    ),
  );
}