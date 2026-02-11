import 'package:flutter/material.dart';
import 'add_new_species.dart'; // Ensure these separate files are in the same directory
import 'edit_plant.dart';

class PlantDatabaseView extends StatefulWidget {
  const PlantDatabaseView({super.key});

  @override
  State<PlantDatabaseView> createState() => _PlantDatabaseViewState();
}

class _PlantDatabaseViewState extends State<PlantDatabaseView> {
  int _selectedPlantIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // Mock data reflecting the specific entries from your reference
  final List<Map<String, String>> _plants = [
    {
      "id": "PLT-001",
      "name": "Philippine Orchid",
      "scientific": "Phalaenopsis amabilis",
      "status": "Rare",
      "stage": "Flowering",
      "desc": "Endemic orchid species with delicate white petals, plays crucial role in forest ecosystem.",
      "habitat": "Tropical rainforest, Zone A",
      "conservation": "Protected species under DENR regulations",
      "ar_path": "/models/orchid.glb",
      "audio_path": "/audio/orchid-guide.mp3"
    },
    {
      "id": "PLT-002",
      "name": "Mountain Fern",
      "scientific": "Nephrolepis cordifolia",
      "status": "Common",
      "stage": "Growth",
      "desc": "Resilient fern found in higher altitudes with distinctive cordate leaves.",
      "habitat": "Montane forest, Zone C",
      "conservation": "General conservation status",
      "ar_path": "/models/fern.glb",
      "audio_path": "/audio/fern-guide.mp3"
    },
    {
      "id": "PLT-003",
      "name": "Jade Vine",
      "scientific": "Strongylodon macrobotrys",
      "status": "Endangered",
      "stage": "Dormant",
      "desc": "Vibrant turquoise woody climber endemic to Philippine tropical forests.",
      "habitat": "Damp tropical forest, Zone B",
      "conservation": "Strict priority protection required",
      "ar_path": "/models/jade_vine.glb",
      "audio_path": "/audio/jade-guide.mp3"
    },
  ];

  @override
  Widget build(BuildContext context) {
    final selectedPlant = _plants[_selectedPlantIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 🧾 PAGE HEADER ---
        _buildHeader(),
        const SizedBox(height: 24),

        // --- 📊 SUMMARY METRICS ---
        _buildMetricRow(),
        const SizedBox(height: 32),

        // --- 📂 MAIN CONTENT AREA (Two-Column Layout) ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT PANEL: Species Database List
            Expanded(flex: 4, child: _buildSpeciesList()),
            const SizedBox(width: 32),
            // RIGHT PANEL: Species Record Details
            Expanded(flex: 6, child: _buildSpeciesDetails(selectedPlant)),
          ],
        ),
      ],
    );
  }

  // --- 🔝 HEADER WITH ADD BUTTON ---
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
          onPressed: () => showDialog(
            context: context,
            builder: (context) => const AddSpeciesDialog(), // Opens your separate pop-out
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text("ADD SPECIES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4D6D4D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        )
      ],
    );
  }

  // --- 📊 KPI METRICS ROW ---
  Widget _buildMetricRow() {
    return Row(
      children: [
        _metricCard("3", "Total Species", "In database", Colors.black87),
        _metricCard("3", "AR Models", "3D assets available", Colors.black87),
        _metricCard("2", "Audio Guides", "Narration recorded", Colors.black87),
        _metricCard("1", "Endangered", "PRIORITY CONSERVATION", Colors.red),
      ],
    );
  }

  Widget _metricCard(String val, String title, String sub, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.black12))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(val, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: col)),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
              ],
            ),
            Text(sub, style: TextStyle(fontSize: 9, color: col.withOpacity(0.6), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  // --- 📋 LEFT PANEL: SPECIES LIST ---
  Widget _buildSpeciesList() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.black12)),
      child: Column(
        children: [
          _panelHeader("Species Database", "${_plants.length} records"),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by name...",
                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.black26),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            itemCount: _plants.length,
            itemBuilder: (context, index) {
              final plant = _plants[index];
              bool isSelected = _selectedPlantIndex == index;
              return InkWell(
                onTap: () => setState(() => _selectedPlantIndex = index),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF0F4F8) : Colors.transparent,
                    border: const Border(bottom: BorderSide(color: Colors.black12)),
                  ),
                  child: Row(
                    children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plant['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(plant['scientific']!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black45)),
                            const SizedBox(height: 4),
                            Text("${plant['id']}  •  ${plant['status']}", style: TextStyle(fontSize: 10, color: _getStatusColor(plant['status']!), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const Column(
                        children: [
                          Icon(Icons.visibility_outlined, size: 14, color: Colors.black12),
                          SizedBox(height: 4),
                          Icon(Icons.volume_up_outlined, size: 14, color: Colors.black12),
                        ],
                      )
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

  // --- 📄 RIGHT PANEL: SPECIES DETAILS ---
  Widget _buildSpeciesDetails(Map<String, String> plant) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.black12)),
      child: Column(
        children: [
          _panelHeader("Species Record", ""),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 140, height: 140, decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(plant['name']!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
                              _badge(plant['status']!, _getStatusColor(plant['status']!)),
                            ],
                          ),
                          Text(plant['scientific']!, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Color(0xFF4D6D4D))),
                          const SizedBox(height: 12),
                          Text("${plant['id']}  •  ${plant['stage']}", style: const TextStyle(fontSize: 13, color: Colors.black38)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _detailBlock("Description", plant['desc']!),
                _detailBlock("Habitat", plant['habitat']!),
                _detailBlock("Conservation Status", plant['conservation']!),
                
                const SizedBox(height: 32),
                const Text("Digital Assets", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 12),
                _assetRow(Icons.view_in_ar_outlined, "AR 3D Model", plant['ar_path']!),
                _assetRow(Icons.volume_up_outlined, "Audio Guide", plant['audio_path']!),
                
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => EditPlantDialog(plant: plant), // Triggers your edit pop-out
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text("EDIT RECORD", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4D6D4D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS & HELPERS ---
  Widget _detailBlock(String label, String content) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 2),
    decoration: BoxDecoration(border: Border.all(color: Colors.black.withOpacity(0.05)), borderRadius: BorderRadius.circular(2)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black26)),
        const SizedBox(height: 6),
        Text(content, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
      ],
    ),
  );

  Widget _assetRow(IconData icon, String label, String path) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(border: Border.all(color: Colors.black.withOpacity(0.05)), borderRadius: BorderRadius.circular(4)),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.black45),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(path, style: const TextStyle(fontSize: 11, color: Colors.black)),
            ],
          ),
        ),
        _badge("AVAILABLE", Colors.green),
      ],
    ),
  );

  Widget _panelHeader(String title, String count) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    decoration: const BoxDecoration(color: Color(0xFFF9FAFB), border: Border(bottom: BorderSide(color: Colors.black12))),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
        Text(count, style: const TextStyle(fontSize: 11, color: Colors.black26)),
      ],
    ),
  );

  Color _getStatusColor(String status) {
    if (status == "Endangered") return Colors.red;
    if (status == "Rare") return Colors.purple;
    return Colors.green;
  }

  Widget _badge(String text, Color col) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold)),
  );
}