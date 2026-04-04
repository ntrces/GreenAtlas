import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Collect/observation_model.dart';
import '../Collect/collect01.dart'; 

class DraftDetailScreen extends StatelessWidget {
  final Map<String, dynamic> draft;
  const DraftDetailScreen({super.key, required this.draft});

  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);
  final Color lightGreenBG = const Color(0xFFEAF7EA);
  final Color draftBadgeColor = const Color(0xFF8BA88B);

  // --- LOGIC: EDIT ---
  void _handleEdit(BuildContext context) {
    final model = context.read<ObservationModel>();
    
    model.observationDate = DateTime.parse(draft['observation_date'] ?? DateTime.now().toString());
    model.region = draft['region'] ?? '';
    model.province = draft['province'] ?? '';
    model.protectedArea = draft['protected_area'] ?? '';
    model.speciesName = draft['common_name'] ?? '';
    model.taxon = draft['taxon_group'] ?? '';
    model.habitat = draft['habitat_type'] ?? '';
    model.quantity = draft['count'] ?? 0;
    model.observationNotes = draft['notes'] ?? '';

    model.updateData();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectStep1Screen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreenBG,
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), 
          onPressed: () => Navigator.pop(context)
        ),
        title: Column(
          children: [
            const Text("Entry Details", style: TextStyle(color: Colors.white, fontSize: 16)),
            Text("BMS-${draft['id'].toString().substring(0,5).toUpperCase()}", 
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: draftBadgeColor, borderRadius: BorderRadius.circular(8)),
              child: const Text("Draft", style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
            const SizedBox(height: 16),

            // Metadata Card
            _buildCard([
              _buildDataRow("User ID:", "FO-12345"),
              _buildDataRow("Created:", draft['created_at'].toString().substring(0, 16)),
              _buildDataRow("Modified:", draft['observation_date'] ?? "N/A"),
            ]),

            // Location Card
            _buildCard([
              const Text("Location Details", style: TextStyle(fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildInfoItem("Region", draft['region'] ?? "N/A")),
                Expanded(child: _buildInfoItem("Province", draft['province'] ?? "N/A")),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildInfoItem("Protected Area", draft['protected_area'] ?? "N/A")),
                Expanded(child: _buildInfoItem("Date", draft['observation_date'] ?? "N/A")),
              ]),
            ]),

            // Observation Card
            _buildCard([
              const Text("Observation 1", style: TextStyle(fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 12),
              _buildInfoItem("Species Name", draft['common_name'] ?? "Unnamed"),
              const SizedBox(height: 12),
              _buildInfoItem("Habitat", draft['habitat_type'] ?? "N/A"),
            ]),

            const SizedBox(height: 24),

            // Buttons (Side by Side)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleEdit(context),
                    icon: Icon(Icons.edit_note, color: forestGreen),
                    label: Text("Edit", style: TextStyle(color: forestGreen)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: forestGreen.withOpacity(0.3)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context), // Link to your delete logic
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    label: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFFFE0E0)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white, 
      borderRadius: BorderRadius.circular(12), 
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _buildDataRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black38, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.black87, fontSize: 12)),
      ],
    ),
  );

  Widget _buildInfoItem(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.black38)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87)),
    ],
  );
}