import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditPlantDialog extends StatefulWidget {
  final Map<String, dynamic> plant; // Changed to dynamic to match database
  const EditPlantDialog({super.key, required this.plant});

  @override
  State<EditPlantDialog> createState() => _EditPlantDialogState();
}

class _EditPlantDialogState extends State<EditPlantDialog> {
  final _supabase = Supabase.instance.client;
  
  // Controllers initialized with current database values
  late TextEditingController _nameController;
  late TextEditingController _scientificController;
  late TextEditingController _descriptionController;
  late TextEditingController _habitatController;
  
  String? _selectedCategory;
  String? _selectedStatus;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plant['common_name']);
    _scientificController = TextEditingController(text: widget.plant['scientific_name']);
    _descriptionController = TextEditingController(text: widget.plant['description']);
    _habitatController = TextEditingController(text: widget.plant['location_zone']);
    _selectedCategory = widget.plant['category'];
    _selectedStatus = widget.plant['conservation_status'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scientificController.dispose();
    _descriptionController.dispose();
    _habitatController.dispose();
    super.dispose();
  }

  // --- CONNECTED DATABASE UPDATE LOGIC ---
  Future<void> _updatePlant() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      // Perform the Update query using the record ID
      await _supabase.from('plants').update({
        'common_name': _nameController.text.trim(),
        'scientific_name': _scientificController.text.trim(),
        'category': _selectedCategory,
        'conservation_status': _selectedStatus,
        'location_zone': _habitatController.text.trim(),
        'description': _descriptionController.text.trim(),
      }).eq('id', widget.plant['id']); // MUST target the correct ID

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plant Updated Successfully"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent));
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
              
              Row(children: [
                Expanded(child: _buildTextField("COMMON NAME *", _nameController)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField("SCIENTIFIC NAME *", _scientificController)),
              ]),
              const SizedBox(height: 16),
              
              Row(children: [
                Expanded(child: _buildDropdown("CATEGORY *", ["Flowering Plants", "Ferns", "Trees"], _selectedCategory, (v) => setState(() => _selectedCategory = v))),
                const SizedBox(width: 16),
                Expanded(child: _buildDropdown("STATUS *", ["Common", "Uncommon", "Rare", "Endangered"], _selectedStatus, (v) => setState(() => _selectedStatus = v))),
              ]),
              const SizedBox(height: 16),
              
              _buildTextField("DESCRIPTION *", _descriptionController, maxLines: 4),
              const SizedBox(height: 16),
              
              _buildTextField("HABITAT/ZONE *", _habitatController),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _updatePlant,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4D6D4D), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("UPDATE DATABASE", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget _buildHeader(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("EDIT PLANT DATA", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text("Update plant information and AR metadata", style: TextStyle(fontSize: 13, color: Colors.black38))]), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]);

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)), const SizedBox(height: 8), TextFormField(controller: controller, maxLines: maxLines, decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16)))]);

  Widget _buildDropdown(String label, List<String> items, String? current, Function(String?) onChanged) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)), const SizedBox(height: 8), DropdownButtonFormField<String>(value: current, decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)), items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged)]);
}