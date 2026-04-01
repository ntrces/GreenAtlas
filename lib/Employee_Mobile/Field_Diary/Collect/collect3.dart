import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; // Added for file/gallery access
import '../Collect/observation_model.dart';
import '../../../theme_provider.dart';
import '../../../UserProfile/user_profile.dart';
import '../../EmployeeNotification/employeenotif.dart';

// Ensure these imports match your actual file structure
import '../Employee_FieldDiary.dart'; 
import '../clearentry.dart'; 

class CollectStep3Screen extends StatefulWidget {
  const CollectStep3Screen({super.key});

  @override
  State<CollectStep3Screen> createState() => _CollectStep3ScreenState();
}

class _CollectStep3ScreenState extends State<CollectStep3Screen> {
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker(); // Initialize the Picker
  bool _isSaving = false;

  // --- MATCHING STEP 1: Key for physical UI reset ---
  Key _formKey = UniqueKey();

  // Colors
  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);

  // Controllers for text input
  late TextEditingController _habitatOthersController;
  late TextEditingController _obsOthersController;
  late TextEditingController _taxonController;
  late TextEditingController _commonNameController;
  late TextEditingController _countController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final model = context.read<ObservationModel>();
    _habitatOthersController = TextEditingController(text: model.habitatOthers);
    _obsOthersController = TextEditingController(text: model.obsCategoryOthers);
    _taxonController = TextEditingController(text: model.taxon);
    _commonNameController = TextEditingController(text: model.speciesName);
    _countController = TextEditingController(text: model.quantity == 0 ? "" : model.quantity.toString());
  }

  @override
  void dispose() {
    _habitatOthersController.dispose();
    _obsOthersController.dispose();
    _taxonController.dispose();
    _commonNameController.dispose();
    _countController.dispose();
    super.dispose();
  }

  // --- LOGIC: File/Gallery Manager ---
  Future<void> _pickImage(ObservationModel model) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, // Opens the file manager/gallery
        imageQuality: 70, 
      );

      if (image != null) {
        setState(() {
          // IMPORTANT: Ensure you add 'String? imagePath' to your ObservationModel
          model.imagePath = image.path; 
          model.updateData();
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // --- LOGIC: Clear all entries (MATCHING STEP 1 DIALOG PATTERN) ---
  void _handleClearAll(ObservationModel model) {
    showDialog(
      context: context,
      builder: (context) => ClearEntryDialog(
        onClear: () {
          setState(() {
            // 1. Reset the global Provider data
            model.reset();
            model.imagePath = null; // Clear the selected photo path
            
            // 2. Explicitly clear local controllers
            _habitatOthersController.clear();
            _obsOthersController.clear();
            _taxonController.clear();
            _commonNameController.clear();
            _countController.clear(); 

            // 3. Force the ListView to recreate blank (Like Step 1)
            _formKey = UniqueKey();
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("All form entries cleared"), duration: Duration(seconds: 1)),
          );
        },
      ),
    );
  }

  // Options
  final List<String> _habitats = ['Mangrove forest', 'Beach forest', 'Freshwater swamp forest', 'Urban Forest', 'Other'];
  final List<String> _observations = ['Invasive Alien Species (IAS)', 'Signs of people presence', 'Wildlife', 'Other'];

  // SUBMISSION LOGIC
  Future<void> _submitForm(ObservationModel model, {bool isDraft = false}) async {
    if (_taxonController.text.isEmpty && !isDraft) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Taxon is required"), backgroundColor: Colors.redAccent)
      );
      return;
    }

    setState(() => _isSaving = true);
    model.taxon = _taxonController.text;
    model.speciesName = _commonNameController.text;
    model.quantity = int.tryParse(_countController.text) ?? 0;

    try {
      final user = _supabase.auth.currentUser;
      final observationData = {
        'user_id': user?.id,
        'observer_id_code': model.observerName,
        'region': model.region,
        'province': model.province,
        'protected_area': model.protectedArea,
        'weather': model.weatherCondition,
        'obs_date': DateFormat('yyyy-MM-dd').format(model.observationDate),
        'habitat': model.habitat.isEmpty ? null : model.habitat,
        'observation_category': model.observationCategory.isEmpty ? null : model.observationCategory,
        'taxon': model.taxon,
        'common_name': model.speciesName,
        'count': model.quantity,
        'status': isDraft ? 'Draft' : 'Sent',
      };

      await _supabase.from('field_entries').insert(observationData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isDraft ? "Saved to drafts" : "Observation sent!")));
        if (!isDraft) model.reset();
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const FieldObservationScreen()), (route) => false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final model = Provider.of<ObservationModel>(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      body: Column(
        children: [
          _buildTopNavBar(context, isDark),
          _buildSecondaryHeader(context, model),
          Expanded(
            child: ListView(
              key: _formKey, 
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                const Text("Step 3 of 3", style: TextStyle(fontSize: 13, color: Colors.black45, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text("Observation Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkGreen)),
                const SizedBox(height: 24),

                _buildCardTitle("HABITAT & CATEGORY", isDark),
                _whiteCard(isDark, [
                  _buildLabel("Habitat *"),
                  const SizedBox(height: 8),
                  _buildDropdownField(model.habitat, _habitats, "Select habitat", (v) => setState(() => model.habitat = v!)),
                  if (model.habitat == 'Other') ...[
                    const SizedBox(height: 12),
                    _buildTextField("Type habitat name...", _habitatOthersController),
                  ],
                  const Divider(height: 32, thickness: 0.5),
                  
                  _buildLabel("Observation *"),
                  const SizedBox(height: 8),
                  _buildDropdownField(model.observationCategory, _observations, "Select category", (v) => setState(() => model.observationCategory = v!)),
                ]),

                const SizedBox(height: 24),

                _buildCardTitle("WILDLIFE", isDark),
                _whiteCard(isDark, [
                  _buildLabel("Taxon *"),
                  const SizedBox(height: 8),
                  _buildTextField("e.g. Aves, Mammalia", _taxonController),
                  const SizedBox(height: 16),
                  
                  _buildLabel("Common Name"),
                  const SizedBox(height: 8),
                  _buildTextField("Enter common name", _commonNameController),
                  const Divider(height: 32, thickness: 0.5),

                  _buildLabel("Count"),
                  const SizedBox(height: 8),
                  _buildTextField("Enter count", _countController, isNum: true),
                  const Divider(height: 32, thickness: 0.5),

                  _buildLabel("Observation Type"),
                  _buildCheckbox("Seen", model.seen, (v) => setState(() => model.seen = v!)),
                  _buildCheckbox("Heard", model.heard, (v) => setState(() => model.heard = v!)),
                  _buildCheckbox("Presence", model.presence, (v) => setState(() => model.presence = v!)),
                  
                  const Divider(height: 32, thickness: 0.5),

                  // --- UPLOAD PHOTO SECTION ---
                  _buildLabel("Upload Photo *"),
                  const SizedBox(height: 12),
                  _buildPhotoBox(isDark, model),
                ]),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomStepper(context, model),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildTopNavBar(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 10, left: 16, right: 16),
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      child: Row(
        children: [
          Image.asset('assets/logo2.png', height: 32),
          const SizedBox(width: 12),
          Text("Field Diary", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : darkGreen)),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.notifications_none_outlined, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeNotifications())),
          ),
          _buildProfileIcon(context, isDark),
        ],
      ),
    );
  }

  Widget _buildSecondaryHeader(BuildContext context, ObservationModel model) {
    return Container(
      color: darkGreen,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20), 
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FieldObservationScreen()))
          ),
          const Text("BMS Field Diary", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          TextButton(
            onPressed: () => _handleClearAll(model), 
            child: const Text("Clear all", style: TextStyle(color: Colors.white70, fontSize: 12))
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoBox(bool d, ObservationModel model) {
    bool hasPhoto = model.imagePath != null && model.imagePath!.isNotEmpty;

    return InkWell(
      onTap: () => _pickImage(model),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120, width: double.infinity,
        decoration: BoxDecoration(
          color: d ? Colors.white10 : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasPhoto ? forestGreen : (d ? Colors.white24 : Colors.black12), 
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasPhoto ? Icons.check_circle : Icons.add_a_photo_outlined, 
              size: 32, 
              color: hasPhoto ? forestGreen : (d ? Colors.white38 : Colors.black26),
            ),
            const SizedBox(height: 8),
            Text(
              hasPhoto ? "Photo selected!" : "Tap to upload wildlife photo...", 
              style: TextStyle(
                color: hasPhoto ? forestGreen : (d ? Colors.white38 : Colors.black26), 
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hasPhoto)
              const Text("(Tap to change)", style: TextStyle(fontSize: 10, color: Colors.black26)),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text.replaceFirst('*', ''),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
        children: [
          if (text.contains('*')) const TextSpan(text: '*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {bool isNum = false}) => TextField(
    controller: controller,
    keyboardType: isNum ? TextInputType.number : TextInputType.text,
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black26),
      filled: true,
      fillColor: const Color(0xFFF9F9F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
  );

  Widget _buildDropdownField(String v, List<String> items, String hint, Function(String?) onChanged) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(12)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: v.isEmpty ? null : v, 
        isExpanded: true,
        hint: Text(hint, style: const TextStyle(fontSize: 14, color: Colors.black26)),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
      ),
    ),
  );

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) => CheckboxListTile(
    title: Text(label, style: const TextStyle(fontSize: 14)),
    value: value,
    activeColor: forestGreen,
    controlAffinity: ListTileControlAffinity.leading,
    contentPadding: EdgeInsets.zero,
    onChanged: onChanged,
  );

  Widget _buildBottomStepper(BuildContext context, ObservationModel model) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, size: 14, color: Colors.black45),
            label: const Text("Back", style: TextStyle(color: Colors.black45)),
          ),
          const Text("3 of 3", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          ElevatedButton(
            onPressed: _isSaving ? null : () => _submitForm(model),
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Submit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileIcon(BuildContext context, bool isDark) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
    child: Container(
      height: 36, width: 36,
      decoration: BoxDecoration(color: const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
      child: const Icon(Icons.person_outline, color: Colors.black54, size: 20),
    ),
  );

  Widget _whiteCard(bool d, List<Widget> children) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: d ? const Color(0xFF1F1F1F) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _buildCardTitle(String t, bool d) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: d ? Colors.white38 : Colors.black45)),
  );
}