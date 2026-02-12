import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  Uint8List? _imageBytes;
  String? _existingAvatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = await _supabase.from('profiles').select().eq('id', user.id).single();
        setState(() {
          // Splitting full_name if separate first/last names aren't in the DB yet
          String fullName = data['full_name'] ?? "";
          List<String> parts = fullName.split(" ");
          
          _firstNameController.text = data['first_name'] ?? (parts.isNotEmpty ? parts[0] : "");
          _lastNameController.text = data['last_name'] ?? (parts.length > 1 ? parts.sublist(1).join(" ") : "");
          
          _emailController.text = user.email ?? "";
          _phoneController.text = data['phone'] ?? "";
          _locationController.text = data['location'] ?? "";
          _existingAvatarUrl = data['avatar_url'];
        });
      } catch (e) {
        debugPrint("Error loading profile: $e");
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _handleSave() async {
    // Triggers the validators in each TextFormField
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      String? finalAvatarUrl = _existingAvatarUrl;

      // Clean the inputs
      final fName = _firstNameController.text.trim();
      final lName = _lastNameController.text.trim();
      final phone = _phoneController.text.trim();
      final location = _locationController.text.trim();

      if (_imageBytes != null) {
        final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = '${user!.id}/$fileName';

        await _supabase.storage.from('Profiles').uploadBinary(
          path,
          _imageBytes!,
          fileOptions: const FileOptions(upsert: true),
        );
        
        finalAvatarUrl = _supabase.storage.from('Profiles').getPublicUrl(path);
      }

      await _supabase.from('profiles').update({
        'full_name': "$fName $lName",
        'first_name': fName,
        'last_name': lName,
        'phone': phone,
        'location': location,
        'avatar_url': finalAvatarUrl,
      }).eq('id', user!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated!"), backgroundColor: Colors.green)
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3E2D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Edit Profile", style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey, // Needed for validation
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatarPicker(),
                const SizedBox(height: 30),
                const Text("PERSONAL INFORMATION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A634A))),
                const SizedBox(height: 24),
                _buildInputField("LAST NAME", _lastNameController),
                _buildInputField("FIRST NAME", _firstNameController),
                _buildInputField("EMAIL", _emailController, isEnabled: false),
                _buildInputField("PHONE", _phoneController),
                _buildInputField("LOCATION", _locationController),
                const SizedBox(height: 20),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPicker() => Center(
    child: GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFF0F4F0),
            backgroundImage: _imageBytes != null 
                ? MemoryImage(_imageBytes!) 
                : (_existingAvatarUrl != null ? NetworkImage(_existingAvatarUrl!) : null) as ImageProvider?,
            child: (_imageBytes == null && _existingAvatarUrl == null) 
                ? const Icon(Icons.person_outline, size: 50, color: Colors.black12) 
                : null,
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Color(0xFF5D7A5D), shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildActionButtons() => Row(
    children: [
      Expanded(
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5D7A5D),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            side: const BorderSide(color: Colors.black12),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text("CANCEL", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
        ),
      ),
    ],
  );

  Widget _buildInputField(String label, TextEditingController controller, {bool isEnabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            enabled: isEnabled,
            // Automatically show numeric keyboard for Phone
            keyboardType: label == "PHONE" ? TextInputType.phone : TextInputType.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: isEnabled ? Colors.white : const Color(0xFFF9F9F9),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF5D7A5D))),
            ),
            validator: (value) {
              final val = value ?? "";
              if (val.trim().isEmpty) return "This field is required";

              // Name Validation: Letters and spaces only
              if (label == "FIRST NAME" || label == "LAST NAME") {
                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(val)) {
                  return "Letters only, no numbers or symbols";
                }
              }

              // Phone Validation: Exactly 11 digits
              if (label == "PHONE") {
                if (!RegExp(r'^\d{11}$').hasMatch(val)) {
                  return "Must be exactly 11 digits";
                }
              }

              return null;
            },
          ),
        ],
      ),
    );
  }
}