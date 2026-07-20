import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../theme_provider.dart';
import 'sent.dart'; 

class SentListScreen extends StatefulWidget {
  final String? highlightEntryId;
  const SentListScreen({super.key, this.highlightEntryId});

  @override
  State<SentListScreen> createState() => _SentListScreenState();
}

class _SentListScreenState extends State<SentListScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final userId = _supabase.auth.currentUser?.id;
    final textTheme = Theme.of(context).textTheme;

    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA);
    final textColor = isDark ? Colors.white : darkGreen;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0.5,
        title: Text(
          "Sent Observations", 
          style: textTheme.titleLarge?.copyWith(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchSection(isDark, textTheme),
          Expanded(
            child: userId == null
                ? const Center(child: Text("Please log in."))
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _supabase
                        .from('field_entries')
                        .stream(primaryKey: ['id'])
                        .eq('user_id', userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF5D7A5D)));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }

                      var sentItems = (snapshot.data ?? [])
                          .where((e) => e['status']?.toString().toUpperCase() != 'DRAFT')
                          .toList();

                      if (_searchQuery.isNotEmpty) {
                        sentItems = sentItems.where((e) {
                          final name = (e['common_name'] ?? e['species_name'] ?? e['plant_type'] ?? '').toString().toLowerCase();
                          final area = (e['protected_area'] ?? '').toString().toLowerCase();
                          return name.contains(_searchQuery.toLowerCase()) || area.contains(_searchQuery.toLowerCase());
                        }).toList();
                      }

                      if (sentItems.isEmpty) return _buildEmptyState(isDark, textTheme);

                      // Sort newest first
                      sentItems.sort((a, b) {
                        final dtA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
                        final dtB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
                        return dtB.compareTo(dtA);
                      });

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        itemCount: sentItems.length,
                        itemBuilder: (context, index) {
                          return _buildSentTile(context, sentItems[index], isDark, textTheme);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(bool isDark, TextTheme textTheme) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white, 
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _searchQuery = v),
      style: textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: "Search species or location...", 
        hintStyle: textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white38 : Colors.black38),
        border: InputBorder.none, 
        icon: Icon(Icons.search_rounded, size: 22, color: forestGreen),
        suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.cancel_rounded, size: 18, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
      ),
    ),
  );

  Widget _buildSentTile(BuildContext context, Map<String, dynamic> entry, bool isDark, TextTheme textTheme) {
    final String entryId = entry['id']?.toString() ?? '';
    final bool isHighlighted = widget.highlightEntryId != null && widget.highlightEntryId == entryId;
    final species = entry['common_name'] ?? entry['species_name'] ?? entry['plant_type'] ?? "Observation Entry";
    final date = DateFormat('MMM dd, yyyy').format(DateTime.tryParse(entry['obs_date'] ?? entry['created_at'] ?? '') ?? DateTime.now());
    final status = entry['status']?.toString().toUpperCase() ?? 'SENT';
    final area = entry['protected_area'] ?? 'Protected Area';

    Color badgeColor = forestGreen;
    IconData statusIcon = Icons.send_rounded;

    if (status == 'VALIDATED' || status == 'APPROVED') {
      badgeColor = const Color(0xFF4CAF50);
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'REJECTED') {
      badgeColor = const Color(0xFFF44336);
      statusIcon = Icons.cancel_rounded;
    } else if (status == 'FLAGGED' || status == 'NEEDS_REVIEW') {
      badgeColor = Colors.orange;
      statusIcon = Icons.rate_review_rounded;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SentObservationsScreen(observation: entry),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighlighted 
              ? (isDark ? Colors.amber.withOpacity(0.15) : Colors.amber.shade50) 
              : (isDark ? const Color(0xFF1F1F1F) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: isHighlighted 
              ? Border.all(color: Colors.amber.shade700, width: 2.0)
              : Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: isHighlighted 
                  ? Colors.amber.withOpacity(0.25)
                  : Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: isHighlighted ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isHighlighted) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber.shade900, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "Highlighted Notification Item",
                      style: TextStyle(color: Colors.amber.shade900, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.eco_rounded, color: badgeColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        species, 
                        style: textTheme.titleMedium?.copyWith(
                          color: isDark ? Colors.white : darkGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            date, 
                            style: textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                          Text("•", style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              area,
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBadge(status, badgeColor, statusIcon, textTheme),
                    const SizedBox(height: 6),
                    Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? Colors.white38 : Colors.black26),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon, TextTheme textTheme) => Container(
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
          label, 
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  Widget _buildEmptyState(bool isDark, TextTheme textTheme) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: isDark ? Colors.white30 : Colors.black26),
          const SizedBox(height: 12),
          Text(
            "No observation submissions found.", 
            style: textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  );
}