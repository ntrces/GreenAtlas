import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // REQUIRED for file viewing
import '../../theme_provider.dart';

class MeetingAttendanceScreen extends StatefulWidget {
  final Map<String, dynamic> meeting;
  const MeetingAttendanceScreen({super.key, required this.meeting});

  @override
  State<MeetingAttendanceScreen> createState() => _MeetingAttendanceScreenState();
}

class _MeetingAttendanceScreenState extends State<MeetingAttendanceScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  // --- FILE VIEWER LOGIC ---
  Future<void> _viewFile(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open file.")));
    }
  }

  Future<void> _updateRSVP(String status) async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('meeting_rsvps').upsert({
        'meeting_id': widget.meeting['meeting_id'], 
        'user_id': userId,
        'status': status,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final String? fileUrl = widget.meeting['attachment_url']; // Linked from Admin

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        title: Text(widget.meeting['title'] ?? "Details", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildMeetingInfoBox(widget.meeting),
            const SizedBox(height: 16),
            _buildInfoCard(isDark, "About Meeting", widget.meeting['agenda'] ?? "No agenda."),
            
            // --- ATTACHMENT VIEWING ---
            if (fileUrl != null) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _viewFile(fileUrl),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withOpacity(0.2))),
                  child: Row(children: [
                    const Icon(Icons.description_outlined, color: Colors.blue),
                    const SizedBox(width: 12),
                    const Expanded(child: Text("View Attached Briefing Document", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                    const Icon(Icons.open_in_new, size: 16, color: Colors.blue),
                  ]),
                ),
              ),
            ],

            const SizedBox(height: 40),
            if (_isLoading) const CircularProgressIndicator()
            else ...[
              _actionBtn("I WILL ATTEND", const Color(0xFF5D7A5D), () => _updateRSVP('Accepted')),
              const SizedBox(height: 12),
              _actionBtn("CANNOT ATTEND", Colors.black12, () => _updateRSVP('Declined'), isOutlined: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingInfoBox(Map<String, dynamic> m) => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: const Color(0xFFE1ECE1), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      _iconRow(Icons.calendar_today, m['meeting_date'] ?? "TBD"),
      const SizedBox(height: 12),
      _iconRow(Icons.location_on_outlined, m['location'] ?? "Unknown"),
      const SizedBox(height: 12),
      _iconRow(Icons.people_outline, "${m['accepted_count'] ?? 0} attending"),
    ]),
  );

  Widget _iconRow(IconData i, String t) => Row(children: [Icon(i, size: 18, color: const Color(0xFF5D7A5D)), const SizedBox(width: 12), Text(t, style: const TextStyle(fontWeight: FontWeight.bold))]);
  Widget _buildInfoCard(bool d, String l, String v) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: d ? const Color(0xFF1F1F1F) : Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 11, color: Colors.black38)), const SizedBox(height: 4), Text(v, style: TextStyle(color: d ? Colors.white : Colors.black87))]));
  Widget _actionBtn(String l, Color c, VoidCallback t, {bool isOutlined = false}) => SizedBox(width: double.infinity, height: 54, child: ElevatedButton(onPressed: t, style: ElevatedButton.styleFrom(backgroundColor: isOutlined ? Colors.white : c, side: isOutlined ? const BorderSide(color: Colors.black12) : BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: Text(l, style: TextStyle(color: isOutlined ? Colors.black54 : Colors.white, fontWeight: FontWeight.bold))));
}