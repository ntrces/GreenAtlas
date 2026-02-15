import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart'; 
import 'view_report.dart';

class SubmitReportScreen extends StatefulWidget {
  const SubmitReportScreen({super.key});

  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  String? _selectedType;
  Uint8List? _imageBytes; 
  bool _isSubmitting = false;
  bool _isFetchingLocation = false;

  double? _latitude;
  double? _longitude;

  // --- 🛰️ GPS FETCH LOGIC ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
        );
        
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationController.text = "GPS: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}";
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location pinpointed successfully!"), backgroundColor: Color(0xFF5D7A5D))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching GPS: $e"), backgroundColor: Colors.redAccent)
      );
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (selected != null) {
      final bytes = await selected.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  // --- 🚀 SUBMIT LOGIC WITH FULL VALIDATION ---
  Future<void> _submitToSupabase() async {
    // 1. Validate Form Fields (Type, Description, Location)
    final bool isFormValid = _formKey.currentState!.validate();
    
    // 2. Manual Validation for Evidence (Image)
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Evidence photo is required! Please upload an image."), 
          backgroundColor: Colors.redAccent
        )
      );
      return;
    }

    if (!isFormValid) return;

    setState(() => _isSubmitting = true);

    try {
      final user = supabase.auth.currentUser;
      String? imageUrl;

      // Evidence Upload
      final fileName = 'evidence_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'public/$fileName';
      await supabase.storage.from('Evidence').uploadBinary(path, _imageBytes!);
      imageUrl = supabase.storage.from('Evidence').getPublicUrl(path);

      // Final Insertion
      final response = await supabase.from('reports').insert({
        'user_id': user?.id,
        'incident_type': _selectedType,
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'latitude': _latitude, 
        'longitude': _longitude, 
        'evidence_url': imageUrl,
        'severity': 'High',
        'status': 'Pending',
      }).select().single();

      if (mounted) _showSuccessPopup(response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Submission Error: $e"), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Submit Report", style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel("Incident Type", isRequired: true),
              DropdownButtonFormField<String>(
                decoration: _inputDecoration("Select type"),
                items: ['Illegal Logging', 'Water Pollution', 'Wildfire Risk', 'Others']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => _selectedType = val),
                validator: (v) => v == null ? "Please select an incident type" : null,
              ),
              const SizedBox(height: 20),
              
              _buildFieldLabel("Description", isRequired: true),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration("Provide details of the observation..."),
                validator: (v) => v!.trim().isEmpty ? "Description is required" : null,
              ),
              const SizedBox(height: 20),

              _buildFieldLabel("Location Details", isRequired: true),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration("Zone, landmark, or specific spot", icon: Icons.location_on_outlined).copyWith(
                  suffixIcon: IconButton(
                    icon: _isFetchingLocation 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location, color: Color(0xFF5D7A5D)),
                    onPressed: _getCurrentLocation,
                  ),
                ),
                validator: (v) => v!.trim().isEmpty ? "Please provide a location description or use GPS" : null,
              ),
              if (_latitude != null) 
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4),
                  child: Text("📌 Precise GPS Location Locked", style: TextStyle(fontSize: 10, color: Colors.green[800], fontWeight: FontWeight.bold)),
                ),

              const SizedBox(height: 20),
              _buildFieldLabel("Evidence (Photo)", isRequired: true),
              _buildImagePickerBox(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget _buildFieldLabel(String label, {bool isRequired = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(label + (isRequired ? " *" : ""), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
  );

  InputDecoration _inputDecoration(String hint, {IconData? icon}) => InputDecoration(
    hintText: hint, prefixIcon: icon != null ? Icon(icon, color: Colors.black38) : null,
    filled: true, fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF5D7A5D))),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent)),
  );

  Widget _buildImagePickerBox() {
    final bool hasImage = _imageBytes != null;
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity, 
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: hasImage ? const Color(0xFF5D7A5D) : Colors.black12, width: hasImage ? 2 : 1),
        ),
        child: hasImage 
          ? Column(
              children: [
                Image.memory(_imageBytes!, height: 150, fit: BoxFit.contain),
                const SizedBox(height: 10),
                const Text("Tap to change photo", style: TextStyle(color: Colors.black38, fontSize: 12)),
              ],
            )
          : const Column(
              children: [
                Icon(Icons.camera_alt_outlined, size: 40, color: Color(0xFF5D7A5D)), 
                Text("Capture Evidence", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("(Required)", style: TextStyle(color: Colors.redAccent, fontSize: 10)),
              ],
            ),
      ),
    );
  }

  Widget _buildSubmitButton() => SizedBox(
    width: double.infinity, height: 55,
    child: ElevatedButton(
      onPressed: _isSubmitting ? null : _submitToSupabase,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D7A5D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      child: _isSubmitting 
        ? const CircularProgressIndicator(color: Colors.white) 
        : const Text("SUBMIT REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ),
  );

  void _showSuccessPopup(Map<String, dynamic> reportData) {
    showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
      title: const Icon(Icons.check_circle, color: Color(0xFF5D7A5D), size: 60),
      content: const Text("Thank you! Your report has been submitted for review.", textAlign: TextAlign.center),
      actions: [
        Center(child: TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ViewReportScreen(reportData: reportData))), child: const Text("VIEW MY REPORT", style: TextStyle(fontWeight: FontWeight.bold)))),
      ],
    ));
  }
}