import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../theme_provider.dart';

class SentObservationsScreen extends StatelessWidget {
  final Map<String, dynamic> observation;

  const SentObservationsScreen({super.key, required this.observation});

  // Theme Colors from Design
  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);
  final Color lightGreenBG = const Color(0xFFEAF7EA);
  final Color statusBlue = const Color(0xFF5D7A7A); // Soft blue for Validated/Sent

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    // Safety check for date keys (observation_date or obs_date)
    final rawDate = observation['observation_date'] ?? observation['obs_date'] ?? DateTime.now().toString();
    final date = DateFormat('MMMM dd, yyyy').format(DateTime.parse(rawDate));
    
    final String status = observation['status']?.toString().toUpperCase() ?? "PENDING";

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : lightGreenBG,
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text("Entry Details", style: TextStyle(color: Colors.white, fontSize: 16)),
            Text("BMS-${observation['id'].toString().substring(0, 5).toUpperCase()}", 
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // Status Pill (Centered)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status, 
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
            const SizedBox(height: 16),

            // Metadata Card
            _buildWhiteCard([
              _buildDataRow("User ID:", "FO-12345"),
              _buildDataRow("Created:", observation['created_at']?.toString().substring(0, 16) ?? "N/A"),
              _buildDataRow("Modified:", date),
            ]),

            // Team Members Card (If jsonb data exists)
            if (observation['team_members'] != null)
              _buildWhiteCard([
                const Text("Team Members", style: TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 12),
                ... (observation['team_members'] as List).map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${m['firstname']} ${m['lastname']}", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      Text(m['role'] ?? "Member", style: const TextStyle(color: Colors.black38, fontSize: 11)),
                    ],
                  ),
                )),
              ]),

            // Location Details Card
            _buildWhiteCard([
              const Text("Location Details", style: TextStyle(fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildInfoItem("Region", observation['region'] ?? "N/A")),
                Expanded(child: _buildInfoItem("Province", observation['province'] ?? "N/A")),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildInfoItem("Protected Area", observation['protected_area'] ?? "N/A")),
                Expanded(child: _buildInfoItem("Date", date)),
              ]),
              const SizedBox(height: 12),
              _buildInfoItem("Weather", "${observation['weather_condition'] ?? 'N/A'}, ${observation['temperature'] ?? '--'}°C"),
            ]),

            // Observation Details Card
            _buildWhiteCard([
              const Text("Observation 1", style: TextStyle(fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 12),
              _buildInfoItem("Time", observation['observation_time'] ?? "N/A"),
              const SizedBox(height: 12),
              _buildInfoItem("Habitat", observation['habitat_type'] ?? "N/A"),
              const SizedBox(height: 12),
              _buildInfoItem("Wildlife Details", "${observation['taxon_group'] ?? 'N/A'}: ${observation['common_name'] ?? 'Unnamed'}"),
              const SizedBox(height: 12),
              _buildInfoItem("Discovery Method", observation['discovery_method'] ?? "N/A"),
            ]),

            // Image Card (if available)
            if (observation['image_url'] != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    observation['image_url'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildWhiteCard(List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white, 
      borderRadius: BorderRadius.circular(12), 
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _buildDataRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.black38, fontSize: 12)),
      Text(value, style: const TextStyle(color: Colors.black87, fontSize: 12)),
    ]),
  );

  Widget _buildInfoItem(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.black38)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87)),
    ],
  );

  Color _getStatusColor(String status) {
    if (status == 'VALIDATED') return Colors.blue;
    if (status == 'REJECTED') return Colors.red;
    return forestGreen; // Default for PENDING
  }
}