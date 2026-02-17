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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _supabase.from('plants').stream(primaryKey: ['id']).order('common_name'),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
            final plants = snapshot.data ?? [];

            return Column(
              children: [
                _buildMetricRow(plants),
                const SizedBox(height: 32),
                if (snapshot.connectionState == ConnectionState.waiting && plants.isEmpty)
                  const Center(child: CircularProgressIndicator(color: Color(0xFF4D6D4D)))
                else if (plants.isEmpty)
                  _buildEmptyState()
                else
                  _buildMainContent(plants),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMainContent(List<Map<String, dynamic>> plants) {
    if (_selectedPlantIndex >= plants.length) _selectedPlantIndex = 0;
    final selectedPlant = plants[_selectedPlantIndex];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: _buildSpeciesList(plants)),
        const SizedBox(width: 32),
        Expanded(flex: 6, child: _buildSpeciesDetails(selectedPlant)),
      ],
    );
  }

  Widget _buildSpeciesList(List<Map<String, dynamic>> plants) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.black12)),
      child: Column(children: [
        _panelHeader("Species Database", "${plants.length} records"),
        ListView.builder(
          shrinkWrap: true,
          itemCount: plants.length,
          itemBuilder: (context, index) {
            final plant = plants[index];
            return InkWell(
              onTap: () => setState(() => _selectedPlantIndex = index),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedPlantIndex == index ? const Color(0xFFF0F4F8) : Colors.transparent, 
                  border: const Border(bottom: BorderSide(color: Colors.black12))
                ),
                child: Row(children: [
                  CircleAvatar(
                    backgroundImage: (plant['image_url'] != null) ? NetworkImage(plant['image_url']) : null, 
                    radius: 20,
                    child: (plant['image_url'] == null) ? const Icon(Icons.park) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(plant['common_name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold))),
                  _badge(plant['conservation_status'] ?? "Common", _getStatusColor(plant['conservation_status'])),
                ]),
              ),
            );
          },
        ),
      ]),
    );
  }

  // FIXED: Now displays all scientific, physical, and ecological inputs
  Widget _buildSpeciesDetails(Map<String, dynamic> plant) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.black12)),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(plant['common_name'] ?? "No Name", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
            IconButton(onPressed: () => showDialog(context: context, builder: (_) => EditPlantDialog(plant: plant)), icon: const Icon(Icons.edit_outlined)),
          ]),
          Text(plant['scientific_name'] ?? "N/A", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black45)),
          const Divider(height: 32),
          
          // 1. Scientific Classification
          _sectionHeader("SCIENTIFIC CLASSIFICATION"),
          _detailRow("Kingdom", plant['kingdom'] ?? "Plantae"),
          _detailRow("Family", plant['family'] ?? "N/A"),
          _detailRow("Genus", plant['genus'] ?? "N/A"),
          _detailRow("Species", plant['species'] ?? "N/A"),
          
          const SizedBox(height: 24),
          
          // 2. Physical Characteristics
          _sectionHeader("PHYSICAL CHARACTERISTICS"),
          Wrap(spacing: 20, runSpacing: 10, children: [
             _miniCard("Height", plant['height'] ?? "N/A"),
             _miniCard("Leaf Type", plant['leaf_type'] ?? "N/A"),
             _miniCard("Flowering", plant['flowering'] ?? "N/A"),
             _miniCard("Growth", plant['growth'] ?? "N/A"),
          ]),

          const SizedBox(height: 24),

          // 3. Habitat & Ecology
          _sectionHeader("HABITAT & ECOLOGY"),
          _detailRow("Ecosystem", plant['ecosystem_type'] ?? "N/A"),
          _detailRow("Location/Zone", plant['location_zone'] ?? "N/A"),
          const SizedBox(height: 12),
          const Text("Ecological Importance:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black38)),
          Text(plant['ecological_importance'] ?? "No data provided.", style: const TextStyle(color: Colors.black54, height: 1.4)),

          const SizedBox(height: 24),
          _sectionHeader("BOTANICAL DESCRIPTION"),
          Text(plant['description'] ?? "No description available.", style: const TextStyle(color: Colors.black54, height: 1.5)),
        ]),
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _sectionHeader(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8), 
    child: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.1))
  );

  Widget _miniCard(String l, String v) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(6)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l, style: const TextStyle(fontSize: 9, color: Colors.black38)),
      Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _buildHeader() => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("PLANT DATABASE MANAGEMENT", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text("Scientific profiles • Physical Metadata • Habitat", style: TextStyle(fontSize: 13, color: Colors.black38))]), ElevatedButton.icon(onPressed: () => showDialog(context: context, builder: (context) => const AddSpeciesDialog()), icon: const Icon(Icons.add), label: const Text("ADD SPECIES"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4D6D4D), foregroundColor: Colors.white))]);
  Widget _buildMetricRow(List plants) => Row(children: [_metricCard(plants.length.toString(), "Total Species", Colors.black87), _metricCard(plants.where((p)=>p['conservation_status']=='Endangered').length.toString(), "Endangered", Colors.red)]);
  Widget _metricCard(String v, String t, Color c) => Expanded(child: Column(children: [Text(v, style: TextStyle(fontSize: 28, color: c, fontWeight: FontWeight.bold)), Text(t)]));
  Widget _badge(String t, Color c) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(t, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)));
  Color _getStatusColor(String? s) => s == "Endangered" ? Colors.red : Colors.green;
  Widget _panelHeader(String t, String c) => Container(padding: const EdgeInsets.all(12), color: const Color(0xFFF9FAFB), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.bold)), Text(c)]));
  Widget _detailRow(String l, String v) => Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [Text("$l: ", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)), Text(v, style: const TextStyle(fontSize: 13))]));
  Widget _buildEmptyState() => const Center(child: Text("Database empty."));
}