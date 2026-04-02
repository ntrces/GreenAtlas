import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../theme_provider.dart';
import '../Collect/observation_model.dart';
import '../Collect/collect01.dart'; 

class DraftsListScreen extends StatefulWidget {
  const DraftsListScreen({super.key});

  @override
  State<DraftsListScreen> createState() => _DraftsListScreenState();
}

class _DraftsListScreenState extends State<DraftsListScreen> {
  final _supabase = Supabase.instance.client;
  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);

  void _openDraft(BuildContext context, Map<String, dynamic> draft) {
    final model = context.read<ObservationModel>();

    model.observerName = draft['observer_id_code'] ?? 'FO-12345';
    model.observationDate = DateTime.parse(draft['obs_date'] ?? DateTime.now().toString());
    model.region = draft['region'] ?? model.region;
    model.province = draft['province'] ?? model.province;
    model.protectedArea = draft['protected_area'] ?? model.protectedArea;
    model.weatherConditions = draft['weather'] ?? 'Sunny';
    model.habitat = draft['habitat'] ?? 'Mangrove forest';
    model.taxon = draft['taxon'] ?? '';
    model.speciesName = draft['common_name'] ?? ''; 
    model.quantity = draft['count'] ?? 1;
    model.observationNotes = draft['notes'] ?? '';

    model.updateData();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CollectStep1Screen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final userId = _supabase.auth.currentUser?.id;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0,
        title: Text(
          "My Drafts", 
          style: textTheme.titleLarge?.copyWith(color: darkGreen),
        ),
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
                  return _buildEmptyState(isDark, textTheme);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: drafts.length,
                  itemBuilder: (context, index) {
                    final item = drafts[index];
                    return _buildDraftTile(context, item, isDark, textTheme);
                  },
                );
              },
            ),
    );
  }

  Widget _buildDraftTile(BuildContext context, Map<String, dynamic> draft, bool isDark, TextTheme textTheme) {
    final species = draft['common_name'] ?? "Unnamed Entry";
    final date = DateFormat('MMM dd, yyyy').format(DateTime.parse(draft['obs_date']));

    return GestureDetector(
      onTap: () => _openDraft(context, draft),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.white,
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
                  Text(
                    species, 
                    style: textTheme.titleMedium?.copyWith(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    "Last edited: $date", 
                    style: textTheme.bodySmall?.copyWith(color: Colors.black45),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.note_alt_outlined, size: 60, color: Colors.black12),
          const SizedBox(height: 16),
          Text(
            "No drafts yet", 
            style: textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}