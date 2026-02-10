import 'package:flutter/material.dart';

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reportData['incident_type'] ?? "Report", style: const TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 18)),
            Text(reportData['report_id'] ?? "RPT-XXX", style: const TextStyle(color: Colors.black38, fontSize: 12)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(20)),
              child: Text(reportData['status'] ?? "Pending", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- IMAGE HEADER ---
            Container(
              width: double.infinity, height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                image: evidenceUrl != null ? DecorationImage(image: NetworkImage(evidenceUrl), fit: BoxFit.cover) : null
              ),
              child: evidenceUrl == null ? const Center(child: Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.black12)) : null,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildBanner(),
                  const SizedBox(height: 20),
                  _buildDetailsCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFDE7), 
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.orangeAccent.withOpacity(0.3))
    ),
    child: const Row(
      children: [
        Icon(Icons.access_time, color: Colors.orange, size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Under Investigation", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Our team is currently investigating this incident. We will update you once completed.", style: TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          )
        )
      ]
    ),
  );

  Widget _buildDetailsCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Incident Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _buildItem("Description", reportData['description']),
        _buildItem("Location", reportData['location']),
        _buildItem("Date Reported", reportData['created_at'].toString().split('T')[0]),
      ],
    ),
  );

  Widget _buildItem(String label, String? value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.black38)),
      const SizedBox(height: 4),
      Text(value ?? "N/A", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      const SizedBox(height: 16),
    ],
  );
}