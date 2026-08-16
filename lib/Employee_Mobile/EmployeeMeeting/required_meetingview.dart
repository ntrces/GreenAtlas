import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme_provider.dart';
import 'cannotattend.dart'; 

class MeetingViewScreen extends StatefulWidget {
  final Map<String, dynamic> meeting;
  final bool highlightMoM;
  const MeetingViewScreen({super.key, required this.meeting, this.highlightMoM = false});

  @override
  State<MeetingViewScreen> createState() => _MeetingViewScreenState();
}

class _MeetingViewScreenState extends State<MeetingViewScreen> {
  final _supabase = Supabase.instance.client;

  bool _isSubmitting = false;
  late String? _userStatus;

  // Design Colors
  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);
  final Color lightGreenBG = const Color(0xFFEAF7EA);
  final Color errorRed = const Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _userStatus = widget.meeting['user_status']?.toString();
  }

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

  // --- DATABASE LOGIC ---

  Future<void> _confirmAttendance() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSubmitting = true);

    try {
      await _supabase.from('meeting_rsvps').upsert(
        {
          'meeting_id': widget.meeting['id'],
          'user_id': userId,
          'status': 'attending', 
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'meeting_id,user_id',
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _userStatus = 'attending';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Attendance confirmed! You are marked as attending."),
            backgroundColor: Color(0xFF5D7A5D),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
    
    final String title = widget.meeting['title'] ?? "Meeting Review";
    final rawDate = widget.meeting['meeting_date'] ?? DateTime.now().toString();
    
    String formattedDate;
    try {
      formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(rawDate));
    } catch (_) {
      formattedDate = "N/A";
    }

    final String time = widget.meeting['meeting_time'] ?? "N/A";
    final String location = widget.meeting['location'] ?? "N/A";
    
    final String fullId = (widget.meeting['id'] ?? "000").toString();
    final String meetingId = fullId.length >= 3 
        ? fullId.substring(0, 3).toUpperCase() 
        : fullId.toUpperCase();
    
    final String createdBy = widget.meeting['created_by_name'] ?? "Admin Team";
    final bool isMandatory = widget.meeting['is_mandatory'] == true;
    final String? status = widget.meeting['status']?.toString();
    final String? cancelReason = widget.meeting['cancellation_reason']?.toString();
    final String? virtualLink = widget.meeting['virtual_link']?.toString();

    final bool isCancelled = status?.toUpperCase() == 'CANCELLED';
    final bool isDone = _checkIsMeetingDone(widget.meeting);
    final bool isAttending = _userStatus?.toLowerCase() == 'attending';
    final bool isDeclined = _userStatus?.toLowerCase() == 'declined';

    // Status Pill Formatting
    String statusPillText = "RSVP Required";
    Color statusPillBg = Colors.orange.withOpacity(0.15);
    Color statusPillFg = Colors.orange;

    if (isCancelled) {
      statusPillText = "Cancelled";
      statusPillBg = errorRed.withOpacity(0.15);
      statusPillFg = errorRed;
    } else if (isDone) {
      statusPillText = "Meeting Completed";
      statusPillBg = Colors.grey.withOpacity(0.2);
      statusPillFg = Colors.grey[700]!;
    } else if (isAttending) {
      statusPillText = "Attending";
      statusPillBg = forestGreen.withOpacity(0.15);
      statusPillFg = forestGreen;
    } else if (isDeclined) {
      statusPillText = "Not Attending";
      statusPillBg = errorRed.withOpacity(0.15);
      statusPillFg = errorRed;
    }

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
                          color: statusPillBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusPillText, 
                          style: TextStyle(
                            color: statusPillFg, 
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Cancellation Notice if Cancelled
                  if (isCancelled || (cancelReason != null && cancelReason.isNotEmpty))
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: errorRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: errorRed.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cancel_outlined, color: errorRed, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Meeting Cancelled", style: TextStyle(color: errorRed, fontSize: 14, fontWeight: FontWeight.bold)),
                                if (cancelReason != null && cancelReason.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(cancelReason, style: TextStyle(color: errorRed, fontSize: 12)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Attending Notice Banner (If confirmed attending and active)
                  if (isAttending && !isDone && !isCancelled)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: forestGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: forestGreen.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14, 
                            backgroundColor: forestGreen, 
                            child: const Icon(Icons.check, color: Colors.white, size: 16)
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "You're Attending This Meeting",
                                  style: TextStyle(color: Color(0xFF2D3E2D), fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Attendance has been confirmed. See you there!",
                                  style: TextStyle(color: Colors.black54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Completed Notice Banner (If Done and not cancelled)
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

                  // Mandatory Notice
                  if (isMandatory && !isCancelled && !isDone && !isAttending)
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

                  // Virtual Meeting Link if present
                  if (virtualLink != null && virtualLink.trim().isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.video_call_rounded, color: Colors.blue, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Virtual Meeting Link", style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(virtualLink, style: const TextStyle(color: Colors.black87, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final uri = Uri.parse(virtualLink);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: const Text("Join"),
                          ),
                        ],
                      ),
                    ),
                  ],

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
                    widget.meeting['agenda'] ?? "No agenda description provided for this meeting.",
                    style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Meeting Agenda PDF Card
                  const Text("Meeting Agenda", style: TextStyle(color: Colors.black38, fontSize: 12)),
                  const SizedBox(height: 12),
                  _buildAgendaFile(createdBy),

                  // Minutes of Meeting (MoM) Section
                  _buildMinutesOfMeetingSection(widget.meeting, isDark),
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
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting 
                              ? null 
                              : (isAttending 
                                  ? () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("You are already confirmed as attending!"),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    } 
                                  : _confirmAttendance), 
                          icon: _isSubmitting 
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Icon(isAttending ? Icons.check_circle : Icons.check, color: Colors.white),
                          label: Text(
                            _isSubmitting 
                                ? "Updating..." 
                                : (isAttending ? "Attending (Confirmed)" : "Confirm Attendance"), 
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: forestGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context, 
                            MaterialPageRoute(builder: (_) => CannotAttendScreen(meeting: widget.meeting))
                          ),
                          child: Text(
                            isAttending ? "Change response to 'Cannot Attend'" : "I cannot attend this meeting",
                            style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                          ),
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
        if (widget.highlightMoM) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade700, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, color: Colors.amber.shade800, size: 16),
                const SizedBox(width: 6),
                Text(
                  "Highlighted Notification Item — Minutes of Meeting",
                  style: TextStyle(color: Colors.amber.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
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
              color: widget.highlightMoM ? (isDark ? Colors.amber.withOpacity(0.08) : Colors.amber.shade50) : (isDark ? Colors.white10 : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.highlightMoM ? Colors.amber.shade600 : forestGreen.withOpacity(0.3), width: widget.highlightMoM ? 2.0 : 1.0),
              boxShadow: [
                BoxShadow(
                  color: widget.highlightMoM ? Colors.amber.withOpacity(0.18) : Colors.black.withOpacity(0.03),
                  blurRadius: widget.highlightMoM ? 12 : 10,
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

  Widget _buildAgendaFile(String creator) {
    final String? rawUrl = (
      widget.meeting['attachment_url'] ??
      widget.meeting['agenda_url'] ??
      widget.meeting['file_url'] ??
      widget.meeting['mom_attachment_url'] ??
      widget.meeting['pdf_url'] ??
      widget.meeting['url'] ??
      widget.meeting['document_url'] ??
      widget.meeting['link'] ??
      widget.meeting['attachment']
    )?.toString().trim();

    final bool hasUrl = rawUrl != null && rawUrl.isNotEmpty && rawUrl != "null";

    String fileName = "Meeting_Agenda_Final.pdf";
    if (hasUrl) {
      final uriName = Uri.tryParse(rawUrl)?.pathSegments.last;
      if (uriName != null && uriName.isNotEmpty) {
        fileName = Uri.decodeComponent(uriName);
      }
    }

    return Container(
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
              Icon(Icons.description_outlined, color: hasUrl ? forestGreen : Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasUrl ? fileName : "No File Attached", 
                      style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
              onPressed: hasUrl ? () async {
                try {
                  final uri = Uri.parse(rawUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    await launchUrl(uri, mode: LaunchMode.platformDefault);
                  }
                } catch (e) {
                  debugPrint("Error launching agenda URL: $e");
                }
              } : null, 
              icon: Icon(Icons.download, size: 18, color: hasUrl ? forestGreen : Colors.grey), 
              label: Text(
                hasUrl ? "Download Agenda" : "No Attachment Available", 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 13,
                  color: hasUrl ? forestGreen : Colors.black38,
                ),
              ), 
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: hasUrl ? forestGreen : Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
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