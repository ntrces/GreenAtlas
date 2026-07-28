import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../theme_constants.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _municipalityController = TextEditingController();
  final _cityController = TextEditingController();

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
          _firstNameController.text = data['first_name'] ?? "";
          _lastNameController.text = data['last_name'] ?? "";
          _emailController.text = user.email ?? "";
          _phoneController.text = data['phone'] ?? "";
          _municipalityController.text = data['municipality'] ?? "";
          _cityController.text = data['city'] ?? "";
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      String? finalAvatarUrl = _existingAvatarUrl;

      // 1. Handle Image Upload if changed
      if (_imageBytes != null) {
        final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = '${user.id}/$fileName';

        await _supabase.storage.from('Profiles').uploadBinary(
          path,
          _imageBytes!,
          fileOptions: const FileOptions(upsert: true),
        );
        
        finalAvatarUrl = _supabase.storage.from('Profiles').getPublicUrl(path);
      }

      // 2. Update Profile Data
      await _supabase.from('profiles').update({
        'full_name': "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}",
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'municipality': _municipalityController.text.trim(),
        'city': _cityController.text.trim(),
        'avatar_url': finalAvatarUrl,
      }).eq('id', user.id);

      // 3. NEW: Connect to audit_logs
      await _supabase.from('audit_logs').insert({
        'user_id': user.id,
        'title': 'Profile Updated',
        'description': 'User updated profile details.',
        'action': 'profile_update',
        'category': 'security',
        'is_read': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: getScaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: getCardBg(isDark),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: getTextColor(isDark)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Profile", 
          style: textTheme.titleLarge?.copyWith(color: getTextColor(isDark), fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: getCardBg(isDark),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatarPicker(isDark),
                const SizedBox(height: 30),
                Text(
                  "ACCOUNT DETAILS", 
                  style: textTheme.labelSmall?.copyWith(color: isDark ? leafAccent : const Color(0xFF5D7A5D), letterSpacing: 1.0),
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(child: _buildInputField("FIRST NAME", _firstNameController, isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInputField("LAST NAME", _lastNameController, isDark)),
                  ],
                ),
                
                _buildInputField("EMAIL ADDRESS", _emailController, isDark, isEnabled: false, icon: Icons.email_outlined),
                _buildInputField("PHONE NUMBER", _phoneController, isDark, icon: Icons.phone_android_outlined),
                
                Divider(height: 40, color: isDark ? Colors.white12 : Colors.black12),
                Text(
                  "LOCATION DETAILS", 
                  style: textTheme.labelSmall?.copyWith(color: isDark ? leafAccent : const Color(0xFF5D7A5D), letterSpacing: 1.0),
                ),
                const SizedBox(height: 20),
                
                _buildInputField("MUNICIPALITY", _municipalityController, isDark, icon: Icons.location_city_outlined),
                _buildInputField("CITY / PROVINCE", _cityController, isDark, icon: Icons.map_outlined),
                
                const SizedBox(height: 30),
                _buildActionButtons(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPicker(bool isDark) => Center(
    child: GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: isDark ? const Color(0xFF253326) : const Color(0xFFF0F4F0),
            backgroundImage: _imageBytes != null 
                ? MemoryImage(_imageBytes!) 
                : (_existingAvatarUrl != null ? NetworkImage(_existingAvatarUrl!) : null) as ImageProvider?,
            child: (_imageBytes == null && _existingAvatarUrl == null) 
                ? Icon(Icons.person_outline, size: 55, color: isDark ? Colors.white24 : Colors.black12) 
                : null,
          ),
          Positioned(
            bottom: 0, right: 4,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: isDark ? leafAccent : const Color(0xFF5D7A5D), shape: BoxShape.circle, border: Border.all(color: isDark ? Colors.black : Colors.white, width: 2)),
              child: Icon(Icons.camera_alt, color: isDark ? Colors.black : Colors.white, size: 18),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildInputField(String label, TextEditingController controller, bool isDark, {bool isEnabled = true, IconData? icon}) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: textTheme.labelSmall?.copyWith(color: getSubtextColor(isDark)),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            enabled: isEnabled,
            keyboardType: label.contains("PHONE") ? TextInputType.phone : TextInputType.text,
            style: textTheme.bodyMedium?.copyWith(fontSize: 14, color: getTextColor(isDark)),
            decoration: InputDecoration(
              prefixIcon: icon != null ? Icon(icon, size: 18, color: isDark ? leafAccent : const Color(0xFF5D7A5D)) : null,
              filled: true,
              fillColor: isEnabled 
                ? (isDark ? const Color(0xFF253326) : Colors.white) 
                : (isDark ? const Color(0xFF182219) : const Color(0xFFF5F5F5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? leafAccent : const Color(0xFF5D7A5D))),
              disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
              errorStyle: textTheme.labelSmall?.copyWith(fontSize: 10, color: Colors.redAccent),
            ),
            validator: (value) {
              final val = value ?? "";
              if (isEnabled && val.trim().isEmpty) return "Field required";
              if ((label.contains("NAME") || label.contains("MUNICIPALITY")) && !RegExp(r'^[a-zA-Z\s]+$').hasMatch(val)) {
                return "Letters only";
              }
              if (label.contains("PHONE") && !RegExp(r'^\d{11}$').hasMatch(val)) {
                return "Enter 11 digits";
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? leafAccent : const Color(0xFF5D7A5D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isLoading 
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: isDark ? Colors.black : Colors.white, strokeWidth: 2)) 
                : Text(
                    "SAVE CHANGES", 
                    style: textTheme.labelLarge?.copyWith(color: isDark ? Colors.black : Colors.white, letterSpacing: 1, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Discard changes", 
            style: textTheme.bodySmall?.copyWith(color: getSubtextColor(isDark), fontSize: 13),
          ),
        ),
      ],
    );
  }
}