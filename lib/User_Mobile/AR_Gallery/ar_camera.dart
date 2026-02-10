import 'package:flutter/material.dart';
import '../../theme_constants.dart';

class ARCameraScreen extends StatefulWidget {
  const ARCameraScreen({super.key});

  @override
  State<ARCameraScreen> createState() => _ARCameraScreenState();
}

class _ARCameraScreenState extends State<ARCameraScreen> {
  bool _isModelLoaded = false;

  @override
  void initState() {
    super.initState();
    // Simulate model loading for the edutainment experience
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isModelLoaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Camera background color
      body: Stack(
        children: [
          // --- 1. CAMERA FEED PLACEHOLDER ---
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: const Center(
              child: Icon(Icons.camera_alt_outlined, color: Colors.white24, size: 100),
            ),
          ),

          // --- 2. AR MODEL OVERLAY (Simulation) ---
          if (_isModelLoaded)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.eco, color: Colors.greenAccent, size: 150), // Simulated 3D model
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Philippine Orchid (3D)",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // --- 3. TOP CONTROLS ---
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Text(
                  "AR VIEW",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: Icon(Icons.info_outline, color: Colors.white),
                ),
              ],
            ),
          ),

          // --- 4. BOTTOM ACTION BAR ---
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (!_isModelLoaded)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCaptureButton(Icons.refresh, "Reset"),
                    _buildMainCaptureButton(),
                    _buildCaptureButton(Icons.share, "Share"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.white24,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }

  Widget _buildMainCaptureButton() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: const CircleAvatar(
        radius: 35,
        backgroundColor: Colors.white,
      ),
    );
  }
}