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
  final _nameController = TextEditingController();
  final _scientificController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _habitatController = TextEditingController();

  String? _selectedCategory;
  String? _selectedStatus;
  bool _arEnabled = false;
  bool _isSaving = false;
  XFile? _pickedImage;
  PlatformFile? _pickedARModel;

  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<void> _pickARModel() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['glb', 'gltf'], withData: true);
    if (result != null) setState(() => _pickedARModel = result.files.first);
  }

  Future<String?> _uploadFile(String bucket, String fileName, Uint8List bytes) async {
    final path = 'uploads/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _supabase.storage.from(bucket).uploadBinary(path, bytes);
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  Future<void> _saveSpecies() async {
    if (_nameController.text.isEmpty || _selectedCategory == null || _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Missing required fields or image")));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final imageBytes = await _pickedImage!.readAsBytes();
      final imageUrl = await _uploadFile('species-images', _pickedImage!.name, imageBytes);

      String? arUrl;
      if (_arEnabled && _pickedARModel != null && _pickedARModel!.bytes != null) {
        arUrl = await _uploadFile('species-images', _pickedARModel!.name, _pickedARModel!.bytes!);
      }

      await _supabase.from('plants').insert({
        'common_name': _nameController.text.trim(),
        'scientific_name': _scientificController.text.trim(),
        'category': _selectedCategory,
        'location_zone': _habitatController.text.trim(),
        'conservation_status': _selectedStatus,
        'image_url': imageUrl,
        'ar_model_url': arUrl,
        'description': _descriptionController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New Species Added!")));
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600, padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("ADD NEW SPECIES", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
              const SizedBox(height: 20),
              _buildImageUploader(),
              const SizedBox(height: 20),
              Row(children: [Expanded(child: _buildField("COMMON NAME", _nameController)), const SizedBox(width: 12), Expanded(child: _buildField("SCIENTIFIC NAME", _scientificController))]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _buildDropdown("PLANT TYPE", ["Flowering Plants", "Ferns", "Trees"], (v) => setState(() => _selectedCategory = v))),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown("STATUS", ["Common", "Uncommon", "Rare", "Endangered"], (v) => setState(() => _selectedStatus = v))),
              ]),
              const SizedBox(height: 16),
              _buildField("DESCRIPTION", _descriptionController, lines: 3),
              const SizedBox(height: 32),
              SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: _isSaving ? null : _saveSpecies, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4D6D4D)), child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE TO DATABASE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploader() => Center(child: GestureDetector(onTap: _pickImage, child: Container(width: 150, height: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)), child: _pickedImage != null ? ClipRRect(borderRadius: BorderRadius.circular(12), child: kIsWeb ? Image.network(_pickedImage!.path, fit: BoxFit.cover) : Image.file(File(_pickedImage!.path), fit: BoxFit.cover)) : const Icon(Icons.camera_alt_outlined, color: Colors.grey))));
  Widget _buildField(String l, TextEditingController c, {int lines = 1}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(height: 6), TextField(controller: c, maxLines: lines, decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)))]);
  Widget _buildDropdown(String l, List<String> i, Function(String?) o) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(height: 6), DropdownButtonFormField<String>(items: i.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: o, decoration: const InputDecoration(filled: true, fillColor: Colors.white))]);
}