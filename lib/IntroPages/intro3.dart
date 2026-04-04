import 'package:flutter/material.dart';
import '../theme_constants.dart';
import '../Login_Signup_Mobile/LoadingScreen/loading_pages.dart';

class Intro3Screen extends StatelessWidget {
  const Intro3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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

                          Center(
                            child: Text(
                              "Explore Plant Knowledge",
                              style: textTheme.headlineMedium?.copyWith(
                                color: const Color(0xFF2D3E33),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Center(
                            child: Text(
                              "Access comprehensive information about each species including habitat, uses, conservation threats, and cultural significance curated by DENR botanists.",
                              style: textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF5A7F66),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // --- BOTTOM SECTION ---
                      Column(
                        children: [
                          // Page Indicator
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
                                    child: Text(
                                      "Back",
                                      style: textTheme.labelLarge?.copyWith(
                                        color: const Color(0xFF5A7463),
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
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Get Started",
                                          style: textTheme.labelLarge?.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          
                          // Footer
                          Text(
                            "In partnership with",
                            style: textTheme.labelSmall?.copyWith(color: Colors.grey),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 10),
                            child: Center(
                              child: Text(
                                "Department of Environment and Natural Resources",
                                style: textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF4A6354),
                                ),
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