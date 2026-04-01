import 'package:flutter/material.dart';

class ObservationModel extends ChangeNotifier {
  // --- Step 1 Fields: Basic Info & Team ---
  String? userId;
  String observerName = 'FO-12345'; 

  List<Map<String, String>> members = [
    {'firstname': '', 'lastname': '', 'role': ''}
  ];

  // --- Step 2 Fields: Date, Time & Location ---
  DateTime observationDate = DateTime.now();
  
  String region = "Region IV-A (CALABARZON)";
  String province = "Cavite";
  String protectedArea = "Cavite Protected Landscape";

  List<String> weatherConditions = []; 

  // --- Step 3 Fields: Wildlife Details ---
  String habitat = '';            
  String? habitatOthers;
  String observationCategory = ''; 
  String? obsCategoryOthers;

  String taxon = '';
  String speciesName = '';
  bool isUnfamiliar = false;
  int quantity = 0;               

  bool seen = false;
  bool heard = false;
  bool presence = false;

  // --- UPDATED: Multiple Photo Support ---
  List<String> imagePaths = []; // Now stores a collection of local file paths

  String status = 'Sent';
  String observationNotes = '';

  // --- Methods ---

  void updateLocationData({String? region, String? province, String? protectedArea}) {
    this.region = region ?? this.region;
    this.province = province ?? this.province;
    this.protectedArea = protectedArea ?? this.protectedArea;
    notifyListeners();
  }

  void updateData() {
    notifyListeners();
  }

  /// COMPREHENSIVE RESET
  void reset() {
    // Step 1
    members = [
      {'firstname': '', 'lastname': '', 'role': ''}
    ];

    // Step 2
    observationDate = DateTime.now();
    weatherConditions = []; 
    
    // Step 3
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
    
    // Photo Reset
    imagePaths = []; // Wipes all selected photos from the list
    
    status = 'Sent';
    observationNotes = '';

    notifyListeners(); 
  }
}