import 'package:flutter/material.dart';

class ClearEntryDialog extends StatelessWidget {
  final VoidCallback onClear;

  const ClearEntryDialog({super.key, required this.onClear});

  static void show(BuildContext context, {required VoidCallback onClear}) {
    showDialog(
      context: context,
      builder: (context) => ClearEntryDialog(onClear: onClear),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color darkGreen = const Color(0xFF2D3E2D);
    final Color forestGreen = const Color(0xFF5D7A5D);
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7EA),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_sweep_outlined, size: 40, color: forestGreen),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              "Clear all entries?",
              style: textTheme.titleLarge?.copyWith(
                fontSize: 18, 
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 12),
            
            // Description - Wrapped in Center instead of using TextAlign
            Center(
              child: Text(
                "This will reset the entire form and remove all data you've entered across all steps. This action cannot be undone.",
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.black54, 
                  fontSize: 14, 
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel", 
                      style: textTheme.labelLarge?.copyWith(color: Colors.black45),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onClear();
                      Navigator.pop(context); // Close Dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      "Clear All", 
                      style: textTheme.labelLarge?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}