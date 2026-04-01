import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../theme_provider.dart';
import '../Collect/collect01.dart'; 
import '../Collect/observation_model.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);
  final Color draftOrange = const Color(0xFFFF9800);

  // --- DELETE DRAFT LOGIC ---
  Future<void> _deleteDraft(String id) async {
    try {
      await _supabase.from('field_entries').delete().match({'id': id});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Draft deleted successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting draft: $e")),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, String id, String speciesName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Draft"),
          content: Text("Are you sure you want to delete the draft for '$speciesName'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
            ),
            TextButton(
              onPressed: () {
                _deleteDraft(id);
                Navigator.pop(context);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // --- CONTINUE DRAFT LOGIC ---
  void _continueDraft(BuildContext context, Map<String, dynamic> draft) {
    final model = context.read<ObservationModel>();

    // Reloading data into the model from the database fields
    model.observerName = draft['observer_id_code'] ?? 'FO-12345';
    model.observationDate = DateTime.parse(draft['obs_date']);
    model.region = draft['region'] ?? model.region;
    model.province = draft['province'] ?? model.province;
    model.protectedArea = draft['protected_area'] ?? model.protectedArea;
    model.weatherCondition = draft['weather'] ?? 'Sunny';
    model.habitat = draft['habitat'] ?? 'Mangrove forest';
    model.habitatOthers = draft['habitat_others'];
    model.observationCategory = draft['observation_category'] ?? 'Wildlife';
    model.obsCategoryOthers = draft['obs_category_others'];
    model.taxon = draft['taxon'] ?? '';
    model.speciesName = draft['common_name'] ?? ''; 
    model.isUnfamiliar = draft['is_unfamiliar'] ?? false;
    model.quantity = draft['count'] ?? 1;
    model.seen = draft['obs_type_seen'] ?? false;
    model.heard = draft['obs_type_heard'] ?? false;
    model.presence = draft['obs_type_presence'] ?? false;
    model.observationNotes = draft['notes'] ?? '';

    model.updateData();

    Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectStep1Screen()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final user = _supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      appBar: _buildAppBar(context, isDark),
      body: Column(
        children: [
          _buildSearchSection(isDark),
          Expanded(
            child: user == null 
              ? const Center(child: Text("Please login to see your drafts"))
              : StreamBuilder<List<Map<String, dynamic>>>(
                  // FIX: We only use ONE .eq() here to avoid the code error.
                  stream: _supabase
                      .from('field_entries')
                      .stream(primaryKey: ['id'])
                      .eq('user_id', user.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // FIX: Filter for 'DRAFT' status locally in the logic
                    // Ensure 'DRAFT' is uppercase to match your DB's naming convention
                    List<Map<String, dynamic>> drafts = (snapshot.data ?? [])
                        .where((d) => d['status'] == 'DRAFT') 
                        .toList();

                    // Apply search filter locally
                    if (_searchQuery.isNotEmpty) {
                      drafts = drafts.where((d) {
                        final name = (d['common_name'] ?? '').toString().toLowerCase();
                        return name.contains(_searchQuery.toLowerCase());
                      }).toList();
                    }

                    if (drafts.isEmpty) return _buildEmptyState(isDark);

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: drafts.length,
                      itemBuilder: (context, index) => _buildDraftCard(context, drafts[index], isDark),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) => AppBar(
    backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
    elevation: 0,
    leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: darkGreen, size: 20), onPressed: () => Navigator.pop(context)),
    title: Text("Drafts", style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold, fontSize: 18)),
    centerTitle: true,
  );

  Widget _buildSearchSection(bool isDark) => Padding(
    padding: const EdgeInsets.all(20.0),
    child: Row(children: [
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.white, 
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: const InputDecoration(
              hintText: "Search drafts...", 
              border: InputBorder.none, 
              icon: Icon(Icons.search, size: 20, color: Colors.black26)
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Container(
        padding: const EdgeInsets.all(12), 
        decoration: BoxDecoration(color: forestGreen, borderRadius: BorderRadius.circular(12)), 
        child: const Icon(Icons.tune, color: Colors.white, size: 20)
      ),
    ]),
  );

  Widget _buildDraftCard(BuildContext context, Map<String, dynamic> draft, bool isDark) {
    final DateTime createdAt = DateTime.parse(draft['created_at']);
    final String formattedDate = DateFormat('MMMM dd, yyyy • hh:mm a').format(createdAt);
    final String speciesName = draft['common_name'] ?? "Unnamed Observation";
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(speciesName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            const SizedBox(width: 8),
            _buildBadge("DRAFT", draftOrange),
          ]),
          const SizedBox(height: 4),
          Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.black45)),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.location_on, color: forestGreen, size: 14), 
            const SizedBox(width: 4),
            Text(draft['protected_area'] ?? "N/A", style: TextStyle(fontSize: 12, color: forestGreen, fontWeight: FontWeight.w500))
          ]),
        ])),
        IconButton(
          icon: Icon(Icons.edit_note_rounded, color: forestGreen, size: 28), 
          onPressed: () => _continueDraft(context, draft)
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24), 
          onPressed: () => _showDeleteConfirmation(context, draft['id'].toString(), speciesName)
        ),
      ]),
    );
  }

  Widget _buildBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), 
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))
  );

  Widget _buildEmptyState(bool isDark) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center, 
      children: [
        Icon(Icons.auto_stories_outlined, size: 64, color: isDark ? Colors.white10 : Colors.black12), 
        const SizedBox(height: 16),
        Text("No drafts found", style: TextStyle(color: isDark ? Colors.white38 : Colors.black26, fontWeight: FontWeight.bold)),
      ]
    )
  );
}