import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';

class FieldDiaryDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> entry;
  const FieldDiaryDetailsScreen({super.key, required this.entry});

  @override
  State<FieldDiaryDetailsScreen> createState() => _FieldDiaryDetailsScreenState();
}

class _FieldDiaryDetailsScreenState extends State<FieldDiaryDetailsScreen> {
  final _supabase = Supabase.instance.client;
  late Map<String, dynamic> _currentEntry;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
    _fetchLatestData();
    _setupRealtimeSubscription(); // Sync with Admin actions
  }

  // --- 🔄 REAL-TIME SYNC ---
  void _setupRealtimeSubscription() {
    _supabase
        .from('field_entries')
        .stream(primaryKey: ['id'])
        .eq('id', widget.entry['id'])
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty && mounted) {
            setState(() => _currentEntry = data.first);
          }
        });
  }

  Future<void> _fetchLatestData() async {
    try {
      final data = await _supabase
          .from('field_entries')
          .select()
          .eq('id', widget.entry['id'])
          .single();
      if (mounted) setState(() { _currentEntry = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        title: Text(_currentEntry['plant_name'] ?? "Details", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [ _buildStatusBadge(_currentEntry['status'] ?? "Pending"), const SizedBox(width: 16) ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLatestData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Health Indicator Card
              _buildMainCard(isDark: isDark, borderSideColor: _getHealthColor(_currentEntry['health_status']),
                child: Text(_currentEntry['health_status'] ?? "Healthy", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _getHealthColor(_currentEntry['health_status']))),
              ),
              const SizedBox(height: 12),

              // --- 🛑 ADMIN FEEDBACK SECTION ---
              if (_currentEntry['admin_feedback'] != null && _currentEntry['admin_feedback'].toString().isNotEmpty)
                _buildMainCard(
                  isDark: isDark,
                  title: "ADMIN CORRECTION NOTES",
                  backgroundColor: _currentEntry['status'] == "Rejected" ? Colors.red.withOpacity(0.05) : Colors.green.withOpacity(0.05),
                  borderSideColor: _currentEntry['status'] == "Rejected" ? Colors.red : Colors.green,
                  child: Text(_currentEntry['admin_feedback'], style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500)),
                ),
              const SizedBox(height: 12),

              // Data Grid
              Row(children: [
                Expanded(child: _buildInfoBox("Location", _currentEntry['location'] ?? "N/A", isDark)),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoBox("Date", _currentEntry['created_at'].toString().split('T')[0], isDark)),
              ]),
              const SizedBox(height: 12),

              _buildMainCard(isDark: isDark, child: Column(children: [
                _buildDetailRow(Icons.opacity, "Soil Condition", _currentEntry['soil_condition'] ?? "N/A"),
                const Divider(height: 24),
                _buildDetailRow(Icons.eco_outlined, "Flowering Stage", _currentEntry['flowering_stage'] ?? "N/A"),
              ])),
            ],
          ),
        ),
      ),
    );
  }

  // Helpers for Status Mapping
  Widget _buildStatusBadge(String status) {
    final bool isApproved = status.toLowerCase() == 'approved';
    final bool isRejected = status.toLowerCase() == 'rejected';
    Color col = isApproved ? Colors.green : (isRejected ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Color _getHealthColor(String? s) => (s == 'Poor') ? Colors.red : (s == 'Moderate' ? Colors.orange : Colors.green);

  Widget _buildMainCard({required bool isDark, required Widget child, Color? borderSideColor, String? title, Color? backgroundColor}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: backgroundColor ?? (isDark ? const Color(0xFF1F1F1F) : Colors.white), borderRadius: BorderRadius.circular(12),
        border: borderSideColor != null ? Border(left: BorderSide(color: borderSideColor, width: 4)) : Border.all(color: Colors.black)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ if (title != null) Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black38)), child ]),
    );
  }

  Widget _buildInfoBox(String l, String v, bool d) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: d ? const Color(0xFF1F1F1F) : Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(l, style: const TextStyle(fontSize: 11, color: Colors.black38)), Text(v, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)) ]));

  Widget _buildDetailRow(IconData i, String l, String v) => Row(children: [ Icon(i, size: 18, color: const Color(0xFF4D6D4D)), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(l, style: const TextStyle(fontSize: 11, color: Colors.black38)), Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)) ]) ]);
}