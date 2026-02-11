import 'package:flutter/material.dart';
import 'submit_report.dart'; // Import your form screen

class SubmitReport1Screen extends StatelessWidget {
  const SubmitReport1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA),
      
      body: Column(
        children: [
          // --- 2. SUB-HEADER WITH BACK BUTTON ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3E2D)),
                  onPressed: () => Navigator.pop(context),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Submit Report", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
                    Text("Help protect our area", style: TextStyle(fontSize: 12, color: Colors.black38)),
                  ],
                ),
              ],
            ),
          ),
          // --- 3. LEGAL INFO CONTENT ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF5D7A5D).withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegalSection(
                      "Protected Under RA 9147",
                      "Republic Act No. 9147 - Wildlife Resources Conservation and Protection Act of 2001",
                      ["Killing or destroying wildlife species", "Inflicting injury on wildlife", "Collecting wildlife without permit", "Trading or exporting wildlife", "Destroying critical habitats"],
                      "Violators face 6-12 years imprisonment and fines up to ₱1,000,000."
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
                    _buildLegalSection(
                      "Protected Under RA 11038",
                      "Republic Act No. 11038 - E-NIPAS Act of 2018",
                      ["Hunting or disturbing wildlife", "Cutting timber/forest products", "Mineral extraction", "Dumping waste materials", "Setting fires"],
                      "Violators face imprisonment and fines from ₱50,000 to ₱5,000,000."
                    ),
                  ],
                ),
              ),
            ),
          ),
          // --- 4. NAVIGATION FOOTER ---
          _buildNavigationFooter(context),
        ],
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildLegalSection(String title, String desc, List<String> acts, String penalty) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.info_outline, color: Color(0xFF32A852), size: 18),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
      ]),
      const SizedBox(height: 8),
      Text(desc, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      const SizedBox(height: 12),
      const Text("Prohibited Acts:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ...acts.map((act) => Padding(
        padding: const EdgeInsets.only(top: 4, left: 8),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 14, color: Color(0xFF5D7A5D)),
          const SizedBox(width: 8),
          Expanded(child: Text(act, style: const TextStyle(fontSize: 12, color: Colors.black54))),
        ]),
      )),
      const SizedBox(height: 12),
      const Text("Penalties:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      Text(penalty, style: const TextStyle(fontSize: 12, color: Colors.black54)),
    ]);
  }

  Widget _buildNavigationFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFFEAF7EA),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitReportScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D7A5D),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Row(children: [
              Text("Next", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 18, color: Colors.white),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, {bool hasBadge = false}) {
    return Stack(alignment: Alignment.center, children: [
      IconButton(icon: Icon(icon, color: const Color(0xFF2D3E2D), size: 28), onPressed: () {}),
      if (hasBadge) Positioned(right: 8, top: 12, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFF5D7A5D), shape: BoxShape.circle), child: const Text("2", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
    ]);
  }

  Widget _buildProfileContainer() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0, left: 8),
      child: Container(height: 38, width: 38, decoration: BoxDecoration(color: const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)), child: const Icon(Icons.person_outline, color: Colors.black54)),
    );
  }
}