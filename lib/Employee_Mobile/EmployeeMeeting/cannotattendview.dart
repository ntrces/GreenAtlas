import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../theme_provider.dart';

class CannotAttendViewScreen extends StatelessWidget {
  final Map<String, dynamic> meeting;

  const CannotAttendViewScreen({super.key, required this.meeting});

  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);
  final Color lightGreenBG = const Color(0xFFEAF7EA);
  final Color errorRed = const Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final String title = meeting['title'] ?? "Monthly Review";
    final rawDate = meeting['meeting_date'] ?? DateTime.now().toString();
    final formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(rawDate));
    final String time = meeting['meeting_time'] ?? "N/A";
    final String location = meeting['location'] ?? "N/A";
    
    final String fullId = (meeting['id'] ?? "000").toString();
    final String meetingId = fullId.length > 3 ? fullId.substring(0, 3).toUpperCase() : fullId.toUpperCase();
    final String createdBy = meeting['created_by_name'] ?? "Admin Team";

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
                  // Status Pill (Declined/Not Attending)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Not Attending", 
                          style: TextStyle(color: errorRed, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

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
                  Text(createdBy, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                  const SizedBox(height: 24),

                  const Text("Agenda Description", style: TextStyle(color: Colors.black38, fontSize: 12)),
                  Text(
                    meeting['agenda'] ?? "No agenda description provided.",
                    style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Status Alert Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: errorRed.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: errorRed.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12, 
                          backgroundColor: errorRed, 
                          child: const Icon(Icons.close, color: Colors.white, size: 14)
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("You're not attending", style: TextStyle(color: errorRed, fontSize: 14)),
                            const Text("Justification submitted", style: TextStyle(color: Colors.black38, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Want to change your response?", style: TextStyle(color: Colors.black38, fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Button to change back to attending
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Logic to change back to attending can be added here
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: forestGreen),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text("I will attend", style: TextStyle(color: forestGreen, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Current Status (Disabled Button)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: errorRed.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text("Not Attending", style: TextStyle(color: errorRed, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteCard(List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.only(bottom: 24),
    decoration: BoxDecoration(
      color: Colors.white, 
      borderRadius: BorderRadius.circular(12), 
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
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