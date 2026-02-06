import 'package:flutter/material.dart';

// Colors
const Color primaryForest = Color(0xFF1B5E20);
const Color softGreen = Color(0xFFF1F8E9);
const Color leafAccent = Color(0xFF81C784);
const Color surfaceWhite = Colors.white;

// Shared Input Style
InputDecoration ecoInputStyle({required String label, required IconData icon}) {
  return InputDecoration(
    prefixIcon: Icon(icon, color: primaryForest),
    labelText: label,
    filled: true,
    fillColor: surfaceWhite,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Colors.black12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: primaryForest, width: 2),
    ),
  );
}