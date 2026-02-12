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
          // Real-time stream from Supabase 'plants' table
          stream: _supabase.from('plants').stream(primaryKey: ['id']).order('common_name'),
          builder: (context, snapshot) {
            final plants = snapshot.data ?? [];

            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

            return Column(
              children: [
                _buildMetricRow(plants),
                const SizedBox(height: 32),
                if (snapshot.connectionState == ConnectionState.waiting && plants.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: CircularProgressIndicator(color: Color(0xFF4D6D4D)),
                  )
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
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(4), 
        border: Border.all(color: Colors.black12)
      ),
      child: Column(
        children: [
          _panelHeader("Species Database", "${plants.length} records"),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final plant = plants[index];
              bool isSelected = _selectedPlantIndex == index;
              return InkWell(
                onTap: () => setState(() => _selectedPlantIndex = index),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF0F4F8) : Colors.transparent, 
                    border: const Border(bottom: BorderSide(color: Colors.black12))
                  ),
                  child: Row(
                    children: [
                      // Square Thumbnail List View
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: 44, height: 44,
                          color: Colors.black.withOpacity(0.05),
                          child: (plant['image_url'] != null && plant['image_url'].toString().isNotEmpty)
                            ? Image.network(
                                plant['image_url'], 
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                              )
                            : const Icon(Icons.park_outlined, size: 20, color: Colors.grey),
                        ),
                      ),
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

  // --- FIXED: SMALLER SQUARE PREVIEW ON RIGHT SIDE ---
  Widget _buildSpeciesDetails(Map<String, dynamic> plant) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(4), 
        border: Border.all(color: Colors.black12)
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SMALL SQUARE PREVIEW
              if (plant['image_url'] != null && plant['image_url'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 24.0),
                  child: SizedBox(
                    width: 150, // Smaller width for the square
                    child: AspectRatio(
                      aspectRatio: 1 / 1, // Maintains square
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          plant['image_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey[100], child: const Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                  ),
                ),
              
              // TEXT DETAILS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plant['common_name'] ?? "No Name", 
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
                    const SizedBox(height: 4),
                    Text(plant['scientific_name'] ?? "Scientific Name Not Provided", 
                      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black38)),
                    const SizedBox(height: 16),
                    _badge(plant['conservation_status'] ?? "Common", _getStatusColor(plant['conservation_status'])),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Divider(),
          _detailBlock("Category", plant['category'] ?? "N/A"),
          _detailBlock("Habitat/Zone", plant['location_zone'] ?? "N/A"),
          _detailBlock("Description", plant['description'] ?? "No description available."), // Added after SQL update
          
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.view_in_ar, size: 18, color: Colors.black38),
              const SizedBox(width: 8),
              Expanded(
                child: Text(plant['ar_model_url'] ?? "No 3D Model Attached", 
                  style: const TextStyle(fontSize: 12, color: Colors.black38))
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("PLANT DATABASE MANAGEMENT", 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
            Text("Species profiles • AR content • Educational metadata", 
              style: TextStyle(fontSize: 13, color: Colors.black38)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => showDialog(context: context, builder: (context) => const AddSpeciesDialog()),
          icon: const Icon(Icons.add, size: 18),
          label: const Text("ADD SPECIES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4D6D4D), 
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        )
      ],
    );
  }

  Widget _buildMetricRow(List<Map<String, dynamic>> plants) {
    final endangered = plants.where((p) => p['conservation_status'] == 'Endangered').length;
    final arModels = plants.where((p) => p['ar_model_url'] != null && p['ar_model_url'].toString().isNotEmpty).length;
    return Row(
      children: [
        _metricCard(plants.length.toString(), "Total Species", "In database", Colors.black87),
        _metricCard(arModels.toString(), "AR Models", "3D assets", Colors.black87),
        _metricCard(endangered.toString(), "Endangered", "PRIORITY", Colors.red),
      ],
    );
  }

  Color _getStatusColor(String? status) => status == "Endangered" ? Colors.red : status == "Rare" ? Colors.purple : Colors.green;
  Widget _metricCard(String v, String t, String s, Color c) => Expanded(child: Column(children: [Text(v, style: TextStyle(fontSize: 28, color: c, fontWeight: FontWeight.bold)), Text(t), Text(s, style: TextStyle(fontSize: 10, color: c.withOpacity(0.5)))]));
  Widget _badge(String t, Color c) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(t, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)));
  Widget _panelHeader(String t, String c) => Container(padding: const EdgeInsets.all(12), color: const Color(0xFFF9FAFB), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.bold)), Text(c, style: const TextStyle(color: Colors.black38))]));
  Widget _detailBlock(String l, String c) => Padding(padding: const EdgeInsets.only(top: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 10, color: Colors.black26, fontWeight: FontWeight.bold)), Text(c, style: const TextStyle(fontSize: 16))]));
  Widget _buildEmptyState() => const Padding(padding: EdgeInsets.symmetric(vertical: 80), child: Center(child: Text("Database empty. Add your first species.", style: TextStyle(color: Colors.black38))));
}