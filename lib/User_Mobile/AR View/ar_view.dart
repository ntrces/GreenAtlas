import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  defaultValue:
      'https://raw.githubusercontent.com/ntrces/GreenAtlas/main/remote_ar_models',
);
const double _growthTriggerDistanceMeters = 1.5;

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
  final String leafDetails;
  final String barkDetails;
  final String conservationDetails;

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
    this.leafDetails =
        'Its leaves capture sunlight for photosynthesis, release oxygen, and help regulate moisture and temperature around the tree. Fallen leaves also return nutrients to the forest floor.',
    this.barkDetails =
        'Its trunk and bark support the canopy, transport water and nutrients, and provide habitat for small forest organisms. Mature trees are especially important seed sources.',
    this.conservationDetails =
        'Protecting this threatened native tree requires conserving its habitat, preventing illegal cutting, supporting responsible propagation, and monitoring planted seedlings until they mature.',
  });
}

// Native trees represented in the GreenAtlas AR collection. Conservation
// categories follow DENR Administrative Order 2026-20 (Philippine national
// status), rather than the separate global IUCN Red List categories.
const List<TreeModel> threatenedTrees = [
  TreeModel(
    name: 'Subyang / Quisumbing Gisok',
    scientificName: 'Hopea quisumbingiana',
    assetPath: 'assets/paho.glb',
    color: Colors.red,
    remoteModelFile: 'Hopea_quisumbingiana.glb',
    conservationStatus: 'Critically Endangered (PH)',
    habitat: 'A Philippine-endemic dipterocarp of lowland tropical rainforest. Its very restricted wild population makes every remaining habitat and mature seed tree exceptionally important.',
    ecologicalImportance: 'As a canopy tree, it stores carbon, stabilizes forest soil, and adds structure and food resources to native forest. Its loss would also remove habitat used by many smaller organisms.',
    leafDetails: 'The leaves are simple, alternate, leathery, and elliptic, with a pointed tip and clearly visible side veins. Their firm surface helps the tree function in warm, humid forest conditions.',
    barkDetails: 'Like other gisok trees, it develops a straight woody trunk and durable timber. Its rarity means wild trees must never be treated as a timber source; mature individuals are vital seed producers.',
    conservationDetails: 'DENR lists this species as Critically Endangered. Priorities include strict habitat protection, prevention of cutting and collection, propagation from documented local seed sources, and long-term monitoring of both wild and restored populations.',
  ),
  TreeModel(
    name: 'Molave',
    scientificName: 'Vitex parviflora',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
    remoteModelFile: 'Vitex_parviflora.glb',
    conservationStatus: 'Vulnerable (PH)',
    habitat: 'Native to seasonal lowland forest, limestone forest, and other relatively dry forest habitats in the Philippines. It tolerates stronger seasonal drought than many rainforest trees.',
    ecologicalImportance: 'Molave forms sturdy forest structure, supplies flowers and fruit to wildlife, stores carbon, and helps protect soil in seasonally dry landscapes.',
    leafDetails: 'Its leaves are compound, usually with three leaflets. The leaflets are firm and often paler beneath—useful identification characters when distinguishing Molave from simple-leaved trees.',
    barkDetails: 'Molave is renowned for dense, durable wood used historically in heavy construction. That value encouraged extensive harvesting, so surviving mature trunks now have high conservation and seed-source value.',
    conservationDetails: 'DENR lists Molave as Vulnerable. Protect remnant dry and limestone forests, stop unauthorized cutting, retain mature seed trees, and use traceable native planting material in restoration.',
  ),
  TreeModel(
    name: 'Manggachapui',
    scientificName: 'Hopea acuminata',
    assetPath: 'assets/paho.glb',
    color: Colors.orange,
    remoteModelFile: 'Hopea_acuminata.glb',
    conservationStatus: 'Endangered (PH)',
    habitat: 'A Philippine-endemic dipterocarp associated with lowland evergreen forest. It depends on intact forest conditions for successful flowering, seedling establishment, and canopy development.',
    ecologicalImportance: 'This canopy tree contributes large amounts of living biomass, shades the forest floor, supports wildlife, and helps regulate water movement through forest soil.',
    leafDetails: 'Leaves are simple, alternate, and leathery, generally elliptic to lance-shaped with an elongated tip. Numerous fine, parallel-looking side veins are characteristic of many dipterocarps.',
    barkDetails: 'The trunk can yield valuable dipterocarp timber, making the species vulnerable to logging. Large individuals are irreplaceable sources of seed and forest structure.',
    conservationDetails: 'DENR lists Manggachapui as Endangered. Remaining populations need protection from forest clearing and cutting, accompanied by local seed collection, nursery propagation, enrichment planting, and survival monitoring.',
  ),
  TreeModel(
    name: 'Kubili',
    scientificName: 'Cubilia cubili',
    assetPath: 'assets/paho.glb',
    color: Colors.orange,
    remoteModelFile: 'Cubilia_cubili.glb',
    conservationStatus: 'Endangered (PH)',
    habitat: 'A Philippine-endemic forest tree occurring in lowland to lower montane rainforest. Healthy native forest and functioning seed dispersal are essential to its regeneration.',
    ecologicalImportance: 'Its canopy, flowers, and fruits add food and shelter to the forest community, while its roots and leaf litter support soil stability and nutrient cycling.',
    leafDetails: 'Kubili has alternate, compound leaves with paired leaflets. The leaflet arrangement separates it from simple-leaved species and gives the crown a layered texture.',
    barkDetails: 'Its woody trunk is part of the long-lived framework of the forest. Because the species is endemic and endangered, mature trees should be conserved principally as habitat and seed sources.',
    conservationDetails: 'DENR lists Kubili as Endangered. Conservation should protect known stands, prevent unauthorized removal, document fruiting trees, propagate genetically diverse seedlings, and restore them within suitable native forest.',
  ),
  TreeModel(
    name: 'Dao',
    scientificName: 'Dracontomelon dao',
    assetPath: 'assets/paho.glb',
    color: Colors.blue,
    remoteModelFile: 'Dracontomelon_dao.glb',
    conservationStatus: 'Other Threatened Species (PH)',
    habitat: 'A large tree of lowland rainforest, often favoring moist valleys, river margins, and deep soils. It occurs in the Philippines and elsewhere in Southeast Asia and the Pacific.',
    ecologicalImportance: 'Dao develops a broad canopy and large buttressed base, stores substantial carbon, stabilizes moist soil, and produces fruit used by wildlife.',
    leafDetails: 'The leaves are pinnately compound, with several opposite or nearly opposite leaflets. Young foliage may flush pinkish or reddish before becoming green.',
    barkDetails: 'Older Dao trees often have conspicuous buttress roots and a massive trunk. Its attractive timber has been used for furniture and interior work, contributing to harvesting pressure.',
    conservationDetails: 'DENR places Dao under Other Threatened Species. Retaining old trees, protecting riverine forest, controlling harvest, and raising seedlings from several parent trees can help maintain healthy populations.',
  ),
  TreeModel(
    name: 'Pahutan',
    scientificName: 'Mangifera altissima',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
    remoteModelFile: 'Mangifera_altissima.glb',
    conservationStatus: 'Vulnerable (PH)',
    habitat: 'A Philippine-endemic wild mango of lowland and hill forest. It belongs in diverse native forest rather than in open monoculture plantations.',
    ecologicalImportance: 'Its flowers support pollinators and its mango-like fruits can feed wildlife. The crown stores carbon, moderates heat, and helps maintain native forest complexity.',
    leafDetails: 'Leaves are simple, alternate, leathery, and elongated, usually clustered toward twig ends. New leaves may appear reddish before maturing to deep green.',
    barkDetails: 'The trunk contains resinous sap typical of mango relatives. Wild trees should be handled carefully and retained as seed sources rather than harvested indiscriminately.',
    conservationDetails: 'DENR lists Pahutan as Vulnerable. Priorities are conserving remaining forest populations, preventing conversion and cutting, documenting fruiting trees, and propagating seedlings with verified identity.',
  ),
  TreeModel(
    name: 'Narra',
    scientificName: 'Pterocarpus indicus',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
    remoteModelFile: 'Pterocarpus_indicus.glb',
    conservationStatus: 'Vulnerable (PH)',
    habitat: 'Native to Philippine lowland forest, including seasonal forest and sites near streams. It also grows well in open planted landscapes when given adequate space.',
    ecologicalImportance: 'Narra is a nitrogen-fixing legume that can improve soil, provide shade, support pollinators, and produce winged fruits dispersed away from the parent tree.',
    leafDetails: 'Its leaves are pinnately compound, usually bearing several oval leaflets with smooth edges. The leaflets form a light, spreading crown rather than a dense solid mass.',
    barkDetails: 'The trunk yields richly colored, highly valued wood and may exude reddish sap. Heavy demand for timber has made protection and legal sourcing especially important.',
    conservationDetails: 'DENR lists Narra as Vulnerable. Protect natural populations, enforce timber controls, retain genetically diverse seed trees, and favor locally sourced seedlings in restoration and civic planting.',
  ),
  TreeModel(
    name: 'Kamagong',
    scientificName: 'Diospyros discolor',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
    remoteModelFile: 'Diospyros_discolor.glb',
    conservationStatus: 'Vulnerable (PH)',
    habitat: 'A Philippine native of lowland rainforest. It grows as an evergreen tree and is also cultivated for its edible velvet apple fruit.',
    ecologicalImportance: 'Its flowers and fruits support insects, fruit-eating birds, bats, and other animals. The dense crown adds shade, carbon storage, and vertical structure to forest habitat.',
    leafDetails: 'Leaves are simple, alternate, oblong, and leathery. Their upper surface is glossy green while the lower surface is often paler and softly hairy.',
    barkDetails: 'Kamagong can form very dark, dense heartwood known as Philippine ebony. High timber value and slow replacement make mature wild trees particularly vulnerable to illegal cutting.',
    conservationDetails: 'DENR lists Kamagong as Vulnerable. Protect fruiting adults and their habitat, prevent illegal timber extraction, propagate from multiple parent trees, and distinguish conservation planting from fruit-only cultivation.',
  ),
  TreeModel(
    name: 'Kalantas',
    scientificName: 'Toona calantas',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
    remoteModelFile: 'kalantas.glb',
    conservationStatus: 'Vulnerable (PH)',
    habitat:
        'Kalantas is native to Philippine lowland forests, including the remaining forest fragments and protected landscapes of Cavite. It grows best in warm, humid sites where deep soil and a healthy forest canopy support seedlings and mature trees.',
    ecologicalImportance:
        'Kalantas provides shelter, shade, and feeding space for insects, birds, and other forest wildlife. Its roots help hold soil in place, while its canopy stores carbon, cools the surrounding habitat, and supports the recovery of a layered native forest. Because valuable timber and habitat loss have reduced its population, every surviving mature tree can serve as a seed source for future restoration. Protecting Kalantas means preserving both a distinctive Philippine species and the wider community of life that depends on healthy native forests.',
    leafDetails:
        'Kalantas produces large compound leaves made up of several paired leaflets. Their broad green surfaces capture sunlight and use photosynthesis to turn water and carbon dioxide into sugars that fuel the tree’s growth. The leaves release oxygen and water vapor, helping cool the air beneath the canopy. Fallen leaf litter also returns nutrients to the forest soil and supports fungi, insects, and other organisms.',
    barkDetails:
        'The straight trunk of Kalantas produces lightweight, workable timber traditionally valued for furniture, carving, and construction. That usefulness also placed the species under pressure from excessive and illegal cutting. Large mature trees preserve genetic diversity and produce seeds, allowing natural regeneration to continue and providing locally adapted planting material for restoration.',
    conservationDetails:
        'Kalantas is classified as Vulnerable because its population has declined through habitat loss and timber extraction. Recovery requires protecting remaining forest, preventing illegal cutting, caring for mature seed trees, propagating native seedlings, and restoring degraded sites with diverse local species. Community education and long-term monitoring are equally important because a planted seedling becomes a conservation success only when it survives and matures.',
  ),
  TreeModel(
    name: 'Dila-dila',
    scientificName: 'Cynometra inaequifolia',
    assetPath: 'assets/paho.glb',
    color: Colors.blue,
    remoteModelFile: 'Cynometra_inaequifolia.glb',
    conservationStatus: 'Other Threatened Species (PH)',
    habitat: 'A Philippine-endemic member of the bean family found in native lowland forest. Its survival depends on retaining suitable forest habitat and natural regeneration.',
    ecologicalImportance: 'As a native legume tree it contributes to forest structure, offers resources to insects and other wildlife, and helps protect soil beneath its crown.',
    leafDetails: 'Its compound leaves typically have a small number of unequal-sided leaflets, reflected in the name inaequifolia. Young growth may differ noticeably in color from mature foliage.',
    barkDetails: 'The trunk supports a compact native canopy and the living communities associated with bark and wood. Scarce mature trees are more valuable as reproductive sources than as timber.',
    conservationDetails: 'DENR places Dila-dila under Other Threatened Species. Known trees should be mapped and protected, with seeds propagated from several parents and returned only to ecologically suitable native sites.',
  ),
  TreeModel(
    name: 'Haikan',
    scientificName: 'Camellia lanceolata',
    assetPath: 'assets/paho.glb',
    color: Colors.green,
    remoteModelFile: 'Camellia_lanceolata.glb',
    conservationStatus: 'Other Wildlife Species (PH)',
    habitat: 'A native evergreen of humid forest, generally associated with shaded woodland conditions. It is a wild relative of tea and ornamental camellias.',
    ecologicalImportance: 'Its evergreen foliage and flowers contribute year-round cover and seasonal resources for forest insects, while its roots and litter help maintain forest soil.',
    leafDetails: 'Leaves are simple, alternate, leathery, and lance-shaped, with a pointed tip and finely toothed margin—features consistent with its scientific name lanceolata.',
    barkDetails: 'The relatively modest woody stem supports an evergreen crown. Its conservation value lies in maintaining native plant diversity and the genetic variety of wild camellia relatives.',
    conservationDetails: 'The current DENR national list treats Haikan as Other Wildlife Species rather than a threatened category. It still deserves habitat protection and responsible, documented collection, especially where local populations are small.',
  ),
  TreeModel(
    name: 'Malachico / Mamolko',
    scientificName: 'Glenniea philippinensis',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
    remoteModelFile: 'Glenniea_philippinensis.glb',
    conservationStatus: 'Vulnerable (PH)',
    habitat: 'A native forest tree of the Philippines and nearby parts of Southeast Asia, occurring in lowland tropical forest where mature stands and animal dispersers remain.',
    ecologicalImportance: 'As a member of the soapberry family, it contributes flowers and fruits to forest food webs while adding canopy cover, carbon storage, and leaf litter.',
    leafDetails: 'Leaves are compound, with several leaflets arranged along a central stalk. This leaflet pattern is a useful field character for separating it from simple-leaved neighbors.',
    barkDetails: 'Its woody trunk forms part of the permanent forest framework. Mature specimens are important genetic and reproductive resources and should not be removed without lawful scientific justification.',
    conservationDetails: 'DENR lists Malachico or Mamolko as Vulnerable. Protect remaining habitat and fruiting trees, limit destructive collection, maintain several seed sources, and monitor restored seedlings over many years.',
  ),
  TreeModel(
    name: 'Bagarilau',
    scientificName: 'Cryptocarya ampla',
    assetPath: 'assets/paho.glb',
    color: Colors.blue,
    remoteModelFile: 'Cryptocarya_ampla.glb',
    conservationStatus: 'Other Threatened Species (PH)',
    habitat: 'A Philippine-endemic tree in the laurel family, associated with native lowland to montane forest. Forest continuity is important for its regeneration and dispersal.',
    ecologicalImportance: 'Its fleshy fruits can support forest animals, while its evergreen crown stores carbon, intercepts rain, and supplies litter to the soil community.',
    leafDetails: 'Leaves are simple, alternate, evergreen, and generally broad to elliptic. As in many laurels, the foliage may be aromatic when crushed, though field identification should use several characters.',
    barkDetails: 'The trunk and bark support lichens, insects, and other small organisms. Mature endemic trees are important seed reservoirs and should be retained within intact forest.',
    conservationDetails: 'DENR places Bagarilau under Other Threatened Species. Habitat protection, population surveys, verified seed collection, nursery propagation, and long-term survival checks are appropriate recovery actions.',
  ),
  TreeModel(
    name: 'Nato',
    scientificName: 'Palaquium luzoniense',
    assetPath: 'assets/paho.glb',
    color: Colors.green,
    remoteModelFile: 'Palaquium_luzoniense.glb',
    conservationStatus: 'Other Wildlife Species (PH)',
    habitat: 'A native sapotaceous tree of Philippine lowland forest. It favors warm, humid forest conditions where seedlings can develop beneath and eventually enter the canopy.',
    ecologicalImportance: 'Its flowers and fleshy fruits support forest fauna, while the evergreen canopy stores carbon, protects soil, and contributes to a multilayered forest.',
    leafDetails: 'Leaves are simple, alternate, leathery, and often crowded near twig tips. The lower surface may be paler than the glossy upper surface.',
    barkDetails: 'Cut tissues of many Palaquium species release milky latex. The trunk has also been valued for wood, so legal sourcing and retention of mature wild trees remain important.',
    conservationDetails: 'The current DENR list places Nato under Other Wildlife Species. This does not remove the need to protect local populations from forest loss, poor regeneration, or unsustainable cutting.',
  ),
  TreeModel(
    name: 'Malak-malak',
    scientificName: 'Palaquium philippense',
    assetPath: 'assets/paho.glb',
    color: Colors.green,
    remoteModelFile: 'Palaquium_philippense.glb',
    conservationStatus: 'Other Wildlife Species (PH)',
    habitat: 'A Philippine-endemic Palaquium of native tropical forest. It relies on forest habitat and animal-assisted ecological processes for long-term regeneration.',
    ecologicalImportance: 'The evergreen crown, flowers, and fleshy fruits contribute food and shelter to forest wildlife; roots and litter help retain soil nutrients and moisture.',
    leafDetails: 'Leaves are simple, alternate, and leathery, commonly clustered toward the ends of twigs. Their durable texture suits an evergreen forest canopy.',
    barkDetails: 'The woody stem may release milky latex when damaged, a familiar trait in the sapodilla family. Endemic mature trees should be protected as local seed and habitat sources.',
    conservationDetails: 'The current DENR national list treats Malak-malak as Other Wildlife Species. Because it is Philippine-endemic, habitat protection, verified identification, and locally diverse propagation remain prudent safeguards.',
  ),
  TreeModel(
    name: 'Anang',
    scientificName: 'Diospyros pyrrhocarpa',
    assetPath: 'assets/paho.glb',
    color: Colors.amber,
    remoteModelFile: 'Diospyros_pyrrhocarpa.glb',
    conservationStatus: 'Vulnerable (PH)',
    habitat: 'A native Diospyros tree of lowland tropical forest in the Philippines and parts of Southeast Asia. It needs surviving forest and reproductive adults for natural renewal.',
    ecologicalImportance: 'Its crown contributes shade and carbon storage, while flowers and fruits add resources for insects and fruit-eating animals in the forest food web.',
    leafDetails: 'Leaves are simple, alternate, and leathery, generally elliptic to oblong with an unbroken margin. Multiple characters, including fruit and flowers, are needed for reliable identification.',
    barkDetails: 'As an ebony relative, Anang produces dense wood. Mature trees are slow to replace and are ecologically more valuable when retained as habitat and seed sources.',
    conservationDetails: 'DENR lists Anang as Vulnerable. Conserve known stands, prevent unauthorized cutting, protect fruiting adults, collect seed across several parents, and monitor planted trees through establishment.',
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
  static const MethodChannel _arDiagnosticsChannel =
      MethodChannel('com.example.greenatlas/ar_diagnostics');
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
  bool _isArInfoExpanded = true;
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
  final Set<String> _downloadedModelFiles = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.initialSpeciesID != null) {
      final requestedID = widget.initialSpeciesID!.trim().toLowerCase();
      TreeModel? requestedTree;
      for (final tree in threatenedTrees) {
        final treeID = tree.scientificName
            .trim()
            .replaceAll(RegExp(r'\s+'), '_')
            .toLowerCase();
        if (treeID == requestedID) {
          requestedTree = tree;
          break;
        }
      }
      if (requestedTree != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _viewPlantInAR(requestedTree!);
        });
      }
    }
    _checkPermission();
    _refreshDownloadedModels();
  }

  Future<void> _refreshDownloadedModels() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/greenatlas_ar_models');
    final downloaded = <String>{};

    if (await directory.exists()) {
      await for (final entity in directory.list()) {
        if (entity is File &&
            !entity.path.endsWith('.download') &&
            await entity.length() > 0) {
          downloaded.add(entity.uri.pathSegments.last);
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _downloadedModelFiles
        ..clear()
        ..addAll(downloaded);
    });
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
    if (!mounted) return;
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
      _isArInfoExpanded = true;
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
      _isArInfoExpanded = true;
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
      _reportArStartupFailure();
    });
  }

  Future<void> _reportArStartupFailure() async {
    Map<String, dynamic>? diagnostics;
    try {
      final result = await _arDiagnosticsChannel
          .invokeMapMethod<String, dynamic>('getArDiagnostics');
      diagnostics = result;
    } catch (error) {
      debugPrint('Unable to read Android AR diagnostics: $error');
    }

    if (!mounted || _viewingArTree == null || _arStatus == 'AR ready') return;

    final unityLoaded = _unitySceneReady;
    final installed = diagnostics?['arCoreInstalled'] == true;
    final enabled = diagnostics?['arCoreEnabled'] == true;
    final cameraGranted = diagnostics?['cameraGranted'] == true;
    final hasArFeature = diagnostics?['hasArCameraFeature'] == true;
    final version = diagnostics?['arCoreVersionName']?.toString();
    final device = [
      diagnostics?['manufacturer'],
      diagnostics?['model'],
    ].whereType<Object>().map((value) => value.toString()).join(' ');

    late final String message;
    if (diagnostics == null) {
      message = unityLoaded
          ? 'Unity loaded, but Android AR diagnostics could not be read. '
              'This does not mean ARCore is missing. Reconnect the device and capture logs.'
          : 'Unity did not finish loading, and Android AR diagnostics could '
              'not be read. This is a Unity/Flutter integration failure, not '
              'proof that ARCore is missing.';
    } else if (!cameraGranted) {
      message = 'Camera permission is not granted. Enable Camera permission '
          'for GreenAtlas in Android Settings, then reopen AR.';
    } else if (!installed) {
      message = 'Google Play Services for AR is not installed. Install it '
          'from Google Play, then reopen GreenAtlas.';
    } else if (!enabled) {
      message = 'Google Play Services for AR is installed but disabled. '
          'Enable it in Android Settings, then reopen GreenAtlas.';
    } else if (!unityLoaded) {
      message = 'Unity did not finish loading within 18 seconds. ARCore is '
          'installed${version == null ? '' : ' (version $version)'}. This is '
          'a Unity startup/embedding failure, not a missing-ARCore error.';
    } else if (!hasArFeature) {
      message = 'Unity loaded and Google Play Services for AR is installed'
          '${version == null ? '' : ' (version $version)'}, but Android does '
          'not advertise the AR camera feature on ${device.isEmpty ? 'this device' : device}. '
          'The device firmware or ARCore certification may be the cause.';
    } else {
      message = 'Unity loaded and Google Play Services for AR is installed'
          '${version == null ? '' : ' (version $version)'}, but the ARCore '
          'session did not start tracking. This points to an AR session, '
          'camera configuration, graphics, or Unity scene error—not a missing '
          'AR installation. Reconnect the device and capture logs for the exact cause.';
    }

    setState(() => _arError = message);
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
        setState(() {
          _shelfDownloadPercent = 100;
          _downloadedModelFiles.add(modelFile);
        });
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
          _growthDistanceMeters =
              distance.clamp(0, _growthTriggerDistanceMeters);
          _arStatus =
              'Step back slowly: ${distance.toStringAsFixed(1)} / 1.5 m';
        });
      }
    }
  }

  Widget _buildInformationSection(String title, String details) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFB9D9BB),
              fontFamily: 'Poppins-Bold',
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            details,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(
                        () => _isArInfoExpanded = !_isArInfoExpanded,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Color(0xFFB9D9BB), size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Information',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins-Bold',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Icon(
                              _isArInfoExpanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_up,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isArInfoExpanded) ...[
                      const SizedBox(height: 8),
                      _modelDownloadRequired || _modelDownloading
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
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
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
                                        backgroundColor:
                                            const Color(0xFF517156),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : _growthComplete
                              ? ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.sizeOf(context).height *
                                            0.46,
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
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
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontStyle: FontStyle.italic,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _viewingArTree!.conservationStatus,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _viewingArTree!.color,
                                            fontFamily: 'Poppins-Bold',
                                            fontSize: 12,
                                          ),
                                        ),
                                        _buildInformationSection(
                                          'General overview',
                                          '${_viewingArTree!.habitat}\n\n${_viewingArTree!.ecologicalImportance}',
                                        ),
                                        _buildInformationSection(
                                          'Leaves',
                                          _viewingArTree!.leafDetails,
                                        ),
                                        _buildInformationSection(
                                          'Trunk and bark',
                                          _viewingArTree!.barkDetails,
                                        ),
                                        _buildInformationSection(
                                          'Conservation',
                                          _viewingArTree!.conservationDetails,
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton.icon(
                                          onPressed: _restartGrowth,
                                          icon: const Icon(Icons.replay,
                                              color: Color(0xFFB9D9BB)),
                                          label: const Text(
                                            'Back to Sprout',
                                            style: TextStyle(
                                                color: Color(0xFFB9D9BB)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!_plantPlaced)
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                                text: _viewingArTree!.name),
                                            const TextSpan(text: ' • '),
                                            TextSpan(
                                              text: _viewingArTree!
                                                  .conservationStatus,
                                              style: TextStyle(
                                                color: _viewingArTree!.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins-Bold',
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                      )
                                    else
                                      Text(
                                        _wateringCount < _wateringsRequired
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
                                              'Move slowly while the app searches for a flat floor, then tap the surface to plant the sprout.'
                                          : _wateringCount < _wateringsRequired
                                              ? 'Tap the sprout to water it three times. Each watering responds with light, sound, and a splash.'
                                              : 'Walk backward from the sprout. The shimmer rises until the tree blooms at 1.5 meters.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (_plantPlaced && _wateringCount > 0) ...[
                                      const SizedBox(height: 10),
                                      LinearProgressIndicator(
                                        value: _growthDistanceMeters /
                                            _growthTriggerDistanceMeters,
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
                                        '${_growthDistanceMeters.toStringAsFixed(1)} / 1.5 meters',
                                        style: const TextStyle(
                                          color: Color(0xFFB9D9BB),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
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
    final modelFile = plant.remoteModelFile;
    final isModelDownloaded =
        modelFile != null && _downloadedModelFiles.contains(modelFile);
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
                : modelFile == null
                    ? 'Model unavailable'
                    : isModelDownloaded
                        ? 'View in AR'
                        : 'Download AR',
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
