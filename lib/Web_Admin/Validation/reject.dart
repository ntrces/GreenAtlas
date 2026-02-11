import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RejectDialog extends StatefulWidget {
  final Map<String, dynamic> entry;
  const RejectDialog({super.key, required this.entry});

  @override
  State<RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<RejectDialog> {
  // Define controller here so it persists during state changes
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _handleReject() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide feedback for the ranger.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Corrected to use 'field_entries' table and 'admin_feedback' column
      await Supabase.instance.client.from('field_entries').update({
        'status': 'Rejected',
        'admin_feedback': _feedbackController.text.trim(),
        'validated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.entry['id']);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: const Color(0xFFFCE4E4), // Rejection theme
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "REJECT ENTRY", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFB71C1C))
            ),
            const SizedBox(height: 16),
            const Text(
              "FEEDBACK FOR FIELD OFFICER *", 
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45)
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                hintText: "Explain what needs correction...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text("CANCEL"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleReject,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("REJECT", style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}