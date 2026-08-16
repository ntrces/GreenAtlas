import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File, Platform;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OfflineDraftService extends ChangeNotifier {
  late Box<Map> _draftsBox;
  late Box<String> _imagesBox;
  bool _isOnline = true;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  bool get isOnline => _isOnline;
  bool get hasOfflineDrafts => _draftsBox.isOpen && _draftsBox.isNotEmpty;
  bool get hasPendingOfflineDrafts =>
      _draftsBox.isOpen &&
      _draftsBox.values.any((draft) => draft['synced'] != true);

  // Stream to notify when online status changes
  Stream<bool> get onOnlineStatusChanged => _connectivity.onConnectivityChanged
      .map((result) => result != ConnectivityResult.none)
      .distinct();

  /// Initialize the offline draft service
  Future<void> init() async {
    await Hive.initFlutter();
    _draftsBox = await Hive.openBox<Map>('offline_drafts');
    _imagesBox = await Hive.openBox<String>('offline_images');

    // Check initial connectivity
    await _checkConnectivity();
    if (_isOnline) {
      unawaited(_syncPendingDrafts());
    }

    // Listen to connectivity changes
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      if (wasOnline != _isOnline) {
        notifyListeners();
        if (_isOnline) {
          _syncPendingDrafts();
        }
      }
    });
  }

  /// Check if user session is valid
  /// (Kept for debugging purposes)
  Future<bool> isSessionValid() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      return user != null;
    } catch (e) {
      debugPrint('Session validity check failed: $e');
      return false;
    }
  }

  /// Clear all offline drafts (call this when user logs out)
  Future<void> clearAllOfflineDrafts() async {
    if (!_draftsBox.isOpen || !_imagesBox.isOpen) {
      debugPrint('Offline service not initialized');
      return;
    }
    await _draftsBox.clear();
    await _imagesBox.clear();
    notifyListeners();
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
    } catch (e) {
      _isOnline = false;
    }
  }

  /// Save draft offline (no session check - purely local storage)
  Future<String> saveDraftOffline(Map<String, dynamic> draftData) async {
    if (!_draftsBox.isOpen) {
      throw Exception(
          'Offline storage service not initialized. Please restart the app.');
    }

    final draftId = DateTime.now().millisecondsSinceEpoch.toString();
    final draftWithMetadata = {
      ...draftData,
      'draft_id': draftId,
      'created_at': DateTime.now().toIso8601String(),
      'synced': false,
      'sync_attempts': 0,
    };

    // Save to local Hive database - NO session check needed
    await _draftsBox.put(draftId, draftWithMetadata);
    notifyListeners();
    return draftId;
  }

  /// Copy draft photos into durable app storage, then remember those paths.
  Future<void> saveImagePathsOffline(
      String draftId, List<String> imagePaths) async {
    if (!_imagesBox.isOpen) {
      throw Exception(
          'Offline storage service not initialized. Please restart the app.');
    }

    final imageKey = 'images_$draftId';
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final draftImageDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}'
      'offline_draft_images${Platform.pathSeparator}$draftId',
    );
    await draftImageDirectory.create(recursive: true);

    final durablePaths = <String>[];
    for (var index = 0; index < imagePaths.length; index++) {
      final sourcePath = imagePaths[index];
      if (sourcePath.startsWith('http://') ||
          sourcePath.startsWith('https://')) {
        durablePaths.add(sourcePath);
        continue;
      }

      final source = File(sourcePath);
      if (!source.existsSync()) continue;
      if (source.path.startsWith(draftImageDirectory.path)) {
        durablePaths.add(source.path);
        continue;
      }

      final sourceName = source.uri.pathSegments.isEmpty
          ? 'photo.jpg'
          : source.uri.pathSegments.last;
      final destination = File(
        '${draftImageDirectory.path}${Platform.pathSeparator}'
        '${index}_$sourceName',
      );
      await source.copy(destination.path);
      durablePaths.add(destination.path);
    }

    await _imagesBox.put(imageKey, jsonEncode(durablePaths));
  }

  /// Get all offline drafts
  List<Map<String, dynamic>> getAllOfflineDrafts() {
    if (!_draftsBox.isOpen) {
      debugPrint('Offline draft service not initialized');
      return [];
    }
    return _draftsBox.values
        .map((draft) => Map<String, dynamic>.from(draft as Map))
        .toList();
  }

  /// Get specific offline draft
  Map<String, dynamic>? getOfflineDraft(String draftId) {
    if (!_draftsBox.isOpen) {
      debugPrint('Offline draft service not initialized');
      return null;
    }
    final draft = _draftsBox.get(draftId);
    return draft != null ? Map<String, dynamic>.from(draft as Map) : null;
  }

  /// Get image paths for a draft
  List<String> getImagePathsForDraft(String draftId) {
    if (!_imagesBox.isOpen) {
      debugPrint('Offline image service not initialized');
      return [];
    }
    final imageKey = 'images_$draftId';
    final imageJson = _imagesBox.get(imageKey);
    if (imageJson != null) {
      try {
        return List<String>.from(jsonDecode(imageJson));
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  /// Update draft sync status
  Future<void> updateDraftSyncStatus(
    String draftId,
    bool synced, {
    String? serverDraftId,
  }) async {
    if (!_draftsBox.isOpen) {
      debugPrint('Offline draft service not initialized');
      return;
    }
    final draft = _draftsBox.get(draftId);
    if (draft != null) {
      final updated = Map<String, dynamic>.from(draft as Map);
      updated['synced'] = synced;
      if (serverDraftId != null) {
        updated['server_draft_id'] = serverDraftId;
      }
      updated['sync_attempts'] = (updated['sync_attempts'] ?? 0) + 1;
      await _draftsBox.put(draftId, updated);
      notifyListeners();
    }
  }

  Map<String, dynamic>? getOfflineDraftByServerId(String serverDraftId) {
    for (final draft in getAllOfflineDrafts()) {
      if (draft['server_draft_id']?.toString() == serverDraftId) {
        return draft;
      }
    }
    return null;
  }

  /// Update offline draft content
  Future<void> updateOfflineDraft(
      String draftId, Map<String, dynamic> updatedData) async {
    if (!_draftsBox.isOpen) {
      throw Exception(
          'Offline storage service not initialized. Please restart the app.');
    }
    final draft = _draftsBox.get(draftId);
    if (draft != null) {
      final updated = Map<String, dynamic>.from(draft as Map);
      // Merge updated data while preserving metadata
      updated.addAll(updatedData);
      updated['draft_id'] = draftId; // Preserve draft ID
      updated['created_at'] =
          draft['created_at']; // Preserve creation timestamp
      await _draftsBox.put(draftId, updated);
      notifyListeners();
    }
  }

  /// Delete offline draft and associated image files
  Future<void> deleteOfflineDraft(String draftId) async {
    if (!_draftsBox.isOpen || !_imagesBox.isOpen) {
      debugPrint('Offline service not initialized');
      return;
    }

    try {
      // Get image paths for cleanup
      final imagePaths = getImagePathsForDraft(draftId);

      // Delete image files from device storage
      for (final imagePath in imagePaths) {
        try {
          final file = File(imagePath);
          if (file.existsSync()) {
            await file.delete();
            debugPrint('Deleted image file: $imagePath');
          }
        } catch (e) {
          debugPrint('Error deleting image file $imagePath: $e');
          // Continue deleting other files even if one fails
        }
      }

      // Delete from Hive storage
      await _draftsBox.delete(draftId);
      final imageKey = 'images_$draftId';
      await _imagesBox.delete(imageKey);

      debugPrint('Offline draft deleted: $draftId');
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting offline draft: $e');
      rethrow;
    }
  }

  /// Safe delete offline draft - returns success/failure instead of throwing
  Future<bool> safeDeleteOfflineDraft(String draftId) async {
    try {
      await deleteOfflineDraft(draftId);
      return true;
    } catch (e) {
      debugPrint('Safe delete failed for $draftId: $e');
      return false;
    }
  }

  /// Sync pending drafts when online
  Future<void> _syncPendingDrafts() async {
    if (!_isOnline) return;

    final drafts = getAllOfflineDrafts();
    for (final draft in drafts) {
      if (draft['synced'] != true) {
        await _syncDraft(draft);
      }
    }
  }

  /// Sync a single draft to Supabase
  Future<bool> _syncDraft(Map<String, dynamic> draft) async {
    try {
      final draftId = draft['draft_id'] as String;
      final imagePaths = getImagePathsForDraft(draftId);

      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final userId = user?.id;

      if (userId == null) {
        debugPrint('No authenticated user - sync requires re-login');
        throw Exception(
          'Authentication required. Please log in to sync drafts.',
        );
      }

      // Upload images if any
      List<String> uploadedUrls = [];
      for (final path in imagePaths) {
        try {
          if (File(path).existsSync()) {
            final fileName =
                '${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
            final storagePath = '$userId/$fileName';
            final bytes = await File(path).readAsBytes();

            await supabase.storage
                .from('observation-photos')
                .uploadBinary(storagePath, bytes);

            final String publicUrl = supabase.storage
                .from('observation-photos')
                .getPublicUrl(storagePath);
            uploadedUrls.add(publicUrl);
          }
        } catch (e) {
          debugPrint('Error uploading image: $e');
        }
      }

      // Update image URLs in draft
      draft['image_urls'] = uploadedUrls;

      // Upsert species data
      final speciesData = await supabase
          .from('observed_species')
          .upsert({
            'common_name': draft['common_name'] ?? 'Unnamed',
            'taxon_group': draft['taxon_group'] ?? '',
          }, onConflict: 'common_name')
          .select()
          .single();

      draft['species_id'] = speciesData['id'];

      final submissionIntent =
          draft['submission_intent']?.toString() == 'submit'
              ? 'submit'
              : 'draft';

      // Prepare database record
      final Map<String, dynamic> dbData = {
        'user_id': userId,
        'species_id': draft['species_id'],
        'image_urls': uploadedUrls,
        'team_members': draft['team_members'] ?? [],
        'region': draft['region'] ?? '',
        'province': draft['province'] ?? '',
        'protected_area': draft['protected_area'] ?? '',
        'weather_condition': draft['weather_condition'] ?? '',
        'temperature': draft['temperature'] ?? 0,
        'observation_date': draft['observation_date'] ??
            DateTime.now().toString().split(' ')[0],
        'observation_time': draft['observation_time'] ?? '00:00:00',
        'observation_category': draft['observation_category'] ?? '',
        'habitat_type': draft['habitat_type'] ?? '',
        'taxon_group': draft['taxon_group'] ?? '',
        'common_name': draft['common_name'] ?? 'Unnamed',
        'is_unlisted': draft['is_unlisted'] ?? false,
        'count': draft['count'] ?? 0,
        'discovery_method': draft['discovery_method'] ?? '',
        'notes': draft['notes'] ?? '',
        'status': submissionIntent == 'submit' ? 'PENDING' : 'DRAFT',
      };

      String? serverEntryId;
      final isResubmit = draft['is_resubmit'] == true;
      final originalDraftId = draft['original_draft_id']?.toString();
      final existingServerDraftId = draft['server_draft_id']?.toString();
      if (isResubmit && originalDraftId != null && originalDraftId.isNotEmpty) {
        dbData['resubmit_count'] = (draft['resubmit_count'] is int
                ? draft['resubmit_count'] as int
                : int.tryParse(draft['resubmit_count']?.toString() ?? '') ??
                    0) +
            1;
        dbData['confidence_score'] = null;
        dbData['auto_validation_reason'] = null;
        dbData['admin_feedback'] = null;
        dbData['modified_at'] = DateTime.now().toIso8601String();
        await supabase
            .from('field_entries')
            .update(dbData)
            .eq('id', originalDraftId);
        serverEntryId = originalDraftId;
      } else if (existingServerDraftId != null &&
          existingServerDraftId.isNotEmpty) {
        await supabase
            .from('field_entries')
            .update(dbData)
            .eq('id', existingServerDraftId);
        serverEntryId = existingServerDraftId;
      } else {
        final inserted = await supabase
            .from('field_entries')
            .insert(dbData)
            .select('id')
            .single();
        serverEntryId = inserted['id']?.toString();
      }

      // Log audit entry
      await supabase.from('audit_logs').insert({
        'title': 'Offline Draft Synced',
        'description':
            'Offline draft for ${draft['common_name']} synced to server',
        'category': 'Field Data',
        'ip_address': 'Mobile App',
        'result': 'Success',
        'severity': 'Low',
        'user': user?.email ?? 'Unknown',
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final localDraftId = draft['draft_id'] as String;
      if (submissionIntent == 'submit') {
        // A queued Submit belongs in Sent, not in Drafts.
        await deleteOfflineDraft(localDraftId);
      } else {
        // Explicitly saved drafts stay editable and retain their server identity.
        await updateDraftSyncStatus(
          localDraftId,
          true,
          serverDraftId: serverEntryId,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error syncing draft: $e');
      return false;
    }
  }

  /// Manually trigger sync of all pending drafts
  /// Throws exception if offline or if authentication is required
  Future<void> syncAllPendingDrafts() async {
    if (!_isOnline) {
      throw Exception(
          'Device is offline. Please check your internet connection.');
    }

    await _syncPendingDrafts();
  }

  /// Clean up offline copy of a synced draft
  /// Call this when a synced draft is deleted online to remove the offline copy
  Future<void> cleanupSyncedDraft(String? draftId) async {
    if (draftId == null || draftId.isEmpty) return;

    // Ensure boxes are initialized before accessing
    if (!_draftsBox.isOpen || !_imagesBox.isOpen) {
      debugPrint('Offline service not initialized, skipping cleanup');
      return;
    }

    try {
      // Check if this draft exists offline
      final offlineDraft =
          getOfflineDraft(draftId) ?? getOfflineDraftByServerId(draftId);
      if (offlineDraft != null && offlineDraft['synced'] == true) {
        // Delete the offline copy since it's been synced
        await deleteOfflineDraft(offlineDraft['draft_id'].toString());
        debugPrint('Cleaned up synced draft: $draftId');
      }
    } catch (e) {
      debugPrint('Error cleaning up synced draft: $e');
      // Don't throw - this is a cleanup operation
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
