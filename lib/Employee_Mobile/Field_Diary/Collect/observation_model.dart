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
  String? habitatOthers; // Required for Step 3
  
  String observationCategory = ''; 
  String? obsCategoryOthers; // Required for Step 3

  String taxon = '';
  String speciesName = '';
  String localName = ''; 
  bool isUnfamiliar = false;
  int quantity = 0;               

  bool seen = false;
  bool heard = false;
  bool presence = false;

  List<String> imagePaths = []; 
  String observationNotes = '';
  
  // FIXED: Default to PENDING (Uppercase) to satisfy DB Constraint
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
    seen = false; heard = false; presence = false;
    imagePaths = [];
    observationNotes = '';
    status = 'PENDING'; 
    notifyListeners();
  }
}