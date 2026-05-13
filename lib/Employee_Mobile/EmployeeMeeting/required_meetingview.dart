import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme_provider.dart';
import 'MeetingAttendanceScreen.dart'; 
import 'cannotattend.dart'; 

class MeetingViewScreen extends StatelessWidget {
  final Map<String, dynamic> meeting;
  MeetingViewScreen({super.key, required this.meeting});

  final _supabase = Supabase.instance.client;

  // Design Colors
  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);
  final Color lightGreenBG = const Color(0xFFEAF7EA);
  final Color errorRed = const Color(0xFFD32F2F);

  // --- DATABASE LOGIC ---

  Future<void> _confirmAttendance(BuildContext context) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Upsert RSVP status to lowercase 'attending' and include updated_at
      await _supabase.from('meeting_rsvps').upsert({
        'meeting_id': meeting['id'],
        'user_id': userId,
        'status': 'attending', 
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (context.mounted) {
        // Return to the meetings list as requested
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Attendance confirmed!"),
            backgroundColor: Color(0xFF5D7A5D),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: Could not confirm attendance. $e"),
            backgroundColor: errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    // Safety checks for data formatting
    final String title = meeting['title'] ?? "Meeting Review";
    final rawDate = meeting['meeting_date'] ?? DateTime.now().toString();
    
    String formattedDate;
    try {
      formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(rawDate));
    } catch (_) {
      formattedDate = "N/A";
    }

    final String time = meeting['meeting_time'] ?? "N/A";
    final String location = meeting['location'] ?? "N/A";
    
    // Safe substring for Meeting ID to prevent "RangeError"
    final String fullId = (meeting['id'] ?? "000").toString();
    final String meetingId = fullId.length >= 3 
        ? fullId.substring(0, 3).toUpperCase() 
        : fullId.toUpperCase();
    
    final String createdBy = meeting['created_by_name'] ?? "Admin Team";
    final bool isMandatory = meeting['is_mandatory'] == true;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : lightGreenBG,
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
            Text("MTG-$meetingId", style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "RSVP Required", 
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Mandatory Notice
                  if (isMandatory)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: errorRed.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: errorRed.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: errorRed, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "This is a mandatory meeting. Your attendance is expected unless a valid justification is provided.",
                              style: TextStyle(
                                color: errorRed, 
                                fontSize: 13, 
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Info Row Card
                  _buildWhiteCard([
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildIconDetail(Icons.calendar_today_outlined, "Date", formattedDate),
                        _buildIconDetail(Icons.access_time, "Time", time),
                        _buildIconDetail(Icons.location_on_outlined, "Location", location),
                      ],
                    ),
                  ]),

                  const Text("Organized by", style: TextStyle(color: Colors.black38, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(createdBy, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                  const SizedBox(height: 24),

                  const Text("Agenda Description", style: TextStyle(color: Colors.black38, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(
                    meeting['agenda'] ?? "No agenda description provided for this meeting.",
                    style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Meeting Agenda PDF Card
                  const Text("Meeting Agenda", style: TextStyle(color: Colors.black38, fontSize: 12)),
                  const SizedBox(height: 12),
                  _buildAgendaFile(createdBy),
                ],
              ),
            ),
          ),

          // Bottom Action Buttons (Fixed Footer)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05), 
                  blurRadius: 10, 
                  offset: const Offset(0, -4)
                )
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _confirmAttendance(context), 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: forestGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text("Confirm Attendance", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (_) => CannotAttendScreen(meeting: meeting))
                    ),
                    child: const Text("I cannot attend this meeting", style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildAgendaFile(String creator) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, 
      borderRadius: BorderRadius.circular(12), 
      border: Border.all(color: Colors.black.withOpacity(0.05)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Icon(Icons.description_outlined, color: forestGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Meeting_Agenda_Final.pdf", style: TextStyle(fontSize: 14, color: Colors.black87)),
                  Text("Uploaded by $creator", style: const TextStyle(fontSize: 10, color: Colors.black38)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, 
          child: OutlinedButton.icon(
            onPressed: () {}, 
            icon: const Icon(Icons.download, size: 18), 
            label: const Text("Download Agenda"), 
            style: OutlinedButton.styleFrom(
              foregroundColor: forestGreen, 
              side: BorderSide(color: forestGreen.withOpacity(0.5)),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildWhiteCard(List<Widget> children) => Container(
    width: double.infinity, 
    padding: const EdgeInsets.all(20), 
    margin: const EdgeInsets.only(bottom: 24), 
    decoration: BoxDecoration(
      color: Colors.white, 
      borderRadius: BorderRadius.circular(12), 
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03), 
          blurRadius: 10, 
          offset: const Offset(0, 4)
        )
      ],
    ), 
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _buildIconDetail(IconData icon, String label, String value) => Column(
    children: [
      Icon(icon, color: forestGreen, size: 20), 
      const SizedBox(height: 8), 
      Text(label, style: const TextStyle(color: Colors.black38, fontSize: 10)), 
      Text(value, style: const TextStyle(color: Colors.black87, fontSize: 12)),
    ],
  );
}