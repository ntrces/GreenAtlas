import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; 
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
  String? _currentStatus; // Tracks if user responded: 'Accepted' or 'Declined'

  @override
  void initState() {
    super.initState();
    _checkExistingRSVP();
  }

  // Queries the database to see if the user has already responded
  Future<void> _checkExistingRSVP() async {
    final userId = _supabase.auth.currentUser?.id;
    final meetingId = widget.meeting['id'] ?? widget.meeting['meeting_id'];
    
    if (userId == null) return;

    try {
      final data = await _supabase
          .from('meeting_rsvps')
          .select('status')
          .eq('meeting_id', meetingId)
          .eq('user_id', userId)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() => _currentStatus = data['status']);
      }
    } catch (e) {
      debugPrint("Error checking RSVP status: $e");
    }
  }

  Future<void> _viewFile(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _updateRSVP(String status) async {
    // Prevent interaction if a response is already logged
    if (_isLoading || _currentStatus != null) return;

    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw "User not authenticated";

      final meetingId = widget.meeting['id'] ?? widget.meeting['meeting_id'];

      // Perform upsert to save response
      await _supabase.from('meeting_rsvps').upsert({
        'meeting_id': meetingId, 
        'user_id': userId,
        'status': status,
      });

      if (mounted) {
        setState(() => _currentStatus = status);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Response sent: $status"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final String? fileUrl = widget.meeting['attachment_url'];
    
    // Status Logic for Button Locking
    final bool isAccepted = _currentStatus == 'Accepted';
    final bool isDeclined = _currentStatus == 'Declined';
    final bool hasResponded = _currentStatus != null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        title: Text(widget.meeting['title'] ?? "Meeting Details", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildMeetingInfoBox(widget.meeting),
            const SizedBox(height: 16),
            _buildInfoCard(isDark, "About Meeting", widget.meeting['agenda'] ?? "No agenda provided."),
            
            if (fileUrl != null) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _viewFile(fileUrl),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withOpacity(0.2))),
                  child: const Row(children: [
                    Icon(Icons.description_outlined, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(child: Text("View Briefing Document", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                    Icon(Icons.open_in_new, size: 16, color: Colors.blue),
                  ]),
                ),
              ),
            ],

            const SizedBox(height: 40),
            if (_isLoading) 
              const CircularProgressIndicator(color: Color(0xFF5D7A5D))
            else ...[
              // ACCEPT BUTTON: Locks if user already accepted
              _actionBtn(
                isAccepted ? "RESPONSE SENT: ACCEPTED" : (isDeclined ? "CANNOT ATTEND" : "I WILL ATTEND"), 
                isAccepted ? Colors.grey : const Color(0xFF5D7A5D), 
                hasResponded ? () {} : () => _updateRSVP('Accepted'),
                opacity: isDeclined ? 0.3 : 1.0 // Fade out if other option was chosen
              ),
              const SizedBox(height: 12),
              // DECLINE BUTTON: Locks if user already declined
              _actionBtn(
                isDeclined ? "RESPONSE SENT: DECLINED" : "CANNOT ATTEND", 
                isDeclined ? Colors.red.withOpacity(0.1) : Colors.black12, 
                hasResponded ? () {} : () => _updateRSVP('Declined'), 
                isOutlined: true,
                textColor: isDeclined ? Colors.red : null,
                opacity: isAccepted ? 0.3 : 1.0 // Fade out if other option was chosen
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildMeetingInfoBox(Map<String, dynamic> m) => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: const Color(0xFFE1ECE1), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      _iconRow(Icons.calendar_today, m['meeting_date'] ?? "TBD"),
      const SizedBox(height: 12),
      _iconRow(Icons.location_on_outlined, m['location'] ?? "Unknown"),
    ]),
  );

  Widget _iconRow(IconData i, String t) => Row(children: [Icon(i, size: 18, color: const Color(0xFF5D7A5D)), const SizedBox(width: 12), Text(t, style: const TextStyle(fontWeight: FontWeight.bold))]);
  
  Widget _buildInfoCard(bool d, String l, String v) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16), 
    decoration: BoxDecoration(color: d ? const Color(0xFF1F1F1F) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.05))), 
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 11, color: Colors.black38)), const SizedBox(height: 4), Text(v, style: TextStyle(color: d ? Colors.white : Colors.black87))])
  );
  
  Widget _actionBtn(String l, Color c, VoidCallback t, {bool isOutlined = false, Color? textColor, double opacity = 1.0}) => Opacity(
    opacity: opacity,
    child: SizedBox(
      width: double.infinity, 
      height: 54, 
      child: ElevatedButton(
        onPressed: t, 
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.white : c, 
          elevation: isOutlined ? 0 : 2, 
          side: isOutlined ? BorderSide(color: textColor ?? Colors.black12) : BorderSide.none, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
        ), 
        child: Text(l, style: TextStyle(color: textColor ?? (isOutlined ? Colors.black54 : Colors.white), fontWeight: FontWeight.bold))
      )
    ),
  );
}