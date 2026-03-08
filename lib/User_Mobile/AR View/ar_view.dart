import 'package:flutter/material.dart';
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
  int _selectedIndex = 2; // Fixed index for AR View

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    // Navigation matching ARGalleryScreen logic
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserDashboard()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ARGalleryScreen()));
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Immersive dark background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70, // Matched height from ARGallery
        leadingWidth: 70,  // Matched width from ARGallery
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: Image.asset(
              'assets/logo2.png',
              width: 45, // Matched size from ARGallery
              height: 45,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Color(0xFF2D3E2D), size: 30),
            ),
          ),
        ),
        title: const Text(
          "AR View", 
          style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          _buildNotificationIcon(),
          _buildProfileIcon(),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The Eye Icon UI remains centered
            Icon(
              Icons.visibility_outlined, 
              color: Colors.white.withOpacity(0.4), 
              size: 100,
            ),
            const SizedBox(height: 24),
            const Text(
              "AR Camera Active",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 50),
              child: Text(
                "Point your camera at a flat surface to place the Philippine Orchid",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF2D3E2D), // Matched color from ARGallery
        unselectedItemColor: Colors.black38,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.visibility_outlined), label: "Plants Gallery"), // Matched label
          BottomNavigationBarItem(icon: Icon(Icons.view_in_ar_outlined), label: "AR View"),
        ],
      ),
    );
  }

  // --- UI COMPONENTS (Matched Exactly to Gallery Styles) ---

  Widget _buildNotificationIcon() => Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF2D3E2D), size: 26),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
          Positioned(
            right: 10,
            top: 14,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Color(0xFF5D7A5D), shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: const Text('2', 
                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), 
                textAlign: TextAlign.center
              ),
            ),
          )
        ],
      );

  Widget _buildProfileIcon() => Padding(
        padding: const EdgeInsets.only(right: 16.0, left: 8),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
          child: Container(
            height: 36, // Matched size from ARGallery
            width: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EA), 
              borderRadius: BorderRadius.circular(8), 
              border: Border.all(color: Colors.black12),
            ),
            child: const Icon(Icons.person_outline, color: Color(0xFF2D3E2D), size: 20),
          ),
        ),
      );
}