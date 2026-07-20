import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../User_Mobile/notification.dart';
import '../Employee_Mobile/EmployeeNotification/employeenotif.dart';

class UserNotificationBadge extends StatelessWidget {
  final Color iconColor;
  const UserNotificationBadge({super.key, this.iconColor = const Color(0xFF303D32)});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    final iconButton = IconButton(
      icon: Icon(Icons.notifications_none, color: iconColor, size: 26),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
    );

    if (userId == null) return iconButton;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('audit_logs_with_roles').stream(primaryKey: ['id']).eq('user_id', userId),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          final rawNotifs = snapshot.data!.where((n) => 
            n['user_id'] == userId &&
            n['user_role'] != 'admin'
          ).toList();
          final allNotifs = rawNotifs.where((notif) {
            final text = '${notif['title']} ${notif['message'] ?? notif['description']} ${notif['type'] ?? notif['category']} ${notif['action']}'.toLowerCase();
            return text.contains('profile') || text.contains('plant');
          }).toList();
          unreadCount = allNotifs.where((n) => !(n['is_read'] ?? false)).length;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            iconButton,
            if (unreadCount > 0)
              Positioned(
                top: 4,
                right: 4,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class EmployeeNotificationBadge extends StatelessWidget {
  final Color iconColor;
  const EmployeeNotificationBadge({super.key, this.iconColor = Colors.black87});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    final iconButton = IconButton(
      icon: Icon(Icons.notifications_none_outlined, color: iconColor, size: 26),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeNotifications())),
    );

    if (userId == null) return iconButton;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('meetings').stream(primaryKey: ['id']),
      builder: (context, meetingSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase.from('field_entries').stream(primaryKey: ['id']).eq('user_id', userId),
          builder: (context, entrySnapshot) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('audit_logs_with_roles').stream(primaryKey: ['id']),
              builder: (context, auditSnapshot) {
                int unreadCount = 0;
                final Set<String> addedKeys = {};

                // 1. Meetings (MoM)
                final rawMeetings = meetingSnapshot.data ?? [];
                for (final m in rawMeetings) {
                  final String mId = m['id'].toString();
                  final String mCreatedAt = m['created_at'] ?? DateTime.now().toIso8601String();
                  final DateTime itemDt = DateTime.tryParse(mCreatedAt) ?? DateTime.now();
                  final String? minutes = m['minutes']?.toString().trim();
                  final String? momUrl = m['mom_attachment_url']?.toString().trim();

                  if ((minutes != null && minutes.isNotEmpty) || (momUrl != null && momUrl.isNotEmpty)) {
                    final momKey = 'mtg_mom_$mId';
                    if (!addedKeys.contains(momKey) && 
                        !EmployeeNotifications.globalDismissedIds.contains(momKey) &&
                        (EmployeeNotifications.globalClearedAt == null || itemDt.isAfter(EmployeeNotifications.globalClearedAt!))) {
                      addedKeys.add(momKey);
                      unreadCount++;
                    }
                  }
                }

                // 2. Field Entries (Current User)
                final rawEntries = entrySnapshot.data ?? [];
                for (final e in rawEntries) {
                  final String eId = e['id'].toString();
                  final String status = (e['status'] ?? '').toString().toUpperCase();
                  final String updatedAt = e['updated_at'] ?? e['created_at'] ?? DateTime.now().toIso8601String();
                  final DateTime itemDt = DateTime.tryParse(updatedAt) ?? DateTime.now();
                  final bool isRead = e['is_read'] == true;

                  if (isRead) continue;

                  if (status == 'VALIDATED' || status == 'APPROVED' || status == 'ACCEPTED') {
                    final appKey = 'entry_app_$eId';
                    if (!addedKeys.contains(appKey) && 
                        !EmployeeNotifications.globalDismissedIds.contains(appKey) &&
                        (EmployeeNotifications.globalClearedAt == null || itemDt.isAfter(EmployeeNotifications.globalClearedAt!))) {
                      addedKeys.add(appKey);
                      unreadCount++;
                    }
                  } else if (status == 'REJECTED') {
                    final rejKey = 'entry_rej_$eId';
                    if (!addedKeys.contains(rejKey) && 
                        !EmployeeNotifications.globalDismissedIds.contains(rejKey) &&
                        (EmployeeNotifications.globalClearedAt == null || itemDt.isAfter(EmployeeNotifications.globalClearedAt!))) {
                      addedKeys.add(rejKey);
                      unreadCount++;
                    }
                  } else if (status == 'FLAGGED' || status == 'PENDING' || status == 'UNDER REVIEW' || status == 'NEEDS_REVIEW') {
                    final revKey = 'entry_rev_$eId';
                    if (!addedKeys.contains(revKey) && 
                        !EmployeeNotifications.globalDismissedIds.contains(revKey) &&
                        (EmployeeNotifications.globalClearedAt == null || itemDt.isAfter(EmployeeNotifications.globalClearedAt!))) {
                      addedKeys.add(revKey);
                      unreadCount++;
                    }
                  }
                }

                // 3. Audit Logs (MoM updates)
                final rawAudits = auditSnapshot.data ?? [];
                for (final log in rawAudits) {
                  final String logId = log['id']?.toString() ?? '';
                  final String title = (log['title'] ?? '').toString();
                  final String msg = (log['message'] ?? log['description'] ?? log['action'] ?? '').toString();
                  final String text = '$title $msg'.toLowerCase();
                  final String createdAt = log['created_at'] ?? DateTime.now().toIso8601String();
                  final DateTime itemDt = DateTime.tryParse(createdAt) ?? DateTime.now();
                  final bool isRead = log['is_read'] == true;

                  if (isRead) continue;

                  if (text.contains('meeting minutes') || text.contains('mom updated') || text.contains('minutes updated')) {
                    final logKey = 'audit_mom_$logId';
                    if (!addedKeys.contains(logKey) && 
                        !EmployeeNotifications.globalDismissedIds.contains(logKey) &&
                        (EmployeeNotifications.globalClearedAt == null || itemDt.isAfter(EmployeeNotifications.globalClearedAt!))) {
                      addedKeys.add(logKey);
                      unreadCount++;
                    }
                  }
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    iconButton,
                    if (unreadCount > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
