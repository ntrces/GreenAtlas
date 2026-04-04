import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../theme_provider.dart';
import 'sent.dart'; 

class SentListScreen extends StatefulWidget {
  const SentListScreen({super.key});

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
        elevation: 0,
        title: Text(
          "Sent Observations", 
          style: textTheme.titleLarge?.copyWith(color: textColor),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchSection(isDark, textTheme),
          Expanded(
            child: userId == null
                ? const Center(child: Text("Please log in"))
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _supabase
                        .from('field_entries')
                        .stream(primaryKey: ['id'])
                        .eq('user_id', userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }

                      var sentItems = (snapshot.data ?? [])
                          .where((e) => e['status']?.toString().toUpperCase() != 'DRAFT')
                          .toList();

                      if (_searchQuery.isNotEmpty) {
                        sentItems = sentItems.where((e) {
                          final name = (e['common_name'] ?? '').toString().toLowerCase();
                          return name.contains(_searchQuery.toLowerCase());
                        }).toList();
                      }

                      if (sentItems.isEmpty) return _buildEmptyState(isDark, textTheme);

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
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

  Widget _buildSearchSection(bool isDark, TextTheme textTheme) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
    child: Row(children: [
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.white, 
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: textTheme.bodyLarge?.copyWith(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: "Search observations...", 
              hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.black26),
              border: InputBorder.none, 
              icon: const Icon(Icons.search, size: 20, color: Colors.black26)
            ),
          ),
        ),
      ),
    ]),
  );

  Widget _buildSentTile(BuildContext context, Map<String, dynamic> entry, bool isDark, TextTheme textTheme) {
    final species = entry['common_name'] ?? "Unnamed Entry";
    final date = DateFormat('MMM dd, yyyy').format(DateTime.parse(entry['obs_date'] ?? DateTime.now().toString()));
    final status = entry['status']?.toString().toUpperCase() ?? 'PENDING';

    Color badgeColor = (status == 'VALIDATED') ? Colors.blue : (status == 'REJECTED' ? Colors.red : forestGreen);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SentObservationsScreen(observation: entry),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    species, 
                    style: textTheme.titleMedium?.copyWith(color: isDark ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        date, 
                        style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(width: 10),
                      _buildBadge(status, badgeColor, textTheme),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: forestGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, TextTheme textTheme) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(
      label, 
      style: textTheme.labelSmall?.copyWith(color: color),
    ),
  );

  Widget _buildEmptyState(bool isDark, TextTheme textTheme) => Center(
    child: Text(
      "No submissions found", 
      style: textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white38 : Colors.black38),
    ),
  );
}