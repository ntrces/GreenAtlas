import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../User_Mobile/notification.dart';
import '../Employee_Mobile/EmployeeNotification/employeenotif.dart';
import '../services/user_session_service.dart';

class NotificationStateNotifier extends ChangeNotifier {
  static final NotificationStateNotifier instance = NotificationStateNotifier().._init();

  final Set<String> dismissedIds = {};
  DateTime? clearedAt;
  String? _loadedUserId;

  void _init() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? UserSessionService.currentUserId ?? 'default';
    _loadForUser(userId);
  }

  void ensureUserLoaded([String? userId]) {
    final effective = userId ?? Supabase.instance.client.auth.currentUser?.id ?? UserSessionService.currentUserId ?? 'default';
    if (_loadedUserId != effective) {
      _loadForUser(effective);
    }
  }

  Future<void> _loadForUser(String userId) async {
    _loadedUserId = userId;
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedClearedAt = prefs.getString('notif_cleared_at_$userId');
      if (savedClearedAt != null) {
        clearedAt = DateTime.tryParse(savedClearedAt);
      } else {
        clearedAt = null;
      }

      final savedDismissed = prefs.getStringList('notif_dismissed_ids_$userId');
      dismissedIds.clear();
      if (savedDismissed != null) {
        dismissedIds.addAll(savedDismissed);
      }
      notifyListeners();
    } catch (_) {}
  }

  void clearAll({List<String>? currentIds}) async {
    clearedAt = DateTime.now();
    if (currentIds != null) {
      dismissedIds.addAll(currentIds);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _loadedUserId ?? Supabase.instance.client.auth.currentUser?.id ?? UserSessionService.currentUserId ?? 'default';
      await prefs.setString('notif_cleared_at_$userId', clearedAt!.toIso8601String());
      await prefs.setStringList('notif_dismissed_ids_$userId', dismissedIds.toList());
    } catch (_) {}
  }

  void dismissSingle(String id) async {
    dismissedIds.add(id);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _loadedUserId ?? Supabase.instance.client.auth.currentUser?.id ?? UserSessionService.currentUserId ?? 'default';
      await prefs.setStringList('notif_dismissed_ids_$userId', dismissedIds.toList());
    } catch (_) {}
  }

  bool isUnread({required String id, required bool isRead, DateTime? createdAt}) {
    if (isRead) return false;
    if (dismissedIds.contains(id)) return false;
    if (clearedAt != null && createdAt != null && !createdAt.isAfter(clearedAt!)) {
      return false;
    }
    return true;
  }
}

class UserNotificationBadge extends StatelessWidget {
  final Color iconColor;
  const UserNotificationBadge({super.key, this.iconColor = const Color(0xFF303D32)});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? UserSessionService.currentUserId;

    final iconButton = IconButton(
      icon: Icon(Icons.notifications_none, color: iconColor, size: 26),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
    );

    if (userId == null) return iconButton;

    NotificationStateNotifier.instance.ensureUserLoaded(userId);

    return AnimatedBuilder(
      animation: NotificationStateNotifier.instance,
      builder: (context, _) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase.from('audit_logs_with_roles').stream(primaryKey: ['id']).eq('user_id', userId),
          builder: (context, snapshot) {
            int unreadCount = 0;
            if (snapshot.hasData) {
              final rawNotifs = snapshot.data!.where((n) => n['user_id'] == userId).toList();
              final notifier = NotificationStateNotifier.instance;
              unreadCount = rawNotifs.where((n) {
                final String id = n['id']?.toString() ?? '';
                final bool isRead = n['is_read'] == true;
                final DateTime? createdAt = DateTime.tryParse(n['created_at']?.toString() ?? '');
                return notifier.isUnread(id: id, isRead: isRead, createdAt: createdAt);
              }).length;
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
  }
}

class EmployeeNotificationBadge extends StatelessWidget {
  final Color iconColor;
  const EmployeeNotificationBadge({super.key, this.iconColor = Colors.black87});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? UserSessionService.currentUserId;

    final iconButton = IconButton(
      icon: Icon(Icons.notifications_none_outlined, color: iconColor, size: 26),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeNotifications())),
    );

    if (userId == null) return iconButton;

    NotificationStateNotifier.instance.ensureUserLoaded(userId);

    return AnimatedBuilder(
      animation: NotificationStateNotifier.instance,
      builder: (context, _) {
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
                    final notifier = NotificationStateNotifier.instance;

                    bool isItemUnread(String key, DateTime itemDt) {
                      if (addedKeys.contains(key)) return false;
                      if (notifier.dismissedIds.contains(key) || EmployeeNotifications.globalDismissedIds.contains(key)) return false;
                      if (notifier.clearedAt != null && !itemDt.isAfter(notifier.clearedAt!)) return false;
                      if (EmployeeNotifications.globalClearedAt != null && !itemDt.isAfter(EmployeeNotifications.globalClearedAt!)) return false;
                      return true;
                    }

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
                        if (isItemUnread(momKey, itemDt)) {
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
                        if (isItemUnread(appKey, itemDt)) {
                          addedKeys.add(appKey);
                          unreadCount++;
                        }
                      } else if (status == 'REJECTED') {
                        final rejKey = 'entry_rej_$eId';
                        if (isItemUnread(rejKey, itemDt)) {
                          addedKeys.add(rejKey);
                          unreadCount++;
                        }
                      } else if (status == 'FLAGGED' || status == 'PENDING' || status == 'UNDER REVIEW' || status == 'NEEDS_REVIEW') {
                        final revKey = 'entry_rev_$eId';
                        if (isItemUnread(revKey, itemDt)) {
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
                        if (isItemUnread(logKey, itemDt)) {
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
      },
    );
  }
}
