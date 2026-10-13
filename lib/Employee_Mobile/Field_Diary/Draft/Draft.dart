import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Collect/observation_model.dart';
import '../Collect/collect01.dart';
import '../Collect/offline_draft_service.dart';
import '../../../theme_provider.dart';
import '../../../theme_constants.dart';

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
  bool _isDeleting = false;

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
    final model = context.read<ObservationModel>();
    if (widget.isOfflineDraft) {
      final draftId = _editingDraft['draft_id']?.toString();
      model.populateFromDraft(
        _editingDraft,
        draftId: draftId,
        localImagePaths: draftId == null
            ? const []
            : widget.offlineService!.getImagePathsForDraft(draftId),
      );
    } else {
      model.populateFromDraft(_editingDraft);
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CollectStep1Screen()),
    );
  }

  // --- LOGIC: DELETE ---
  void _handleDelete(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: getCardBg(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? const Color(0xFF2E3D2F) : Colors.black.withOpacity(0.06),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Delete Draft?",
                style: TextStyle(
                  color: isDark ? Colors.white : darkGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete this ${widget.isOfflineDraft ? 'offline ' : ''}draft? This action cannot be undone.",
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(dialogContext),
            child: Text(
              "Cancel",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _isDeleting
                ? null
                : () async {
                    Navigator.pop(dialogContext);
                    await _performDelete();
                  },
            child: _isDeleting
                ? const Text("Deleting...", style: TextStyle(color: Colors.white))
                : const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete() async {
    if (_isDeleting) return;

    setState(() => _isDeleting = true);

    try {
      if (widget.isOfflineDraft && widget.offlineService != null) {
        final draftId = _editingDraft['draft_id'] as String?;
        if (draftId != null) {
          final serverDraftId = _editingDraft['server_draft_id']?.toString();
          if (serverDraftId != null && serverDraftId.isNotEmpty) {
            try {
              await Supabase.instance.client
                  .from('field_entries')
                  .delete()
                  .eq('id', serverDraftId);
            } catch (_) {}
            try {
              await Supabase.instance.client
                  .from('field_entries')
                  .update({'status': 'ARCHIVED'})
                  .eq('id', serverDraftId);
            } catch (_) {}
          }
          await widget.offlineService!.deleteOfflineDraft(draftId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Offline draft deleted successfully"),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.pop(context, {
              'deleted': true,
              'id': draftId,
              'serverDraftId': serverDraftId,
            });
          }
        }
      } else {
        // Delete online draft from Supabase
        final supabase = Supabase.instance.client;
        final draftId = _editingDraft['id'];
        final user = supabase.auth.currentUser;

        try {
          if (user != null) {
            await supabase
                .from('field_entries')
                .delete()
                .eq('id', draftId)
                .eq('user_id', user.id);
          } else {
            await supabase.from('field_entries').delete().eq('id', draftId);
          }
        } catch (e) {
          debugPrint('Physical delete error: $e');
        }
        try {
          if (user != null) {
            await supabase
                .from('field_entries')
                .update({'status': 'ARCHIVED'})
                .eq('id', draftId)
                .eq('user_id', user.id);
          } else {
            await supabase
                .from('field_entries')
                .update({'status': 'ARCHIVED'})
                .eq('id', draftId);
          }
        } catch (e) {
          debugPrint('Archive status error: $e');
        }

        // Also cleanup offline copy if it exists
        if (widget.offlineService != null) {
          await widget.offlineService!.cleanupSyncedDraft(draftId?.toString());
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Draft deleted successfully"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Pop with result indicating deletion
          Navigator.pop(context, {
            'deleted': true,
            'id': draftId?.toString(),
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        final errorMsg = e.toString();
        debugPrint('Error deleting draft: $errorMsg');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error deleting draft: ${errorMsg.length > 50 ? errorMsg.substring(0, 50) + '...' : errorMsg}",
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  List<String> _getImages() {
    if (widget.isOfflineDraft && widget.offlineService != null) {
      final draftId = _editingDraft['draft_id'] as String?;
      if (draftId != null) {
        return widget.offlineService!.getImagePathsForDraft(draftId);
      }
    } else {
      final urls = _editingDraft['image_urls'];
      if (urls is List) {
        return List<String>.from(urls);
      }
    }
    return [];
  }

  void _showImagePreview(BuildContext context, String pathOrUrl) {
    final isUrl = pathOrUrl.startsWith('http') || pathOrUrl.startsWith('https');
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black,
                ),
                clipBehavior: Clip.antiAlias,
                child: isUrl
                    ? Image.network(pathOrUrl, fit: BoxFit.contain)
                    : Image.file(File(pathOrUrl), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String pathOrUrl) {
    final isUrl = pathOrUrl.startsWith('http') || pathOrUrl.startsWith('https');
    return Container(
      width: 120,
      height: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      clipBehavior: Clip.antiAlias,
      child: isUrl
          ? Image.network(pathOrUrl, fit: BoxFit.cover)
          : (kIsWeb
              ? Image.network(pathOrUrl, fit: BoxFit.cover)
              : Image.file(File(pathOrUrl), fit: BoxFit.cover)),
    );
  }

  Widget _buildImagesSection(bool isDark) {
    final images = _getImages();
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Photos",
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black38)),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              final img = images[index];
              return GestureDetector(
                onTap: () => _showImagePreview(context, img),
                child: _buildImageWidget(img),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeamCard(bool isDark) {
    final List<dynamic>? members = _editingDraft['team_members'];
    if (members == null || members.isEmpty) return const SizedBox.shrink();

    // Filter out completely empty members
    final activeMembers = members.where((m) {
      if (m is! Map) return false;
      final first = m['firstname']?.toString().trim() ?? '';
      final last = m['lastname']?.toString().trim() ?? '';
      return first.isNotEmpty || last.isNotEmpty;
    }).toList();

    if (activeMembers.isEmpty) return const SizedBox.shrink();

    return _buildCard([
      Text("Team Members",
          style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      ...activeMembers.map((m) {
        final map = m as Map;
        final name =
            "${map['firstname'] ?? ''} ${map['lastname'] ?? ''}".trim();
        final role = map['role'] ?? 'Member';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name,
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
              Text(role,
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
            ],
          ),
        );
      }).toList(),
    ], isDark);
  }

  Widget _buildEnvironmentCard(bool isDark) {
    return _buildCard([
      Text("Environment",
          style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: _buildInfoItem("Weather Conditions",
                _editingDraft['weather_condition'] ?? "N/A", isDark)),
        Expanded(
            child: _buildInfoItem(
                "Temperature", "${_editingDraft['temperature'] ?? 'N/A'}°C", isDark)),
      ]),
    ], isDark);
  }

  Widget _buildObservationCard(bool isDark) {
    final List<String> methods = [];
    final discoveryMethod = _editingDraft['discovery_method'];
    if (discoveryMethod != null && discoveryMethod.toString().isNotEmpty) {
      methods.add(discoveryMethod.toString());
    }

    return _buildCard([
      Text("Observation Details",
          style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: _buildInfoItem(
                "Species Name", _editingDraft['common_name'] ?? "Unnamed", isDark)),
        Expanded(
            child: _buildInfoItem(
                "Taxon Group", _editingDraft['taxon_group'] ?? "N/A", isDark)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: _buildInfoItem(
                "Category", _editingDraft['observation_category'] ?? "N/A", isDark)),
        Expanded(
            child: _buildInfoItem(
                "Habitat", _editingDraft['habitat_type'] ?? "N/A", isDark)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: _buildInfoItem(
                "Count/Quantity", _editingDraft['count']?.toString() ?? "0", isDark)),
        Expanded(
            child: _buildInfoItem("Discovery Method",
                methods.isNotEmpty ? methods.join(', ') : "N/A", isDark)),
      ]),
      if (_editingDraft['notes'] != null &&
          _editingDraft['notes'].toString().trim().isNotEmpty) ...[
        const SizedBox(height: 12),
        _buildInfoItem("Observation Notes", _editingDraft['notes'], isDark),
      ],
      if (_getImages().isNotEmpty) ...[
        Divider(height: 32, color: isDark ? Colors.white12 : Colors.black12),
        _buildImagesSection(isDark),
      ],
    ], isDark);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final badgeColor = widget.isOfflineDraft ? Colors.orange : draftBadgeColor;
    final badgeText = widget.isOfflineDraft ? "Offline Draft" : "Draft";

    return Scaffold(
      backgroundColor: getScaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        title: Column(
          children: [
            const Text("Entry Details",
                style: TextStyle(color: Colors.white, fontSize: 16)),
            Text(
                "BMS-${_editingDraft['draft_id']?.toString().substring(0, 5).toUpperCase() ?? _editingDraft['id'].toString().substring(0, 5).toUpperCase()}",
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
              decoration: BoxDecoration(
                  color: badgeColor, borderRadius: BorderRadius.circular(8)),
              child: Text(badgeText,
                  style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
            const SizedBox(height: 16),

            // Offline indicator
            if (widget.isOfflineDraft)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off,
                        color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "This draft is stored offline and will sync when online",
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            // Metadata Card
            _buildCard([
              _buildDataRow("User ID:", "FO-12345", isDark),
              _buildDataRow("Created:",
                  _editingDraft['created_at'].toString().substring(0, 16), isDark),
              _buildDataRow(
                  "Modified:", _editingDraft['observation_date'] ?? "N/A", isDark),
            ], isDark),

            // Team Members Card
            _buildTeamCard(isDark),

            // Location Card
            _buildCard([
              Text("Location Details",
                  style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _buildInfoItem(
                        "Region", _editingDraft['region'] ?? "N/A", isDark)),
                Expanded(
                    child: _buildInfoItem(
                        "Province", _editingDraft['province'] ?? "N/A", isDark)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _buildInfoItem("Protected Area",
                        _editingDraft['protected_area'] ?? "N/A", isDark)),
                Expanded(
                    child: _buildInfoItem(
                        "Observation Date/Time",
                        "${_editingDraft['observation_date'] ?? 'N/A'} ${_editingDraft['observation_time'] ?? ''}"
                            .trim(), isDark)),
              ]),
            ], isDark),

            // Environment Card
            _buildEnvironmentCard(isDark),

            // Observation Details Card (includes photos)
            _buildObservationCard(isDark),

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
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    label: const Text("Delete",
                        style: TextStyle(color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: isDark ? Colors.red.withOpacity(0.3) : const Color(0xFFFFE0E0)),
                      backgroundColor: isDark ? const Color(0xFF2A1F1F) : const Color(0xFFFFF0F0),
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

  Widget _buildCard(List<Widget> children, [bool isDark = false]) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
            color: getCardBg(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF2E3D2F) : Colors.black.withOpacity(0.04)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10)
            ]),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _buildDataRow(String label, String value, [bool isDark = false]) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black38, fontSize: 12)),
            Text(value,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12)),
          ],
        ),
      );

  Widget _buildInfoItem(String label, String value, [bool isDark = false]) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black38)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
        ],
      );
}
