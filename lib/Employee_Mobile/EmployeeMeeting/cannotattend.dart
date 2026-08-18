import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme_provider.dart';
import 'cannotattendview.dart';
import '../../../services/error_handler.dart';

class CannotAttendScreen extends StatefulWidget {
  final Map<String, dynamic> meeting;
  const CannotAttendScreen({super.key, required this.meeting});
  @override
  State<CannotAttendScreen> createState() => _CannotAttendScreenState();
}

class _CannotAttendScreenState extends State<CannotAttendScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);
  final Color lightGreenBG = const Color(0xFFEAF7EA);
  final Color errorRed = const Color(0xFFD32F2F);

  Future<void> _submitReason() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Upsert to match your NatureLink database schema
      await _supabase.from('meeting_rsvps').upsert(
        {
          'meeting_id': widget.meeting['id'],
          'user_id': userId,
          'status': 'declined', 
          'reason': _reasonController.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'meeting_id,user_id',
      );

      if (mounted) {
        // Return to the meetings list as requested
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Justification submitted successfully"),
            backgroundColor: Color(0xFF5D7A5D),
          ),
        );
      }
    } catch (e) {
      debugPrint("Supabase Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showError(context, e);
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final String title = widget.meeting['title'] ?? "Review Meeting";
    final rawDate = widget.meeting['meeting_date'] ?? DateTime.now().toString();
    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(rawDate));
    final String time = widget.meeting['meeting_time'] ?? "N/A";
    final bool isMandatory = widget.meeting['is_mandatory'] ?? true;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : lightGreenBG,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : darkGreen, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Absence Justification",
          style: TextStyle(color: isDark ? Colors.white : darkGreen, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMandatory)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: errorRed.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: errorRed.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: errorRed, size: 20),
                          const SizedBox(width: 12),
                          // FIXED: Removed 'const' here to allow use of errorRed variable
                          Expanded(
                            child: Text(
                              "This is a mandatory meeting. Please explain why you cannot attend.",
                              style: TextStyle(color: errorRed, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                        Text(
                          "$formattedDate • $time",
                          style: const TextStyle(fontSize: 12, color: Colors.black38),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text("Reason for absence *", style: TextStyle(fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: TextField(
                      controller: _reasonController,
                      maxLines: 6,
                      onChanged: (v) => setState(() {}),
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      decoration: const InputDecoration(
                        hintText: "Please provide a detailed justification...",
                        contentPadding: EdgeInsets.all(16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Minimum of 30 characters",
                        style: TextStyle(
                          fontSize: 11,
                          color: _reasonController.text.length < 30 ? Colors.black26 : forestGreen,
                        ),
                      ),
                      Text(
                        "${_reasonController.text.length} characters",
                        style: const TextStyle(fontSize: 11, color: Colors.black26),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _reasonController.text.length < 30 || _isLoading ? null : _submitReason,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      disabledBackgroundColor: Colors.black12,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text("Submit", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel", style: TextStyle(color: Colors.black38, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}