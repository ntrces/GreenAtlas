import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'approved.dart'; 
import 'reject.dart';   

class ValidationQueueView extends StatefulWidget {
  const ValidationQueueView({super.key});

  @override
  State<ValidationQueueView> createState() => _ValidationQueueViewState();
}

class _ValidationQueueViewState extends State<ValidationQueueView> {
  int _selectedEntryIndex = 0;
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('field_entries') // Based on your actual table name
          .stream(primaryKey: ['id'])
          .eq('status', 'Pending') 
          .order('created_at'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final entries = snapshot.data!;
        
        if (entries.isEmpty) {
          return const Center(child: Text("All field entries have been validated."));
        }

        if (_selectedEntryIndex >= entries.length) _selectedEntryIndex = 0;
        final entry = entries[_selectedEntryIndex];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _buildEntryQueue(entries)),
            const SizedBox(width: 32),
            Expanded(flex: 4, child: _buildReviewPanel(entry)),
          ],
        );
      },
    );
  }

  Widget _buildEntryQueue(List<Map<String, dynamic>> entries) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: entries.length,
        itemBuilder: (context, index) => ListTile(
          selected: _selectedEntryIndex == index,
          selectedTileColor: const Color(0xFFF9FAFB),
          onTap: () => setState(() => _selectedEntryIndex = index),
          title: Text(entries[index]['plant_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("ID: ${entries[index]['id'].toString().substring(0,8)}"),
          trailing: const Icon(Icons.chevron_right, size: 16),
        ),
      ),
    );
  }

  Widget _buildReviewPanel(Map<String, dynamic> entry) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry['plant_name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Divider(height: 32),
          _detailBox("SOIL CONDITION", entry['soil_condition'] ?? 'N/A'),
          _detailBox("FLOWERING STAGE", entry['growth_stage'] ?? 'N/A'),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => showDialog(context: context, builder: (c) => ApprovedDialog(entry: entry)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48)),
            child: const Text("APPROVE & PUBLISH"),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => showDialog(context: context, builder: (c) => RejectDialog(entry: entry)),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), minimumSize: const Size(double.infinity, 48)),
            child: const Text("REJECT WITH FEEDBACK"),
          ),
        ],
      ),
    );
  }

  Widget _detailBox(String label, String content) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black26)),
      Text(content, style: const TextStyle(fontSize: 14)),
      const SizedBox(height: 16),
    ],
  );
}