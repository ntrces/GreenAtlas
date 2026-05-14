import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Collect/observation_model.dart';
import '../Collect/collect01.dart';
import '../Collect/offline_draft_service.dart';

class DraftDetailScreen extends StatefulWidget {
  final Map<String, dynamic> draft;
  final bool isOfflineDraft;
  final OfflineDraftService? offlineService;

  const DraftDetailScreen({
    super.key,
    required this.draft,
    this.isOfflineDraft = false,
    this.offlineService,
  });

  @override
  State<DraftDetailScreen> createState() => _DraftDetailScreenState();
}

class _DraftDetailScreenState extends State<DraftDetailScreen> {
  late Map<String, dynamic> _editingDraft;

  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);
  final Color lightGreenBG = const Color(0xFFEAF7EA);
  final Color draftBadgeColor = const Color(0xFF8BA88B);

  @override
  void initState() {
    super.initState();
    _editingDraft = Map<String, dynamic>.from(widget.draft);
  }

  // --- LOGIC: EDIT ---
  void _handleEdit(BuildContext context) {
    if (widget.isOfflineDraft) {
      // For offline drafts, navigate to collector with draft data
      final model = context.read<ObservationModel>();
      
      model.observationDate = DateTime.parse(_editingDraft['observation_date'] ?? DateTime.now().toString());
      model.region = _editingDraft['region'] ?? '';
      model.province = _editingDraft['province'] ?? '';
      model.protectedArea = _editingDraft['protected_area'] ?? '';
      model.speciesName = _editingDraft['common_name'] ?? '';
      model.taxon = _editingDraft['taxon_group'] ?? '';
      model.habitat = _editingDraft['habitat_type'] ?? '';
      model.quantity = _editingDraft['count'] ?? 0;
      model.observationNotes = _editingDraft['notes'] ?? '';
      model.originalDraftId = _editingDraft['draft_id'] as String?;

      model.updateData();
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectStep1Screen()));
    } else {
      final model = context.read<ObservationModel>();
      
      model.observationDate = DateTime.parse(_editingDraft['observation_date'] ?? DateTime.now().toString());
      model.region = _editingDraft['region'] ?? '';
      model.province = _editingDraft['province'] ?? '';
      model.protectedArea = _editingDraft['protected_area'] ?? '';
      model.speciesName = _editingDraft['common_name'] ?? '';
      model.taxon = _editingDraft['taxon_group'] ?? '';
      model.habitat = _editingDraft['habitat_type'] ?? '';
      model.quantity = _editingDraft['count'] ?? 0;
      model.observationNotes = _editingDraft['notes'] ?? '';
      model.originalDraftId = _editingDraft['id'] as String?; // Set original draft ID for online drafts

      model.updateData();
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectStep1Screen()));
    }
  }

  // --- LOGIC: DELETE ---
  void _handleDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text("Delete Draft?"),
        content: Text(
          "Are you sure you want to delete this ${widget.isOfflineDraft ? 'offline ' : ''}draft? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              if (widget.isOfflineDraft && widget.offlineService != null) {
                // Delete offline draft
                final draftId = _editingDraft['draft_id'] as String?;
                if (draftId != null) {
                  await widget.offlineService!.deleteOfflineDraft(draftId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Offline draft deleted")),
                    );
                    Navigator.pop(context);
                  }
                }
              } else {
                // Delete online draft from Supabase
                try {
                  final supabase = Supabase.instance.client;
                  final draftId = _editingDraft['id'];
                  
                  await supabase
                      .from('field_entries')
                      .delete()
                      .eq('id', draftId);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Draft deleted successfully")),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error deleting draft: $e")),
                    );
                  }
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = widget.isOfflineDraft ? Colors.orange : draftBadgeColor;
    final badgeText = widget.isOfflineDraft ? "Offline Draft" : "Draft";

    return Scaffold(
      backgroundColor: lightGreenBG,
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), 
          onPressed: () => Navigator.pop(context)
        ),
        title: Column(
          children: [
            const Text("Entry Details", style: TextStyle(color: Colors.white, fontSize: 16)),
            Text("BMS-${_editingDraft['draft_id']?.toString().substring(0, 5).toUpperCase() ?? _editingDraft['id'].toString().substring(0, 5).toUpperCase()}", 
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
              child: Text(badgeText, style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
            const SizedBox(height: 16),

            // Offline indicator
            if (widget.isOfflineDraft)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "This draft is stored offline and will sync when online",
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            // Metadata Card
            _buildCard([
              _buildDataRow("User ID:", "FO-12345"),
              _buildDataRow("Created:", _editingDraft['created_at'].toString().substring(0, 16)),
              _buildDataRow("Modified:", _editingDraft['observation_date'] ?? "N/A"),
            ]),

            // Location Card
            _buildCard([
              const Text("Location Details", style: TextStyle(fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildInfoItem("Region", _editingDraft['region'] ?? "N/A")),
                Expanded(child: _buildInfoItem("Province", _editingDraft['province'] ?? "N/A")),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildInfoItem("Protected Area", _editingDraft['protected_area'] ?? "N/A")),
                Expanded(child: _buildInfoItem("Date", _editingDraft['observation_date'] ?? "N/A")),
              ]),
            ]),

            // Observation Card
            _buildCard([
              const Text("Observation 1", style: TextStyle(fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 12),
              _buildInfoItem("Species Name", _editingDraft['common_name'] ?? "Unnamed"),
              const SizedBox(height: 12),
              _buildInfoItem("Habitat", _editingDraft['habitat_type'] ?? "N/A"),
            ]),

            const SizedBox(height: 24),

            // Buttons (Side by Side)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleEdit(context),
                    icon: Icon(Icons.edit_note, color: forestGreen),
                    label: Text("Edit", style: TextStyle(color: forestGreen)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: forestGreen.withOpacity(0.3)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleDelete(context),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    label: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFFFE0E0)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white, 
      borderRadius: BorderRadius.circular(12), 
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _buildDataRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black38, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.black87, fontSize: 12)),
      ],
    ),
  );

  Widget _buildInfoItem(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.black38)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87)),
    ],
  );
}