import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../theme_provider.dart';
import '../../../theme_constants.dart';
import '../Collect/offline_draft_service.dart';
import './Draft.dart'; // Import the detail screen

class DraftsListScreen extends StatefulWidget {
  const DraftsListScreen({super.key});

  static final Set<String> locallyDeletedDraftIds = {};

  @override
  State<DraftsListScreen> createState() => _DraftsListScreenState();
}

class _DraftsListScreenState extends State<DraftsListScreen> {
  final _supabase = Supabase.instance.client;
  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);
  late OfflineDraftService _offlineService;
  bool _isSyncing = false;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _initOfflineService(); // Add a small delay to allow Supabase to process updates
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _refreshDraftList();
      }
    });
  }

  void _initOfflineService() async {
    _offlineService = OfflineDraftService();
    await _offlineService.init();
    setState(() {});
    _offlineService.addListener(() {
      if (mounted) {
        setState(() {
          _refreshKey++; // Force rebuild with new key
        });
      }
    });
  }

  void _refreshDraftList() {
    if (mounted) {
      setState(() {
        _refreshKey++;
      });
    }
  }

  @override
  void dispose() {
    _offlineService.dispose();
    super.dispose();
  }

  Future<void> _syncOfflineDrafts() async {
    setState(() => _isSyncing = true);
    try {
      await _offlineService.syncAllPendingDrafts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("All offline drafts synced successfully"),
            duration: Duration(seconds: 2),
          ),
        );
        // Refresh the UI to show synced drafts
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();

        // Check for authentication error
        if (errorMsg.contains('Authentication required')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Please log in again to sync your drafts.",
              ),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Log In',
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Sync error: $errorMsg"),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<bool> _confirmDeleteDraft(BuildContext context, bool isDark,
      {bool isOffline = false}) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            backgroundColor: getCardBg(isDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF2E3D2F)
                    : Colors.black.withOpacity(0.06),
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
                  child: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isOffline ? "Delete Offline Draft?" : "Delete Draft?",
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
              "Are you sure you want to delete this ${isOffline ? 'offline ' : ''}draft? This action cannot be undone.",
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  "Cancel",
                  style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text("Delete",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteOfflineDraft(String draftId,
      [String? serverDraftId]) async {
    setState(() {
      DraftsListScreen.locallyDeletedDraftIds.add(draftId);
      if (serverDraftId != null) {
        DraftsListScreen.locallyDeletedDraftIds.add(serverDraftId);
      }
    });

    try {
      final user = _supabase.auth.currentUser;
      if (serverDraftId != null && serverDraftId.isNotEmpty) {
        try {
          if (user != null) {
            await _supabase
                .from('field_entries')
                .delete()
                .eq('id', serverDraftId)
                .eq('user_id', user.id);
          } else {
            await _supabase.from('field_entries').delete().eq('id', serverDraftId);
          }
        } catch (_) {}
        try {
          if (user != null) {
            await _supabase
                .from('field_entries')
                .update({'status': 'ARCHIVED'})
                .eq('id', serverDraftId)
                .eq('user_id', user.id);
          } else {
            await _supabase
                .from('field_entries')
                .update({'status': 'ARCHIVED'})
                .eq('id', serverDraftId);
          }
        } catch (_) {}
      }
      await _offlineService.deleteOfflineDraft(draftId);
      if (serverDraftId != null) {
        await _offlineService.cleanupSyncedDraft(serverDraftId);
      }
      if (mounted) {
        _refreshDraftList();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Offline draft deleted successfully"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting draft: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteOnlineDraft(dynamic draftId) async {
    final strId = draftId.toString();
    setState(() {
      DraftsListScreen.locallyDeletedDraftIds.add(strId);
    });

    try {
      final user = _supabase.auth.currentUser;
      try {
        if (user != null) {
          await _supabase
              .from('field_entries')
              .delete()
              .eq('id', draftId)
              .eq('user_id', user.id);
        } else {
          await _supabase.from('field_entries').delete().eq('id', draftId);
        }
      } catch (e) {
        debugPrint('Physical delete error: $e');
      }
      try {
        if (user != null) {
          await _supabase
              .from('field_entries')
              .update({'status': 'ARCHIVED'})
              .eq('id', draftId)
              .eq('user_id', user.id);
        } else {
          await _supabase
              .from('field_entries')
              .update({'status': 'ARCHIVED'})
              .eq('id', draftId);
        }
      } catch (e) {
        debugPrint('Archive status error: $e');
      }
      try {
        await _offlineService.cleanupSyncedDraft(strId);
      } catch (e) {
        debugPrint('Cleanup error: $e');
      }

      if (mounted) {
        _refreshDraftList();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Draft deleted successfully"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting draft: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final userId = _supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: getScaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: getCardBg(isDark),
        elevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: isDark
                ? const Color(0xFF2E3D2F)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        title: Text(
          "My Drafts",
          style: TextStyle(
            color: isDark ? Colors.white : darkGreen,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : darkGreen,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_offlineService.hasPendingOfflineDrafts &&
              _offlineService.isOnline)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: _isSyncing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? leafAccent : forestGreen,
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.cloud_upload),
                        color: isDark ? leafAccent : forestGreen,
                        tooltip: "Sync offline drafts",
                        onPressed: _syncOfflineDrafts,
                      ),
              ),
            ),
        ],
      ),
      body: userId == null
          ? Center(
              child: Text(
                "Please log in",
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Offline indicator
                  if (!_offlineService.isOnline)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      color: Colors.orange.shade700,
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            "You are offline - Drafts will be saved locally",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  // Offline drafts section
                  if (_offlineService.hasOfflineDrafts)
                    _buildOfflineDraftsSection(isDark),
                  // Online drafts section
                  _buildOnlineDraftsSection(userId, isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildOfflineDraftsSection(bool isDark) {
    final offlineDrafts = _offlineService
        .getAllOfflineDrafts()
        .where((draft) =>
            (!_offlineService.isOnline || draft['synced'] != true) &&
            !DraftsListScreen.locallyDeletedDraftIds
                .contains(draft['draft_id']?.toString()) &&
            !DraftsListScreen.locallyDeletedDraftIds
                .contains(draft['server_draft_id']?.toString()))
        .toList();

    if (offlineDrafts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.cloud_off, size: 18, color: Colors.orange.shade400),
                const SizedBox(width: 8),
                Text(
                  "Offline Drafts (${offlineDrafts.length})",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          ...offlineDrafts
              .map((draft) => _buildOfflineDraftTile(draft, isDark)),
          Divider(
            height: 32,
            thickness: 0.5,
            color: isDark ? const Color(0xFF2E3D2F) : Colors.black12,
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineDraftsSection(String? userId, bool isDark) {
    return KeyedSubtree(
      key: ValueKey('online_drafts_$_refreshKey'),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: userId != null
            ? _supabase
                .from('field_entries')
                .stream(primaryKey: ['id']).eq('user_id', userId)
            : const Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: isDark ? leafAccent : forestGreen,
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            debugPrint('Stream error: ${snapshot.error}');
            return const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: Text("Error loading drafts",
                    style: TextStyle(color: Colors.red)),
              ),
            );
          }

          final drafts = (snapshot.data ?? [])
              .where((d) =>
                  d['status'] == 'DRAFT' &&
                  !DraftsListScreen.locallyDeletedDraftIds
                      .contains(d['id']?.toString()))
              .toList();

          if (drafts.isEmpty && !_offlineService.hasOfflineDrafts) {
            return Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Text(
                  "No drafts yet",
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }

          if (drafts.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_done_rounded,
                        size: 18,
                        color: isDark ? leafAccent : forestGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Synced Drafts (${drafts.length})",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                ...drafts.map((item) => _buildDraftTile(context, item, isDark)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfflineDraftTile(Map<String, dynamic> draft, bool isDark) {
    final species = draft['common_name'] ?? "Unnamed Entry";
    final dateString = draft['observation_date'] ?? DateTime.now().toString();
    final date = DateFormat('MMM dd, yyyy').format(DateTime.parse(dateString));
    final isSynced = draft['synced'] == true;
    final draftId = draft['draft_id'] as String;
    final serverDraftId = draft['server_draft_id']?.toString();

    return Dismissible(
      key: ValueKey('offline_$draftId$_refreshKey'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _confirmDeleteDraft(context, isDark, isOffline: true);
      },
      onDismissed: (direction) async {
        await _deleteOfflineDraft(draftId, serverDraftId);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: getCardBg(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF2E3D2F)
                : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DraftDetailScreen(
                  draft: draft,
                  isOfflineDraft: true,
                  offlineService: _offlineService,
                ),
              ),
            ).then((result) {
              if (result is Map && result['deleted'] == true) {
                final delId = result['id']?.toString();
                final srvId = result['serverDraftId']?.toString();
                setState(() {
                  if (delId != null) {
                    DraftsListScreen.locallyDeletedDraftIds.add(delId);
                  }
                  if (srvId != null) {
                    DraftsListScreen.locallyDeletedDraftIds.add(srvId);
                  }
                });
              } else if (result == true) {
                setState(() {
                  DraftsListScreen.locallyDeletedDraftIds.add(draftId);
                  if (serverDraftId != null) {
                    DraftsListScreen.locallyDeletedDraftIds.add(serverDraftId);
                  }
                });
              }
              _refreshDraftList();
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF253326)
                        : Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSynced ? Icons.cloud_done : Icons.cloud_queue,
                    color: isSynced
                        ? (isDark ? leafAccent : Colors.green)
                        : Colors.orange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        species,
                        style: TextStyle(
                          color: isDark ? Colors.white : darkGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Last edited: $date",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      if (isSynced) ...[
                        const SizedBox(height: 2),
                        Text(
                          "Synced",
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? leafAccent : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: isDark ? Colors.red.shade300 : Colors.redAccent,
                    size: 22,
                  ),
                  tooltip: "Delete draft",
                  onPressed: () async {
                    final confirmed = await _confirmDeleteDraft(context, isDark,
                        isOffline: true);
                    if (confirmed) {
                      await _deleteOfflineDraft(draftId, serverDraftId);
                    }
                  },
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: isDark ? Colors.white38 : Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraftTile(
      BuildContext context, Map<String, dynamic> draft, bool isDark) {
    final species = draft['common_name'] ?? "Unnamed Entry";
    final dateString = draft['observation_date'] ?? DateTime.now().toString();
    final date = DateFormat('MMM dd, yyyy').format(DateTime.parse(dateString));
    final draftId = draft['id'];

    return Dismissible(
      key: ValueKey('online_$draftId$_refreshKey'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _confirmDeleteDraft(context, isDark, isOffline: false);
      },
      onDismissed: (direction) async {
        await _deleteOnlineDraft(draftId);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: getCardBg(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF2E3D2F)
                : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DraftDetailScreen(
                  draft: draft,
                  offlineService: _offlineService,
                ),
              ),
            ).then((result) {
              if (result is Map && result['deleted'] == true) {
                final delId = result['id']?.toString();
                if (delId != null) {
                  setState(() {
                    DraftsListScreen.locallyDeletedDraftIds.add(delId);
                  });
                }
              } else if (result == true) {
                setState(() {
                  DraftsListScreen.locallyDeletedDraftIds.add(draftId.toString());
                });
              }
              _refreshDraftList();
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF253326)
                        : forestGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.edit_document,
                    color: isDark ? leafAccent : forestGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        species,
                        style: TextStyle(
                          color: isDark ? Colors.white : darkGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Last edited: $date",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: isDark ? Colors.red.shade300 : Colors.redAccent,
                    size: 22,
                  ),
                  tooltip: "Delete draft",
                  onPressed: () async {
                    final confirmed =
                        await _confirmDeleteDraft(context, isDark);
                    if (confirmed) {
                      await _deleteOnlineDraft(draftId);
                    }
                  },
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: isDark ? Colors.white38 : Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
