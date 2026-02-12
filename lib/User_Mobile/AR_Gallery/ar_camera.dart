import 'package:flutter/material.dart';

class ARCameraScreen extends StatefulWidget {
  final Map<String, dynamic> plantData;

  const ARCameraScreen({
    super.key, 
    required this.plantData 
  });

  @override
  State<ARCameraScreen> createState() => _ARCameraScreenState();
}

class _ARCameraScreenState extends State<ARCameraScreen> {
  @override
  Widget build(BuildContext context) {
    // Extracting dynamic data
    final String commonName = widget.plantData['common_name'] ?? "Unknown Species";
    final String scientificName = widget.plantData['scientific_name'] ?? "N/A";
    final String status = widget.plantData['conservation_status'] ?? "Common";
    final String zone = widget.plantData['location_zone'] ?? "N/A";
    final String description = widget.plantData['description'] ?? "No additional information.";
    final String? imgUrl = widget.plantData['image_url'];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // --- 1. FULLSCREEN CAMERA FEED PLACEHOLDER ---
          const SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.black),
              child: Center(child: Icon(Icons.camera_alt_outlined, color: Colors.white10, size: 80)),
            ),
          ),

          // --- 2. TOP BRANDING HEADER (Clean Version) ---
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(commonName, 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3E2D))),
                        Text(scientificName, 
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black38)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 3. CENTRAL UI: LARGE IMAGE BESIDE AR CONTROLS ---
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- LARGE SQUARE REFERENCE IMAGE ---
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: 140, height: 140, // Significantly bigger square
                      color: Colors.white10,
                      child: (imgUrl != null && imgUrl.startsWith('http'))
                        ? Image.network(imgUrl, fit: BoxFit.cover)
                        : const Icon(Icons.eco, size: 40, color: Colors.white24),
                    ),
                  ),
                  
                  const SizedBox(width: 24),

                  // --- AR INSTRUCTION COLUMN ---
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.visibility_outlined, color: Colors.white, size: 48),
                        const SizedBox(height: 12),
                        const Text("AR Active", 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text("Find a flat surface to place the $commonName",
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == "Endangered" ? const Color(0xFFFFEBEE) : const Color(0xFFEAF7EA), 
                          borderRadius: BorderRadius.circular(6)
                        ),
                        child: Text(status, 
                          style: TextStyle(
                            color: status == "Endangered" ? Colors.redAccent : const Color(0xFF5D7A5D), 
                            fontSize: 10, fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.black38),
                      const SizedBox(width: 4),
                      Text(zone, style: const TextStyle(color: Colors.black38, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(description,
                    style: const TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                          label: const Text("Start AR Placement", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D7A5D),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
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