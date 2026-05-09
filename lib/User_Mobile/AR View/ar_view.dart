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
  final String assetPath;

  const TreeModel({
    required this.name,
    required this.scientificName,
    required this.assetPath,
  });
}

// Sample threatened trees from Cavite Protected Area
const List<TreeModel> threatenedTrees = [
  TreeModel(
    name: 'Dao',
    scientificName: 'Dracontomelon dao',
    assetPath: 'assets/red_rose.glb',
  ),
  TreeModel(
    name: 'Pahutan',
    scientificName: 'Mangifera altissima',
    assetPath: 'assets/red_rose.glb',
  ),
  TreeModel(
    name: 'Narra',
    scientificName: 'Pterocarpus indicus',
    assetPath: 'assets/red_rose.glb',
  ),
  TreeModel(
    name: 'Molave',
    scientificName: 'Vitex parviflora',
    assetPath: 'assets/red_rose.glb',
  ),
  TreeModel(
    name: 'Manggachapui',
    scientificName: 'Hopea acuminata',
    assetPath: 'assets/red_rose.glb',
  ),
  TreeModel(
    name: 'Kamagong',
    scientificName: 'Diospyros discolor',
    assetPath: 'assets/red_rose.glb',
  ),
  TreeModel(
    name: 'Kalantas',
    scientificName: 'Toona calantas',
    assetPath: 'assets/red_rose.glb',
  ),
  TreeModel(
    name: 'Dila-dila',
    scientificName: 'Cynometra inaequifolia',
    assetPath: 'assets/red_rose.glb',
  ),
  TreeModel(
    name: 'Haikan',
    scientificName: 'Camellia lanceolata',
    assetPath: 'assets/red_rose.glb',
  ),
  TreeModel(
    name: 'Malachio',
    scientificName: 'Glenniea philippinensis',
    assetPath: 'assets/red_rose.glb',
  ),
  TreeModel(
    name: 'Bagarlau',
    scientificName: 'Cryptocarya ampla',
    assetPath: 'assets/red_rose.glb',
  ),
  TreeModel(
    name: 'Kubili',
    scientificName: 'Cubilia cubili',
    assetPath: 'assets/red_rose.glb',
  ),
  TreeModel(
    name: 'Subyang',
    scientificName: 'Hopea quisumbingiana',
    assetPath: 'assets/red_rose.glb',
  ),
  TreeModel(
    name: 'Nato',
    scientificName: 'Palaquium luzoniense',
    assetPath: 'assets/red_rose.glb',
  ),
  TreeModel(
    name: 'Malak-malak',
    scientificName: 'Palaquium philippense',
    assetPath: 'assets/red_rose.glb',
  ),
  TreeModel(
    name: 'Katmon',
    scientificName: 'Dillenia philippinensis',
    assetPath: 'assets/red_rose.glb',
  ),
];

class Ar_View extends StatefulWidget {
  const Ar_View({super.key});

  @override
  State<Ar_View> createState() => _Ar_ViewState();
}

class _Ar_ViewState extends State<Ar_View> {
  int _selectedIndex = 2;
  TreeModel? _viewingArTree; // Tree currently being viewed in AR
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

  void _viewPlantInAR(TreeModel tree) {
    if (!_hasPermission) {
      _checkPermission();
      return;
    }
    setState(() => _viewingArTree = tree);
  }

  void _closeARViewer() {
    setState(() => _viewingArTree = null);
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

    // If viewing a plant in AR, show the AR viewer
    if (_viewingArTree != null) {
      return _buildARViewerScreen();
    }

    // Show plant shelf with overlay buttons
    return _buildPlantShelfScreen();
  }

  Widget _buildARViewerScreen() {
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _viewingArTree!.name,
              style: const TextStyle(
                fontFamily: 'Poppins-Bold',
                fontSize: 18,
                color: Color(0xFF303D32),
                height: 1.2,
              ),
            ),
            Text(
              _viewingArTree!.scientificName,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
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
          // AR viewer
          ModelViewer(
            backgroundColor: const Color(0xFF0A0A0A),
            src: _viewingArTree!.assetPath,
            alt: "A 3D model of ${_viewingArTree!.name}",
            ar: true,
            autoRotate: true,
            cameraControls: true,
            arModes: const ['scene-viewer', 'webxr-ar-module', 'quick-look'],
          ),

          // Surface prompt text
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _viewingArTree!.name,
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

          // Close button
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: _closeARViewer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF517156),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Close AR Viewer',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins-Bold',
                  fontSize: 14,
                ),
              ),
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

  Widget _buildPlantShelfScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
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
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              // Background plant shelf image with fixed size
              Container(
                width: double.infinity,
                height: 600,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/plant_shelf.jpg'),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {},
                  ),
                  color: Colors.grey[300],
                ),
              ),
              // Overlay buttons positioned on plants
              _buildPlantOverlays(),
            ],
          ),
        ),
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

  Widget _buildPlantOverlays() {
    // Plant positions on the shelf (adjust these based on your image)
    final plantPositions = [
      // Top shelf
      _PlantPosition(left: 30, top: 40, plant: threatenedTrees[0]), // Dao
      _PlantPosition(left: 130, top: 60, plant: threatenedTrees[1]), // Pahutan
      _PlantPosition(left: 230, top: 40, plant: threatenedTrees[2]), // Narra
      _PlantPosition(left: 330, top: 60, plant: threatenedTrees[3]), // Molave
      // Second shelf
      _PlantPosition(left: 30, top: 180, plant: threatenedTrees[4]), // Manggachapui
      _PlantPosition(left: 130, top: 180, plant: threatenedTrees[5]), // Kamagong
      _PlantPosition(left: 230, top: 200, plant: threatenedTrees[6]), // Kalantas
      _PlantPosition(left: 330, top: 180, plant: threatenedTrees[7]), // Dila-dila
      // Middle/Hanging section
      _PlantPosition(left: 150, top: 260, plant: threatenedTrees[8]), // Haikan
      _PlantPosition(left: 260, top: 280, plant: threatenedTrees[9]), // Malachio
      // Third shelf
      _PlantPosition(left: 30, top: 380, plant: threatenedTrees[10]), // Bagarlau
      _PlantPosition(left: 130, top: 400, plant: threatenedTrees[11]), // Kubili
      _PlantPosition(left: 230, top: 380, plant: threatenedTrees[12]), // Subyang
      _PlantPosition(left: 330, top: 400, plant: threatenedTrees[13]), // Nato
      // Bottom shelf
      _PlantPosition(left: 30, top: 500, plant: threatenedTrees[14]), // Malak-malak
      _PlantPosition(left: 130, top: 520, plant: threatenedTrees[15]), // Katmon
    ];

    return SizedBox(
      width: double.infinity,
      height: 600,
      child: Stack(
        children: plantPositions
            .map(
              (pos) => Positioned(
                left: pos.left,
                top: pos.top,
                child: _buildPlantButton(pos.plant),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPlantButton(TreeModel plant) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            plant.name,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins-Bold',
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(height: 4),
        ElevatedButton(
          onPressed: () => _viewPlantInAR(plant),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF517156),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(0, 32),
          ),
          child: const Text(
            'View in AR',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins-Bold',
              fontSize: 10,
            ),
          ),
        ),
      ],
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

// Helper class for plant position mapping
class _PlantPosition {
  final double left;
  final double top;
  final TreeModel plant;

  _PlantPosition({
    required this.left,
    required this.top,
    required this.plant,
  });
}
