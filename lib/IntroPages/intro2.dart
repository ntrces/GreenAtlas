import 'package:flutter/material.dart';
import '../theme_constants.dart';
import 'intro3.dart'; 
import '../Login_Signup_Mobile/LoadingScreen/loading_pages.dart'; 

class Intro2Screen extends StatelessWidget {
  const Intro2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F4), 
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center, // * Centers everything
                    children: [
                      // --- TOP SECTION ---
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: TextButton(
                              onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const LoadingPage()),
                              ),
                              child: Text(
                                "Skip",
                                style: textTheme.labelLarge?.copyWith(
                                  color: const Color(0xFF5A7463),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 180), // * Matches Intro 1
                          
                          // Camera Icon Container (Styled like Logo in Intro 1)
                          Center(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  color: Color(0xFF5A7463),
                                  size: 50,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Header Text
                          Column(
                            children: [
                              Text(
                                "AR Botanical",
                                style: textTheme.headlineMedium?.copyWith(
                                  color: const Color(0xFF2D3E33),
                                  fontFamily: 'Poppins-Bold',
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                "Gallery",
                                style: textTheme.headlineMedium?.copyWith(
                                  color: const Color(0xFF2D3E33),
                                  fontFamily: 'Poppins-Bold',
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Description matching Intro 1's 313 width
                          Center(
                            child: SizedBox(
                              width: 313,
                              child: Column(
                                children: [
                                  Text(
                                    "Explore an immersive collection of native",
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF5A7F66),
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                  Text(
                                    "plants in augmented reality. Point your",
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF5A7F66),
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                  Text(
                                    "camera at the environment to discover",
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF5A7F66),
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                  Text(
                                    "interactive 3D plant models.",
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF5A7F66),
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // --- BOTTOM SECTION ---
                      Column(
                        children: [
                          const SizedBox(height: 5), // * Sitting higher
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildDot(isActive: false),
                              const SizedBox(width: 6),
                              _buildDot(isActive: true),
                              const SizedBox(width: 6),
                              _buildDot(isActive: false),
                            ],
                          ),
                          const SizedBox(height: 15),

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
                                        fontFamily: 'Poppins-Bold',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Next Button
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const Intro3Screen()),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF517156),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Next",
                                          style: textTheme.labelLarge?.copyWith(
                                            color: Colors.white,
                                            fontFamily: 'Poppins-Bold',
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          
                          // Footer with larger text sizes
                          Text(
                            "In partnership with",
                            style: textTheme.labelSmall?.copyWith(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              "Department of Environment and Natural Resources",
                              style: textTheme.labelSmall?.copyWith(
                                color: const Color(0xFF4A6354),
                                fontSize: 13,
                                fontFamily: 'poppins-bold'
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
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