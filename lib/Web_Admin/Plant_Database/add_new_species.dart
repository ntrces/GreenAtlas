import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddSpeciesDialog extends StatefulWidget {
  const AddSpeciesDialog({super.key});

  @override
  State<AddSpeciesDialog> createState() => _AddSpeciesDialogState();
}

class _AddSpeciesDialogState extends State<AddSpeciesDialog> {
  final _supabase = Supabase.instance.client;
  
  // 📝 Controllers to capture data
  final _nameController = TextEditingController();
  final _scientificController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _habitatController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedStatus;
  bool _arEnabled = false;
  bool _audioEnabled = false;
  bool _isSaving = false;

  // 🚀 Logic to insert into Supabase plants table
  Future<void> _saveSpecies() async {
    if (_nameController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in the required fields (*)")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _supabase.from('plants').insert({
        'common_name': _nameController.text.trim(),
        'category': _selectedCategory,
        'location_zone': _habitatController.text.trim(),
        'conservation_status': _selectedStatus,
        // Paths for your assets folder
        'image_url': 'assets/logo1.png', 
        'ar_model_url': _arEnabled ? 'models/sample.glb' : null,
      });

      if (mounted) {
        Navigator.pop(context); // Close dialog on success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Species added successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: const Color(0xFFEDF7ED), 
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
                  Expanded(child: _buildTextField("COMMON NAME *", "e.g., Philippine Orchid", _nameController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("SCIENTIFIC NAME *", "e.g., Phalaenopsis amabilis", _scientificController)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDropdown("CATEGORY *", ["Fern", "Orchid", "Tree", "Vine"], (val) => setState(() => _selectedCategory = val))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdown("CONSERVATION STATUS *", ["Common", "Rare", "Endangered"], (val) => setState(() => _selectedStatus = val))),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField("DESCRIPTION *", "Detailed description...", _descriptionController, maxLines: 4),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField("HABITAT *", "e.g., Zone A", _habitatController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("CONSERVATION NOTES", "e.g., Protected", null)),
                ],
              ),
              const SizedBox(height: 24),
              const Text("AR & MEDIA FEATURES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 12),
              _buildToggleRow(Icons.visibility_outlined, "AR 3D Model", "3D model for AR", _arEnabled, (v) => setState(() => _arEnabled = v)),
              _buildToggleRow(Icons.volume_up_outlined, "Audio Guide", "Educational audio", _audioEnabled, (v) => setState(() => _audioEnabled = v)),
              const SizedBox(height: 32),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSpecies,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4D6D4D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("ADD TO DATABASE", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Updated Helper methods to accept controllers and callbacks
  Widget _buildHeader(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("ADD NEW SPECIES", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text("Add a new species to the database", style: TextStyle(fontSize: 13, color: Colors.black38)),
      ]),
      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
    ],
  );

  Widget _buildTextField(String label, String hint, TextEditingController? controller, {int maxLines = 1}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16)),
      ),
    ],
  );

  Widget _buildDropdown(String label, List<String> items, Function(String?) onChanged) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        onChanged: onChanged,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
      ),
    ],
  );

  Widget _buildToggleRow(IconData icon, String title, String sub, bool value, Function(bool) onChanged) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black.withOpacity(0.05))),
    child: Row(children: [
      Icon(icon, size: 20, color: Colors.black54),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text(sub, style: const TextStyle(fontSize: 11, color: Colors.black38))])),
      Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF4D6D4D)),
    ]),
  );
}