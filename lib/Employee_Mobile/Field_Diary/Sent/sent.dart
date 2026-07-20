import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../theme_provider.dart';
import '../Collect/observation_model.dart';
import '../Collect/collect01.dart';

class SentObservationsScreen extends StatelessWidget {
  final Map<String, dynamic> observation;

  const SentObservationsScreen({super.key, required this.observation});

  // Theme Colors from Design
  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);
  final Color lightGreenBG = const Color(0xFFEAF7EA);
  final Color statusBlue = const Color(0xFF5D7A7A); // Soft blue for Validated/Sent

  List<String> _getImages(Map<String, dynamic> obs) {
    final urls = obs['image_urls'] ?? obs['image_url'];
    if (urls is List) {
      return List<String>.from(urls);
    } else if (urls is String) {
      return [urls];
    }
    return [];
  }

  void _showImagePreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection(BuildContext context, List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Photos", style: TextStyle(fontSize: 12, color: Colors.black38)),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              final url = images[index];
              return GestureDetector(
                onTap: () => _showImagePreview(context, url),
                child: Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.black26),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    // Safety check for date keys (observation_date or obs_date)
    final rawDate = observation['observation_date'] ?? observation['obs_date'] ?? DateTime.now().toString();
    final date = DateFormat('MMMM dd, yyyy').format(DateTime.parse(rawDate));
    
    final String status = observation['status']?.toString().toUpperCase() ?? "PENDING";
    final List<String> images = _getImages(observation);

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

            // Rejection Reason Card (If Rejected)
            if (status == 'REJECTED') ...[
              _buildRejectionReasonCard(observation, isDark),
            ],

            // Metadata Card
            _buildWhiteCard([
              _buildDataRow("User ID:", "FO-12345"),
              _buildDataRow("Created:", observation['created_at']?.toString().substring(0, 16) ?? "N/A"),
              _buildDataRow("Modified:", date),
            ]),

            // Team Members Card (If jsonb data exists)
            if (observation['team_members'] != null)
              _buildWhiteCard([
                const Text("Team Members", style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ... (observation['team_members'] as List).map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${m['firstname']} ${m['lastname']}", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      Text(m['role'] ?? "Member", style: const TextStyle(color: Colors.black38, fontSize: 11)),
                    ],
                  ),
                )),
              ]),

            // Location Details Card
            _buildWhiteCard([
              const Text("Location Details", style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildInfoItem("Region", observation['region'] ?? "N/A")),
                Expanded(child: _buildInfoItem("Province", observation['province'] ?? "N/A")),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildInfoItem("Protected Area", observation['protected_area'] ?? "N/A")),
                Expanded(child: _buildInfoItem("Observation Date", date)),
              ]),
            ]),

            // Environment Card
            _buildWhiteCard([
              const Text("Environment", style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildInfoItem("Weather Conditions", observation['weather_condition'] ?? "N/A")),
                Expanded(child: _buildInfoItem("Temperature", "${observation['temperature'] ?? '--'}°C")),
              ]),
            ]),

            // Observation Details Card
            _buildWhiteCard([
              const Text("Observation Details", style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildInfoItem("Species Name", observation['common_name'] ?? "Unnamed")),
                Expanded(child: _buildInfoItem("Taxon Group", observation['taxon_group'] ?? "N/A")),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildInfoItem("Category", observation['observation_category'] ?? "N/A")),
                Expanded(child: _buildInfoItem("Habitat", observation['habitat_type'] ?? "N/A")),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildInfoItem("Count/Quantity", observation['count']?.toString() ?? "0")),
                Expanded(child: _buildInfoItem("Discovery Method", observation['discovery_method'] ?? "N/A")),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildInfoItem("Observation Time", observation['observation_time'] ?? "N/A")),
                Expanded(child: const SizedBox.shrink()),
              ]),
              if (observation['notes'] != null && observation['notes'].toString().trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoItem("Observation Notes", observation['notes']),
              ],
              if (images.isNotEmpty) ...[
                const Divider(height: 32),
                _buildImagesSection(context, images),
              ],
            ]),
            if (status == 'REJECTED') ...[
              _buildResubmitButton(context, isDark),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectionReasonCard(Map<String, dynamic> observation, bool isDark) {
    final String? reason = (observation['rejection_reason'] ??
            observation['rejection_remarks'] ??
            observation['admin_feedback'] ??
            observation['auto_validation_reason'] ??
            observation['remarks'] ??
            observation['reason'])
        ?.toString()
        .trim();

    final String displayReason = (reason != null && reason.isNotEmpty)
        ? reason
        : "No specific reason was provided for this rejection. Please review your observation data or contact your supervisor.";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                "Reason for Rejection",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            displayReason,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResubmitButton(BuildContext context, bool isDark) {
    final int resubmitCount = observation['resubmit_count'] is int 
        ? observation['resubmit_count'] as int 
        : int.tryParse(observation['resubmit_count']?.toString() ?? '') ?? 0;

    if (resubmitCount >= 1) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Column(
          children: const [
            Text(
              "Resubmission Limit Reached",
              style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              "This entry has already been resubmitted the maximum allowed number of times (1). We limit corrections to prevent flooding the validation queue. Please submit a new observation instead.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontSize: 11, height: 1.4),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      child: ElevatedButton.icon(
        onPressed: () {
          final model = context.read<ObservationModel>();
          model.populateForResubmit(observation);
          
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CollectStep1Screen()),
          );
        },
        icon: const Icon(Icons.replay_rounded, color: Colors.white),
        label: Text("Resubmit Entry (${1 - resubmitCount} remaining)"),
        style: ElevatedButton.styleFrom(
          backgroundColor: forestGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
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
    final statusUpper = status.toUpperCase();
    if (statusUpper == 'VALIDATED') return Colors.blue;
    if (statusUpper == 'REJECTED') return Colors.red;
    if (statusUpper == 'FLAGGED') return Colors.orange;
    return forestGreen; // Default for PENDING
  }
}