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
      icon: Icon(Icons.notifications_none, color: iconColor, size: 28),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
    );

    if (userId == null) return iconButton;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('audit_logs_with_roles').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          final rawNotifs = snapshot.data!.where((n) => 
            (n['user_id'] == null || n['user_id'] == userId) &&
            n['user_role'] != 'admin'
          ).toList();
          final allNotifs = rawNotifs.where((notif) {
            final text = '${notif['title']} ${notif['message'] ?? notif['description']} ${notif['type'] ?? notif['category']} ${notif['action']}'.toLowerCase();
            return text.contains('profile') || text.contains('plant');
          }).toList();
          unreadCount = allNotifs.where((n) => !(n['is_read'] ?? false)).length;
        }

        return Badge(
          isLabelVisible: unreadCount > 0,
          label: Text(unreadCount.toString()),
          backgroundColor: Colors.redAccent,
          child: iconButton,
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
      stream: supabase.from('audit_logs_with_roles').stream(primaryKey: ['id']).eq('user_id', userId),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          final allNotifs = snapshot.data!;
          final notifications = allNotifs.where((notif) {
            final text = '${notif['title']} ${notif['message'] ?? notif['description']} ${notif['type'] ?? notif['category']} ${notif['action']}'.toLowerCase();
            return text.contains('observation validatated') ||
                   text.contains('observation validated') ||
                   text.contains('rejected') ||
                   text.contains('meeting') ||
                   text.contains('password') ||
                   text.contains('name');
          }).toList();
          unreadCount = notifications.where((n) => !(n['is_read'] ?? false)).length;
        }

        return Badge(
          isLabelVisible: unreadCount > 0,
          label: Text(unreadCount.toString()),
          backgroundColor: Colors.redAccent,
          child: iconButton,
        );
      },
    );
  }
}
