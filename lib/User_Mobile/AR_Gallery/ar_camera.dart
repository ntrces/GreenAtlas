import 'package:flutter/material.dart';
import '../../theme_constants.dart';

class ARCameraScreen extends StatefulWidget {
  const ARCameraScreen({super.key});

  @override
  State<ARCameraScreen> createState() => _ARCameraScreenState();
}

class _ARCameraScreenState extends State<ARCameraScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // --- 1. CAMERA FEED PLACEHOLDER ---
          const SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.black),
              child: Center(child: Icon(Icons.camera_alt_outlined, color: Colors.white10, size: 80)),
            ),
          ),

          // --- 2. TOP WHITE BRANDING HEADER ---
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 50, bottom: 15, left: 16, right: 16),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Philippine Orchid", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3E2D))),
                      Text("Phalaenopsis amabilis", 
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black38)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // --- 3. CENTRAL INSTRUCTIONS ---
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility_outlined, color: Colors.white, size: 80),
                const SizedBox(height: 16),
                const Text("AR Camera Active", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text("Point your camera at a flat surface to place the Philippine Orchid",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.4)),
                ),
              ],
            ),
          ),

          // --- 4. BOTTOM SPECIES CARD ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(6)),
                        child: const Text("Endangered", 
                          style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.black38),
                      const SizedBox(width: 4),
                      const Text("Zone A-3", style: TextStyle(color: Colors.black38, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("Endemic orchid species with delicate white petals, plays crucial role in forest ecosystem.",
                    style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                          label: const Text("Start AR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D7A5D),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildIconButton(Icons.volume_up_outlined),
                      const SizedBox(width: 12),
                      _buildIconButton(Icons.info_outline),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // Helper for small side buttons
  Widget _buildIconButton(IconData icon) {
    return Container(
      height: 54, width: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Icon(icon, color: const Color(0xFF5D7A5D)),
    );
  }
}