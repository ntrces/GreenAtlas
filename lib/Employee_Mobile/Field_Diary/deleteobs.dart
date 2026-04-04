import 'package:flutter/material.dart';

class DeleteEntryDialog {
  static void show(BuildContext context, {required VoidCallback onDelete}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final textTheme = Theme.of(context).textTheme;

        return Dialog(
          backgroundColor: const Color(0xFFEAF7EA), // Pale green background
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      "Delete Entry",
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        color: const Color(0xFF2D3E2D), // Dark Green
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, color: Colors.grey, size: 24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Content Text - Wrapped in Center instead of using TextAlign
                Center(
                  child: Text(
                    "Are you sure you want to delete this field entry?",
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: const Color(0xFF5D7A5D), // Forest Green
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    // DELETE BUTTON
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          onDelete(); // Logic to delete from Supabase/Local
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F), // Red
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          "Delete",
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.white, 
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // CANCEL BUTTON
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.black12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          "Cancel",
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.black54, 
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}