import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../Login_Signup_Mobile/LoadingScreen/loading_pages.dart';
import '../services/error_handler.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _municipalityController = TextEditingController();
  final _cityController = TextEditingController();
  Uint8List? _imageBytes;
  final _picker = ImagePicker();

  bool _isLoading = false;

  final Color darkGreen = const Color(0xFF303D32);
  final Color sageGreen = const Color(0xFF517156);
  final Color softGreen = const Color(0xFFF1F8F2);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final nameParts = (user.userMetadata?['full_name'] as String?)?.split(' ') ?? [];
      if (nameParts.isNotEmpty) {
        setState(() {
          _firstNameController.text = nameParts.first;
          if (nameParts.length > 1) {
            _lastNameController.text = nameParts.sublist(1).join(' ');
          }
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<String?> _uploadAvatar(String userId) async {
    if (_imageBytes == null) return null;
    try {
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$userId/$fileName';
      
      await _supabase.storage.from('Profiles').uploadBinary(
            filePath,
            _imageBytes!,
            fileOptions: const FileOptions(upsert: true),
          );
          
      final publicUrl = _supabase.storage.from('Profiles').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  Future<void> _handleComplete() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      
      String? avatarUrl;
      if (_imageBytes != null) {
        avatarUrl = await _uploadAvatar(user.id);
      }

      final Map<String, dynamic> updateData = {
        'full_name': "$firstName $lastName",
        'first_name': firstName,
        'last_name': lastName,
        'phone': _phoneController.text.trim(),
        'municipality': _municipalityController.text.trim(),
        'city': _cityController.text.trim(),
        'is_first_time': false,
      };
      
      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
      }

      await _supabase.from('profiles').update(updateData).eq('id', user.id);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoadingPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softGreen,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Complete Your Profile",
                  style: TextStyle(
                    fontSize: 28,
                    fontFamily: 'Poppins-Bold',
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Tell us a bit more about yourself before we get started.",
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins-Light',
                    color: sageGreen,
                  ),
                ),
                const SizedBox(height: 24),
                
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: sageGreen.withOpacity(0.2), width: 4),
                          image: _imageBytes != null 
                              ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _imageBytes == null 
                            ? Icon(Icons.person_outline, size: 50, color: sageGreen.withOpacity(0.5))
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: sageGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildInputField("First Name", _firstNameController, Icons.person_outline, isName: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildInputField("Last Name", _lastNameController, Icons.person_outline, isName: true)),
                        ],
                      ),
                      _buildInputField("Phone Number", _phoneController, Icons.phone_android_outlined, isPhone: true),
                      _buildInputField("Municipality", _municipalityController, Icons.location_city_outlined),
                      _buildInputField("City / Province", _cityController, Icons.map_outlined),
                      
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleComplete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: sageGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                              : const Text(
                                  "Continue", 
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Poppins-Bold',
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {bool isPhone = false, bool isName = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Poppins-Bold',
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
            maxLength: isPhone ? 11 : null,
            style: const TextStyle(fontSize: 14, fontFamily: 'Poppins-Light'),
            decoration: InputDecoration(
              counterText: "", // Hides the max length counter text
              prefixIcon: Icon(icon, size: 18, color: sageGreen),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: sageGreen)),
              errorStyle: const TextStyle(fontSize: 10, color: Colors.redAccent),
            ),
            validator: (value) {
              final val = value ?? "";
              if (val.trim().isEmpty) return "Required";
              if (isName && !RegExp(r'^[a-zA-Z\s]+$').hasMatch(val)) return "Letters only";
              if (isPhone && !RegExp(r'^\d{11}$').hasMatch(val)) return "11 digits required";
              return null;
            },
          ),
        ],
      ),
    );
  }
}
