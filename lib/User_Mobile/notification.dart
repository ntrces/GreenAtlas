import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; 

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _supabase = Supabase.instance.client;
  final Set<String> _readIds = {};

  String? get _userId => _supabase.auth.currentUser?.id;

  void _markAllAsRead(List<Map<String, dynamic>> notifications) {
    setState(() {
      for (var notif in notifications) {
        _readIds.add(notif['id'].toString());
      }
    });
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

  Color _getIconColor(String type) {
    switch (type) {
      case 'plant_added': return Colors.green;
      case 'security': return Colors.redAccent;
      case 'profile_update': return Colors.blueAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_userId == null) {
      return const Scaffold(
        body: Center(
          child: Text("Please log in.")
        )
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        
        final allNotifs = snapshot.data?.where((n) => 
          n['user_id'] == null || n['user_id'] == _userId
        ).toList() ?? [];

        final unreadCount = allNotifs.where((n) => !_readIds.contains(n['id'].toString())).length;

        return Scaffold(
          backgroundColor: const Color(0xFFEAF7EA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3E2D)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Text(
                  "Activity", 
                  style: textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF2D3E2D), 
                    fontSize: 18,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  _buildBadge(unreadCount),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: allNotifs.isEmpty ? null : () => _markAllAsRead(allNotifs),
                child: Text(
                  "Mark all as read", 
                  style: textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF5D7A5D), 
                    fontSize: 12,
                  ),
                ),
              )
            ],
          ),
          body: allNotifs.isEmpty 
            ? const Center(
                child: Text(
                  "No new activity.", 
                  style: TextStyle(color: Colors.black38),
                )
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: allNotifs.length,
                itemBuilder: (context, index) {
                  final notif = allNotifs[index];
                  final String id = notif['id'].toString();
                  final String type = notif['type'] ?? 'general';
                  final bool isUnread = !_readIds.contains(id);
                  
                  final DateTime createdAt = DateTime.parse(notif['created_at']);
                  final String timeLabel = DateFormat.jm().format(createdAt); 

                  return InkWell(
                    onTap: () => setState(() => _readIds.add(id)),
                    child: _buildNotifTile(
                      icon: _getIcon(type),
                      iconColor: _getIconColor(type),
                      title: notif['title'] ?? "Notification",
                      body: notif['message'] ?? "",
                      time: timeLabel,
                      isUnread: isUnread,
                    ),
                  );
                },
              ),
        );
      }
    );
  }

  Widget _buildBadge(int count) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFF5D7A5D), borderRadius: BorderRadius.circular(10)),
      child: Text(
        count.toString(), 
        style: textTheme.labelSmall?.copyWith(color: Colors.white, fontSize: 11),
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
  }) {
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? Colors.white : const Color(0xFFF1F4F1).withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isUnread ? const Color(0xFF5D7A5D).withOpacity(0.2) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1), 
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
                        color: const Color(0xFF2D3E2D),
                      ),
                    ),
                    Text(
                      time, 
                      style: textTheme.labelSmall?.copyWith(fontSize: 10, color: Colors.black38),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body, 
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12, 
                    color: isUnread ? Colors.black87 : Colors.black45, 
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
               decoration: const BoxDecoration(color: Color(0xFF5D7A5D), shape: BoxShape.circle)
             ),
        ],
      ),
    );
  }
}