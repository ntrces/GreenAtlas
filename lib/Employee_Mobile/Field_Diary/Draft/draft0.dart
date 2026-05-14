import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../theme_provider.dart';
import '../Collect/offline_draft_service.dart';
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
  late OfflineDraftService _offlineService;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _initOfflineService();
  }

  void _initOfflineService() async {
    _offlineService = OfflineDraftService();
    await _offlineService.init();
    setState(() {});
    _offlineService.addListener(() {
      setState(() {});
    });
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
        actions: [
          if (_offlineService.hasOfflineDrafts && _offlineService.isOnline)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: _isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.cloud_upload),
                        color: forestGreen,
                        tooltip: "Sync offline drafts",
                        onPressed: _syncOfflineDrafts,
                      ),
              ),
            ),
        ],
      ),
      body: userId == null
          ? const Center(child: Text("Please log in"))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Offline indicator
                  if (!_offlineService.isOnline)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      color: Colors.orange.shade600,
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "You are offline",
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
    final offlineDrafts = _offlineService.getAllOfflineDrafts();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(
                  "Offline Drafts (${offlineDrafts.length})",
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54),
                ),
              ],
            ),
          ),
          ...offlineDrafts.map((draft) =>
              _buildOfflineDraftTile(draft, isDark)),
          const Divider(height: 24, thickness: 1),
        ],
      ),
    );
  }

  Widget _buildOnlineDraftsSection(String? userId, bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: userId != null
          ? _supabase
              .from('field_entries')
              .stream(primaryKey: ['id'])
              .eq('user_id', userId)
          : const Stream.empty(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          );
        }

        final drafts = (snapshot.data ?? [])
            .where((d) => d['status'] == 'DRAFT')
            .toList();

        if (drafts.isEmpty && !_offlineService.hasOfflineDrafts) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(
                child: Text("No drafts yet",
                    style: TextStyle(color: Colors.black38))),
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  "Synced Drafts (${drafts.length})",
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54),
                ),
              ),
              ...drafts.map((item) =>
                  _buildDraftTile(context, item, isDark)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfflineDraftTile(
      Map<String, dynamic> draft, bool isDark) {
    final species = draft['common_name'] ?? "Unnamed Entry";
    final dateString = draft['observation_date'] ?? DateTime.now().toString();
    final date = DateFormat('MMM dd, yyyy').format(DateTime.parse(dateString));
    final isSynced = draft['synced'] == true;

    return GestureDetector(
      onTap: () {
        // Show offline draft details
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("This draft will be synced when you go online"),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.1),
              child: Icon(
                isSynced ? Icons.cloud_done : Icons.cloud_queue,
                color: isSynced ? Colors.green : Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(species,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 16)),
                  Text(
                    "Last edited: $date",
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  if (isSynced)
                    const Text(
                      "Synced",
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.w500),
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

  Widget _buildDraftTile(
      BuildContext context, Map<String, dynamic> draft, bool isDark) {
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
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
          ],
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
                  Text(species,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 16)),
                  Text("Last edited: $date",
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black45)),
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