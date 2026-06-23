import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:io' show File;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

// Model & Components
import '../Collect/observation_model.dart';
import '../Collect/offline_draft_service.dart';
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
  late OfflineDraftService _offlineService;
  Key _formKey = UniqueKey();
  final Map<String, Position> _imageLocations = {};

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
    _initOfflineService();
  }

  void _initOfflineService() async {
    _offlineService = OfflineDraftService();
    await _offlineService.init();
    setState(() {});
    // Listen for online status changes
    _offlineService.addListener(() {
      setState(() {});
    });
  }

  void _initControllers() {
    final model = context.read<ObservationModel>();
    _habitatOthersController =
        TextEditingController(text: model.habitatOthers ?? '');
    _obsOthersController =
        TextEditingController(text: model.obsCategoryOthers ?? '');
    _taxonController = TextEditingController(text: model.taxon);
    _commonNameController = TextEditingController(text: model.speciesName);
    _countController = TextEditingController(
        text: model.quantity == 0 ? "" : model.quantity.toString());
  }

  // Species fetching removed as per request for only 2 static choices

  @override
  void dispose() {
    _habitatOthersController.dispose();
    _obsOthersController.dispose();
    _taxonController.dispose();
    _commonNameController.dispose();
    _countController.dispose();
    _offlineService.dispose();
    super.dispose();
  }

  final List<String> _habitats = [
    'Mangrove forest',
    'Beach forest',
    'Freshwater swamp forest',
    'Peat swamp forest',
    'Forest over limestone',
    'Forest over ultramafic rocks',
    'Tropical lowland evergreen rain forest',
    'Urban Forest',
    'Other'
  ];

  final List<String> _observations = [
    'Invasive Alien Species (IAS)',
    'Wildlife',
    'Signs of people presence',
    'Other'
  ];

  final List<String> _speciesChoices = ['Scientific Name', 'Not Applicable'];

  Future<String> _watermarkImage(String path, Position? position, ObservationModel model) async {
    if (kIsWeb) {
      return path;
    }
    try {
      final File file = File(path);
      final Uint8List bytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      final Paint paint = Paint();
      canvas.drawImage(image, Offset.zero, paint);

      final String timestampStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      
      String locationStr = "";
      String addressStr = "";
      if (position != null) {
        locationStr = "GPS: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            final Placemark place = placemarks.first;
            final String city = place.locality ?? "";
            final String subAdmin = place.subAdministrativeArea ?? "";
            
            final List<String> addressParts = [];
            if (city.isNotEmpty) addressParts.add(city);
            if (subAdmin.isNotEmpty && subAdmin != city) addressParts.add(subAdmin);
            
            addressStr = addressParts.join(', ');
          }
        } catch (e) {
          debugPrint("Error reverse geocoding: $e");
        }
      }

      final List<String> watermarkLines = [
        timestampStr,
        if (addressStr.isNotEmpty) addressStr,
        locationStr.isNotEmpty ? locationStr : "GPS: Unavailable",
      ];
      final String watermarkText = watermarkLines.join('\n');

      final double fontSize = image.height * 0.035; 
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: watermarkText,
          style: TextStyle(
            color: Colors.orangeAccent,
            fontSize: fontSize > 12 ? fontSize : 12,
            fontWeight: FontWeight.bold,
            height: 1.2,
            shadows: const [
              Shadow(
                blurRadius: 4.0,
                color: Colors.black,
                offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
        textAlign: TextAlign.right,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();

      final double padding = image.height * 0.02;
      final double x = image.width - textPainter.width - padding;
      final double y = image.height - textPainter.height - padding;

      textPainter.paint(canvas, Offset(x, y));

      final ui.Picture picture = recorder.endRecording();
      final ui.Image watermarkedUiImage = await picture.toImage(image.width, image.height);
      final ByteData? byteData = await watermarkedUiImage.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final Uint8List watermarkedBytes = byteData.buffer.asUint8List();
        await file.writeAsBytes(watermarkedBytes);
      }
    } catch (e) {
      debugPrint("Error watermarking image: $e");
    }
    return path;
  }

  Future<void> _pickImages(ObservationModel model) async {
    try {
      final XFile? pickedImage =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (pickedImage != null) {
        Position? position;
        try {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (serviceEnabled) {
            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied) {
              permission = await Geolocator.requestPermission();
            }
            if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
              position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high,
                timeLimit: const Duration(seconds: 5),
              );
            }
          }
        } catch (e) {
          debugPrint("Error getting GPS location: $e");
        }

        final String watermarkedPath = await _watermarkImage(pickedImage.path, position, model);
        setState(() {
          if (position != null) {
            _imageLocations[watermarkedPath] = position;
          }
          model.imagePaths.add(watermarkedPath);
          model.updateData();
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  void _removeImage(int index, ObservationModel model) {
    final String path = model.imagePaths[index];
    setState(() {
      _imageLocations.remove(path);
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

  Future<void> _submitForm(ObservationModel model,
      {bool isDraft = false}) async {
    if (_taxonController.text.isEmpty && !isDraft) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Taxon group is required")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = _supabase.auth.currentUser;
      final userId = user?.id;

      if (userId == null) {
        throw Exception("User not authenticated");
      }

      // Check connectivity
      if (!_offlineService.isOnline) {
        // Save offline
        if (isDraft) {
          final draftData = {
            'user_id': userId,
            'team_members': model.members,
            'region': model.region,
            'province': model.province,
            'protected_area': model.protectedArea,
            'weather_condition': model.weatherConditions.join(', '),
            'temperature': model.temperature,
            'observation_date':
                DateFormat('yyyy-MM-dd').format(model.observationDate),
            'observation_time':
                DateFormat('HH:mm:ss').format(model.observationDate),
            'observation_category': model.observationCategory,
            'habitat_type': model.habitat,
            'taxon_group': _taxonController.text,
            'common_name': _commonNameController.text,
            'is_unlisted': model.isUnfamiliar,
            'count': int.tryParse(_countController.text) ?? 0,
            'notes': model.observationNotes,
            'status': 'DRAFT',
          };

          List<String> methods = [];
          if (model.seen) methods.add("Seen");
          if (model.heard) methods.add("Heard");
          if (model.presence) methods.add("Presence Signs");
          draftData['discovery_method'] = methods.join(', ');

          final draftId = await _offlineService.saveDraftOffline(draftData);
          await _offlineService.saveImagePathsOffline(
              draftId, model.imagePaths);

          if (mounted) {
            model.reset();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    "Draft saved offline. Will sync when you're back online."),
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const EmployeePortal(initialIndex: 1)),
                (route) => false);
          }
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "You are offline. Please save as draft or connect to internet."),
              duration: Duration(seconds: 3),
            ),
          );
          setState(() => _isSaving = false);
          return;
        }
      }

      // Online flow - original implementation
      List<String> uploadedUrls = [];
      for (String path in model.imagePaths) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
        final storagePath = '$userId/$fileName';

        final XFile xFile = XFile(path);
        final Uint8List bytes = await xFile.readAsBytes();

        await _supabase.storage.from('observation-photos').uploadBinary(
              storagePath,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );

        final String publicUrl = _supabase.storage
            .from('observation-photos')
            .getPublicUrl(storagePath);
        uploadedUrls.add(publicUrl);
      }

      // Save to observed_species table (taxon_group is the column name)
      final speciesData = await _supabase
          .from('observed_species')
          .upsert({
            'taxon_group': _taxonController.text,
            'common_name': _commonNameController.text,
          }, onConflict: 'common_name')
          .select()
          .single();

      final String speciesId = speciesData['id'];

      List<String> methods = [];
      if (model.seen) methods.add("Seen");
      if (model.heard) methods.add("Heard");
      if (model.presence) methods.add("Presence Signs");

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
        'observation_date':
            DateFormat('yyyy-MM-dd').format(model.observationDate),
        'observation_time':
            DateFormat('HH:mm:ss').format(model.observationDate),
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

      // If this was an edited draft, delete the original draft
      if (model.originalDraftId != null && !isDraft) {
        try {
          // Delete online draft from database
          await _supabase
              .from('field_entries')
              .delete()
              .eq('id', model.originalDraftId!);
          
          // Also check if it was an offline draft and delete from local storage
          if (_offlineService.getOfflineDraft(model.originalDraftId!) != null) {
            await _offlineService.deleteOfflineDraft(model.originalDraftId!);
          }
        } catch (e) {
          debugPrint('Error deleting original draft: $e');
        }
      }

      await _supabase.from('audit_logs').insert({
        'title': isDraft ? 'Draft Saved' : 'Field Report Submitted',
        'description': isDraft
            ? 'User saved a draft for ${_commonNameController.text}'
            : 'New field entry submitted for ${_commonNameController.text} in ${model.protectedArea}',
        'category': 'Field Data',
        'ip_address': 'Mobile App',
        'result': 'Success',
        'severity': 'Low',
        'user': user?.email ?? 'Unknown',
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        if (!isDraft) model.reset();
        // Wait a moment for backend to sync before navigating
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (_) => const EmployeePortal(initialIndex: 1)),
            (route) => false);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
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
          // Offline indicator
          if (!_offlineService.isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.orange.shade600,
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "You are offline - Drafts will be saved locally",
                    style: textTheme.labelSmall?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          _buildTopNavBar(context, isDark, textTheme),
          _buildSecondaryHeader(context, model, textTheme),
          Expanded(
            child: ListView(
              key: _formKey,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                Text("Step 3 of 3",
                    style:
                        textTheme.labelSmall?.copyWith(color: Colors.black45)),
                const SizedBox(height: 4),
                Text("Observation Details",
                    style: textTheme.headlineSmall?.copyWith(color: darkGreen)),
                const SizedBox(height: 24),
                _buildCardTitle("HABITAT & CATEGORY", isDark, textTheme),
                _whiteCard(isDark, [
                  _buildLabel("Habitat *", textTheme),
                  const SizedBox(height: 8),
                  _buildDropdownField(
                      _habitats.contains(model.habitat) ? model.habitat : null,
                      _habitats,
                      "Select habitat",
                      (v) => setState(() => model.habitat = v ?? ''),
                      textTheme),
                  if (model.habitat == 'Other') ...[
                    const SizedBox(height: 12),
                    _buildTextField("Type habitat name...",
                        _habitatOthersController, textTheme),
                  ],
                  const Divider(height: 32, thickness: 0.5),
                  _buildLabel("Observation *", textTheme),
                  const SizedBox(height: 8),
                  _buildDropdownField(
                      _observations.contains(model.observationCategory)
                          ? model.observationCategory
                          : null,
                      _observations,
                      "Select category",
                      (v) =>
                          setState(() => model.observationCategory = v ?? ''),
                      textTheme),
                ]),
                const SizedBox(height: 24),
                _buildCardTitle("WILDLIFE", isDark, textTheme),
                _whiteCard(isDark, [
                  _buildLabel("Species Name *", textTheme),
                  _buildDropdownField(
                      (_speciesChoices?.contains(model.taxon ?? '') ?? false)
                          ? model.taxon
                          : null,
                      _speciesChoices ?? [],
                      "Select option",
                      (v) => setState(() {
                            model.taxon = v ?? '';
                            if (v == 'Not Applicable') {
                              _taxonController.text = 'N/A';
                            }
                          }),
                      textTheme),
                  if (model.taxon == 'Scientific Name') ...[
                    const SizedBox(height: 12),
                    _buildTextField(
                        "Type scientific name...", _taxonController, textTheme,
                        onChanged: (v) => setState(() => model.updateData())),
                  ],
                  const SizedBox(height: 16),
                  _buildLabel("Common Name", textTheme),
                  _buildTextField(
                      "Enter common name", _commonNameController, textTheme),
                  const Divider(height: 32, thickness: 0.5),
                  _buildLabel("Unlisted or unfamiliar species? *", textTheme),
                  Row(children: [
                    Expanded(
                        child: RadioListTile<bool>(
                            title: Text("Yes", style: textTheme.bodyMedium),
                            value: true,
                            groupValue: model.isUnfamiliar,
                            activeColor: forestGreen,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) =>
                                setState(() => model.isUnfamiliar = v!))),
                    Expanded(
                        child: RadioListTile<bool>(
                            title: Text("No", style: textTheme.bodyMedium),
                            value: false,
                            groupValue: model.isUnfamiliar,
                            activeColor: forestGreen,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) =>
                                setState(() => model.isUnfamiliar = v!))),
                  ]),
                  const Divider(height: 32, thickness: 0.5),
                  _buildLabel("Count", textTheme),
                  _buildTextField("Enter quantity", _countController, textTheme,
                      isNum: true),
                  const Divider(height: 32, thickness: 0.5),
                  _buildLabel("Observation Type", textTheme),
                  _buildCheckbox("Seen", model.seen,
                      (v) => setState(() => model.seen = v!), textTheme),
                  _buildCheckbox("Heard", model.heard,
                      (v) => setState(() => model.heard = v!), textTheme),
                  _buildCheckbox("Presence Signs", model.presence,
                      (v) => setState(() => model.presence = v!), textTheme),
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

  Widget _buildTopNavBar(
          BuildContext context, bool isDark, TextTheme textTheme) =>
      Container(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 10,
              left: 16,
              right: 16),
          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          child: Row(children: [
            Image.asset('assets/logo2.png', height: 32),
            const SizedBox(width: 12),
            Text("Field Observation",
                style: textTheme.titleLarge?.copyWith(
                  color: isDark ? Colors.white : darkGreen,
                  fontWeight: FontWeight.bold,
                )),
            const Spacer(),
            IconButton(
                icon: Icon(Icons.notifications_none_outlined,
                    color: isDark ? Colors.white : Colors.black),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EmployeeNotifications()))),
            _buildProfileIcon(context, isDark)
          ]));

  Widget _buildSecondaryHeader(
          BuildContext context, ObservationModel model, TextTheme textTheme) =>
      Container(
          color: darkGreen,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EmployeePortal(initialIndex: 1)),
                    (route) => false)),
            const Spacer(),
            Text("BMS Field Observation",
                style: textTheme.titleSmall?.copyWith(color: Colors.white)),
            const Spacer(),
            TextButton(
                onPressed: () => _handleClearAll(model),
                child: Text("Clear all",
                    style:
                        textTheme.bodySmall?.copyWith(color: Colors.white70)))
          ]));

  void _showImagePreview(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black,
                ),
                clipBehavior: Clip.antiAlias,
                child: kIsWeb
                    ? Image.network(path, fit: BoxFit.contain)
                    : Image.file(File(path), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiPhotoBox(
      bool d, ObservationModel model, TextTheme textTheme) {
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
                final String path = model.imagePaths[index];
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _showImagePreview(context, path),
                      child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                  image: kIsWeb
                                      ? NetworkImage(path) as ImageProvider
                                      : FileImage(File(path)),
                                  fit: BoxFit.cover))),
                    ),
                    Positioned(
                        top: 4,
                        right: 14,
                        child: GestureDetector(
                            onTap: () => _removeImage(index, model),
                            child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    size: 14, color: Colors.white)))),
                  ],
                );
              },
            ),
          ),
        InkWell(
          onTap: () => _pickImages(model),
          borderRadius: BorderRadius.circular(12),
          child: Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: d ? Colors.white10 : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: d ? Colors.white24 : Colors.black12)),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        size: 24, color: forestGreen),
                    const SizedBox(height: 4),
                    Text("Add Photos",
                        style:
                            textTheme.labelLarge?.copyWith(color: forestGreen))
                  ])),
        ),
      ],
    );
  }

  Widget _buildBottomStepper(
      BuildContext context, ObservationModel model, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
          color: lightGreenBG,
          border:
              Border(top: BorderSide(color: Colors.black.withOpacity(0.05)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios, size: 14),
                  label: Text("Back", style: textTheme.labelLarge)),
              Text("3 of 3",
                  style: textTheme.titleSmall?.copyWith(color: forestGreen)),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _submitForm(model),
                icon: const Icon(Icons.check, size: 18),
                label: Text("Submit",
                    style: textTheme.labelLarge?.copyWith(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: forestGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () => _submitForm(model, isDraft: true),
                  icon: const Icon(Icons.save_outlined),
                  label: Text("Save as Draft",
                      style:
                          textTheme.labelLarge?.copyWith(color: forestGreen)),
                  style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.5),
                      side: BorderSide(color: forestGreen.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))))),
        ],
      ),
    );
  }

  // UPDATED: Added helpText parameter and Tooltip widget
  Widget _buildLabel(String t, TextTheme textTheme, {String? helpText}) {
    final Widget label = RichText(
        text: TextSpan(
            text: t.replaceFirst('*', ''),
            style: textTheme.titleSmall?.copyWith(color: Colors.black87),
            children: [
          if (t.contains('*'))
            const TextSpan(text: '*', style: TextStyle(color: Colors.red))
        ]));

    if (helpText != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Tooltip(
          message: helpText,
          preferBelow: false,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              label,
              const SizedBox(width: 6),
              const Icon(Icons.info_outline, size: 16, color: Colors.black45),
            ],
          ),
        ),
      );
    }
    return label;
  }

  Widget _buildTextField(String h, TextEditingController c, TextTheme textTheme,
          {bool isNum = false, Function(String)? onChanged}) =>
      TextField(
          controller: c,
          onChanged: onChanged,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          style: textTheme.bodyMedium,
          decoration: InputDecoration(
              hintText: h,
              hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.black26),
              filled: true,
              fillColor: const Color(0xFFF9F9F9),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none)));
  Widget _buildDropdownField(String? v, List<String> i, String h,
          Function(String?) o, TextTheme textTheme, {bool isLoading = false}) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12)),
          child: isLoading
              ? Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: forestGreen))),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                      value: (v == null || v.isEmpty) ? null : v,
                      isExpanded: true,
                      hint: Text(h, style: textTheme.bodyMedium),
                      items: i
                          .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e, style: textTheme.bodyMedium)))
                          .toList(),
                      onChanged: o)));
  Widget _buildCheckbox(
          String l, bool v, Function(bool?) o, TextTheme textTheme) =>
      CheckboxListTile(
          title: Text(l, style: textTheme.bodyMedium),
          value: v,
          activeColor: forestGreen,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: o);
  Widget _whiteCard(bool d, List<Widget> c) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: d ? const Color(0xFF1F1F1F) : Colors.white,
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: c));
  Widget _buildCardTitle(String t, bool d, TextTheme textTheme) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(t,
          style: textTheme.labelSmall?.copyWith(
            color: Colors.black45,
            fontWeight: FontWeight.bold,
          )));
  Widget _buildProfileIcon(BuildContext context, bool d) => InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const UserProfileScreen())),
      child: Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
              color: const Color(0xFFF0F4F0),
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.person_outline, size: 20)));
}
