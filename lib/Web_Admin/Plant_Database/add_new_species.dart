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
  final ImagePicker _picker = ImagePicker();

  // 📝 Controllers
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

  @override
  void dispose() {
    _nameController.dispose();
    _scientificController.dispose();
    _descriptionController.dispose();
    _habitatController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<void> _pickARModel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['glb', 'gltf'],
      withData: true,
    );
    if (result != null) setState(() => _pickedARModel = result.files.first);
  }

  // --- FIXED UPLOAD LOGIC ---
  Future<String?> _uploadToSupabase(String bucket, String fileName, dynamic fileData) async {
    final path = 'uploads/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final Uint8List bytes = fileData is File ? await fileData.readAsBytes() : fileData as Uint8List;

    await _supabase.storage.from(bucket).uploadBinary(path, bytes);
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  Future<void> _saveSpecies() async {
    if (_nameController.text.isEmpty || _selectedCategory == null || _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing required fields or image"))
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Upload to correct bucket: 'species-images'
      final imageBytes = await _pickedImage!.readAsBytes();
      final imageUrl = await _uploadToSupabase('species-images', _pickedImage!.name, imageBytes);

      String? arUrl;
      if (_arEnabled && _pickedARModel != null && _pickedARModel!.bytes != null) {
        arUrl = await _uploadToSupabase('species-images', _pickedARModel!.name, _pickedARModel!.bytes!);
      }

      // 2. Insert using EXACT column names
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFFF4F9F4),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              // THE SQUARE UPLOADER
              _buildSquareImageUploader(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildTextField("COMMON NAME *", "e.g. Philippine Orchid", _nameController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField("SCIENTIFIC NAME", "e.g. Phalaenopsis", _scientificController)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDropdown("PLANT TYPE *", ["Flowering Plants", "Ferns", "Trees"], (v) => setState(() => _selectedCategory = v))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDropdown("STATUS *", ["Common", "Uncommon", "Rare", "Endangered"], (v) => setState(() => _selectedStatus = v))),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField("DESCRIPTION", "Enter details...", _descriptionController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField("ZONE", "e.g. Zone A", _habitatController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildARSelector()),
                ],
              ),
              const SizedBox(height: 24),
              _buildToggleRow(Icons.view_in_ar, "Enable AR View", "Show 3D model", _arEnabled, (v) => setState(() => _arEnabled = v)),
              const SizedBox(height: 24),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildHeader(context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text("ADD NEW SPECIES", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
    ],
  );

  // --- FIXED: SQUARE IMAGE UPLOADER ---
  Widget _buildSquareImageUploader() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: SizedBox(
          width: 150, // Controlled width for square
          child: AspectRatio(
            aspectRatio: 1 / 1, // Forces square shape
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: _pickedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.network(_pickedImage!.path, fit: BoxFit.cover)
                          : Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("Upload Image", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildARSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("AR MODEL (.GLB)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      OutlinedButton(onPressed: _pickARModel, style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45)), child: Text(_pickedARModel != null ? "Attached" : "Choose File")),
    ],
  );

  Widget _buildTextField(String label, String hint, TextEditingController controller) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      TextField(
        controller: controller, 
        decoration: InputDecoration(
          hintText: hint, 
          filled: true, 
          fillColor: Colors.white, 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), // Fixed decoration logic
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    ],
  );

  Widget _buildDropdown(String label, List<String> items, Function(String?) onChanged) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged, decoration: const InputDecoration(filled: true, fillColor: Colors.white)),
    ],
  );

  Widget _buildToggleRow(icon, title, sub, value, onChanged) => Container(
    padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
    child: Row(children: [Icon(icon, color: const Color(0xFF4D6D4D)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey))])), Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF4D6D4D))]),
  );

  Widget _buildSaveButton() => SizedBox(
    width: double.infinity, height: 48,
    child: ElevatedButton(
      onPressed: _isSaving ? null : _saveSpecies,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4D6D4D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE TO DATABASE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ),
  );
}