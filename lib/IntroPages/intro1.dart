import 'package:flutter/material.dart';
import '../theme_constants.dart';
import 'intro2.dart'; 
import '../Login_Signup_Mobile/LoadingScreen/loading_pages.dart'; 

class Intro1Screen extends StatelessWidget {
  const Intro1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F4),
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
                          const SizedBox(height: 10),
                          
                          // Proportional Logo
                          Container(
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
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Image.asset(
                                  'logo2.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => 
                                      const Icon(Icons.eco, color: Color(0xFF5A7463), size: 50),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Center(
                            child: Text(
                              "Welcome to\nGreenAtlas",
                              style: textTheme.headlineMedium?.copyWith(
                                color: const Color(0xFF2D3E33),
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Center(
                            child: Text(
                              "Your interactive guide to discovering and learning about the rich plant biodiversity of Cavite Protected Area through augmented reality.",
                              style: textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF5A7F66),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Feature List
                          _buildFeatureItem("Interactive AR Botanical Gallery", textTheme),
                          _buildFeatureItem("Comprehensive Plant Database", textTheme),
                          _buildFeatureItem("Protected Area Flora Guide", textTheme),
                          _buildFeatureItem("Conservation & Educational Resources", textTheme),
                        ],
                      ),

                      // --- BOTTOM SECTION ---
                      Column(
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildDot(isActive: true),
                              const SizedBox(width: 6),
                              _buildDot(isActive: false),
                              const SizedBox(width: 6),
                              _buildDot(isActive: false),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5A7463),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const Intro2Screen()),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Next", 
                                    style: textTheme.labelLarge?.copyWith(color: Colors.white, fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "In partnership with",
                            style: textTheme.labelSmall?.copyWith(color: Colors.grey, fontSize: 10),
                          ),
                          Center(
                            child: Text(
                              "Department of Environment and Natural Resources",
                              style: textTheme.labelSmall?.copyWith(
                                color: const Color(0xFF4A6354),
                                fontSize: 11,
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

  Widget _buildFeatureItem(String text, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF94B49F), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: textTheme.titleSmall?.copyWith(fontSize: 13, color: const Color(0xFF4A4A4A)),
            ),
          ),
        ],
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