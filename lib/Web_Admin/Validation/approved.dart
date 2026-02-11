import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApprovedDialog extends StatelessWidget {
  final Map<String, dynamic> entry;
  ApprovedDialog({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 450, padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("APPROVE ENTRY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B5E20))),
            const SizedBox(height: 16),
            Text("Publish ${entry['plant_name']} to the scientific record?"),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
              ElevatedButton(
                onPressed: () async {
                  await Supabase.instance.client.from('field_entries').update({'status': 'Approved'}).eq('id', entry['id']);
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("APPROVE", style: TextStyle(color: Colors.white)),
              ),
            ])
          ],
        ),
      ),
    );
  }
}