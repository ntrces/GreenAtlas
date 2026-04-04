import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../theme_provider.dart';
import './draft.dart'; // Import the detail screen

class DraftsListScreen extends StatefulWidget {
  const DraftsListScreen({super.key});

  @override
  State<DraftsListScreen> createState() => _DraftsListScreenState();
}

class _DraftsListScreenState extends State<DraftsListScreen> {
  final _supabase = Supabase.instance.client;
  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final userId = _supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0,
        title: Text("My Drafts", style: TextStyle(color: darkGreen, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: darkGreen, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: userId == null
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

                final drafts = (snapshot.data ?? [])
                    .where((d) => d['status'] == 'DRAFT')
                    .toList();

                if (drafts.isEmpty) {
                  return const Center(child: Text("No drafts yet", style: TextStyle(color: Colors.black38)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: drafts.length,
                  itemBuilder: (context, index) {
                    final item = drafts[index];
                    return _buildDraftTile(context, item, isDark);
                  },
                );
              },
            ),
    );
  }

  Widget _buildDraftTile(BuildContext context, Map<String, dynamic> draft, bool isDark) {
    final species = draft['common_name'] ?? "Unnamed Entry";
    final dateString = draft['observation_date'] ?? DateTime.now().toString();
    final date = DateFormat('MMM dd, yyyy').format(DateTime.parse(dateString));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DraftDetailScreen(draft: draft)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: forestGreen.withOpacity(0.1),
              child: Icon(Icons.edit_document, color: forestGreen, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(species, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16)),
                  Text("Last edited: $date", style: const TextStyle(fontSize: 12, color: Colors.black45)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}