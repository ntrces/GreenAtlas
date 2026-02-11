import 'package:flutter/material.dart';

class EditPlantDialog extends StatefulWidget {
  final Map<String, String> plant;
  const EditPlantDialog({super.key, required this.plant});

  @override
  State<EditPlantDialog> createState() => _EditPlantDialogState();
}

class _EditPlantDialogState extends State<EditPlantDialog> {
  late bool _arEnabled;
  late bool _audioEnabled;

  @override
  void initState() {
    super.initState();
    _arEnabled = widget.plant['ar_path'] != null;
    _audioEnabled = widget.plant['audio_path'] != null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: const Color(0xFFEDF7ED), //
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
                  Expanded(child: _buildTextField("COMMON NAME *", widget.plant['name']!)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("SCIENTIFIC NAME *", widget.plant['scientific']!)),
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
              
              _buildTextField("DESCRIPTION *", widget.plant['desc']!, maxLines: 4),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(child: _buildTextField("HABITAT *", widget.plant['habitat']!)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("CONSERVATION NOTES", widget.plant['conservation']!)),
                ],
              ),
              const SizedBox(height: 24),
              
              const Text("AR & MEDIA FEATURES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 12),
              _buildToggleRow(Icons.visibility_outlined, "AR 3D Model", "3D model for AR visualization", _arEnabled, (v) => setState(() => _arEnabled = v)),
              _buildToggleRow(Icons.volume_up_outlined, "Audio Guide", "Educational audio narration", _audioEnabled, (v) => setState(() => _audioEnabled = v)),
              
              const SizedBox(height: 32),
              _buildActionButton("UPDATE DATABASE", const Color(0xFF4D6D4D)),
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
            Text("EDIT PLANT DATA", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Update plant information and AR content", style: TextStyle(fontSize: 13, color: Colors.black38)),
          ],
        ),
        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildTextField(String label, String initialValue, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          maxLines: maxLines,
          decoration: InputDecoration(
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