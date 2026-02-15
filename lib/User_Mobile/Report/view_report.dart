import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this for map support
import '../Report/report.dart';

class ViewReportScreen extends StatelessWidget {
  final Map<String, dynamic> reportData;
  const ViewReportScreen({super.key, required this.reportData});

  // --- 🗺️ MAP LAUNCHER LOGIC ---
  Future<void> _openInMaps() async {
    final double? lat = reportData['latitude'];
    final double? lng = reportData['longitude'];

    if (lat != null && lng != null) {
      // Create Google Maps URL
      final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
      
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open maps.';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? evidenceUrl = reportData['evidence_url'];
    final double? lat = reportData['latitude'];
    final double? lng = reportData['longitude'];

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
              // --- HEADER SECTION ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
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
                          "ID: ${reportData['id']?.toString().substring(0, 8).toUpperCase() ?? "N/A"}",
                          style: const TextStyle(color: Colors.black38, fontSize: 11, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 12),
                        _buildStatusBadge(reportData['status']),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _buildBanner(),
              const SizedBox(height: 20),

              // --- 📍 MAP LOCATION CARD ---
              if (lat != null && lng != null) _buildMapCard(lat, lng),

              const SizedBox(height: 20),
              _buildDetailsCard(),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildStatusBadge(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status?.toUpperCase() ?? "PENDING",
        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildMapCard(double lat, double lng) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF5D7A5D).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Precise Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text("$lat, $lng", style: const TextStyle(fontSize: 12, color: Colors.black45)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openInMaps,
              icon: const Icon(Icons.map_outlined, size: 18, color: Colors.white),
              label: const Text("OPEN IN GOOGLE MAPS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D7A5D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
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
                  "Our team is checking the precise coordinates and evidence provided.",
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
            _buildItem("Area/Zone", reportData['location']),
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