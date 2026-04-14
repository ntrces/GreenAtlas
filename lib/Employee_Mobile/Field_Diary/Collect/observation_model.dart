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
  String speciesName = '';
  String localName = ''; 
  bool isUnfamiliar = false;
  int quantity = 0;               

  bool seen = false;
  bool heard = false;
  bool presence = false;

  // Image Handling
  List<String> imagePaths = [];  // Local file paths (Step 3 UI)
  List<String> imageUrls = [];   // Remote Supabase Storage URLs (Database)
  
  String observationNotes = '';
  
  String status = 'PENDING';

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
    localName = '';
    isUnfamiliar = false;
    quantity = 0;
    seen = false; 
    heard = false; 
    presence = false;
    imagePaths = [];
    imageUrls = []; // Reset URLs as well
    observationNotes = '';
    status = 'PENDING'; 
    notifyListeners();
  }
}