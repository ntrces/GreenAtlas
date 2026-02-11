import 'package:flutter/material.dart';

class AddSpeciesDialog extends StatefulWidget {
  const AddSpeciesDialog({super.key});

  @override
  State<AddSpeciesDialog> createState() => _AddSpeciesDialogState();
}

class _AddSpeciesDialogState extends State<AddSpeciesDialog> {
  bool _arEnabled = false;
  bool _audioEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: const Color(0xFFEDF7ED), // Soft green background
      child: Container(
        width: 700,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(child: _buildTextField("COMMON NAME *", "e.g., Philippine Orchid")),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("SCIENTIFIC NAME *", "e.g., Phalaenopsis amabilis")),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(child: _buildDropdown("CATEGORY *", ["Fern", "Orchid", "Tree", "Vine"])),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdown("CONSERVATION STATUS *", ["Common", "Rare", "Endangered"])),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildTextField("DESCRIPTION *", "Detailed description of the plant...", maxLines: 4),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(child: _buildTextField("HABITAT *", "e.g., Tropical rainforest, Zone A")),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("CONSERVATION NOTES", "e.g., Protected species")),
                ],
              ),
              const SizedBox(height: 24),
              
              const Text("AR & MEDIA FEATURES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 12),
              _buildToggleRow(Icons.visibility_outlined, "AR 3D Model", "3D model for AR visualization", _arEnabled, (v) => setState(() => _arEnabled = v)),
              _buildToggleRow(Icons.volume_up_outlined, "Audio Guide", "Educational audio narration", _audioEnabled, (v) => setState(() => _audioEnabled = v)),
              
              const SizedBox(height: 32),
              _buildActionButton("ADD TO DATABASE", const Color(0xFF4D6D4D)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ADD NEW SPECIES", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Add a new species to the database", style: TextStyle(fontSize: 13, color: Colors.black38)),
          ],
        ),
        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildTextField(String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 8),
        DropdownButtonFormField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          hint: const Text("Select option", style: TextStyle(fontSize: 13, color: Colors.black26)),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) {},
        ),
      ],
    );
  }

  Widget _buildToggleRow(IconData icon, String title, String sub, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(sub, style: const TextStyle(fontSize: 11, color: Colors.black38)),
            ]),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF4D6D4D)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color col) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(backgroundColor: col, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}