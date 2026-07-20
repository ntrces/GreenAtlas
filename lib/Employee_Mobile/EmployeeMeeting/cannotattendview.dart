import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme_provider.dart';

class CannotAttendViewScreen extends StatelessWidget {
  final Map<String, dynamic> meeting;

  const CannotAttendViewScreen({super.key, required this.meeting});

  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);
  final Color lightGreenBG = const Color(0xFFEAF7EA);
  final Color errorRed = const Color(0xFFD32F2F);

  bool _checkIsMeetingDone(Map<String, dynamic> meeting) {
    if (meeting['is_completed'] == true) return true;
    final String? status = meeting['status']?.toString().toUpperCase();
    if (status == 'COMPLETED' || status == 'DONE') return true;

    try {
      final rawDate = meeting['meeting_date']?.toString();
      if (rawDate != null) {
        final mDate = DateTime.parse(rawDate);
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);
        if (mDate.isBefore(startOfToday)) {
          return true;
        }
      }
    } catch (_) {}

    return false;
  }

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

    final bool isDone = _checkIsMeetingDone(meeting);
    final String? status = meeting['status']?.toString();
    final bool isCancelled = status?.toUpperCase() == 'CANCELLED';

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
                  // Status Pill (Declined/Not Attending or Completed)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCancelled 
                              ? errorRed.withOpacity(0.15) 
                              : (isDone ? Colors.grey.withOpacity(0.2) : errorRed.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isCancelled 
                              ? "Cancelled" 
                              : (isDone ? "Meeting Completed" : "Not Attending"), 
                          style: TextStyle(
                            color: isCancelled ? errorRed : (isDone ? Colors.grey[700] : errorRed), 
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (isDone && !isCancelled)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.grey, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Meeting Already Done",
                                  style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "This meeting took place in the past or has concluded. Responses are now closed.",
                                  style: TextStyle(color: Colors.black54, fontSize: 12),
                                ),
                              ],
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

                  // Minutes of Meeting (MoM) Section
                  _buildMinutesOfMeetingSection(meeting, isDark),
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
            child: (isDone || isCancelled)
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.lock_clock_outlined, size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          "Meeting Already Done — Responses Closed",
                          style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Want to change your response?", style: TextStyle(color: Colors.black38, fontSize: 12)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Logic to change back to attending
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

  Widget _buildMinutesOfMeetingSection(Map<String, dynamic> meetingData, bool isDark) {
    final String? minutesText = meetingData['minutes']?.toString().trim();
    final String? momUrl = meetingData['mom_attachment_url']?.toString().trim();
    final bool hasMinutesText = minutesText != null && minutesText.isNotEmpty;
    final bool hasMomUrl = momUrl != null && momUrl.isNotEmpty;

    if (!hasMinutesText && !hasMomUrl) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(Icons.assignment_turned_in_outlined, color: forestGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              "Minutes of the Meeting (MoM)",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : darkGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (hasMinutesText)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: forestGreen.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildMoMBody(minutesText, isDark),
          ),
        if (hasMomUrl)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Minutes_of_Meeting_Attachment.pdf",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          const Text("Official MoM Document", style: TextStyle(fontSize: 10, color: Colors.black38)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(momUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.download, size: 18, color: Colors.white),
                    label: const Text("View / Download MoM Document"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: forestGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMoMBody(String rawMinutes, bool isDark) {
    Map<String, dynamic>? parsed;
    try {
      if (rawMinutes.startsWith('{')) {
        final decoded = jsonDecode(rawMinutes);
        if (decoded is Map<String, dynamic>) {
          parsed = decoded;
        }
      }
    } catch (_) {}

    if (parsed != null) {
      final List<Widget> items = [];

      final orderAt = parsed['calledToOrderAt']?.toString().trim();
      final orderBy = parsed['calledToOrderBy']?.toString().trim();
      final attendees = parsed['attendees']?.toString().trim();
      final absentees = parsed['absentees']?.toString().trim();

      if ((orderAt != null && orderAt.isNotEmpty) ||
          (orderBy != null && orderBy.isNotEmpty) ||
          (attendees != null && attendees.isNotEmpty) ||
          (absentees != null && absentees.isNotEmpty)) {
        items.add(_buildMoMSectionHeader("1. Call to Order & Roll Call", isDark));
        if (orderAt != null && orderAt.isNotEmpty) {
          items.add(_buildMoMBullet("Called to order at:", orderAt, isDark));
        }
        if (orderBy != null && orderBy.isNotEmpty) {
          items.add(_buildMoMBullet("Presided by:", orderBy, isDark));
        }
        if (attendees != null && attendees.isNotEmpty) {
          items.add(_buildMoMBullet("Attendees:", attendees, isDark));
        }
        if (absentees != null && absentees.isNotEmpty) {
          items.add(_buildMoMBullet("Absentees:", absentees, isDark));
        }
        items.add(const SizedBox(height: 10));
      }

      final topics = parsed['topics']?.toString().trim();
      if (topics != null && topics.isNotEmpty) {
        items.add(_buildMoMSectionHeader("2. Topics Discussed", isDark));
        items.add(Text(topics, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87, height: 1.4)));
        items.add(const SizedBox(height: 10));
      }

      final decisions = parsed['decisions']?.toString().trim();
      if (decisions != null && decisions.isNotEmpty) {
        items.add(_buildMoMSectionHeader("3. Key Decisions Made", isDark));
        items.add(Text(decisions, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87, height: 1.4)));
        items.add(const SizedBox(height: 10));
      }

      final actionItems = parsed['actionItems']?.toString().trim();
      if (actionItems != null && actionItems.isNotEmpty) {
        items.add(_buildMoMSectionHeader("4. Action Items & Assignments", isDark));
        items.add(Text(actionItems, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87, height: 1.4)));
        items.add(const SizedBox(height: 10));
      }

      final adjournedAt = parsed['adjournedAt']?.toString().trim();
      final nextMeeting = parsed['nextMeeting']?.toString().trim();
      if ((adjournedAt != null && adjournedAt.isNotEmpty) ||
          (nextMeeting != null && nextMeeting.isNotEmpty)) {
        items.add(_buildMoMSectionHeader("5. Adjournment", isDark));
        if (adjournedAt != null && adjournedAt.isNotEmpty) {
          items.add(_buildMoMBullet("Adjourned at:", adjournedAt, isDark));
        }
        if (nextMeeting != null && nextMeeting.isNotEmpty) {
          items.add(_buildMoMBullet("Next Meeting:", nextMeeting, isDark));
        }
      }

      if (items.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items,
        );
      }
    }

    return Text(
      rawMinutes,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 13,
        height: 1.5,
      ),
    );
  }

  Widget _buildMoMSectionHeader(String title, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: forestGreen,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _buildMoMBullet(String label, String val, bool isDark) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("• ", style: TextStyle(fontSize: 12, color: forestGreen, fontWeight: FontWeight.bold)),
        Text("$label ", style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
        Expanded(
          child: Text(
            val,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
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