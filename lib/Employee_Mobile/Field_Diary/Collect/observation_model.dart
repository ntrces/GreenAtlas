import 'package:flutter/material.dart';

class ObservationModel extends ChangeNotifier {
  String? userId;
  String observerName = 'FO-12345';

  // DB Column: team_members (jsonb)
  List<Map<String, String>> members = [{'firstname': '', 'lastname': '', 'role': ''}];

  // Location & Environment
  DateTime observationDate = DateTime.now();
  String region = "Region IV-A (CALABARZON)";
  String province = "Cavite";
  String protectedArea = "Cavite Protected Landscape";
  List<String> weatherConditions = [];
  int temperature = 28; 

  // Wildlife Details
  String habitat = ''; 
  String? habitatOthers; 
  
  String observationCategory = ''; 
  String? obsCategoryOthers; 

  String taxon = '';
  String speciesName = ''; // This maps to "Common Name" in your UI
  bool isUnfamiliar = false;
  int quantity = 0;               

  bool seen = false;
  bool heard = false;
  bool presence = false;

  // Image Handling
  List<String> imagePaths = [];  // Local Blob URLs (Step 3 UI)
  List<String> imageUrls = [];   // Remote Supabase Storage URLs (Database)
  
  String observationNotes = '';
  
  // Default to PENDING to satisfy DB Constraint
  String status = 'PENDING';
  
  // Track original draft ID when editing (used to delete old draft after submission)
  String? originalDraftId;

  // Track resubmission details
  bool isResubmit = false;
  int resubmitCount = 0;
  Map<String, dynamic>? originalValues;

  void populateForResubmit(Map<String, dynamic> data) {
    reset(); // Clear state first
    
    isResubmit = true;
    originalDraftId = data['id']?.toString();
    resubmitCount = data['resubmit_count'] is int 
        ? data['resubmit_count'] as int 
        : int.tryParse(data['resubmit_count']?.toString() ?? '') ?? 0;
    
    originalValues = Map<String, dynamic>.from(data);
    
    userId = data['user_id']?.toString();
    region = data['region']?.toString() ?? region;
    province = data['province']?.toString() ?? province;
    protectedArea = data['protected_area']?.toString() ?? protectedArea;
    
    final weather = data['weather_condition']?.toString() ?? '';
    weatherConditions = weather.isNotEmpty ? weather.split(', ') : [];
    temperature = data['temperature'] is int 
        ? data['temperature'] as int 
        : (int.tryParse(data['temperature']?.toString() ?? '') ?? 28);
    
    observationDate = DateTime.tryParse(data['observation_date']?.toString() ?? '') 
        ?? DateTime.tryParse(data['created_at']?.toString() ?? '') 
        ?? DateTime.now();
    
    observationCategory = data['observation_category']?.toString() ?? '';
    habitat = data['habitat_type']?.toString() ?? '';
    taxon = data['taxon_group']?.toString() ?? '';
    speciesName = data['common_name']?.toString() ?? '';
    isUnfamiliar = data['is_unlisted'] == true;
    quantity = data['count'] is int 
        ? data['count'] as int 
        : (int.tryParse(data['count']?.toString() ?? '') ?? 0);
    
    final discovery = data['discovery_method']?.toString() ?? '';
    final methods = discovery.split(', ');
    seen = methods.contains("Seen");
    heard = methods.contains("Heard");
    presence = methods.contains("Presence Signs");
    
    observationNotes = data['notes']?.toString() ?? '';
    
    final urls = data['image_urls'] ?? data['image_url'];
    if (urls is List) {
      imageUrls = List<String>.from(urls);
      imagePaths = List<String>.from(urls);
    } else if (urls is String) {
      imageUrls = [urls];
      imagePaths = [urls];
    }
    
    if (data['team_members'] is List) {
      members = (data['team_members'] as List).map((m) => {
        'firstname': m['firstname']?.toString() ?? '',
        'lastname': m['lastname']?.toString() ?? '',
        'role': m['role']?.toString() ?? '',
      }).toList();
    }
    
    notifyListeners();
  }

  bool hasTextChanges({
    required String commonName,
    required String taxonGroup,
    required int count,
    required String notes,
  }) {
    if (originalValues == null) return true;
    
    final Map<String, dynamic> orig = originalValues!;
    
    if (commonName.trim() != (orig['common_name']?.toString().trim() ?? '')) return true;
    if (taxonGroup.trim() != (orig['taxon_group']?.toString().trim() ?? '')) return true;
    if (count != (orig['count'] is int ? orig['count'] : int.tryParse(orig['count']?.toString() ?? '') ?? 0)) return true;
    if (notes.trim() != (orig['notes']?.toString().trim() ?? '')) return true;
    
    if (region.trim() != (orig['region']?.toString().trim() ?? '')) return true;
    if (province.trim() != (orig['province']?.toString().trim() ?? '')) return true;
    if (protectedArea.trim() != (orig['protected_area']?.toString().trim() ?? '')) return true;
    if (observationCategory.trim() != (orig['observation_category']?.toString().trim() ?? '')) return true;
    if (habitat.trim() != (orig['habitat_type']?.toString().trim() ?? '')) return true;
    if (weatherConditions.join(', ').trim() != (orig['weather_condition']?.toString().trim() ?? '')) return true;
    if (temperature != (orig['temperature'] is int ? orig['temperature'] : int.tryParse(orig['temperature']?.toString() ?? '') ?? 28)) return true;
    
    return false;
  }

  void updateLocationData({String? region, String? province, String? protectedArea}) {
    this.region = region ?? this.region;
    this.province = province ?? this.province;
    this.protectedArea = protectedArea ?? this.protectedArea;
    notifyListeners();
  }

  void updateData() => notifyListeners();

  void reset() {
    members = [{'firstname': '', 'lastname': '', 'role': ''}];
    observationDate = DateTime.now();
    weatherConditions = [];
    temperature = 28;
    habitat = '';
    habitatOthers = null;
    observationCategory = '';
    obsCategoryOthers = null;
    taxon = '';
    speciesName = '';
    isUnfamiliar = false;
    quantity = 0;
    seen = false; 
    heard = false; 
    presence = false;
    imagePaths = [];
    imageUrls = []; 
    observationNotes = '';
    status = 'PENDING';
    originalDraftId = null; 
    isResubmit = false;
    resubmitCount = 0;
    originalValues = null;
    notifyListeners();
  }
}