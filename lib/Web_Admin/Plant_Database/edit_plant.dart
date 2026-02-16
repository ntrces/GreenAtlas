import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditPlantDialog extends StatefulWidget {
  final Map<String, dynamic> plant;
  const EditPlantDialog({super.key, required this.plant});

  @override
  State<EditPlantDialog> createState() => _EditPlantDialogState();
}

class _EditPlantDialogState extends State<EditPlantDialog> {
  final _supabase = Supabase.instance.client;
  bool _isSaving = false;

  // Sync Controllers with Database Columns
  late TextEditingController _nameCtrl, _sciNameCtrl, _descCtrl, _zoneCtrl;
  late TextEditingController _kingdomCtrl, _familyCtrl, _genusCtrl, _speciesCtrl;
  late TextEditingController _heightCtrl, _leafCtrl, _flowerCtrl, _growthCtrl;
  late TextEditingController _ecosystemCtrl, _importanceCtrl;

  String? _selectedCategory;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.plant['common_name']);
    _sciNameCtrl = TextEditingController(text: widget.plant['scientific_name']);
    _descCtrl = TextEditingController(text: widget.plant['description']);
    _zoneCtrl = TextEditingController(text: widget.plant['location_zone']);
    _kingdomCtrl = TextEditingController(text: widget.plant['kingdom'] ?? "Plantae");
    _familyCtrl = TextEditingController(text: widget.plant['family']);
    _genusCtrl = TextEditingController(text: widget.plant['genus']);
    _speciesCtrl = TextEditingController(text: widget.plant['species']);
    _heightCtrl = TextEditingController(text: widget.plant['height']);
    _leafCtrl = TextEditingController(text: widget.plant['leaf_type']);
    _flowerCtrl = TextEditingController(text: widget.plant['flowering']);
    _growthCtrl = TextEditingController(text: widget.plant['growth']);
    _ecosystemCtrl = TextEditingController(text: widget.plant['ecosystem_type']);
    _importanceCtrl = TextEditingController(text: widget.plant['ecological_importance']);
    _selectedCategory = widget.plant['category'];
    _selectedStatus = widget.plant['conservation_status'];
  }

  @override
  void dispose() {
    for (var c in [_nameCtrl, _sciNameCtrl, _descCtrl, _zoneCtrl, _kingdomCtrl, _familyCtrl, _genusCtrl, _speciesCtrl, _heightCtrl, _leafCtrl, _flowerCtrl, _growthCtrl, _ecosystemCtrl, _importanceCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _updatePlant() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      // Update matching the full botanical schema
      await _supabase.from('plants').update({
        'common_name': _nameCtrl.text.trim(),
        'scientific_name': _sciNameCtrl.text.trim(),
        'category': _selectedCategory,
        'description': _descCtrl.text.trim(),
        'location_zone': _zoneCtrl.text.trim(),
        'conservation_status': _selectedStatus,
        'kingdom': _kingdomCtrl.text.trim(),
        'family': _familyCtrl.text.trim(),
        'genus': _genusCtrl.text.trim(),
        'species': _speciesCtrl.text.trim(),
        'height': _heightCtrl.text.trim(),
        'leaf_type': _leafCtrl.text.trim(),
        'flowering': _flowerCtrl.text.trim(),
        'growth': _growthCtrl.text.trim(),
        'ecosystem_type': _ecosystemCtrl.text.trim(),
        'ecological_importance': _importanceCtrl.text.trim(),
      }).eq('id', widget.plant['id']);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Database Updated!"), backgroundColor: Colors.green));
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
      child: Container(
        width: 750, padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Row(children: [Expanded(child: _buildField("Common Name", _nameCtrl)), const SizedBox(width: 12), Expanded(child: _buildField("Scientific Name", _sciNameCtrl))]),
            Row(children: [
              Expanded(child: _buildDropdown("Plant Type", ["Flowering Plants", "Ferns", "Trees"], _selectedCategory, (v) => setState(() => _selectedCategory = v))),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdown("Status", ["Common", "Rare", "Endangered"], _selectedStatus, (v) => setState(() => _selectedStatus = v))),
            ]),
            _buildField("Description", _descCtrl, lines: 3),
            const Divider(height: 40),
            const Text("CLASSIFICATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            Row(children: [Expanded(child: _buildField("Kingdom", _kingdomCtrl)), const SizedBox(width: 12), Expanded(child: _buildField("Family", _familyCtrl))]),
            Row(children: [Expanded(child: _buildField("Genus", _genusCtrl)), const SizedBox(width: 12), Expanded(child: _buildField("Species", _speciesCtrl))]),
            const Divider(height: 40),
            const Text("PHYSICAL & ECOLOGICAL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            Row(children: [Expanded(child: _buildField("Height", _heightCtrl)), const SizedBox(width: 12), Expanded(child: _buildField("Leaf Type", _leafCtrl))]),
            Row(children: [Expanded(child: _buildField("Flowering", _flowerCtrl)), const SizedBox(width: 12), Expanded(child: _buildField("Growth", _growthCtrl))]),
            Row(children: [Expanded(child: _buildField("Ecosystem", _ecosystemCtrl)), const SizedBox(width: 12), Expanded(child: _buildField("Location Zone", _zoneCtrl))]),
            _buildField("Ecological Importance", _importanceCtrl, lines: 2),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isSaving ? null : _updatePlant, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4D6D4D), foregroundColor: Colors.white), child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("UPDATE DATABASE", style: TextStyle(fontWeight: FontWeight.bold)))),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("EDIT PLANT PROFILE", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]);
  Widget _buildField(String l, TextEditingController c, {int lines = 1}) => Padding(padding: const EdgeInsets.only(top: 12), child: TextField(controller: c, maxLines: lines, decoration: InputDecoration(labelText: l, border: const OutlineInputBorder())));
  Widget _buildDropdown(String l, List<String> i, String? val, Function(String?) onChanged) => Padding(padding: const EdgeInsets.only(top: 12), child: DropdownButtonFormField<String>(value: val, items: i.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged, decoration: InputDecoration(labelText: l, border: const OutlineInputBorder())));
}