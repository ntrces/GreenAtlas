import 'package:flutter/material.dart';
import '../Report/report.dart';

class ViewReportScreen extends StatelessWidget {
  final Map<String, dynamic> reportData;
  const ViewReportScreen({super.key, required this.reportData});

  @override
  Widget build(BuildContext context) {
    final String? evidenceUrl = reportData['evidence_url'];

    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3E2D)),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ReportScreen()),
            );
          },
        ),
        title: const Text("Report Details", 
          style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // --- SIDE-BY-SIDE HEADER: IMAGE (LEFT) & DATA (RIGHT) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. LEFT SIDE: SQUARE IMAGE
                  SizedBox(
                    width: 120, // Compact square size
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: evidenceUrl != null
                            ? Image.network(
                                evidenceUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.black12),
                              ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 20),

                  // 2. RIGHT SIDE: REPORT INFO
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reportData['incident_type'] ?? "Incident Report",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reportData['report_id'] ?? "RPT-XXX",
                          style: const TextStyle(color: Colors.black38, fontSize: 13, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 12),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            reportData['status']?.toUpperCase() ?? "PENDING",
                            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _buildBanner(),
              const SizedBox(height: 20),
              _buildDetailsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFFFFFDE7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orangeAccent.withOpacity(0.3))),
        child: const Row(children: [
          Icon(Icons.access_time, color: Colors.orange, size: 20),
          SizedBox(width: 8),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Under Investigation", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  "Our team is currently investigating this incident. We will update you once completed.",
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ))
        ]),
      );

  Widget _buildDetailsCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Full Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            _buildItem("Description", reportData['description']),
            _buildItem("Location", reportData['location']),
            _buildItem(
                "Date Reported",
                reportData['created_at'] != null
                    ? reportData['created_at'].toString().split('T')[0]
                    : "N/A"),
          ],
        ),
      );

  Widget _buildItem(String label, String? value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black26, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value ?? "N/A", style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4)),
          const SizedBox(height: 16),
        ],
      );
}