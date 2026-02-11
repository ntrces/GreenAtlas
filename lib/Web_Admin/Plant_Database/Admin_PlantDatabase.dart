import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_new_species.dart';
import 'edit_plant.dart';

class PlantDatabaseView extends StatefulWidget {
  const PlantDatabaseView({super.key});

  @override
  State<PlantDatabaseView> createState() => _PlantDatabaseViewState();
}

class _PlantDatabaseViewState extends State<PlantDatabaseView> {
  final _supabase = Supabase.instance.client;
  int _selectedPlantIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // Listens to 'plants' table for real-time updates
      stream: _supabase.from('plants').stream(primaryKey: ['id']).order('common_name'),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF4D6D4D)));

        final plants = snapshot.data!;
        if (plants.isEmpty) return _buildEmptyState();

        // Ensure index stays within bounds after a deletion or update
        if (_selectedPlantIndex >= plants.length) _selectedPlantIndex = 0;
        final selectedPlant = plants[_selectedPlantIndex];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildMetricRow(plants),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: _buildSpeciesList(plants)),
                const SizedBox(width: 32),
                Expanded(flex: 6, child: _buildSpeciesDetails(selectedPlant)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("PLANT DATABASE MANAGEMENT", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
            Text("Species profiles • AR content • Educational metadata", style: TextStyle(fontSize: 13, color: Colors.black38)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => showDialog(context: context, builder: (context) => const AddSpeciesDialog()),
          icon: const Icon(Icons.add, size: 18),
          label: const Text("ADD SPECIES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4D6D4D), foregroundColor: Colors.white),
        )
      ],
    );
  }

  Widget _buildMetricRow(List<Map<String, dynamic>> plants) {
    final endangered = plants.where((p) => p['conservation_status'] == 'Endangered').length;
    return Row(
      children: [
        _metricCard(plants.length.toString(), "Total Species", "In database", Colors.black87),
        _metricCard(plants.where((p) => p['ar_model_url'] != null).length.toString(), "AR Models", "3D assets", Colors.black87),
        _metricCard(endangered.toString(), "Endangered", "PRIORITY CONSERVATION", Colors.red),
      ],
    );
  }

  Widget _buildSpeciesList(List<Map<String, dynamic>> plants) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.black12)),
      child: Column(
        children: [
          _panelHeader("Species Database", "${plants.length} records"),
          ListView.builder(
            shrinkWrap: true,
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final plant = plants[index];
              bool isSelected = _selectedPlantIndex == index;
              return InkWell(
                onTap: () => setState(() => _selectedPlantIndex = index),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: isSelected ? const Color(0xFFF0F4F8) : Colors.transparent, border: const Border(bottom: BorderSide(color: Colors.black12))),
                  child: Row(
                    children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plant['common_name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(plant['category'] ?? "N/A", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black45)),
                          ],
                        ),
                      ),
                      _badge(plant['conservation_status'] ?? "Common", _getStatusColor(plant['conservation_status'])),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpeciesDetails(Map<String, dynamic> plant) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.black12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plant['common_name'] ?? "", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
            const SizedBox(height: 8),
            _detailBlock("Category", plant['category'] ?? "N/A"),
            _detailBlock("Habitat/Zone", plant['location_zone'] ?? "N/A"),
            _detailBlock("Conservation Status", plant['conservation_status'] ?? "N/A"),
            const SizedBox(height: 24),
            Row(children: [
              const Icon(Icons.view_in_ar, size: 18, color: Colors.black38),
              const SizedBox(width: 8),
              Text(plant['ar_model_url'] ?? "No 3D Model Attached", style: const TextStyle(fontSize: 12, color: Colors.black38)),
            ]),
          ],
        ),
      ),
    );
  }

  // Reuse your metricCard, badge, panelHeader, and detailBlock helpers here
  Color _getStatusColor(String? status) => status == "Endangered" ? Colors.red : status == "Rare" ? Colors.purple : Colors.green;
  Widget _metricCard(String v, String t, String s, Color c) => Expanded(child: Column(children: [Text(v, style: TextStyle(fontSize: 28, color: c, fontWeight: FontWeight.bold)), Text(t)]));
  Widget _badge(String t, Color c) => Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: c.withOpacity(0.1)), child: Text(t, style: TextStyle(color: c, fontSize: 10)));
  Widget _panelHeader(String t, String c) => Container(padding: const EdgeInsets.all(12), color: const Color(0xFFF9FAFB), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t), Text(c)]));
  Widget _detailBlock(String l, String c) => Padding(padding: const EdgeInsets.only(top: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 10, color: Colors.black26)), Text(c)]));
  Widget _buildEmptyState() => const Center(child: Text("Database empty. Add your first species."));
}