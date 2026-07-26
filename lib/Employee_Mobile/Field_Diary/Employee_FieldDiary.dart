import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../theme_provider.dart';
import '../../UserProfile/user_profile.dart';
import '../EmployeeNotification/employeenotif.dart';
import '../../components/notification_badge.dart';

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

  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textTheme = Theme.of(context).textTheme;

    if (_userId == null) {
      return const Scaffold(body: Center(child: Text("Please sign in.")));
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, isDark, textTheme),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoCard(isDark, textTheme),
                const SizedBox(height: 16),
                _buildDescriptionText(isDark, textTheme),
                const SizedBox(height: 24),
                _buildActionButtons(context, isDark, textTheme), 
                const SizedBox(height: 28),
                _buildSectionHeader("Recent Entries (Max 5)", isDark, textTheme),
                const SizedBox(height: 14),
                _buildRecentEntriesList(isDark, textTheme),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // --- HEADER & APP BAR ---

  Widget _buildHeader(BuildContext context, bool isDark, TextTheme textTheme) => SliverAppBar(
    pinned: true,
    backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
    elevation: 0.5,
    toolbarHeight: 70,
    leadingWidth: 70,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Image.asset('assets/logo2.png', fit: BoxFit.contain, errorBuilder: (c,e,s) => Icon(Icons.eco, color: forestGreen, size: 32)), 
    ),
    title: Text(
      "Field Observation", 
      style: textTheme.titleLarge?.copyWith(
        color: isDark ? Colors.white : darkGreen, 
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      )
    ),
    actions: [
      _buildNotificationIcon(context, isDark, textTheme),
      _buildProfileIcon(context, isDark),
      const SizedBox(width: 16),
    ],
  );

  Widget _buildNotificationIcon(BuildContext context, bool isDark, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: EmployeeNotificationBadge(iconColor: isDark ? Colors.white70 : Colors.black87),
    );
  }

  Widget _buildProfileIcon(BuildContext context, bool isDark) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
    child: Container(
      height: 38, width: 38,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF0F4F0), 
        borderRadius: BorderRadius.circular(10), 
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 1)
      ),
      child: Icon(Icons.person_outline_rounded, color: isDark ? Colors.white70 : Colors.black54, size: 22),
    ),
  );

  // --- INFO & DESCRIPTION ---

  Widget _buildInfoCard(bool isDark, TextTheme textTheme) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isDark 
            ? [const Color(0xFF1F1F1F), const Color(0xFF2A2A2A)]
            : [Colors.white, const Color(0xFFF5FAF5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? Colors.white10 : forestGreen.withOpacity(0.15)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: forestGreen.withOpacity(0.12), 
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: forestGreen.withOpacity(0.2)),
          ),
          child: Icon(Icons.menu_book_rounded, color: forestGreen, size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Digital Logbook for GreenAtlas Observations",
                style: textTheme.titleSmall?.copyWith(
                  fontSize: 15, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : darkGreen,
                  height: 1.3,
                )
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _metaBadge("v1.1.25", Icons.build_circle_outlined, isDark),
                  const SizedBox(width: 8),
                  _metaBadge("BMB_CM", Icons.verified_user_outlined, isDark),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _metaBadge(String text, IconData icon, bool isDark) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: isDark ? Colors.white10 : const Color(0xFFE8F2E8),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: forestGreen),
        const SizedBox(width: 4),
        Text(
          text, 
          style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : darkGreen, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  Widget _buildDescriptionText(bool isDark, TextTheme textTheme) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: forestGreen.withOpacity(isDark ? 0.12 : 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: forestGreen.withOpacity(0.15)),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 18, color: forestGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "Document daily patrols and species observations to enhance ecological monitoring in Cavite Protected Area.",
            style: textTheme.bodySmall?.copyWith(
              fontSize: 12, 
              height: 1.4, 
              color: isDark ? Colors.white70 : darkGreen.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  // --- ACTIONS ---

  Widget _buildActionButtons(BuildContext context, bool isDark, TextTheme textTheme) => Column(
    children: [
      _actionRow(
        icon: Icons.add_circle_rounded, 
        label: "Collect New Observation", 
        subLabel: "Record new species & patrol data",
        color: const Color(0xFF4285F4), 
        isDark: isDark, 
        textTheme: textTheme,
        badgeText: "+ New",
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectStep1Screen())),
      ),
      // Drafts with dynamic count
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('field_entries')
            .select()
            .eq('user_id', _userId!)
            .eq('status', 'DRAFT')
            .asStream(),
        builder: (context, snapshot) {
          final draftCount = snapshot.data?.length ?? 0;
          return _actionRow(
            icon: Icons.drafts_rounded, 
            label: "Drafts", 
            subLabel: "Saved observations pending submission",
            color: const Color(0xFFFF9800), 
            isDark: isDark, 
            textTheme: textTheme,
            badge: draftCount > 0 ? "$draftCount draft(s)" : null,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DraftsListScreen())),
          );
        },
      ),
      // Sent with dynamic count
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('field_entries')
            .select()
            .eq('user_id', _userId!)
            .neq('status', 'DRAFT')
            .asStream(),
        builder: (context, snapshot) {
          final sentCount = snapshot.data?.length ?? 0;
          return _actionRow(
            icon: Icons.cloud_done_rounded, 
            label: "Sent Submissions", 
            subLabel: "View status of submitted observations",
            color: forestGreen, 
            isDark: isDark, 
            textTheme: textTheme,
            badge: sentCount > 0 ? "$sentCount sent" : null,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SentListScreen())),
          );
        },
      ),
    ],
  );

  Widget _actionRow({
    required IconData icon, 
    required String label, 
    String? subLabel,
    required Color color, 
    required bool isDark, 
    required TextTheme textTheme,
    String? badge, 
    String? badgeText,
    VoidCallback? onTap
  }) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), 
          blurRadius: 10, 
          offset: const Offset(0, 3)
        ),
      ],
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label, 
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 15, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : darkGreen,
                    ),
                  ),
                  if (subLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subLabel,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
                    ),
                  ],
                ],
              ),
            ),
            if (badgeText != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12), 
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  badgeText, 
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
            ] else if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Text(
                  badge, 
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white38 : Colors.black26, size: 22),
          ],
        ),
      ),
    ),
  );

  // --- RECENT ENTRIES (MAX 5) ---

  Widget _buildRecentEntriesList(bool isDark, TextTheme textTheme) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('field_entries')
          .stream(primaryKey: ['id'])
          .eq('user_id', _userId!)
          .order('created_at', ascending: false)
          .limit(5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF5D7A5D)));
        }

        final rawEntries = snapshot.data ?? [];
        
        if (rawEntries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24), 
              child: Column(
                children: [
                  Icon(Icons.assignment_outlined, size: 48, color: isDark ? Colors.white30 : Colors.black26),
                  const SizedBox(height: 8),
                  Text(
                    "No observation entries recorded yet.", 
                    style: textTheme.bodySmall?.copyWith(fontSize: 12, color: isDark ? Colors.white38 : Colors.black45),
                  ),
                ],
              ),
            ),
          );
        }

        final entries = List<Map<String, dynamic>>.from(rawEntries);
        entries.sort((a, b) {
          final dtA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(1970);
          final dtB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(1970);
          return dtB.compareTo(dtA);
        });
        
        return Column(
          children: entries.take(5).map((e) => _buildEntryCard(
            e['id'].toString(), 
            DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.tryParse(e['created_at']?.toString() ?? '') ?? DateTime.now()),
            e['protected_area'] ?? e['species_name'] ?? e['taxon'] ?? "Observation Entry", 
            e['status'] ?? "Sent",
            isDark,
            textTheme,
          )).toList(),
        );
      },
    );
  }

  Widget _buildEntryCard(String id, String date, String area, String status, bool isDark, TextTheme textTheme) {
    final String st = status.toUpperCase();
    Color statusColor = forestGreen;
    IconData statusIcon = Icons.send_rounded;

    if (st == 'VALIDATED' || st == 'APPROVED') {
      statusColor = const Color(0xFF4CAF50);
      statusIcon = Icons.check_circle_rounded;
    } else if (st == 'REJECTED') {
      statusColor = const Color(0xFFF44336);
      statusIcon = Icons.cancel_rounded;
    } else if (st == 'FLAGGED' || st == 'NEEDS_REVIEW') {
      statusColor = Colors.orange;
      statusIcon = Icons.rate_review_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "BMS-${id.padLeft(3, '0')}", 
                              style: textTheme.titleSmall?.copyWith(
                                fontSize: 15, 
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : darkGreen,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(status, statusColor, statusIcon, textTheme),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            date, 
                            style: textTheme.labelSmall?.copyWith(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: 12, color: forestGreen),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              area, 
                              style: textTheme.labelSmall?.copyWith(fontSize: 11, color: forestGreen, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color, IconData icon, TextTheme textTheme) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(
          status, 
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  Widget _buildSectionHeader(String title, bool isDark, TextTheme textTheme) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Row(
      children: [
        Container(
          width: 4, height: 14,
          decoration: BoxDecoration(color: forestGreen, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          title, 
          style: textTheme.titleSmall?.copyWith( 
            fontSize: 14, 
            color: isDark ? Colors.white : darkGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}