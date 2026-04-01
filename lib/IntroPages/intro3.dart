import 'package:flutter/material.dart';
import '../theme_constants.dart';
import '../LoadingScreen/loading_pages.dart'; // Import your Loading Page

class Intro3Screen extends StatelessWidget {
  const Intro3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F4), // Soft mint background
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // --- TOP SECTION ---
                      Column(
                        children: [
                          // Skip button removed as requested
                          const SizedBox(height: 60), 
                          
                          // Book Icon Container
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.menu_book_rounded, 
                                color: Color(0xFF5A7463),
                                size: 60,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          const Text(
                            "Explore Plant Knowledge",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2D3E33),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            "Access comprehensive information about each species including habitat, uses, conservation threats, and cultural significance curated by DENR botanists.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF5A7F66),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),

                      // --- BOTTOM SECTION ---
                      Column(
                        children: [
                          // Page Indicator (Third dot active)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildDot(isActive: false),
                              const SizedBox(width: 6),
                              _buildDot(isActive: false),
                              const SizedBox(width: 6),
                              _buildDot(isActive: true),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Button Row
                          Row(
                            children: [
                              // Back Button
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE8F3EB),
                                      side: const BorderSide(color: Color(0xFFD1E3D7)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      "Back",
                                      style: TextStyle(
                                        color: Color(0xFF5A7463),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Get Started Button
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    // UPDATED: Now goes to LoadingPage -> Dashboard
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => const LoadingPage()),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF5A7463),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Get Started",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          
                          // Footer
                          const Text(
                            "In partnership with",
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 4, bottom: 10),
                            child: Text(
                              "Department of Environment and Natural Resources",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A6354),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper for the pill-shaped page indicator
  Widget _buildDot({required bool isActive}) {
    return Container(
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF5A7463) : const Color(0xFFD1E3D7),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}