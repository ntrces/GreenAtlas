import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';
import 'FieldDiary_NewEntry.dart';
import '../Field_Diary/FiedlDiary_Entries.dart'; 

class FieldDiaryScreen extends StatefulWidget {
  const FieldDiaryScreen({super.key});
  @override
  State<FieldDiaryScreen> createState() => _FieldDiaryScreenState();
}

class _FieldDiaryScreenState extends State<FieldDiaryScreen> {
  int _activeFilterIndex = 0;
  final _supabase = Supabase.instance.client;

  Color _getHealthColor(String? health) {
    switch (health?.toLowerCase()) {
      case 'poor': return Colors.red;
      case 'moderate': return Colors.orange;
      case 'critical': return Colors.purple;
      default: return Colors.green;
    }
  }

  // Helper to map validation status to colors
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
      case 'validated': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange; // Pending
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // REAL-TIME STREAM: Updates automatically when Admin approves/rejects
        stream: _supabase
            .from('field_entries')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allEntries = snapshot.data!;

          // DYNAMIC FILTERING: Added index 3 for Rejected
          final filteredEntries = allEntries.where((entry) {
            if (_activeFilterIndex == 1) return entry['status'] == "Pending";
            if (_activeFilterIndex == 2) return (entry['status'] == "Validated" || entry['status'] == "Approved");
            if (_activeFilterIndex == 3) return entry['status'] == "Rejected";
            return true;
          }).toList();

          // STATS CALCULATIONS
          final total = allEntries.length;
          final validated = allEntries.where((e) => e['status'] == 'Validated' || e['status'] == 'Approved').length;
          final rejected = allEntries.where((e) => e['status'] == 'Rejected').length;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true, 
                backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white, 
                title: const Text("Field Diary", style: TextStyle(fontWeight: FontWeight.bold))
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Stats Grid
                    GridView.count(
                      shrinkWrap: true, crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5, 
                      children: [
                        _stat(Icons.menu_book, "$total", "Total Entries", isDark, Colors.blue),
                        _stat(Icons.check_circle_outline, "$validated", "Approved", isDark, Colors.green),
                        _stat(Icons.cancel_outlined, "$rejected", "Rejected", isDark, Colors.red),
                        _stat(Icons.eco_outlined, "12", "Species", isDark, Colors.green),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildFilters(isDark),
                    const SizedBox(height: 24),

                    if (filteredEntries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 50),
                        child: Center(child: Text("No entries found.", style: TextStyle(color: Colors.black38))),
                      )
                    else
                      ...filteredEntries.map((entry) => InkWell(
                        onTap: () => Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => FieldDiaryDetailsScreen(entry: entry))
                        ),
                        child: _buildDiaryTile(entry, isDark),
                      )).toList(),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5D7A5D),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NewFieldEntryScreen())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _stat(IconData i, String v, String l, bool d, Color color) => Container(
    padding: const EdgeInsets.all(12), 
    decoration: BoxDecoration(color: d ? const Color(0xFF1F1F1F) : Colors.white, borderRadius: BorderRadius.circular(12)), 
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        CircleAvatar(radius: 14, backgroundColor: color.withOpacity(0.1), child: Icon(i, size: 14, color: color)), 
        const Spacer(), 
        Text(v, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: d ? Colors.white : Colors.black)), 
        Text(l, style: const TextStyle(fontSize: 10, color: Colors.black38))
      ]
    )
  );

  Widget _buildFilters(bool d) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: [ 
      _filt("All", 0, d), const SizedBox(width: 8), 
      _filt("Pending", 1, d), const SizedBox(width: 8), 
      _filt("Approved", 2, d), const SizedBox(width: 8), 
      _filt("Rejected", 3, d) 
    ]),
  );

  Widget _filt(String l, int i, bool d) => InkWell(
    onTap: () => setState(() => _activeFilterIndex = i), 
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
      decoration: BoxDecoration(
        color: _activeFilterIndex == i ? const Color(0xFF5D7A5D) : (d ? Colors.white10 : const Color(0xFFE8F3E8)), 
        borderRadius: BorderRadius.circular(20)
      ), 
      child: Text(l, style: TextStyle(color: _activeFilterIndex == i ? Colors.white : Colors.green, fontWeight: FontWeight.bold, fontSize: 12))
    )
  );

  Widget _buildDiaryTile(Map<String, dynamic> entry, bool d) {
    final healthCol = _getHealthColor(entry['health_status']);
    final status = entry['status'] ?? "Pending";
    final statusCol = _getStatusColor(status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12), 
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(
        color: d ? const Color(0xFF1F1F1F) : Colors.white, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: d ? Colors.white10 : Colors.black.withOpacity(0.05))
      ), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              Text(entry['plant_name'] ?? "Unknown", style: TextStyle(fontWeight: FontWeight.bold, color: d ? Colors.white : Colors.black)), 
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
                decoration: BoxDecoration(color: healthCol.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), 
                child: Text(entry['health_status'] ?? "N/A", style: TextStyle(color: healthCol, fontSize: 10, fontWeight: FontWeight.bold))
              )
            ]
          ), 
          Text("Zone: ${entry['location'] ?? 'N/A'}", style: const TextStyle(fontSize: 11, color: Colors.black38)), 
          const SizedBox(height: 8), 
          Text(entry['notes'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: d ? Colors.white70 : Colors.black54)),
          const Divider(height: 24),
          Row(
            children: [
              Icon(
                status == "Rejected" ? Icons.error_outline : (status == "Pending" ? Icons.access_time : Icons.check_circle_outline), 
                size: 14, 
                color: statusCol
              ),
              const SizedBox(width: 4),
              Text(
                status.toUpperCase(), 
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusCol)
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, size: 16, color: Colors.black26),
            ],
          )
        ]
      )
    );
  }
}