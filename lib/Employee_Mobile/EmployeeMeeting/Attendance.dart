import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
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

  Future<void> _updateRSVP(String status) async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      // UPSERT handles both new RSVPs and updates to existing ones
      await _supabase.from('meeting_rsvps').upsert({
        'meeting_id': widget.meeting['meeting_id'], 
        'user_id': userId,
        'status': status,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("RSVP set to $status"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.meeting['title'] ?? "Details", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          const Text("INVITATION DETAILS", style: TextStyle(color: Colors.black38, fontSize: 10)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _buildTag(Icons.access_time, "RSVP Required", const Color(0xFFE8F3E8), const Color(0xFF5D7A5D)),
              _buildTag(null, "Mandatory", const Color(0xFFFFEBEE), Colors.redAccent),
            ]),
            const SizedBox(height: 16),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFFE1ECE1), borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                _buildIconRow(Icons.calendar_today, widget.meeting['meeting_date'] ?? "TBD"),
                const SizedBox(height: 16),
                _buildIconRow(Icons.location_on_outlined, widget.meeting['location'] ?? "Unknown"),
                const SizedBox(height: 16),
                _buildIconRow(Icons.people_outline, "${widget.meeting['accepted_count'] ?? 0} / ${widget.meeting['max_attendees'] ?? 0} attending"),
              ]),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(isDark, "Organized by", "Admin Team"),
            const SizedBox(height: 16),
            _buildInfoCard(isDark, "About this meeting", widget.meeting['agenda'] ?? "No agenda provided."),
            const SizedBox(height: 32),
            if (_isLoading) const CircularProgressIndicator(color: Color(0xFF5D7A5D))
            else ...[
              SizedBox(width: double.infinity, height: 54, child: ElevatedButton.icon(onPressed: () => _updateRSVP('Accepted'), icon: const Icon(Icons.check_circle_outline, color: Colors.white), label: const Text("I WILL ATTEND", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D7A5D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, height: 54, child: OutlinedButton.icon(onPressed: () => _updateRSVP('Declined'), icon: const Icon(Icons.cancel_outlined, color: Colors.black45), label: const Text("CANNOT ATTEND", style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(IconData? i, String l, Color b, Color t) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: b, borderRadius: BorderRadius.circular(6)), child: Row(children: [if (i != null) Icon(i, size: 14, color: t), if (i != null) const SizedBox(width: 6), Text(l, style: TextStyle(color: t, fontSize: 11, fontWeight: FontWeight.bold))]));
  Widget _buildIconRow(IconData i, String t) => Row(children: [Icon(i, size: 20, color: const Color(0xFF5D7A5D)), const SizedBox(width: 16), Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D)))]);
  Widget _buildInfoCard(bool d, String l, String v) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: d ? const Color(0xFF1F1F1F) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.05))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 11, color: Colors.black38)), const SizedBox(height: 6), Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: d ? Colors.white : const Color(0xFF2D3E2D)))]));
}