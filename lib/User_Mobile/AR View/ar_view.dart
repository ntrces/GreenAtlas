import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../user_dashboard.dart';
import '../Botanical_Gallery/ar_gallery.dart';
import '../../UserProfile/user_profile.dart';
import '../notification.dart';
import '../../components/notification_badge.dart';

// Tree model data class
class TreeModel {
  final String name;
  final String scientificName;
  final String assetPath;
  final Icon icon;

  const TreeModel({
    required this.name,
    required this.scientificName,
    required this.assetPath,
    required this.icon,
  });
}

// Sample threatened trees from Cavite Protected Area - ordered by conservation status
// CR (Critically Endangered) > EN (Endangered) > VU (Vulnerable)
const List<TreeModel> threatenedTrees = [
  // Critically Endangered (CR)
  TreeModel(
    name: 'Subyang',
    scientificName: 'Hopea quisumbingiana',
    assetPath: 'assets/red_rose.glb',
    icon: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
  ),
  // Endangered (EN)
  TreeModel(
    name: 'Molave',
    scientificName: 'Vitex parviflora',
    assetPath: 'assets/tree.glb',
    icon: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
  ),
  TreeModel(
    name: 'Manggachapui',
    scientificName: 'Hopea acuminata',
    assetPath: 'assets/red_rose.glb',
    icon: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
  ),
  TreeModel(
    name: 'Kubili',
    scientificName: 'Cubilia cubili',
    assetPath: 'assets/red_rose.glb',
    icon: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
  ),
  // Vulnerable (VU)
  TreeModel(
    name: 'Dao',
    scientificName: 'Dracontomelon dao',
    assetPath: 'assets/red_rose.glb',
    icon: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
  ),
  TreeModel(
    name: 'Pahutan',
    scientificName: 'Mangifera altissima',
    assetPath: 'assets/bigfile.glb',
    icon: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
  ),
  TreeModel(
    name: 'Narra',
    scientificName: 'Pterocarpus indicus',
    assetPath: 'assets/narra.glb',
    icon: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
  ),
  TreeModel(
    name: 'Kamagong',
    scientificName: 'Diospyros discolor',
    assetPath: 'assets/red_rose.glb',
    icon: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
  ),
  TreeModel(
    name: 'Kalantas',
    scientificName: 'Toona calantas',
    assetPath: 'assets/red_rose.glb',
    icon: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
  ),
  TreeModel(
    name: 'Dila-dila',
    scientificName: 'Cynometra inaequifolia',
    assetPath: 'assets/red_rose.glb',
    icon: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
  ),
  TreeModel(
    name: 'Haikan',
    scientificName: 'Camellia lanceolata',
    assetPath: 'assets/red_rose.glb',
    icon: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
  ),
  TreeModel(
    name: 'Malachio',
    scientificName: 'Glenniea philippinensis',
    assetPath: 'assets/red_rose.glb',
    icon: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
  ),
  TreeModel(
    name: 'Bagarilau',
    scientificName: 'Cryptocarya ampla',
    assetPath: 'assets/red_rose.glb',
    icon: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
  ),
  TreeModel(
    name: 'Nato',
    scientificName: 'Palaquium luzoniense',
    assetPath: 'assets/red_rose.glb',
    icon: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
  ),
  TreeModel(
    name: 'Malak-malak',
    scientificName: 'Palaquium philippense',
    assetPath: 'assets/red_rose.glb',
    icon: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
  ),
  TreeModel(
    name: 'Katmon',
    scientificName: 'Dillenia philippinensis',
    assetPath: 'assets/red_rose.glb',
    icon: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
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
      backgroundColor: Colors.transparent,
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
          const UserNotificationBadge(iconColor: Color(0xFF303D32)),
          _buildProfileIcon(),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/plant_shelf.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate responsive dimensions based on screen size
              double width = constraints.maxWidth * 0.95;
              double height = width * (803 / 412); // Maintain aspect ratio
              
              return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/plant_shelf.png'),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {},
                  ),
                  color: Colors.grey[300],
                ),
                child: Stack(
                  children: [
                    // Overlay buttons positioned on plants
                    _buildPlantOverlays(width, height),
                  ],
                ),
              );
            },
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

  Widget _buildPlantOverlays(double containerWidth, double containerHeight) {
    // Scale factors based on responsive dimensions
    const double baseWidth = 412;
    const double baseHeight = 803;
    final double scaleX = containerWidth / baseWidth;
    final double scaleY = containerHeight / baseHeight;
    
    // Plant positions on the shelf (center points) - base values for 412x803
    final plantPositions = [
      // Top shelf
      _PlantPosition(left: 95, top: 190, plant: threatenedTrees[0]), // Subyang (CR)
      _PlantPosition(left: 180, top: 170, plant: threatenedTrees[1]), // Molave (EN)
      _PlantPosition(left: 250, top: 170, plant: threatenedTrees[2]), // Manggachapui (EN)
      _PlantPosition(left: 360, top: 190, plant: threatenedTrees[3]), // Kubili (EN)
      // Second shelf
      _PlantPosition(left: 95, top: 310, plant: threatenedTrees[4]), // Dao (VU)
      _PlantPosition(left: 180, top: 290, plant: threatenedTrees[5]), // Pahutan (VU)
      _PlantPosition(left: 270, top: 290, plant: threatenedTrees[6]), // Narra (VU)
      _PlantPosition(left: 350, top: 310, plant: threatenedTrees[7]), // Kamagong (VU)
      // Middle/Hanging section
      _PlantPosition(left: 95, top: 430, plant: threatenedTrees[8]), // Kalantas (VU)
      _PlantPosition(left: 355, top: 430, plant: threatenedTrees[9]), // Dila-dila (VU)
      // Third shelf
      _PlantPosition(left: 95, top: 545, plant: threatenedTrees[10]), // Haikan (VU)
      _PlantPosition(left: 175, top: 540, plant: threatenedTrees[11]), // Malachio (VU)
      _PlantPosition(left: 260, top: 540, plant: threatenedTrees[12]), // Bagarilau (VU)
      _PlantPosition(left: 355, top: 550, plant: threatenedTrees[13]), // Nato (VU)
      // Bottom shelf
      _PlantPosition(left: 80, top: 655, plant: threatenedTrees[14]), // Malak-malak (VU)
      _PlantPosition(left: 355, top: 655, plant: threatenedTrees[15]), // Katmon (VU)
    ];

    return SizedBox(
      width: containerWidth,
      height: containerHeight,
      child: Stack(
        children: plantPositions
            .map(
              (pos) => Positioned(
                left: pos.left * scaleX,
                top: pos.top * scaleY,
                child: Transform.translate(
                  offset: const Offset(-55, -35),
                  child: _buildPlantButton(pos.plant),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPlantButton(TreeModel plant) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        plant.icon,
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            plant.name,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins-Bold',
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        ElevatedButton(
          onPressed: () => _viewPlantInAR(plant),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF517156),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(70, 28),
          ),
          child: const Text(
            'View in AR',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins-Bold',
              fontSize: 9,
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
