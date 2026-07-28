import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../theme_constants.dart';
import 'Botanical_Gallery/ar_gallery.dart';
import '../UserProfile/user_profile.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _supabase = Supabase.instance.client;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<void> _updateReadStatus(dynamic id) async {
    try {
      await _supabase.from('audit_logs').update({'is_read': true}).eq('id', id);
    } catch (e) {
      debugPrint("Error updating read status: $e");
    }
  }

  Future<void> _markAllAsRead(List<Map<String, dynamic>> notifications) async {
    try {
      final unreadIds = notifications.where((n) => !(n['is_read'] ?? false)).map((n) => n['id']).toList();
      if (unreadIds.isEmpty) return;
      await _supabase.from('audit_logs').update({'is_read': true}).inFilter('id', unreadIds);
    } catch (e) {
      debugPrint("Error marking all as read: $e");
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'plant_added':
        return Icons.local_library_rounded; 
      case 'security':
        return Icons.shield_outlined; 
      case 'profile_update':
        return Icons.person_outline_rounded; 
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getIconColor(String type, bool isDark) {
    switch (type) {
      case 'plant_added': return isDark ? leafAccent : Colors.green;
      case 'security': return isDark ? Colors.redAccent : Colors.redAccent;
      case 'profile_update': return isDark ? Colors.lightBlueAccent : Colors.blueAccent;
      default: return isDark ? Colors.white60 : Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textTheme = Theme.of(context).textTheme;

    if (_userId == null) {
      return Scaffold(
        backgroundColor: getScaffoldBg(isDark),
        body: Center(
          child: Text("Please log in.", style: TextStyle(color: getTextColor(isDark)))
        )
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('audit_logs_with_roles')
          .stream(primaryKey: ['id'])
          .eq('user_id', _userId!)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Scaffold(backgroundColor: getScaffoldBg(isDark), body: Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: getTextColor(isDark)))));
        
        final rawNotifs = snapshot.data?.where((n) => 
          n['user_id'] == _userId && 
          n['user_role'] != 'admin'
        ).toList() ?? [];

        final allNotifs = rawNotifs.where((notif) {
          final text = '${notif['title']} ${notif['message'] ?? notif['description']} ${notif['type'] ?? notif['category']} ${notif['action']}'.toLowerCase();
          return text.contains('profile') || text.contains('plant');
        }).take(10).toList();

        final unreadCount = allNotifs.where((n) => !(n['is_read'] ?? false)).length;

        return Scaffold(
          backgroundColor: getScaffoldBg(isDark),
          appBar: AppBar(
            backgroundColor: getCardBg(isDark),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: getTextColor(isDark)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Text(
                  "Activity", 
                  style: textTheme.titleLarge?.copyWith(
                    color: getTextColor(isDark), 
                    fontSize: 18,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  _buildBadge(unreadCount, isDark),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: allNotifs.isEmpty ? null : () => _markAllAsRead(allNotifs),
                child: Text(
                  "Mark all as read", 
                  style: textTheme.labelLarge?.copyWith(
                    color: isDark ? leafAccent : const Color(0xFF5D7A5D), 
                    fontSize: 12,
                  ),
                ),
              )
            ],
          ),
          body: allNotifs.isEmpty 
            ? Center(
                child: Text(
                  "No new activity.", 
                  style: TextStyle(color: getSubtextColor(isDark)),
                )
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: allNotifs.length,
                itemBuilder: (context, index) {
                  final notif = allNotifs[index];
                  final String type = notif['type'] ?? notif['category'] ?? 'general';
                  final bool isUnread = !(notif['is_read'] ?? false);
                  
                  final DateTime createdAt = DateTime.tryParse(notif['created_at']?.toString() ?? '') ?? DateTime.now();
                  final String timeLabel = DateFormat.jm().format(createdAt); 

                  return InkWell(
                    onTap: () {
                      try {
                        if (isUnread) {
                          _updateReadStatus(notif['id']);
                        }
                        final text = '${notif['title']} ${notif['message'] ?? notif['description']} ${notif['type'] ?? notif['category']} ${notif['action']}'.toLowerCase();
                        if (text.contains('plant')) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ARGalleryScreen()));
                        } else if (text.contains('profile')) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen()));
                        }
                      } catch (e) {
                        debugPrint("Error handling notification tap: $e");
                      }
                    },
                    child: _buildNotifTile(
                      icon: _getIcon(type),
                      iconColor: _getIconColor(type, isDark),
                      title: notif['title'] ?? "Notification",
                      body: notif['message'] ?? notif['description'] ?? "",
                      time: timeLabel,
                      isUnread: isUnread,
                      isDark: isDark,
                    ),
                  );
                },
              ),
        );
      }
    );
  }

  Widget _buildBadge(int count, bool isDark) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: isDark ? leafAccent : const Color(0xFF5D7A5D), borderRadius: BorderRadius.circular(10)),
      child: Text(
        count.toString(), 
        style: textTheme.labelSmall?.copyWith(color: isDark ? Colors.black : Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNotifTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    required String time,
    required bool isUnread,
    required bool isDark,
  }) {
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread 
          ? (isDark ? const Color(0xFF253326) : const Color(0xFFD4E8D4)) 
          : getCardBg(isDark),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isUnread 
            ? (isDark ? leafAccent.withOpacity(0.5) : const Color(0xFF5D7A5D).withOpacity(0.4)) 
            : (isDark ? Colors.white12 : const Color(0xFFEAEAEA)),
          width: isUnread ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15), 
              shape: BoxShape.circle
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title, 
                      style: (isUnread ? textTheme.titleSmall : textTheme.bodyMedium)?.copyWith(
                        fontSize: 14, 
                        color: getTextColor(isDark),
                      ),
                    ),
                    Text(
                      time, 
                      style: textTheme.labelSmall?.copyWith(fontSize: 10, color: getSubtextColor(isDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body, 
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12, 
                    color: isUnread ? getTextColor(isDark) : getSubtextColor(isDark), 
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (isUnread) 
             Container(
               margin: const EdgeInsets.only(left: 8, top: 4),
               height: 7, width: 7, 
               decoration: BoxDecoration(color: isDark ? leafAccent : const Color(0xFF5D7A5D), shape: BoxShape.circle)
             ),
        ],
      ),
    );
  }
}