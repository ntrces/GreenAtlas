import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
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
  int _selectedIndex = 2; // "Report Issue" active index

  // --- CROSS-PLATFORM IMAGE PICKER ---
  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(source: ImageSource.gallery);
    if (selected != null) {
      final bytes = await selected.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  // --- SUBMIT LOGIC ---
  Future<void> _submitToSupabase() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final user = supabase.auth.currentUser;
      String? imageUrl;

      if (_imageBytes != null) {
        final fileName = 'evidence_${DateTime.now().millisecondsSinceEpoch}.jpg';
        // Note: Using 'public/' folder prefix as required by your policy template
        final path = 'public/$fileName';
        
        // FIX: Changed bucket name to 'Evidence' to match your dashboard
        await supabase.storage.from('Evidence').uploadBinary(path, _imageBytes!);
        imageUrl = supabase.storage.from('Evidence').getPublicUrl(path);
      }

      final response = await supabase.from('reports').insert({
        'user_id': user?.id,
        'incident_type': _selectedType,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'evidence_url': imageUrl,
        'severity': 'High',
        'status': 'Pending',
      }).select().single();

      if (mounted) _showSuccessPopup(response);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent)
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessPopup(Map<String, dynamic> reportData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF5D7A5D), size: 80),
            const SizedBox(height: 16),
            const Text("Report Submitted", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(builder: (context) => ViewReportScreen(reportData: reportData))
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D7A5D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: const Text("View Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA),
      // --- 1. TOP NAVIGATION BAR ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3E2D)),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Submit Report", style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Help protect our area", style: TextStyle(color: Colors.black38, fontSize: 12)),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.notifications_none, color: Color(0xFF2D3E2D)), onPressed: () {}),
              Positioned(right: 8, top: 8, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Text("2", style: TextStyle(color: Colors.white, fontSize: 8)))),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.person_outline, color: Colors.black54),
            ),
          ),
        ],
      ),
      // --- 5. BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2D3E2D),
        unselectedItemColor: Colors.black38,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.visibility_outlined), label: "AR Gallery"),
          BottomNavigationBarItem(icon: Icon(Icons.error_outline), label: "Report Issue"),
        ],
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
              ),
              const SizedBox(height: 20),
              _buildFieldLabel("Description", isRequired: true),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _inputDecoration("What happened? Include date, time, and details..."),
              ),
              const SizedBox(height: 20),
              _buildFieldLabel("Location", isRequired: true),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration("Zone, landmark, or GPS", icon: Icons.location_on_outlined),
              ),
              const SizedBox(height: 20),
              // --- EVIDENCE UPLOAD ---
              _buildFieldLabel("Evidence (Optional)"),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F0).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: _imageBytes != null 
                    ? Image.memory(_imageBytes!, height: 120, fit: BoxFit.contain)
                    : const Column(
                        children: [
                          Icon(Icons.image_outlined, size: 40, color: Color(0xFF5D7A5D)),
                          SizedBox(height: 8),
                          Text("Upload Photos/Videos", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
                          Text("JPG, PNG, MP4", style: TextStyle(color: Colors.black38, fontSize: 12)),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: 20),
              // --- PRIVACY NOTICE ---
              _buildPrivacyNotice(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildFieldLabel(String label, {bool isRequired = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: RichText(
      text: TextSpan(
        text: label, 
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D), fontSize: 14),
        children: [if (isRequired) const TextSpan(text: " *", style: TextStyle(color: Colors.redAccent))]
      )
    ),
  );

  InputDecoration _inputDecoration(String hint, {IconData? icon}) => InputDecoration(
    hintText: hint, prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.black38) : null,
    filled: true, fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  Widget _buildPrivacyNotice() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
    child: const Row(
      children: [
        Icon(Icons.shield_outlined, size: 20, color: Color(0xFF5D7A5D)),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Your identity is protected", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text("Reports are confidential and handled by authorized personnel only.", style: TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          )
        )
      ]
    ),
  );

  Widget _buildSubmitButton() => SizedBox(
    width: double.infinity, height: 55,
    child: ElevatedButton.icon(
      onPressed: _isSubmitting ? null : _submitToSupabase,
      icon: _isSubmitting 
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
        : const Icon(Icons.send, color: Colors.white, size: 18),
      label: const Text("Submit Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5D7A5D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
      ),
    ),
  );
}