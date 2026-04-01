import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; 
import '../Collect/observation_model.dart';
import '../../../theme_provider.dart';
import '../../../UserProfile/user_profile.dart';
import '../../EmployeeNotification/employeenotif.dart';
import '../Employee_FieldDiary.dart'; 
import '../clearentry.dart'; 
import '../../Employee_Dashboard.dart';

class CollectStep3Screen extends StatefulWidget {
  const CollectStep3Screen({super.key});

  @override
  State<CollectStep3Screen> createState() => _CollectStep3ScreenState();
}

class _CollectStep3ScreenState extends State<CollectStep3Screen> {
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker(); 
  bool _isSaving = false;
  Key _formKey = UniqueKey();

  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);

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

  final List<String> _habitats = [
    'Mangrove forest', 'Beach forest', 'Freshwater swamp forest', 'Peat swamp forest',
    'Forest over limestone', 'Forest over ultramafic rocks', 'Tropical semievergreen rain forest',
    'Tropical moist deciduous forest', 'Tropical lowland evergreen rain forest',
    'Tropical lower montane rain forest', 'Tropical upper montane rain forest',
    'Tropical subalpine forest', 'Urban Forest', 'Other'
  ];

  final List<String> _observations = [
    'Invasive Alien Species (IAS)', 'People encountered and their activities',
    'Physical changes in the landscapes', 'Second-hand Information',
    'Signs of people presence', 'Wildlife', 'Other'
  ];

  Future<void> _pickImages(ObservationModel model) async {
    try {
      final List<XFile> pickedImages = await _picker.pickMultiImage(imageQuality: 70);
      if (pickedImages.isNotEmpty) {
        setState(() {
          model.imagePaths.addAll(pickedImages.map((img) => img.path));
          model.updateData();
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  void _removeImage(int index, ObservationModel model) {
    setState(() {
      model.imagePaths.removeAt(index);
      model.updateData();
    });
  }

  void _handleClearAll(ObservationModel model) {
    showDialog(
      context: context,
      builder: (context) => ClearEntryDialog(
        onClear: () {
          setState(() {
            model.reset();
            _habitatOthersController.clear();
            _obsOthersController.clear();
            _taxonController.clear();
            _commonNameController.clear();
            _countController.clear(); 
            _formKey = UniqueKey();
          });
        },
      ),
    );
  }

  Future<void> _submitForm(ObservationModel model, {bool isDraft = false}) async {
    if (_taxonController.text.isEmpty && !isDraft) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Taxon is required"), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final user = _supabase.auth.currentUser;
      final weatherString = model.weatherConditions.join(', ');
      final imagePathsString = model.imagePaths.join(', ');

      final observationData = {
        'user_id': user?.id,
        'observer_id_code': model.observerName,
        'region': model.region,
        'province': model.province,
        'protected_area': model.protectedArea,
        'weather': weatherString,
        'obs_date': DateFormat('yyyy-MM-dd').format(model.observationDate),
        'habitat': model.habitat,
        'habitat_others': model.habitat == 'Other' ? _habitatOthersController.text : null,
        'observation_category': model.observationCategory,
        'obs_category_others': model.observationCategory == 'Other' ? _obsOthersController.text : null,
        'taxon': _taxonController.text,
        'common_name': _commonNameController.text,
        'is_unfamiliar': model.isUnfamiliar,
        'count': int.tryParse(_countController.text) ?? 0,
        'seen': model.seen,
        'heard': model.heard,
        'presence_signs': model.presence,
        'image_paths': imagePathsString,
        'status': isDraft ? 'Draft' : 'Sent',
      };

      await _supabase.from('field_entries').insert(observationData);

      if (mounted) {
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
                  if (model.observationCategory == 'Other') ...[
                    const SizedBox(height: 12),
                    _buildTextField("Type category name...", _obsOthersController),
                  ],
                ]),

                const SizedBox(height: 24),

                _buildCardTitle("WILDLIFE", isDark),
                _whiteCard(isDark, [
                  _buildLabel("Taxon *"),
                  _buildTextField("e.g. Aves, Mammalia", _taxonController),
                  const SizedBox(height: 16),
                  _buildLabel("Common Name"),
                  _buildTextField("Enter common name", _commonNameController),
                  const Divider(height: 32, thickness: 0.5),
                  
                  _buildLabel("Unlisted or unfamiliar species? *"),
                  Row(
                    children: [
                      Expanded(child: RadioListTile<bool>(title: const Text("Yes", style: TextStyle(fontSize: 14)), value: true, groupValue: model.isUnfamiliar, activeColor: forestGreen, onChanged: (v) => setState(() => model.isUnfamiliar = v!))),
                      Expanded(child: RadioListTile<bool>(title: const Text("No", style: TextStyle(fontSize: 14)), value: false, groupValue: model.isUnfamiliar, activeColor: forestGreen, onChanged: (v) => setState(() => model.isUnfamiliar = v!))),
                    ],
                  ),
                  const Divider(height: 32, thickness: 0.5),

                  _buildLabel("Count"),
                  _buildTextField("Enter quantity", _countController, isNum: true),
                  const Divider(height: 32, thickness: 0.5),

                  _buildLabel("Observation Type"),
                  _buildCheckbox("Seen", model.seen, (v) => setState(() => model.seen = v!)),
                  _buildCheckbox("Heard", model.heard, (v) => setState(() => model.heard = v!)),
                  _buildCheckbox("Presence of tracks/feathers/feces/nest", model.presence, (v) => setState(() => model.presence = v!)),
                  
                  const Divider(height: 32, thickness: 0.5),
                  _buildLabel("Upload Photos *"),
                  const SizedBox(height: 12),
                  _buildMultiPhotoBox(isDark, model),
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

  Widget _buildMultiPhotoBox(bool d, ObservationModel model) {
    return Column(
      children: [
        if (model.imagePaths.isNotEmpty)
          Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: model.imagePaths.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      width: 100, margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: FileImage(File(model.imagePaths[index])), fit: BoxFit.cover)),
                    ),
                    Positioned(top: 4, right: 14, child: GestureDetector(onTap: () => _removeImage(index, model), child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white)))),
                  ],
                );
              },
            ),
          ),
        InkWell(
          onTap: () => _pickImages(model),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 80, width: double.infinity,
            decoration: BoxDecoration(color: d ? Colors.white10 : Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: d ? Colors.white24 : Colors.black12, width: 1.5)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, size: 24, color: forestGreen), const SizedBox(height: 4), Text("Add Photos", style: TextStyle(color: forestGreen, fontSize: 12, fontWeight: FontWeight.bold))]),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return RichText(text: TextSpan(text: text.replaceFirst('*', ''), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87), children: [if (text.contains('*')) const TextSpan(text: '*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]));
  }

  Widget _buildTextField(String hint, TextEditingController controller, {bool isNum = false}) => TextField(controller: controller, keyboardType: isNum ? TextInputType.number : TextInputType.text, style: const TextStyle(fontSize: 14), decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.black26), filled: true, fillColor: const Color(0xFFF9F9F9), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));

  Widget _buildDropdownField(String v, List<String> items, String hint, Function(String?) onChanged) => Container(padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(12)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: v.isEmpty ? null : v, isExpanded: true, hint: Text(hint, style: const TextStyle(fontSize: 14, color: Colors.black26)), items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(), onChanged: onChanged)));

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) => CheckboxListTile(title: Text(label, style: const TextStyle(fontSize: 14)), value: value, activeColor: forestGreen, controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, onChanged: onChanged);

  Widget _buildBottomStepper(BuildContext context, ObservationModel model) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(color: const Color(0xFFEAF7EA), border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, size: 14, color: Colors.black54), label: const Text("Back", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500))),
              const Text("3 of 3", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D7A5D))),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _submitForm(model),
                icon: const Icon(Icons.check, size: 18, color: Colors.white),
                label: const Text("Submit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: forestGreen, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isSaving ? null : () => _submitForm(model, isDraft: true),
              icon: const Icon(Icons.save_outlined, size: 18, color: Color(0xFF2D3E2D)),
              label: const Text("Save as Draft", style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Colors.black12), backgroundColor: Colors.white.withOpacity(0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }

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
          IconButton(icon: Icon(Icons.notifications_none_outlined, color: isDark ? Colors.white : Colors.black), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeNotifications()))),
          _buildProfileIcon(context, isDark),
        ],
      ),
    );
  }

  Widget _buildSecondaryHeader(BuildContext context, ObservationModel model) {
    return Container(
      color: darkGreen, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           IconButton(
  icon: const Icon(Icons.close, color: Colors.white, size: 20), 
  onPressed: () {
    // This closes the form and goes back to the Portal.
    // initialIndex: 1 ensures it lands on the Field Diary tab, not the Dashboard.
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(
        builder: (_) => const EmployeePortal(initialIndex: 1),
      ),
      (route) => false, // This clears the "Steps" from memory so they are fully closed
    );
  },
),
          const Text("BMS Field Diary", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          TextButton(onPressed: () => _handleClearAll(model), child: const Text("Clear all", style: TextStyle(color: Colors.white70, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildProfileIcon(BuildContext context, bool isDark) => InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())), child: Container(height: 36, width: 36, decoration: BoxDecoration(color: const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)), child: const Icon(Icons.person_outline, color: Colors.black54, size: 20)));
  Widget _whiteCard(bool d, List<Widget> children) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: d ? const Color(0xFF1F1F1F) : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children));
  Widget _buildCardTitle(String t, bool d) => Padding(padding: const EdgeInsets.only(bottom: 12, left: 4), child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: d ? Colors.white38 : Colors.black45)));
}