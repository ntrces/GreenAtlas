import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _supabase = Supabase.instance.client;
  
  // This Set persists for the lifetime of this screen instance
  // ensuring read IDs are never lost when the stream refreshes
  final Set<String> _readIds = {};

  void _markAllAsRead(List<Map<String, dynamic>> reports) {
    setState(() {
      for (var report in reports) {
        _readIds.add(report['id'].toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('reports').stream(primaryKey: ['id']).order('created_at', ascending: false),
      builder: (context, snapshot) {
        // We filter out 'Pending' status as per your requirement
        final reports = snapshot.data?.where((r) => r['status'] != 'Pending').toList() ?? [];
        
        // Calculate unread count based on the IDs NOT in our persistence Set
        final unreadCount = reports.where((r) => !_readIds.contains(r['id'].toString())).length;

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
                const Text("Notifications", 
                  style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 18)),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF5D7A5D), borderRadius: BorderRadius.circular(10)),
                    child: Text(unreadCount.toString(), 
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ]
              ],
            ),
            actions: [
              TextButton(
                // Button only active if there are notifications to read
                onPressed: reports.isEmpty ? null : () => _markAllAsRead(reports),
                child: const Text("Mark all as read", style: TextStyle(color: Color(0xFF5D7A5D), fontSize: 12)),
              )
            ],
          ),
          body: reports.isEmpty 
            ? const Center(child: Text("No notifications yet.", style: TextStyle(color: Colors.black38)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final String id = report['id'].toString();
                  final String status = report['status'] ?? "Updated";
                  
                  // Check against our persistent State Set
                  final bool isUnread = !_readIds.contains(id);

                  return InkWell(
                    // Individual read logic: add ID to set and refresh UI
                    onTap: () => setState(() => _readIds.add(id)),
                    child: _buildNotifTile(
                      icon: status == 'Resolved' ? Icons.check_circle_outline : Icons.info_outline,
                      iconColor: status == 'Resolved' ? Colors.green : Colors.orange,
                      title: "Report $status",
                      body: "Your report RPT-${id.substring(0,3)} (${report['incident_type']}) is now $status.",
                      time: "Update",
                      isUnread: isUnread,
                    ),
                  );
                },
              ),
        );
      }
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // READ: Faint grey background | UNREAD: Solid white background
        color: isUnread ? Colors.white : const Color(0xFFF1F4F1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isUnread ? const Color(0xFF5D7A5D).withOpacity(0.3) : Colors.black12,
          width: isUnread ? 1.5 : 1,
        ),
        boxShadow: [
          if (isUnread) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // Icon background fades when read
              color: isUnread ? iconColor.withOpacity(0.1) : Colors.black.withOpacity(0.05), 
              shape: BoxShape.circle
            ),
            child: Icon(icon, color: isUnread ? iconColor : Colors.black38, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, 
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w500, 
                        fontSize: 14, 
                        color: isUnread ? const Color(0xFF2D3E2D) : Colors.black45
                      )),
                    Text(time, style: const TextStyle(fontSize: 11, color: Colors.black38)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body, 
                  style: TextStyle(
                    fontSize: 12, 
                    color: isUnread ? Colors.black87 : Colors.black38, 
                    height: 1.4
                  )),
              ],
            ),
          ),
          // Unread Green Dot: Disappears completely when marked read
          if (isUnread)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4),
              child: Container(height: 8, width: 8, decoration: const BoxDecoration(color: Color(0xFF5D7A5D), shape: BoxShape.circle)),
            ),
        ],
      ),
    );
  }
}