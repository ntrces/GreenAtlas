import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';

class FieldDiaryDetailsScreen extends StatefulWidget {
  // Pass the ID or the initial Map
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
  }

  // --- FETCH LATEST DATA FROM SUPABASE ---
  Future<void> _fetchLatestData() async {
    try {
      final data = await _supabase
          .from('field_entries')
          .select()
          .eq('id', widget.entry['id'])
          .single();

      if (mounted) {
        setState(() {
          _currentEntry = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching entry details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentEntry['plant_name'] ?? "Details", 
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text("ID: ${_currentEntry['id'].toString().substring(0, 8).toUpperCase()}", 
              style: const TextStyle(color: Colors.black38, fontSize: 11)),
          ],
        ),
        actions: [
          _buildStatusBadge(_currentEntry['status'] ?? "Pending"),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLatestData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Health Status
              _buildMainCard(
                isDark: isDark,
                borderSideColor: _getHealthColor(_currentEntry['health_status']),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Health Status", style: TextStyle(fontSize: 12, color: Colors.black38)),
                    const SizedBox(height: 4),
                    Text(_currentEntry['health_status'] ?? "Healthy", 
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _getHealthColor(_currentEntry['health_status']))),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Location & Date Grid
              Row(
                children: [
                  Expanded(child: _buildInfoBox("Location", _currentEntry['location'] ?? "N/A", isDark)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInfoBox("Date", _currentEntry['created_at'].toString().split('T')[0], isDark)),
                ],
              ),
              const SizedBox(height: 12),

              // Environmental Section
              _buildMainCard(
                isDark: isDark,
                child: Column(
                  children: [
                    _buildDetailRow(Icons.opacity, "Soil Condition", _currentEntry['soil_condition'] ?? "N/A"),
                    const Divider(height: 24),
                    _buildDetailRow(Icons.eco_outlined, "Flowering Stage", _currentEntry['flowering_stage'] ?? "N/A"),
                    const Divider(height: 24),
                    _buildDetailRow(Icons.warning_amber_rounded, "Threats", _currentEntry['threats'] ?? "None observed", iconColor: Colors.orange),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Notes Section
              _buildMainCard(
                isDark: isDark,
                title: "Notes",
                backgroundColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8F3E8),
                child: Text(_currentEntry['notes'] ?? "No additional notes.", 
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---

  Color _getHealthColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'poor': return Colors.red;
      case 'moderate': return Colors.orange;
      case 'critical': return Colors.purple;
      default: return Colors.green;
    }
  }

  Widget _buildMainCard({required bool isDark, required Widget child, Color? borderSideColor, String? title, Color? backgroundColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? const Color(0xFF1F1F1F) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: borderSideColor != null 
          ? Border(left: BorderSide(color: borderSideColor, width: 4))
          : Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black38, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black38)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor ?? const Color(0xFF5D7A5D)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black38)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isValidated = status == "Validated";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isValidated ? const Color(0xFFE8F3E8) : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isValidated ? Icons.check_circle_outline : Icons.access_time, 
            size: 14, color: isValidated ? Colors.green : Colors.orange),
          const SizedBox(width: 4),
          Text(status, style: TextStyle(color: isValidated ? Colors.green : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}