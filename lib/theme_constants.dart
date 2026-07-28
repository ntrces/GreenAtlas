import 'package:flutter/material.dart';

// Colors
const Color primaryForest = Color(0xFF517156);
const Color softGreen = Color(0xFFE5F5E8);
const Color leafAccent = Color(0xFF81C784);
const Color surfaceWhite = Colors.white;

// Dark Mode Color Helpers
Color getScaffoldBg(bool isDark) => isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA);
Color getCardBg(bool isDark) => isDark ? const Color(0xFF1E261F) : Colors.white;
Color getTextColor(bool isDark) => isDark ? Colors.white : const Color(0xFF2D3E2D);
Color getSubtextColor(bool isDark) => isDark ? Colors.white70 : Colors.grey[600]!;
Color getBorderColor(bool isDark) => isDark ? Colors.white12 : Colors.black12;

// Shared Input Style
InputDecoration ecoInputStyle({required String label, required IconData icon, bool isDark = false}) {
  return InputDecoration(
    prefixIcon: Icon(icon, color: isDark ? leafAccent : primaryForest),
    labelText: label,
    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
    filled: true,
    fillColor: isDark ? const Color(0xFF253326) : surfaceWhite,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: isDark ? leafAccent : primaryForest, width: 2),
    ),
  );
}