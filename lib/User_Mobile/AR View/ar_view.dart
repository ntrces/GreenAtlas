import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../user_dashboard.dart';
import '../Botanical_Gallery/ar_gallery.dart';
import '../../UserProfile/user_profile.dart';
import '../notification.dart'; // Ensure this matches your file name

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        centerTitle: false, // Ensures title stays left-aligned like other pages
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: Image.asset('assets/logo2.png', width: 45, height: 45, fit: BoxFit.contain),
          ),
        ),
        title: const Text("AR View", 
          style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          _buildNotificationIcon(), 
          _buildProfileIcon(),
          const SizedBox(width: 8), // Padding at the end of actions
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
            // 'scene-viewer' is required for Android AR, 'quick-look' for iOS
            arModes: ['scene-viewer', 'webxr-ar-module', 'quick-look'],
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text("AR Camera Active", 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 50),
                  child: Text("Tap the cube icon to place the Red Rose in your space",
                      textAlign: TextAlign.center, 
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
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

  // --- Header Icons Fixed with Navigation ---

  Widget _buildNotificationIcon() => Stack(
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
            child: IgnorePointer( // Prevents badge from blocking button taps
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Color(0xFF5D7A5D), shape: BoxShape.circle),
                child: const Text('2', 
                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      );

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