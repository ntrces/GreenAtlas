import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';
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
  final Color color;

  const TreeModel({
    required this.name,
    required this.scientificName,
    required this.assetPath,
    required this.color,
  });
}

// Sample threatened trees from Cavite Protected Area - ordered by conservation status
// CR (Critically Endangered) > EN (Endangered) > VU (Vulnerable)
const List<TreeModel> threatenedTrees = [
  // Critically Endangered (CR)
  TreeModel(
    name: 'Subyang',
    scientificName: 'Hopea quisumbingiana',
    assetPath: 'assets/paho.glb',
    color: Colors.red,
  ),
  // Endangered (EN)
  TreeModel(
    name: 'Molave',
    scientificName: 'Vitex parviflora',
    assetPath: 'assets/paho.glb',
    color: Colors.orange,
  ),
  TreeModel(
    name: 'Manggachapui',
    scientificName: 'Hopea acuminata',
    assetPath: 'assets/paho.glb',
    color: Colors.orange,
  ),
  TreeModel(
    name: 'Kubili',
    scientificName: 'Cubilia cubili',
    assetPath: 'assets/paho.glb',
    color: Colors.orange,
  ),
  // Vulnerable (VU)
  TreeModel(
    name: 'Dao',
    scientificName: 'Dracontomelon dao',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Paho',
    scientificName: 'Mangifera altissima',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Narra',
    scientificName: 'Pterocarpus indicus',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Kamagong',
    scientificName: 'Diospyros discolor',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Kalantas',
    scientificName: 'Toona calantas',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Dila-dila',
    scientificName: 'Cynometra inaequifolia',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Haikan',
    scientificName: 'Camellia lanceolata',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Malachio',
    scientificName: 'Glenniea philippinensis',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Bagarilau',
    scientificName: 'Cryptocarya ampla',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Nato',
    scientificName: 'Palaquium luzoniense',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Malak-malak',
    scientificName: 'Palaquium philippense',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Katmon',
    scientificName: 'Dillenia philippinensis',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
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
          // AR viewer - immersive 3D model exploration
          ModelViewer(
            backgroundColor: const Color(0xFF0A0A0A),
            src: _viewingArTree!.assetPath,
            alt: "A 3D model of ${_viewingArTree!.name}",
            ar: true,
            autoRotate: false,  // Don't auto-rotate - let user control
            cameraControls: true,  // Enable full camera control for exploration
            exposure: 1.2,  // Brighter sunlight effect
            shadowIntensity: 0.5,  // Dynamic shadows for depth
            shadowSoftness: 1.0,  // Soft shadows for natural lighting
          ),

          // Surface placement prompt
          Positioned(
            bottom: 160,
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
                const SizedBox(height: 8),
                const Text(
                  "Move around • Pinch to zoom • Drag to rotate",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 11),
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
                    // Dark overlay (~10% opacity for enhanced contrast)
                    Container(
                      width: width,
                      height: height,
                      color: Colors.black.withOpacity(0.1),
                    ),
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
      _PlantPosition(left: 180, top: 290, plant: threatenedTrees[5]), // Paho (VU)
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
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                plant.name,
                style: TextStyle(
                  color: plant.color,
                  fontFamily: 'Poppins-Bold',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: const Offset(1, 1),
                      blurRadius: 3,
                      color: Colors.black54,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        ElevatedButton(
          onPressed: () => _viewPlantInAR(plant),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF517156),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: const Size(60, 24),
          ),
          child: const Text(
            'View in AR',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins-Bold',
              fontSize: 8,
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
