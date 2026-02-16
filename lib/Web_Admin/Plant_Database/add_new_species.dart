import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class AddSpeciesDialog extends StatefulWidget {
  const AddSpeciesDialog({super.key});
  @override
  State<AddSpeciesDialog> createState() => _AddSpeciesDialogState();
}

class _AddSpeciesDialogState extends State<AddSpeciesDialog> {
  final _supabase = Supabase.instance.client;
  bool _isSaving = false;
  XFile? _pickedImage;
  PlatformFile? _pickedARModel;
  bool _arEnabled = false;

  // Controllers for General Info
  final _nameCtrl = TextEditingController();
  final _sciNameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _zoneCtrl = TextEditingController();

  // Controllers for Scientific Classification
  final _kingdomCtrl = TextEditingController(text: "Plantae");
  final _familyCtrl = TextEditingController();
  final _genusCtrl = TextEditingController();
  final _speciesCtrl = TextEditingController();

  // Controllers for Physical Characteristics
  final _heightCtrl = TextEditingController();
  final _leafCtrl = TextEditingController();
  final _flowerCtrl = TextEditingController();
  final _growthCtrl = TextEditingController();

  // Controllers for Habitat & Ecology
  final _ecosystemCtrl = TextEditingController();
  final _importanceCtrl = TextEditingController();

  String? _selectedCategory;
  String? _selectedStatus;

  @override
  void dispose() {
    // Clean up all controllers
    _nameCtrl.dispose(); _sciNameCtrl.dispose(); _descCtrl.dispose();
    _zoneCtrl.dispose(); _kingdomCtrl.dispose(); _familyCtrl.dispose();
    _genusCtrl.dispose(); _speciesCtrl.dispose(); _heightCtrl.dispose();
    _leafCtrl.dispose(); _flowerCtrl.dispose(); _growthCtrl.dispose();
    _ecosystemCtrl.dispose(); _importanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<void> _pickARModel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, 
      allowedExtensions: ['obj', 'usdz', 'glb', 'gltf'], 
      withData: true
    );
    if (result != null) setState(() => _pickedARModel = result.files.first);
  }

  Future<void> _saveSpecies() async {
    if (_nameCtrl.text.isEmpty || _pickedImage == null) return;
    setState(() => _isSaving = true);
    try {
      // 1. Upload Image
      final imageBytes = await _pickedImage!.readAsBytes();
      final imagePath = 'plants/${DateTime.now().millisecondsSinceEpoch}.png';
      await _supabase.storage.from('species-images').uploadBinary(imagePath, imageBytes);
      final imageUrl = _supabase.storage.from('species-images').getPublicUrl(imagePath);

      // 2. Upload AR Model if enabled
      String? arUrl;
      if (_arEnabled && _pickedARModel != null) {
        final modelPath = 'models/${DateTime.now().millisecondsSinceEpoch}_${_pickedARModel!.name}';
        await _supabase.storage.from('species-images').uploadBinary(modelPath, _pickedARModel!.bytes!);
        arUrl = _supabase.storage.from('species-images').getPublicUrl(modelPath);
      }

      // 3. Database Insert
      await _supabase.from('plants').insert({
        'common_name': _nameCtrl.text.trim(),
        'scientific_name': _sciNameCtrl.text.trim(),
        'category': _selectedCategory,
        'conservation_status': _selectedStatus,
        'description': _descCtrl.text.trim(),
        'location_zone': _zoneCtrl.text.trim(),
        'image_url': imageUrl,
        'ar_model_url': arUrl,
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
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Species Saved!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("ADD NEW SPECIES", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 120, width: 120, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                    child: _pickedImage == null ? const Icon(Icons.camera_alt) : Image.network(_pickedImage!.path, fit: BoxFit.cover),
                  ),
                ),
              ),
              _buildField("Common Name", _nameCtrl),
              _buildField("Scientific Name", _sciNameCtrl),
              Row(children: [
                Expanded(child: _buildDropdown("Category", ["Flowering Plants", "Ferns", "Trees"], (v) => _selectedCategory = v)),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown("Status", ["Common", "Rare", "Endangered"], (v) => _selectedStatus = v)),
              ]),
              _buildField("Description", _descCtrl, lines: 3),
              const Divider(height: 32),
              const Text("SCIENTIFIC CLASSIFICATION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black38)),
              Row(children: [Expanded(child: _buildField("Kingdom", _kingdomCtrl)), const SizedBox(width: 12), Expanded(child: _buildField("Family", _familyCtrl))]),
              Row(children: [Expanded(child: _buildField("Genus", _genusCtrl)), const SizedBox(width: 12), Expanded(child: _buildField("Species", _speciesCtrl))]),
              const Divider(height: 32),
              const Text("PHYSICAL & ECOLOGICAL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black38)),
              Row(children: [Expanded(child: _buildField("Height", _heightCtrl)), const SizedBox(width: 12), Expanded(child: _buildField("Leaf Type", _leafCtrl))]),
              Row(children: [Expanded(child: _buildField("Flowering", _flowerCtrl)), const SizedBox(width: 12), Expanded(child: _buildField("Growth", _growthCtrl))]),
              _buildField("Ecosystem", _ecosystemCtrl),
              _buildField("Habitat Zone", _zoneCtrl),
              _buildField("Ecological Importance", _importanceCtrl, lines: 2),
              const SizedBox(height: 24),
              SwitchListTile(title: const Text("AR Feature"), value: _arEnabled, onChanged: (v) => setState(() => _arEnabled = v)),
              if (_arEnabled) OutlinedButton.icon(onPressed: _pickARModel, icon: const Icon(Icons.view_in_ar), label: Text(_pickedARModel == null ? "Attach AR Model" : "Attached: ${_pickedARModel!.name}")),
              const SizedBox(height: 32),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isSaving ? null : _saveSpecies, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4D6D4D)), child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE TO DATABASE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String l, TextEditingController c, {int lines = 1}) => Padding(padding: const EdgeInsets.only(top: 12), child: TextField(controller: c, maxLines: lines, decoration: InputDecoration(labelText: l, border: const OutlineInputBorder())));
  Widget _buildDropdown(String l, List<String> i, Function(String?) o) => Padding(padding: const EdgeInsets.only(top: 12), child: DropdownButtonFormField<String>(items: i.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: o, decoration: InputDecoration(labelText: l, border: const OutlineInputBorder())));
}