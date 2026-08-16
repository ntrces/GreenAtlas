import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import '../../theme_provider.dart';
import '../../theme_constants.dart';
import '../user_dashboard.dart';
import '../Botanical_Gallery/ar_gallery.dart';
import '../../UserProfile/user_profile.dart';
import '../../components/notification_badge.dart';

const String _arModelBaseUrl = String.fromEnvironment(
  'AR_MODEL_BASE_URL',
  defaultValue: '',
);

// Tree model data class
class TreeModel {
  final String name;
  final String scientificName;
  final String assetPath;
  final Color color;
  final String? remoteModelFile;
  final String conservationStatus;
  final String habitat;
  final String ecologicalImportance;

  const TreeModel({
    required this.name,
    required this.scientificName,
    required this.assetPath,
    required this.color,
    this.remoteModelFile,
    this.conservationStatus = 'Threatened',
    this.habitat = 'Native forest habitats in Cavite and the Philippines',
    this.ecologicalImportance =
        'This native tree supports forest biodiversity and deserves protection.',
  });
}

// Sample threatened trees from Cavite Protected Area - ordered by conservation status
// CR (Critically Endangered) > EN (Endangered) > VU (Vulnerable)
const List<TreeModel> threatenedTrees = [
  // Critically Endangered (CR)
  TreeModel(
    name: 'Subyang',
    scientificName: 'Hopea quisumbingiana',
    assetPath: 'assets/paho.glb',
    color: Colors.red,
  ),
  // Endangered (EN)
  TreeModel(
    name: 'Molave',
    scientificName: 'Vitex parviflora',
    assetPath: 'assets/paho.glb',
    color: Colors.orange,
  ),
  TreeModel(
    name: 'Manggachapui',
    scientificName: 'Hopea acuminata',
    assetPath: 'assets/paho.glb',
    color: Colors.orange,
  ),
  TreeModel(
    name: 'Kubili',
    scientificName: 'Cubilia cubili',
    assetPath: 'assets/paho.glb',
    color: Colors.orange,
  ),
  // Vulnerable (VU)
  TreeModel(
    name: 'Dao',
    scientificName: 'Dracontomelon dao',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Paho',
    scientificName: 'Mangifera altissima',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Narra',
    scientificName: 'Pterocarpus indicus',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Kamagong',
    scientificName: 'Diospyros discolor',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Kalantas',
    scientificName: 'Toona calantas',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
    remoteModelFile: 'kalantas.glb',
    conservationStatus: 'Vulnerable',
    habitat:
        'Native lowland forests of Luzon, including remaining Cavite forests',
    ecologicalImportance:
        'Kalantas shelters wildlife and helps restore native forest structure. Every surviving tree is part of a living heritage worth protecting.',
  ),
  TreeModel(
    name: 'Dila-dila',
    scientificName: 'Cynometra ramiflora',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Haikan',
    scientificName: 'Koilodepas bantamense',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Malachio',
    scientificName: 'Aglaia rimosa',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Bagarilau',
    scientificName: 'Cryptocarya edanoii',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Nato',
    scientificName: 'Palaquium luzoniense',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Malak-malak',
    scientificName: 'Palaquium philippense',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
  TreeModel(
    name: 'Katmon',
    scientificName: 'Dillenia philippinensis',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
  ),
];

class Ar_View extends StatefulWidget {
  final String? initialSpeciesName;
  final String? initialScientificName;
  final String? initialSpeciesID;

  const Ar_View({
    super.key,
    this.initialSpeciesName,
    this.initialScientificName,
    this.initialSpeciesID,
  });

  @override
  State<Ar_View> createState() => _Ar_ViewState();
}

class _Ar_ViewState extends State<Ar_View> {
  int _selectedIndex = 2;
  TreeModel? _viewingArTree; // Tree currently being viewed in AR
  bool _hasPermission = false;
  bool _isLoading = true;
  bool _unitySceneReady = false;
  bool _unityAttachMessageScheduled = false;
  String? _viewingSpeciesID;
  String _arStatus = 'Starting Unity…';
  String? _arError;
  Timer? _arStartupTimer;
  bool _plantPlaced = false;
  bool _growthComplete = false;
  int _wateringCount = 0;
  int _wateringsRequired = 3;
  double _growthDistanceMeters = 0;
  bool _modelDownloadRequired = false;
  bool _modelDownloading = false;
  int _modelDownloadPercent = 0;
  String? _viewingModelPath;
  String? _shelfDownloadingSpeciesID;
  int _shelfDownloadPercent = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialSpeciesID != null) {
      _viewingSpeciesID = widget.initialSpeciesID;
      _viewingArTree = TreeModel(
        name: widget.initialSpeciesName ?? widget.initialSpeciesID!,
        scientificName: widget.initialScientificName ?? '',
        assetPath: '',
        color: Colors.green,
        remoteModelFile:
            widget.initialSpeciesID == 'Toona_calantas' ? 'kalantas.glb' : null,
      );
      _startArTimeout();
    }
    _checkPermission(request: _viewingArTree != null);
  }

  @override
  void dispose() {
    _arStartupTimer?.cancel();
    super.dispose();
  }

  Future<bool> _checkPermission({bool request = false}) async {
    var status = await Permission.camera.status;
    if (request && !status.isGranted) {
      status = await Permission.camera.request();
    }
    if (mounted) {
      setState(() {
        _hasPermission = status.isGranted;
        _isLoading = false;
      });
    }
    return status.isGranted;
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    if (index == 0)
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const UserDashboard()));
    if (index == 1)
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ARGalleryScreen()));
  }

  Future<void> _viewPlantInAR(TreeModel tree) async {
    final modelPath = await _ensureModelDownloaded(tree);
    if (modelPath == null || !mounted) return;
    if (!_hasPermission && !await _checkPermission(request: true)) return;
    setState(() {
      _unitySceneReady = false;
      _unityAttachMessageScheduled = false;
      _viewingSpeciesID =
          tree.scientificName.trim().replaceAll(RegExp(r'\s+'), '_');
      _viewingArTree = tree;
      _viewingModelPath = modelPath;
      _arStatus = 'Starting Unity…';
      _arError = null;
      _plantPlaced = false;
      _growthComplete = false;
      _wateringCount = 0;
      _growthDistanceMeters = 0;
      _modelDownloadRequired = false;
      _modelDownloading = false;
      _modelDownloadPercent = 0;
    });
    _startArTimeout();
  }

  void _closeARViewer() {
    _arStartupTimer?.cancel();
    sendToUnity('Plant_Anchor', 'StopExperience', 'exit');
    setState(() {
      _unitySceneReady = false;
      _unityAttachMessageScheduled = false;
      _viewingSpeciesID = null;
      _viewingArTree = null;
      _viewingModelPath = null;
      _arStatus = 'Starting Unity…';
      _arError = null;
      _plantPlaced = false;
      _growthComplete = false;
      _wateringCount = 0;
      _growthDistanceMeters = 0;
      _modelDownloadRequired = false;
      _modelDownloading = false;
      _modelDownloadPercent = 0;
    });
  }

  void _startArTimeout() {
    _arStartupTimer?.cancel();
    _arStartupTimer = Timer(const Duration(seconds: 18), () {
      if (!mounted || _viewingArTree == null || _arStatus == 'AR ready') return;
      setState(() {
        _arError =
            'AR did not begin tracking. Check that Google Play Services for '
            'AR is installed and that this device supports ARCore.';
      });
    });
  }

  void _sendSelectedSpecies() {
    if (_viewingArTree == null || _viewingSpeciesID == null) return;
    final modelLocation = _viewingModelPath == null
        ? ''
        : Uri.file(_viewingModelPath!).toString();
    sendToUnity(
      'Plant_Anchor',
      'LoadSelectedSpecies',
      '${_viewingSpeciesID!}|$modelLocation',
    );
  }

  Future<String?> _ensureModelDownloaded(TreeModel tree) async {
    final modelFile = tree.remoteModelFile;
    if (modelFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${tree.name} does not have an AR model yet.')),
        );
      }
      return null;
    }

    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/greenatlas_ar_models');
    final target = File('${directory.path}/$modelFile');
    if (await target.exists() && await target.length() > 0) return target.path;

    if (_arModelBaseUrl.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('The AR model server is not configured.')),
        );
      }
      return null;
    }

    if (!mounted) return null;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Download ${tree.name} for AR?'),
        content: const Text(
          'The 3D tree is downloaded once and kept on this device for offline AR use. You can continue using GreenAtlas without downloading it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return null;

    final base = _arModelBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final temporary = File('${target.path}.download');
    HttpClient? client;
    IOSink? sink;
    try {
      setState(() {
        _shelfDownloadingSpeciesID =
            tree.scientificName.trim().replaceAll(RegExp(r'\s+'), '_');
        _shelfDownloadPercent = 0;
      });
      await directory.create(recursive: true);
      if (await temporary.exists()) await temporary.delete();

      client = HttpClient();
      final request = await client.getUrl(Uri.parse('$base/$modelFile'));
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Server returned ${response.statusCode}');
      }

      sink = temporary.openWrite();
      var received = 0;
      final total = response.contentLength;
      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (mounted && total > 0) {
          final percent = ((received / total) * 100).round().clamp(0, 99);
          if (percent != _shelfDownloadPercent) {
            setState(() => _shelfDownloadPercent = percent);
          }
        }
      }
      await sink.flush();
      await sink.close();
      sink = null;
      if (await target.exists()) await target.delete();
      await temporary.rename(target.path);
      if (mounted) {
        setState(() => _shelfDownloadPercent = 100);
      }
      return target.path;
    } catch (error) {
      await sink?.close();
      if (await temporary.exists()) await temporary.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Model download failed: $error')),
        );
      }
      return null;
    } finally {
      client?.close(force: true);
      if (mounted) {
        setState(() {
          _shelfDownloadingSpeciesID = null;
          _shelfDownloadPercent = 0;
        });
      }
    }
  }

  void _downloadSelectedModel() {
    if (_modelDownloading || !_modelDownloadRequired) return;
    if (_arModelBaseUrl.trim().isEmpty) {
      setState(() {
        _arError = 'The AR model server has not been configured yet.';
      });
      return;
    }
    setState(() {
      _modelDownloading = true;
      _modelDownloadPercent = 0;
      _arError = null;
      _arStatus = 'Downloading ${_viewingArTree!.name} model…';
    });
    sendToUnity('Plant_Anchor', 'DownloadSelectedSpecies', 'download');
  }

  void _onMessageFromUnity(String message) {
    debugPrint('Message received from Unity: $message');
    if (message == 'scene_loaded') {
      if (mounted) {
        setState(() {
          _unitySceneReady = true;
          _arStatus = 'Unity loaded • Starting ARCore…';
        });
      }
      _sendSelectedSpecies();
    } else if (message == 'ar_ready') {
      _arStartupTimer?.cancel();
      if (mounted) {
        setState(() {
          _arStatus = 'AR ready';
          _arError = null;
        });
      }
    } else if (message.startsWith('status:')) {
      if (mounted) setState(() => _arStatus = message.substring(7));
    } else if (message.startsWith('error:')) {
      if (mounted) {
        setState(() {
          _arError = message.substring(6);
          _modelDownloading = false;
        });
      }
    } else if (message.startsWith('model_download_required:')) {
      if (mounted) {
        setState(() {
          _modelDownloadRequired = true;
          _modelDownloading = false;
          _modelDownloadPercent = 0;
        });
      }
    } else if (message.startsWith('model_download_progress:')) {
      final percent = int.tryParse(message.substring(24));
      if (mounted && percent != null) {
        setState(() {
          _modelDownloading = percent < 100;
          _modelDownloadPercent = percent.clamp(0, 100);
          _arStatus = 'Downloading model… $_modelDownloadPercent%';
        });
      }
    } else if (message == 'model_downloaded' || message == 'model_ready') {
      if (mounted) {
        setState(() {
          _modelDownloadRequired = false;
          _modelDownloading = false;
          _modelDownloadPercent = 100;
          _arError = null;
        });
      }
    } else if (message == 'plant_placed') {
      if (mounted) {
        setState(() {
          _plantPlaced = true;
          _growthComplete = false;
          _wateringCount = 0;
          _arStatus = 'Sprout placed • Water it to help it grow';
        });
      }
    } else if (message.startsWith('growth:')) {
      final parts = message.substring(7).split('/');
      final current = int.tryParse(parts.first);
      final required = parts.length > 1 ? int.tryParse(parts[1]) : null;
      if (mounted && current != null) {
        setState(() {
          _wateringCount = current;
          if (required != null && required > 0) {
            _wateringsRequired = required;
          }
          _arStatus = current == 0
              ? 'Sprout placed • Water it to help it grow'
              : 'Growth progress: $current/$_wateringsRequired';
        });
      }
    } else if (message == 'growth_complete') {
      if (mounted) {
        setState(() {
          _growthComplete = true;
          _wateringCount = _wateringsRequired;
          _arStatus = 'Growth complete!';
        });
      }
    } else if (message.startsWith('growth_distance:')) {
      final distance = double.tryParse(message.substring(16));
      if (mounted && distance != null) {
        setState(() {
          _growthDistanceMeters = distance.clamp(0, 2);
          _arStatus =
              'Step back slowly: ${distance.toStringAsFixed(1)} / 2.0 m';
        });
      }
    } else if (message.startsWith('info_node:')) {
      _showInformationNode(message.substring(10));
    }
  }

  void _showInformationNode(String node) {
    if (!mounted || _viewingArTree == null) return;
    final details = switch (node) {
      'leaves' => (
          'Leaves',
          'Kalantas has compound leaves whose leaflets capture sunlight to make food through photosynthesis. Healthy native canopies also cool and shelter forest life.'
        ),
      'bark' => (
          'Trunk and bark',
          'Its valuable timber made Kalantas vulnerable to heavy and illegal cutting. Protecting mature seed trees is essential for natural regeneration.'
        ),
      _ => (
          'Conservation',
          'Recovery depends on protecting remaining habitat, raising native seedlings, restoring degraded forest, and helping communities recognize the value of living trees.'
        ),
    };
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF233326),
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco, color: Color(0xFFB9D9BB), size: 34),
              const SizedBox(height: 8),
              Text(details.$1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins-Bold',
                    fontSize: 20,
                  )),
              const SizedBox(height: 10),
              Text(details.$2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.5,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _restartGrowth() {
    sendToUnity('Plant_Anchor', 'ResetPlant', 'reset');
    setState(() {
      _plantPlaced = false;
      _growthComplete = false;
      _wateringCount = 0;
      _growthDistanceMeters = 0;
      _arError = null;
      _arStatus = 'Scan a flat surface, then tap to place the sprout';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    // Permission not yet resolved
    if (_isLoading) {
      return Scaffold(
        backgroundColor: getScaffoldBg(isDark),
        body: Center(
            child: CircularProgressIndicator(
                color: isDark ? leafAccent : const Color(0xFF517156))),
      );
    }

    // If viewing a plant in AR, show the AR viewer
    if (_viewingArTree != null) {
      return _buildARViewerScreen(isDark);
    }

    // Show plant shelf with overlay buttons
    return _buildPlantShelfScreen(isDark);
  }

  Widget _buildARViewerScreen(bool isDark) {
    if (!_unityAttachMessageScheduled) {
      _unityAttachMessageScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 750));
        if (!mounted || _viewingArTree == null) return;
        _sendSelectedSpecies();
        if (!_unitySceneReady) setState(() => _unitySceneReady = true);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: getCardBg(isDark),
        elevation: 0,
        toolbarHeight: 80,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: isDark ? const Color(0xFF253326) : Colors.white,
            child: Transform.scale(
              scale: 1.3,
              child: Image.asset('assets/logo2.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.eco,
                      color: isDark ? leafAccent : const Color(0xFF2D3E2D))),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _viewingArTree!.name,
              style: TextStyle(
                fontFamily: 'Poppins-Bold',
                fontSize: 18,
                color: getTextColor(isDark),
                height: 1.2,
              ),
            ),
            Text(
              _viewingArTree!.scientificName,
              style: TextStyle(color: getSubtextColor(isDark), fontSize: 12),
            ),
          ],
        ),
        actions: [
          UserNotificationBadge(
              iconColor: isDark ? Colors.white : const Color(0xFF303D32)),
          _buildProfileIcon(isDark),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          EmbedUnity(
            onMessageFromUnity: _onMessageFromUnity,
          ),

          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SafeArea(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: (_arError == null
                          ? const Color(0xFF263A2B)
                          : const Color(0xFF8B2F2F))
                      .withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 8)
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _arError == null ? Icons.sensors : Icons.error_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _arError ?? _arStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Guided sprout-to-tree experience.
          Positioned(
            bottom: 104,
            left: 16,
            right: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: _modelDownloadRequired || _modelDownloading
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_download_outlined,
                              color: Color(0xFFB9D9BB), size: 30),
                          const SizedBox(height: 6),
                          Text(
                            _modelDownloading
                                ? 'Downloading AR model'
                                : 'Download ${_viewingArTree!.name} for AR?',
                            style: const TextStyle(
                              fontFamily: 'Poppins-Bold',
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _modelDownloading
                                ? '$_modelDownloadPercent% complete. Keep the app open.'
                                : 'This optional model is downloaded once and then kept for offline use.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_modelDownloading)
                            LinearProgressIndicator(
                              value: _modelDownloadPercent / 100,
                              minHeight: 7,
                              borderRadius: BorderRadius.circular(8),
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF79B8E8),
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _downloadSelectedModel,
                                icon: const Icon(Icons.download),
                                label: const Text('Download model'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF517156),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      )
                    : _growthComplete
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.park,
                                  color: Color(0xFF9CC89F), size: 30),
                              const SizedBox(height: 6),
                              Text(
                                _viewingArTree!.name,
                                style: const TextStyle(
                                  fontFamily: 'Poppins-Bold',
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                _viewingArTree!.scientificName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Walk around the full-sized tree. Tap the floating '
                                'leaf, bark, and conservation pins to inspect it.\n\n'
                                '${_viewingArTree!.ecologicalImportance}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _restartGrowth,
                                icon: const Icon(Icons.replay,
                                    color: Color(0xFFB9D9BB)),
                                label: const Text(
                                  'Grow again',
                                  style: TextStyle(color: Color(0xFFB9D9BB)),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                !_plantPlaced
                                    ? '${_viewingArTree!.name} • ${_viewingArTree!.conservationStatus}'
                                    : _wateringCount == 0
                                        ? 'Nurture the sprout'
                                        : 'Give it room to grow',
                                style: const TextStyle(
                                  fontFamily: 'Poppins-Bold',
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                !_plantPlaced
                                    ? '${_viewingArTree!.habitat}.\n\n'
                                        '${_viewingArTree!.ecologicalImportance}\n\n'
                                        'Move slowly to scan the surface grid, then tap the floor to plant the sprout.'
                                    : _wateringCount == 0
                                        ? 'Tap the sprout itself. Water, light, and sound will respond together.'
                                        : 'Walk backward from the sprout. The shimmer rises until the tree blooms at 2 meters.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              if (_plantPlaced && _wateringCount > 0) ...[
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  value: _growthDistanceMeters / 2,
                                  minHeight: 7,
                                  borderRadius: BorderRadius.circular(8),
                                  backgroundColor: Colors.white24,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF79B8E8),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_growthDistanceMeters.toStringAsFixed(1)} / 2.0 meters',
                                  style: const TextStyle(
                                    color: Color(0xFFB9D9BB),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
              ),
            ),
          ),

          if (!_unitySceneReady)
            const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Text(
                      'Starting AR…',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),

          // Close button
          Positioned(
            bottom: 28,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: _closeARViewer,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? leafAccent : const Color(0xFF517156),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Exit AR Mode',
                style: TextStyle(
                  color: isDark ? Colors.black : Colors.white,
                  fontFamily: 'Poppins-Bold',
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildPlantShelfScreen(bool isDark) {
    return Scaffold(
      backgroundColor: getScaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: getCardBg(isDark),
        elevation: 0,
        toolbarHeight: 80,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: isDark ? const Color(0xFF253326) : Colors.white,
            child: Transform.scale(
              scale: 1.3,
              child: Image.asset('assets/logo2.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.eco,
                      color: isDark ? leafAccent : const Color(0xFF2D3E2D))),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "AR View",
              style: TextStyle(
                fontFamily: 'Poppins-Bold',
                fontSize: 15,
                color: getTextColor(isDark),
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "Explore the Cavite Protected Area",
              style: TextStyle(color: getSubtextColor(isDark), fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          UserNotificationBadge(
              iconColor: isDark ? Colors.white : const Color(0xFF303D32)),
          _buildProfileIcon(isDark),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/plant_shelf.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate responsive dimensions based on screen size
              double width = constraints.maxWidth * 0.95;
              double height = width * (803 / 412); // Maintain aspect ratio

              return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/plant_shelf.png'),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {},
                  ),
                  color: isDark ? const Color(0xFF1E261F) : Colors.grey[300],
                ),
                child: Stack(
                  children: [
                    // Dark overlay (~10% opacity for enhanced contrast)
                    Container(
                      width: width,
                      height: height,
                      color: isDark
                          ? Colors.black.withOpacity(0.4)
                          : Colors.black.withOpacity(0.1),
                    ),
                    // Overlay buttons positioned on plants
                    _buildPlantOverlays(width, height, isDark),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildPlantOverlays(
      double containerWidth, double containerHeight, bool isDark) {
    // Scale factors based on responsive dimensions
    const double baseWidth = 412;
    const double baseHeight = 803;
    final double scaleX = containerWidth / baseWidth;
    final double scaleY = containerHeight / baseHeight;

    // Plant positions on the shelf (center points) - base values for 412x803
    final plantPositions = [
      // Top shelf
      _PlantPosition(
          left: 95, top: 190, plant: threatenedTrees[0]), // Subyang (CR)
      _PlantPosition(
          left: 180, top: 170, plant: threatenedTrees[1]), // Molave (EN)
      _PlantPosition(
          left: 250, top: 170, plant: threatenedTrees[2]), // Manggachapui (EN)
      _PlantPosition(
          left: 360, top: 190, plant: threatenedTrees[3]), // Kubili (EN)
      // Second shelf
      _PlantPosition(left: 95, top: 310, plant: threatenedTrees[4]), // Dao (VU)
      _PlantPosition(
          left: 180, top: 290, plant: threatenedTrees[5]), // Paho (VU)
      _PlantPosition(
          left: 270, top: 290, plant: threatenedTrees[6]), // Narra (VU)
      _PlantPosition(
          left: 350, top: 310, plant: threatenedTrees[7]), // Kamagong (VU)
      // Middle/Hanging section
      _PlantPosition(
          left: 95, top: 430, plant: threatenedTrees[8]), // Kalantas (VU)
      _PlantPosition(
          left: 355, top: 430, plant: threatenedTrees[9]), // Dila-dila (VU)
      // Third shelf
      _PlantPosition(
          left: 95, top: 545, plant: threatenedTrees[10]), // Haikan (VU)
      _PlantPosition(
          left: 175, top: 540, plant: threatenedTrees[11]), // Malachio (VU)
      _PlantPosition(
          left: 260, top: 540, plant: threatenedTrees[12]), // Bagarilau (VU)
      _PlantPosition(
          left: 355, top: 550, plant: threatenedTrees[13]), // Nato (VU)
      // Bottom shelf
      _PlantPosition(
          left: 80, top: 655, plant: threatenedTrees[14]), // Malak-malak (VU)
      _PlantPosition(
          left: 355, top: 655, plant: threatenedTrees[15]), // Katmon (VU)
    ];

    return SizedBox(
      width: containerWidth,
      height: containerHeight,
      child: Stack(
        children: plantPositions
            .map(
              (pos) => Positioned(
                left: pos.left * scaleX,
                top: pos.top * scaleY,
                child: Transform.translate(
                  offset: const Offset(-55, -35),
                  child: _buildPlantButton(pos.plant, isDark),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPlantButton(TreeModel plant, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.black87 : Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                plant.name,
                style: TextStyle(
                  color: plant.color,
                  fontFamily: 'Poppins-Bold',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3,
                      color: Colors.black54,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        ElevatedButton(
          onPressed: _shelfDownloadingSpeciesID == null
              ? () => _viewPlantInAR(plant)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? leafAccent : const Color(0xFF517156),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: const Size(60, 24),
          ),
          child: Text(
            _shelfDownloadingSpeciesID ==
                    plant.scientificName.trim().replaceAll(RegExp(r'\s+'), '_')
                ? 'Downloading $_shelfDownloadPercent%'
                : plant.remoteModelFile == null
                    ? 'Model unavailable'
                    : 'View in AR',
            style: TextStyle(
              color: isDark ? Colors.black : Colors.white,
              fontFamily: 'Poppins-Bold',
              fontSize: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileIcon(bool isDark) => Padding(
        padding: const EdgeInsets.only(right: 16.0, left: 8),
        child: InkWell(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const UserProfileScreen())),
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2B3A2C) : const Color(0xFFF0F4F0),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: isDark ? Colors.white24 : Colors.black12),
            ),
            child: Icon(Icons.person_outline, color: getTextColor(isDark)),
          ),
        ),
      );

  Widget _buildBottomNav(bool isDark) => Container(
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: isDark ? Colors.white12 : const Color(0x1A000000),
                  width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: isDark ? leafAccent : const Color(0xFF517156),
          unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
          backgroundColor: getCardBg(isDark),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle:
              const TextStyle(fontFamily: 'Poppins-Bold', fontSize: 12),
          unselectedLabelStyle:
              const TextStyle(fontFamily: 'Poppins', fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories_outlined),
              activeIcon: Icon(Icons.auto_stories),
              label: "Botanical Gallery",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.view_in_ar_outlined),
              activeIcon: Icon(Icons.view_in_ar_rounded),
              label: "AR View",
            ),
          ],
        ),
      );
}

// Helper class for plant position mapping
class _PlantPosition {
  final double left;
  final double top;
  final TreeModel plant;

  _PlantPosition({
    required this.left,
    required this.top,
    required this.plant,
  });
}
