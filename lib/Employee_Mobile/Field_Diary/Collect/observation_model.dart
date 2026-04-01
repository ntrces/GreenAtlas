import 'package:flutter/material.dart';

class ObservationModel extends ChangeNotifier {
  // --- Step 1 Fields ---
  String? userId; 
  String observerName = 'FO-12345'; 
  
  List<Map<String, String>> members = [
    {'firstname': '', 'lastname': '', 'role': ''}
  ];

  // --- Step 2 Fields ---
  DateTime observationDate = DateTime.now();
  String region = "Region IV-A (CALABARZON)";
  String province = "Cavite";
  String protectedArea = "Cavite Protected Landscape";
  String weatherCondition = ''; 

  // --- Step 3 Fields ---
  String habitat = '';            
  String? habitatOthers;
  String observationCategory = ''; 
  String? obsCategoryOthers;

  String taxon = '';
  String speciesName = ''; 
  bool isUnfamiliar = false; 
  int quantity = 0; // Set to 0 so "Enter count" hint shows
  
  bool seen = false; 
  bool heard = false; 
  bool presence = false; 

  // --- NEW FIELD: Photo Upload ---
  String? imagePath; // Stores the local path of the picked photo

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

  // UPDATED: Reset all fields to BLANK/DEFAULT
  void reset() {
    // Step 1 Reset
    members = [
      {'firstname': '', 'lastname': '', 'role': ''}
    ];

    // Step 2 Reset
    observationDate = DateTime.now();
    weatherCondition = ''; 
    
    // Step 3 Reset
    habitat = '';            // Blank for "Select habitat" hint
    habitatOthers = null;
    observationCategory = ''; // Blank for "Select category" hint
    obsCategoryOthers = null;
    taxon = '';
    speciesName = '';
    isUnfamiliar = false;
    quantity = 0;            // 0 for "Enter count" hint
    seen = false;
    heard = false;
    presence = false;
    
    // Photo Reset
    imagePath = null;        // Physically clears the photo box UI
    
    status = 'Sent';
    observationNotes = '';

    notifyListeners(); // Updates all 3 steps simultaneously
  }
}