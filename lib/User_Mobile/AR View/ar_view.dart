import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../user_dashboard.dart';
import '../Botanical_Gallery/ar_gallery.dart';
import '../../UserProfile/user_profile.dart';
import '../notification.dart';

// Tree model data class
class TreeModel {
  final String name;
  final String scientificName;
  final String conservationStatus;
  final String assetPath;
  final String imagePath;

  const TreeModel({
    required this.name,
    required this.scientificName,
    required this.conservationStatus,
    required this.assetPath,
    required this.imagePath,
  });
}

// Sample threatened trees — replace with your actual data
const List<TreeModel> threatenedTrees = [
  TreeModel(
    name: 'Katmon',
    scientificName: 'Dillenia philippinensis',
    conservationStatus: 'Vulnerable',
    assetPath: 'assets/red_rose.glb',
    imagePath: 'assets/logo1.png',
  ),
  TreeModel(
    name: 'Molave',
    scientificName: 'Vitex parviflora',
    conservationStatus: 'Vulnerable',
    assetPath: 'assets/red_rose.glb',
    imagePath: 'assets/logo1.png',
  ),
  TreeModel(
    name: 'Narra',
    scientificName: 'Pterocarpus indicus',
    conservationStatus: 'Endangered',
    assetPath: 'assets/red_rose.glb',
    imagePath: 'assets/logo1.png',
  ),
  TreeModel(
    name: 'Kamagong',
    scientificName: 'Diospyros philippinensis',
    conservationStatus: 'Critically Endangered',
    assetPath: 'assets/red_rose.glb',
    imagePath: 'assets/logo1.png',
  ),
];

class Ar_View extends StatefulWidget {
  const Ar_View({super.key});

  @override
  State<Ar_View> createState() => _Ar_ViewState();
}

class _Ar_ViewState extends State<Ar_View> {
  int _selectedIndex = 2;
  TreeModel _selectedTree = threatenedTrees[0]; // Default first tree
  bool _hasPermission = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
      _isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    if (index == 0)
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const UserDashboard()));
    if (index == 1)
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ARGalleryScreen()));
  }

  // Shows bottom sheet grid for tree selection (TC-94)
  void _showTreeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select a Tree',
                style: TextStyle(
                  fontFamily: 'Poppins-Bold',
                  fontSize: 16,
                  color: Color(0xFF303D32),
                ),
              ),
              const SizedBox(height: 12),
              // Grid of trees (TC-94)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: threatenedTrees.length,
                itemBuilder: (context, index) {
                  final tree = threatenedTrees[index];
                  final isSelected = tree.name == _selectedTree.name;
                  return GestureDetector(
                    onTap: () {
                      // TC-95: Select tree from grid — replaces current one
                      setState(() => _selectedTree = tree);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE8F0E9)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF517156)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.park,
                              size: 36, color: Color(0xFF517156)),
                          const SizedBox(height: 8),
                          Text(
                            tree.name,
                            style: const TextStyle(
                              fontFamily: 'Poppins-Bold',
                              fontSize: 13,
                              color: Color(0xFF303D32),
                            ),
                          ),
                          Text(
                            tree.conservationStatus,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black45),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Shows info bottom sheet for selected tree (TC-98)
  void _showTreeInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedTree.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins-Bold',
                      fontSize: 20,
                      color: Color(0xFF303D32),
                    ),
                  ),
                  // TC-99: Dismissal via X button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.black45),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _selectedTree.scientificName,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedTree.conservationStatus,
                  style: const TextStyle(
                    fontFamily: 'Poppins-Bold',
                    color: Color(0xFF517156),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Permission not yet resolved
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF517156))),
      );
    }

    // TC-87: Camera permission denied
    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.no_photography, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Camera permission is required\nto use AR View.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkPermission,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF517156)),
                child: const Text('Grant Permission',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
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
              child: Image.asset('assets/logo2.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.eco, color: Color(0xFF2D3E2D))),
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
          IconButton(
            icon: const Icon(Icons.notifications_none,
                color: Color(0xFF303D32), size: 28),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
          _buildProfileIcon(),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // TC-93: AR viewer loads selected tree model (one at a time)
          ModelViewer(
            backgroundColor: const Color(0xFF0A0A0A),
            src: _selectedTree.assetPath, // TC-96: One tree at a time
            alt: "A 3D model of ${_selectedTree.name}",
            ar: true,
            autoRotate: true,
            cameraControls: true,
            arModes: const ['scene-viewer', 'webxr-ar-module', 'quick-look'],
          ),

          // TC-86: Surface prompt text
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _selectedTree.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins-Bold',
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Point at a flat surface, then tap the cube icon to place",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // TC-92: Bottom bar — Switch and Info buttons
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Switch button — opens grid (TC-94)
                _buildBottomBarButton(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Switch',
                  onTap: _showTreeSelector,
                ),
                // Info button — opens info panel (TC-97)
                _buildBottomBarButton(
                  icon: Icons.info_outline_rounded,
                  label: 'Info',
                  onTap: _showTreeInfo,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
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
          selectedLabelStyle:
              const TextStyle(fontFamily: 'Poppins-Bold', fontSize: 12),
          unselectedLabelStyle:
              const TextStyle(fontFamily: 'Poppins', fontSize: 12),
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

  Widget _buildBottomBarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins-Bold',
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileIcon() => Padding(
        padding: const EdgeInsets.only(right: 16.0, left: 8),
        child: InkWell(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const UserProfileScreen())),
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black12),
            ),
            child: const Icon(Icons.person_outline, color: Color(0xFF303D32)),
          ),
        ),
      );
}
