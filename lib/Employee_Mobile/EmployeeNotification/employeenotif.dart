import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme_provider.dart';
import '../../components/notification_badge.dart';
import '../Field_Diary/Employee_FieldDiary.dart';
import '../Field_Diary/Sent/sent0.dart';
import '../EmployeeMeeting/Employee_Meetings.dart';
import '../EmployeeMeeting/required_meetingview.dart';
import '../../UserProfile/user_profile.dart';

class EmployeeNotifications extends StatefulWidget {
  const EmployeeNotifications({super.key});

  // Global static state to persist cleared/dismissed notifications across screen re-opens
  static final Set<String> globalDismissedIds = {};
  static DateTime? globalClearedAt;

  @override
  State<EmployeeNotifications> createState() => _EmployeeNotificationsState();
}

class _EmployeeNotificationsState extends State<EmployeeNotifications> {
  final _supabase = Supabase.instance.client;
  String? get _userId => _supabase.auth.currentUser?.id;

  Future<void> _clearAll() async {
    final now = DateTime.now();
    setState(() {
      EmployeeNotifications.globalClearedAt = now;
    });
    NotificationStateNotifier.instance.clearAll();

    if (_userId != null) {
      try {
        await _supabase
            .from('audit_logs')
            .update({'is_read': true})
            .eq('user_id', _userId!)
            .eq('is_read', false);
      } catch (e) {
        debugPrint('Error marking notifications: $e');
      }
    }
  }

  void _dismissSingle(String notifId) async {
    setState(() {
      EmployeeNotifications.globalDismissedIds.add(notifId);
    });
    NotificationStateNotifier.instance.dismissSingle(notifId);

    if (_userId != null) {
      try {
        await _supabase
            .from('audit_logs')
            .update({'is_read': true})
            .eq('id', notifId);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        centerTitle: true,
        title: Text(
          "Notifications",
          style: textTheme.titleLarge?.copyWith(
            color: isDark ? Colors.white : const Color(0xFF2D3E2D),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _clearAll,
            child: Text(
              "Clear all", 
              style: textTheme.labelLarge?.copyWith(color: const Color(0xFF5D7A5D), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _userId == null
          ? const Center(child: Text("Please login to see notifications."))
          : AnimatedBuilder(
              animation: NotificationStateNotifier.instance,
              builder: (context, _) {
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabase
                      .from('meetings')
                      .stream(primaryKey: ['id'])
                      .order('created_at', ascending: false),
                  builder: (context, meetingSnapshot) {
                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _supabase
                          .from('field_entries')
                          .stream(primaryKey: ['id'])
                          .eq('user_id', _userId!)
                          .order('created_at', ascending: false),
                      builder: (context, entrySnapshot) {
                        return StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _supabase
                              .from('audit_logs_with_roles')
                              .stream(primaryKey: ['id'])
                              .order('created_at', ascending: false),
                          builder: (context, auditSnapshot) {
                            if (meetingSnapshot.connectionState == ConnectionState.waiting &&
                                entrySnapshot.connectionState == ConnectionState.waiting &&
                                auditSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: Color(0xFF5D7A5D)));
                            }

                            final notifier = NotificationStateNotifier.instance;

                            final List<Map<String, dynamic>> notifications = [];
                            final Set<String> addedKeys = {};

                            // Helper check function
                            bool isItemValid(String key, DateTime dt) {
                              if (addedKeys.contains(key)) return false;
                              if (EmployeeNotifications.globalDismissedIds.contains(key) || notifier.dismissedIds.contains(key)) return false;
                              if (EmployeeNotifications.globalClearedAt != null && !dt.isAfter(EmployeeNotifications.globalClearedAt!)) return false;
                              if (notifier.clearedAt != null && !dt.isAfter(notifier.clearedAt!)) return false;
                              return true;
                            }

                            // 1. MEETINGS TABLE: Minutes of Meeting Posted Only
                            final rawMeetings = meetingSnapshot.data ?? [];
                            for (final m in rawMeetings) {
                              final String mId = m['id'].toString();
                              final String mTitle = m['title'] ?? 'Meeting';
                              final String mCreatedAt = m['created_at'] ?? DateTime.now().toIso8601String();
                              final DateTime itemDt = DateTime.tryParse(mCreatedAt) ?? DateTime.now();
                              final String? minutes = m['minutes']?.toString().trim();
                              final String? momUrl = m['mom_attachment_url']?.toString().trim();

                              if ((minutes != null && minutes.isNotEmpty) || (momUrl != null && momUrl.isNotEmpty)) {
                                final momKey = 'mtg_mom_$mId';
                                if (isItemValid(momKey, itemDt)) {
                                  addedKeys.add(momKey);
                                  notifications.add({
                                    'id': momKey,
                                    'title': 'Minutes of Meeting Posted',
                                    'message': 'Official Minutes of Meeting (MoM) have been posted for "$mTitle". Tap to view details.',
                                    'type': 'meeting_mom',
                                    'created_at': mCreatedAt,
                                    'is_read': false,
                                    'target': 'meeting',
                                    'meeting_data': m,
                                  });
                                }
                              }
                            }

                            // 2. FIELD ENTRIES: Entry Approved, Entry Rejected, Entry Flagged for Review (Current User)
                            final rawEntries = entrySnapshot.data ?? [];
                            for (final e in rawEntries) {
                              final String eId = e['id'].toString();
                              final String species = e['species_name'] ?? e['plant_type'] ?? 'Observation Entry';
                              final String status = (e['status'] ?? '').toString().toUpperCase();
                              final String updatedAt = e['updated_at'] ?? e['created_at'] ?? DateTime.now().toIso8601String();
                              final DateTime itemDt = DateTime.tryParse(updatedAt) ?? DateTime.now();

                              // Entry Approved
                              if (status == 'VALIDATED' || status == 'APPROVED' || status == 'ACCEPTED') {
                                final appKey = 'entry_app_$eId';
                                if (isItemValid(appKey, itemDt)) {
                                  addedKeys.add(appKey);
                                  notifications.add({
                                    'id': appKey,
                                    'title': 'Observation Entry Approved',
                                    'message': 'Your field entry for "$species" has been validated and approved.',
                                    'type': 'entry_validated',
                                    'created_at': updatedAt,
                                    'is_read': false,
                                    'target': 'entry',
                                    'entry_id': eId,
                                    'entry_data': e,
                                  });
                                }
                              } 
                              // Entry Rejected
                              else if (status == 'REJECTED') {
                                final String reason = (e['rejection_reason'] ?? e['rejection_remarks'] ?? e['admin_feedback'] ?? e['remarks'] ?? 'Needs correction').toString();
                                final rejKey = 'entry_rej_$eId';
                                if (isItemValid(rejKey, itemDt)) {
                                  addedKeys.add(rejKey);
                                  notifications.add({
                                    'id': rejKey,
                                    'title': 'Observation Entry Rejected',
                                    'message': 'Your field entry for "$species" was rejected. Reason: $reason',
                                    'type': 'entry_rejected',
                                    'created_at': updatedAt,
                                    'is_read': false,
                                    'target': 'entry',
                                    'entry_id': eId,
                                    'entry_data': e,
                                  });
                                }
                              } 
                              // Entry Flagged for Review
                              else if (status == 'FLAGGED' || status == 'PENDING' || status == 'UNDER REVIEW' || status == 'NEEDS_REVIEW') {
                                final revKey = 'entry_rev_$eId';
                                if (isItemValid(revKey, itemDt)) {
                                  addedKeys.add(revKey);
                                  notifications.add({
                                    'id': revKey,
                                    'title': 'Observation Flagged for Review',
                                    'message': 'Your field entry for "$species" has been flagged for administrative review.',
                                    'type': 'entry_review',
                                    'created_at': updatedAt,
                                    'is_read': false,
                                    'target': 'entry',
                                    'entry_id': eId,
                                    'entry_data': e,
                                  });
                                }
                              }
                            }

                            // 3. AUDIT LOGS: MoM / Minutes Updates Only
                            final rawAudits = auditSnapshot.data ?? [];
                            for (final log in rawAudits) {
                              final String logId = log['id']?.toString() ?? UniqueKey().toString();
                              final String title = (log['title'] ?? '').toString();
                              final String msg = (log['message'] ?? log['description'] ?? log['action'] ?? '').toString();
                              final String text = '$title $msg'.toLowerCase();
                              final String createdAt = log['created_at'] ?? DateTime.now().toIso8601String();
                              final DateTime itemDt = DateTime.tryParse(createdAt) ?? DateTime.now();

                              if (text.contains('meeting minutes') || text.contains('mom updated') || text.contains('minutes updated')) {
                                final logKey = 'audit_mom_$logId';
                                if (isItemValid(logKey, itemDt)) {
                                  addedKeys.add(logKey);
                                  notifications.add({
                                    'id': logKey,
                                    'title': 'Minutes of Meeting Posted',
                                    'message': msg.isNotEmpty ? msg : 'New Minutes of Meeting have been posted by admin.',
                                    'type': 'meeting_mom',
                                    'created_at': createdAt,
                                    'is_read': false,
                                    'target': 'meeting',
                                  });
                                }
                              }
                            }

                            // Sort newest first
                            notifications.sort((a, b) {
                              final dtA = DateTime.tryParse(a['created_at']) ?? DateTime.now();
                              final dtB = DateTime.tryParse(b['created_at']) ?? DateTime.now();
                              return dtB.compareTo(dtA);
                            });

                            if (notifications.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No notifications yet", 
                                      style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: notifications.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5),
                              itemBuilder: (context, index) {
                                final notif = notifications[index];
                                return _buildNotificationItem(notif, isDark, textTheme);
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notif, bool isDark, TextTheme textTheme) {
    final String type = notif['type']?.toString() ?? 'info';
    final DateTime createdAt = DateTime.tryParse(notif['created_at']) ?? DateTime.now();
    
    IconData icon;
    Color iconColor;
    String badgeLabel;
    Color badgeColor;

    switch (type) {
      case 'meeting_mom':
        icon = Icons.assignment_turned_in_outlined;
        iconColor = const Color(0xFF5D7A5D);
        badgeLabel = "MoM POSTED";
        badgeColor = const Color(0xFF5D7A5D);
        break;
      case 'entry_validated':
        icon = Icons.check_circle_outline;
        iconColor = const Color(0xFF4CAF50);
        badgeLabel = "APPROVED";
        badgeColor = const Color(0xFF4CAF50);
        break;
      case 'entry_rejected':
        icon = Icons.cancel_outlined;
        iconColor = const Color(0xFFF44336);
        badgeLabel = "REJECTED";
        badgeColor = const Color(0xFFF44336);
        break;
      case 'entry_review':
        icon = Icons.rate_review_outlined;
        iconColor = Colors.orange;
        badgeLabel = "FLAGGED FOR REVIEW";
        badgeColor = Colors.orange;
        break;
      default:
        icon = Icons.info_outline;
        iconColor = Colors.blueGrey;
        badgeLabel = "NOTICE";
        badgeColor = Colors.blueGrey;
    }

    return Container(
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.12),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notif['title'] ?? 'Notification',
                style: textTheme.titleMedium?.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              notif['message'] ?? '',
              style: textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('MMM d, yyyy • h:mm a').format(createdAt),
              style: textTheme.labelSmall?.copyWith(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
        onTap: () {
          // 1. Permanently dismiss this notification item
          _dismissSingle(notif['id'].toString());

          // 2. Open destination screen with specific data highlighted
          final target = notif['target']?.toString() ?? '';
          if (target == 'meeting' || type.startsWith('meeting_')) {
            final Map<String, dynamic> meetingData = notif['meeting_data'] ?? {};
            if (meetingData.isNotEmpty) {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => MeetingViewScreen(meeting: meetingData, highlightMoM: true))
              );
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetingsScreen()));
            }
          } else if (target == 'entry' || type.startsWith('entry_')) {
            final String entryId = notif['entry_id']?.toString() ?? '';
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => SentListScreen(highlightEntryId: entryId))
            );
          }
        },
      ),
    );
  }
}