import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../theme_provider.dart';
import '../../UserProfile/user_profile.dart';
import '../EmployeeNotification/employeenotif.dart';

// Navigation Targets
import '../Field_Diary/Collect/collect01.dart'; 
import '../Field_Diary/Sent/sent0.dart';    
import '../Field_Diary/Draft/draft0.dart'; 

class FieldObservationScreen extends StatefulWidget {
  const FieldObservationScreen({super.key});

  @override
  State<FieldObservationScreen> createState() => _FieldObservationScreenState();
}

class _FieldObservationScreenState extends State<FieldObservationScreen> {
  final _supabase = Supabase.instance.client;
  String? get _userId => _supabase.auth.currentUser?.id;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    if (_userId == null) {
      return const Scaffold(body: Center(child: Text("Please sign in.")));
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, isDark),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoCard(isDark),
                const SizedBox(height: 20),
                _buildDescriptionText(isDark),
                const SizedBox(height: 24),
                _buildActionButtons(context, isDark), 
                const SizedBox(height: 32),
                _buildSectionHeader("Recent Entries (Max 5)", isDark),
                const SizedBox(height: 12),
                _buildRecentEntriesList(isDark),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // --- HEADER & APP BAR ---

  Widget _buildHeader(BuildContext context, bool isDark) => SliverAppBar(
    pinned: true,
    backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
    elevation: 0,
    toolbarHeight: 70,
    leadingWidth: 70,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Image.asset('assets/logo2.png', fit: BoxFit.contain), 
    ),
    title: Text("Field Observation", 
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF2D3E2D), 
        fontWeight: FontWeight.bold, 
        fontSize: 20
      )
    ),
    actions: [
      _buildNotificationIcon(context, isDark),
      _buildProfileIcon(context, isDark),
      const SizedBox(width: 16),
    ],
  );

  Widget _buildNotificationIcon(BuildContext context, bool isDark) => Stack(
    alignment: Alignment.center,
    children: [
      IconButton(
        icon: Icon(Icons.notifications_none_outlined, color: isDark ? Colors.white70 : Colors.black87, size: 26),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeNotifications())),
      ),
      Positioned(
        right: 8, top: 18,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: Color(0xFF5D7A5D), shape: BoxShape.circle),
          child: const Text("2", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
        ),
      )
    ],
  );

  Widget _buildProfileIcon(BuildContext context, bool isDark) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
    child: Container(
      height: 36, width: 36,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF0F4F0), 
        borderRadius: BorderRadius.circular(8), 
        border: Border.all(color: Colors.black12)
      ),
      child: const Icon(Icons.person_outline, color: Colors.black54, size: 20),
    ),
  );

  // --- INFO & DESCRIPTION ---

  Widget _buildInfoCard(bool isDark) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.menu_book, color: Color(0xFF5D7A5D), size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Digital logbook for recording activities...",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, height: 1.4)),
              const SizedBox(height: 12),
              _metaText("Version: v.1.1.25"),
              _metaText("Owner: BMB_CM"),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _metaText(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.black38)),
  );

  Widget _buildDescriptionText(bool isDark) => Text(
    "document daily patrols and species observations to enhance ecological monitoring efforts.",
    style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : const Color(0xFF5D7A5D).withOpacity(0.8)),
  );

  // --- ACTIONS ---

  Widget _buildActionButtons(BuildContext context, bool isDark) => Column(
    children: [
      _actionRow(
        icon: Icons.add_box_rounded, 
        label: "Collect", 
        color: const Color(0xFF4285F4), 
        isDark: isDark, 
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectStep1Screen())),
      ),
      _actionRow(
        icon: Icons.insert_drive_file_rounded, 
        label: "Drafts", 
        color: const Color(0xFFFF9800), 
        isDark: isDark, 
        badge: "1",
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DraftsListScreen())),
      ),
      _actionRow(
        icon: Icons.cloud_done_rounded, 
        label: "Sent", 
        color: const Color(0xFF78909C), 
        isDark: isDark, 
        badge: "3",
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SentListScreen())),
      ),
    ],
  );

  Widget _actionRow({required IconData icon, required String label, required Color color, required bool isDark, String? badge, VoidCallback? onTap}) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListTile(
      onTap: onTap,
      leading: CircleAvatar(backgroundColor: color, radius: 18, child: Icon(icon, color: Colors.white, size: 18)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      trailing: badge != null 
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(badge, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          )
        : const Icon(Icons.chevron_right, color: Colors.black26),
    ),
  );

  // --- RECENT ENTRIES (MAX 5) ---

  Widget _buildRecentEntriesList(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // .limit(5) ensures we only fetch 5 rows from Supabase
      stream: _supabase
          .from('field_entries')
          .stream(primaryKey: ['id'])
          .eq('user_id', _userId!)
          .limit(5), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snapshot.data ?? [];
        
        if (entries.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20), 
              child: Text("No observations yet.", style: TextStyle(fontSize: 12, color: Colors.grey))
            )
          );
        }

        // Sorting client-side to ensure the absolute latest is on top
        entries.sort((a, b) => b['created_at'].compareTo(a['created_at']));
        
        return Column(
          children: entries.take(5).map((e) => _buildEntryCard(
            e['id'].toString(), 
            DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(e['created_at'])),
            e['location'] ?? "Unknown Area",
            e['status'] ?? "Sent",
            isDark
          )).toList(),
        );
      },
    );
  }

  Widget _buildEntryCard(String id, String date, String area, String status, bool isDark) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.02)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("BMS-${id.padLeft(3, '0')}", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black)),
            _buildStatusBadge(status),
          ],
        ),
        const SizedBox(height: 4),
        Text(date, style: const TextStyle(fontSize: 12, color: Colors.black45)),
        const SizedBox(height: 8),
        Text("$area • 1 observation(s)", 
          style: const TextStyle(fontSize: 12, color: Color(0xFF5D7A5D), fontWeight: FontWeight.w500)),
      ],
    ),
  );

  Widget _buildStatusBadge(String status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: status.toUpperCase() == "SENT" ? const Color(0xFF5D7A5D).withOpacity(0.1) : Colors.black12,
      borderRadius: BorderRadius.circular(6)
    ),
    child: Text(status, 
      style: TextStyle(
        color: status.toUpperCase() == "SENT" ? const Color(0xFF5D7A5D) : Colors.black54, 
        fontSize: 10, 
        fontWeight: FontWeight.bold
      )
    ),
  );

  Widget _buildSectionHeader(String title, bool isDark) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      title, 
      style: TextStyle( 
        fontWeight: FontWeight.bold, 
        fontSize: 14, 
        color: isDark ? Colors.white : Colors.black87,
      ),
    ),
  );
}