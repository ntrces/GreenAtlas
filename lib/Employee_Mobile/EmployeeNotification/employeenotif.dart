import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme_provider.dart';

class EmployeeNotifications extends StatefulWidget {
  const EmployeeNotifications({super.key});

  @override
  State<EmployeeNotifications> createState() => _EmployeeNotificationsState();
}

class _EmployeeNotificationsState extends State<EmployeeNotifications> {
  final _supabase = Supabase.instance.client;
  String? get _userId => _supabase.auth.currentUser?.id;

  // Function to mark all notifications as read
  Future<void> _markAllAsRead() async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', _userId!)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking notifications: $e');
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
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              "Mark all read", 
              style: textTheme.labelLarge?.copyWith(color: const Color(0xFF5D7A5D)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _userId == null
          ? const Center(child: Text("Please login to see notifications."))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('notifications')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', _userId!)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF5D7A5D)));
                }

                final notifications = snapshot.data ?? [];

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
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return _buildNotificationItem(notif, isDark, textTheme);
                  },
                );
              },
            ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notif, bool isDark, TextTheme textTheme) {
    final bool isRead = notif['is_read'] ?? false;
    final String type = notif['type'] ?? 'info';
    final DateTime createdAt = DateTime.parse(notif['created_at']);
    
    // UI mapping based on type
    IconData icon;
    Color iconColor;
    switch (type) {
      case 'meeting':
        icon = Icons.calendar_today_outlined;
        iconColor = const Color(0xFF5D7A5D);
        break;
      case 'alert':
        icon = Icons.warning_amber_rounded;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.info_outline;
        iconColor = Colors.blueGrey;
    }

    return Container(
      color: isRead 
          ? (isDark ? const Color(0xFF1F1F1F) : Colors.white)
          : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF4FAF4)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            if (!isRead)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
        title: Text(
          notif['title'] ?? 'System Update',
          style: (isRead ? textTheme.titleSmall : textTheme.titleMedium)?.copyWith(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notif['message'] ?? '',
              style: textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('MMM d, h:mm a').format(createdAt),
              style: textTheme.labelSmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        onTap: () async {
          if (!isRead) {
            await _supabase
                .from('notifications')
                .update({'is_read': true})
                .eq('id', notif['id']);
          }
        },
      ),
    );
  }
}