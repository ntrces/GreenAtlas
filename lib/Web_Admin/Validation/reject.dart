import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RejectDialog extends StatelessWidget {
  final Map<String, dynamic> entry;
  RejectDialog({super.key, required this.entry});
  final _feedback = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 450, padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("REJECT ENTRY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
            const SizedBox(height: 16),
            TextField(controller: _feedback, maxLines: 3, decoration: const InputDecoration(hintText: "Enter feedback for ranger...", border: OutlineInputBorder())),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
              ElevatedButton(
                onPressed: () async {
                  await Supabase.instance.client.from('field_entries').update({'status': 'Rejected', 'admin_feedback': _feedback.text}).eq('id', entry['id']);
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("REJECT", style: TextStyle(color: Colors.white)),
              ),
            ])
          ],
        ),
      ),
    );
  }
}