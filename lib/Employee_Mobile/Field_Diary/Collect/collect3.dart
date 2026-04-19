import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:io' show File; 
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; 

// Model & Components
import '../Collect/observation_model.dart';
import '../../../theme_provider.dart';
import '../../../UserProfile/user_profile.dart';
import '../../EmployeeNotification/employeenotif.dart';
import '../clearentry.dart'; 

// Portal Shell
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
  final Color lightGreenBG = const Color(0xFFEAF7EA);

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
    _habitatOthersController = TextEditingController(text: model.habitatOthers ?? '');
    _obsOthersController = TextEditingController(text: model.obsCategoryOthers ?? '');
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
    'Forest over limestone', 'Forest over ultramafic rocks', 'Tropical lowland evergreen rain forest',
    'Urban Forest', 'Other'
  ];

  final List<String> _observations = [
    'Invasive Alien Species (IAS)', 'Wildlife', 'Signs of people presence', 'Other'
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Taxon group is required")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = _supabase.auth.currentUser;
      final userId = user?.id;

      // 1. PLATFORM-SAFE UPLOAD (Web & Mobile)
      List<String> uploadedUrls = [];
      for (String path in model.imagePaths) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
        final storagePath = '$userId/$fileName';
        
        final XFile xFile = XFile(path);
        final Uint8List bytes = await xFile.readAsBytes();

        await _supabase.storage.from('observation-photos').uploadBinary(
          storagePath, 
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
        
        final String publicUrl = _supabase.storage.from('observation-photos').getPublicUrl(storagePath);
        uploadedUrls.add(publicUrl);
      }

      // 2. SAVE TO observed_species (FIXED: removed scientific_name)
      final speciesData = await _supabase.from('observed_species').upsert({
        'common_name': _commonNameController.text,
        'taxon_group': _taxonController.text,
      }, onConflict: 'common_name').select().single();

      final String speciesId = speciesData['id'];

      List<String> methods = [];
      if (model.seen) methods.add("Seen");
      if (model.heard) methods.add("Heard");
      if (model.presence) methods.add("Presence Signs");

      // 3. SAVE TO field_entries (FIXED: removed other_habitat)
      final Map<String, dynamic> dbData = {
        'user_id': userId,
        'species_id': speciesId,
        'image_urls': uploadedUrls,
        'team_members': model.members, 
        'region': model.region,
        'province': model.province,
        'protected_area': model.protectedArea,
        'weather_condition': model.weatherConditions.join(', '),
        'temperature': model.temperature,
        'observation_date': DateFormat('yyyy-MM-dd').format(model.observationDate),
        'observation_time': DateFormat('HH:mm:ss').format(model.observationDate),
        'observation_category': model.observationCategory,
        'habitat_type': model.habitat,
        'taxon_group': _taxonController.text,
        'common_name': _commonNameController.text,
        'is_unlisted': model.isUnfamiliar,
        'count': int.tryParse(_countController.text) ?? 0,
        'discovery_method': methods.join(', '),
        'notes': model.observationNotes,
        'status': isDraft ? 'DRAFT' : 'PENDING', 
      };

      await _supabase.from('field_entries').insert(dbData);

      if (mounted) {
        if (!isDraft) model.reset();
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => const EmployeePortal(initialIndex: 1)), 
          (route) => false
        );
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : lightGreenBG,
      body: Column(
        children: [
          _buildTopNavBar(context, isDark),
          _buildSecondaryHeader(context, model, textTheme),
          Expanded(
            child: ListView(
              key: _formKey, 
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                Text("Step 3 of 3", style: textTheme.labelSmall?.copyWith(color: Colors.black45)),
                const SizedBox(height: 4),
                Text("Observation Details", style: textTheme.headlineSmall?.copyWith(color: darkGreen)),
                const SizedBox(height: 24),

                _buildCardTitle("HABITAT & CATEGORY", isDark, textTheme),
                _whiteCard(isDark, [
                  _buildLabel("Habitat *", textTheme),
                  const SizedBox(height: 8),
                  _buildDropdownField(model.habitat, _habitats, "Select habitat", (v) => setState(() => model.habitat = v!), textTheme),
                  if (model.habitat == 'Other') ...[
                    const SizedBox(height: 12),
                    _buildTextField("Type habitat name...", _habitatOthersController, textTheme),
                  ],
                  const Divider(height: 32, thickness: 0.5),
                  _buildLabel("Observation *", textTheme),
                  const SizedBox(height: 8),
                  _buildDropdownField(model.observationCategory, _observations, "Select category", (v) => setState(() => model.observationCategory = v!), textTheme),
                ]),

                const SizedBox(height: 24),

                _buildCardTitle("WILDLIFE", isDark, textTheme),
                _whiteCard(isDark, [
                  _buildLabel("Taxon Group *", textTheme),
                  _buildTextField("e.g. Aves, Mammalia", _taxonController, textTheme),
                  const SizedBox(height: 16),
                  _buildLabel("Common Name", textTheme),
                  _buildTextField("Enter common name", _commonNameController, textTheme),
                  const Divider(height: 32, thickness: 0.5),
                  _buildLabel("Unlisted or unfamiliar species? *", textTheme),
                  Row(children: [
                    Expanded(child: RadioListTile<bool>(title: Text("Yes", style: textTheme.bodyMedium), value: true, groupValue: model.isUnfamiliar, activeColor: forestGreen, contentPadding: EdgeInsets.zero, onChanged: (v) => setState(() => model.isUnfamiliar = v!))),
                    Expanded(child: RadioListTile<bool>(title: Text("No", style: textTheme.bodyMedium), value: false, groupValue: model.isUnfamiliar, activeColor: forestGreen, contentPadding: EdgeInsets.zero, onChanged: (v) => setState(() => model.isUnfamiliar = v!))),
                  ]),
                  const Divider(height: 32, thickness: 0.5),
                  _buildLabel("Count", textTheme),
                  _buildTextField("Enter quantity", _countController, textTheme, isNum: true),
                  const Divider(height: 32, thickness: 0.5),
                  _buildLabel("Observation Type", textTheme),
                  _buildCheckbox("Seen", model.seen, (v) => setState(() => model.seen = v!), textTheme),
                  _buildCheckbox("Heard", model.heard, (v) => setState(() => model.heard = v!), textTheme),
                  _buildCheckbox("Presence Signs", model.presence, (v) => setState(() => model.presence = v!), textTheme),
                  const Divider(height: 32, thickness: 0.5),
                  _buildLabel("Upload Photos *", textTheme),
                  const SizedBox(height: 12),
                  _buildMultiPhotoBox(isDark, model, textTheme),
                ]),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomStepper(context, model, textTheme),
    );
  }

  // --- UI HELPERS ---

  Widget _buildTopNavBar(BuildContext context, bool isDark) => Container(
    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 10, left: 16, right: 16), 
    color: isDark ? const Color(0xFF1F1F1F) : Colors.white, 
    child: Row(
      children: [
        Image.asset('assets/logo2.png', height: 32), 
        const Spacer(), 
        IconButton(
          icon: Icon(Icons.notifications_none_outlined, color: isDark ? Colors.white : Colors.black), 
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeNotifications()))
        ), 
        _buildProfileIcon(context, isDark)
      ]
    )
  );

  Widget _buildSecondaryHeader(BuildContext context, ObservationModel model, TextTheme textTheme) => Container(
    color: darkGreen, 
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 20), 
          onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const EmployeePortal(initialIndex: 1)), (route) => false)
        ), 
        Text("BMS Field Diary", style: textTheme.titleSmall?.copyWith(color: Colors.white)), 
        TextButton(onPressed: () => _handleClearAll(model), child: Text("Clear all", style: textTheme.bodySmall?.copyWith(color: Colors.white70)))
      ]
    )
  );

  Widget _buildMultiPhotoBox(bool d, ObservationModel model, TextTheme textTheme) {
    return Column(
      children: [
        if (model.imagePaths.isNotEmpty)
          Container(
            height: 100, margin: const EdgeInsets.only(bottom: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: model.imagePaths.length,
              itemBuilder: (context, index) {
                final String path = model.imagePaths[index];
                return Stack(
                  children: [
                    Container(
                      width: 100, 
                      margin: const EdgeInsets.only(right: 10), 
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12), 
                        image: DecorationImage(
                          image: kIsWeb 
                            ? NetworkImage(path) as ImageProvider 
                            : FileImage(File(path)), 
                          fit: BoxFit.cover
                        )
                      )
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
            decoration: BoxDecoration(color: d ? Colors.white10 : Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: d ? Colors.white24 : Colors.black12)), 
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, size: 24, color: forestGreen), const SizedBox(height: 4), Text("Add Photos", style: textTheme.labelLarge?.copyWith(color: forestGreen))])
          ),
        ),
      ],
    );
  }

  Widget _buildBottomStepper(BuildContext context, ObservationModel model, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(color: lightGreenBG, border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, size: 14), label: Text("Back", style: textTheme.labelLarge)),
              Text("3 of 3", style: textTheme.titleSmall?.copyWith(color: forestGreen)),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _submitForm(model),
                icon: const Icon(Icons.check, size: 18), label: Text("Submit", style: textTheme.labelLarge?.copyWith(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: forestGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _isSaving ? null : () => _submitForm(model, isDraft: true), icon: const Icon(Icons.save_outlined), label: Text("Save as Draft", style: textTheme.labelLarge?.copyWith(color: forestGreen)), style: OutlinedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.5), side: BorderSide(color: forestGreen.withOpacity(0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        ],
      ),
    );
  }

  Widget _buildLabel(String t, TextTheme textTheme) => RichText(text: TextSpan(text: t.replaceFirst('*', ''), style: textTheme.titleSmall?.copyWith(color: Colors.black87), children: [if (t.contains('*')) const TextSpan(text: '*', style: TextStyle(color: Colors.red))]));
  Widget _buildTextField(String h, TextEditingController c, TextTheme textTheme, {bool isNum = false}) => TextField(controller: c, keyboardType: isNum ? TextInputType.number : TextInputType.text, style: textTheme.bodyMedium, decoration: InputDecoration(hintText: h, hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.black26), filled: true, fillColor: const Color(0xFFF9F9F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));
  Widget _buildDropdownField(String v, List<String> i, String h, Function(String?) o, TextTheme textTheme) => Container(padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(12)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: v.isEmpty ? null : v, isExpanded: true, hint: Text(h, style: textTheme.bodyMedium), items: i.map((e) => DropdownMenuItem(value: e, child: Text(e, style: textTheme.bodyMedium))).toList(), onChanged: o)));
  Widget _buildCheckbox(String l, bool v, Function(bool?) o, TextTheme textTheme) => CheckboxListTile(title: Text(l, style: textTheme.bodyMedium), value: v, activeColor: forestGreen, controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, onChanged: o);
  Widget _whiteCard(bool d, List<Widget> c) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: d ? const Color(0xFF1F1F1F) : Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: c));
  Widget _buildCardTitle(String t, bool d, TextTheme textTheme) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(t, style: textTheme.labelSmall?.copyWith(color: Colors.black45)));
  Widget _buildProfileIcon(BuildContext context, bool d) => InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())), child: Container(height: 36, width: 36, decoration: BoxDecoration(color: const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.person_outline, size: 20)));
}