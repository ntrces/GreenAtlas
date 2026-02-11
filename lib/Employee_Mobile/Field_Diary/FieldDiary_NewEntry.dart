import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Field_Diary/FiedlDiary_Entries.dart'; // Ensure this matches your filename

class NewFieldEntryScreen extends StatefulWidget {
  const NewFieldEntryScreen({super.key});
  @override
  State<NewFieldEntryScreen> createState() => _NewFieldEntryScreenState();
}

class _NewFieldEntryScreenState extends State<NewFieldEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final _plantNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _soilController = TextEditingController();
  final _threatsController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedHealth;
  String? _selectedStage;
  bool _isSubmitting = false;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      
      // Submit to Supabase
      final List<Map<String, dynamic>> response = await _supabase
          .from('field_entries')
          .insert({
            'user_id': userId,
            'plant_name': _plantNameController.text,
            'location': _locationController.text,
            'health_status': _selectedHealth,
            'soil_condition': _soilController.text,
            'flowering_stage': _selectedStage,
            'threats': _threatsController.text,
            'notes': _notesController.text,
            'status': 'Pending',
          })
          .select(); // .select() is needed to return the new row data

      if (mounted && response.isNotEmpty) {
        // NAVIGATE TO THE DETAILS PAGE ON SUCCESS
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FieldDiaryDetailsScreen(entry: response.first),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ... rest of your build method and UI helpers (_buildLabel, _buildTextField, etc.)
  @override
  Widget build(BuildContext context) {
     return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFFF1F8F1), borderRadius: BorderRadius.circular(20)),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("New Field Entry", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text("Record plant observations", style: TextStyle(fontSize: 12, color: Colors.black38))]),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                ]),
                const SizedBox(height: 30),
                _field("Plant Name *", _plantNameController, "e.g., Philippine Orchid"),
                _field("Location *", _locationController, "e.g., Zone A-3"),
                _drop("Health Status *", ['Healthy', 'Moderate', 'Poor'], (v) => setState(() => _selectedHealth = v)),
                _field("Soil Condition *", _soilController, "e.g., Moist"),
                _drop("Flowering Stage", ['Seedling', 'Vegetative', 'Flowering'], (v) => setState(() => _selectedStage = v)),
                _field("Threats", _threatsController, "e.g., Pests"),
                _field("Notes", _notesController, "Additional notes...", maxLines: 3),
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D7A5D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit Entry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String l, TextEditingController c, String h, {int maxLines = 1}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
    TextFormField(controller: c, maxLines: maxLines, decoration: InputDecoration(hintText: h, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
  ]);

  Widget _drop(String l, List<String> i, ValueChanged<String?> onC) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
    Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: DropdownButtonFormField<String>(decoration: const InputDecoration(border: InputBorder.none), items: i.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onC)),
  ]);
}