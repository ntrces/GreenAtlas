import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../AR View/ar_view.dart';

class ARCameraScreen extends StatefulWidget {
  final Map<String, dynamic> plantData;
  const ARCameraScreen({super.key, required this.plantData});

  @override
  State<ARCameraScreen> createState() => _ARCameraScreenState();
}

class _ARCameraScreenState extends State<ARCameraScreen> {
  final _supabase = Supabase.instance.client;
  bool _isClassificationExpanded = true;

  Future<Map<String, dynamic>> _getLatestPlantData() async {
    return await _supabase
        .from('plants')
        .select()
        .eq('id', widget.plantData['id'])
        .single();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<Map<String, dynamic>>(
        future: _getLatestPlantData(),
        initialData: widget.plantData,
        builder: (context, snapshot) {
          final d = snapshot.data ?? widget.plantData;
          final String importance = d['ecological_importance'] ??
              "Pollinator attractor and biodiversity contributor.";
          final String sName = d['common_name'] ?? 'Subyang';
          final String sID = (d['scientific_name'] ?? 'Hopea_quisumbingiana')
              .toString()
              .replaceAll(' ', '_');

          return Scaffold(
            backgroundColor: const Color(0xFFF0F4F0),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSmallHeader(d['common_name'], d['scientific_name'],
                      d['category'], textTheme),
                  _buildImageHero(d['image_url']),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildConservationStatus(d['conservation_status'],
                            d['source_text'], textTheme),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon:
                              const Icon(Icons.view_in_ar, color: Colors.white),
                          label: Text('View $sName in AR',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            minimumSize: const Size(double.infinity, 48),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Ar_View(
                                  initialSpeciesName: sName,
                                  initialScientificName:
                                      d['scientific_name']?.toString(),
                                  initialSpeciesID: sID,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildSectionHeader("CLIMATE COMPATIBILITY", textTheme),
                        _buildClimateCompatibility(
                            d['temp_min'], d['temp_max'], textTheme),
                        _buildSectionHeader("ABOUT THIS PLANT", textTheme),
                        Text(
                          d['description'] ?? "",
                          style: textTheme.bodySmall?.copyWith(
                              color: Colors.black87, height: 1.5, fontSize: 12),
                        ),
                        const SizedBox(height: 32),
                        _buildScientificClassification(d, textTheme),
                        _buildSectionHeader(
                            "PHYSICAL CHARACTERISTICS", textTheme),
                        _buildCharacteristicsGrid(d, textTheme),
                        const SizedBox(height: 32),
                        _buildSectionHeader(
                            "HABITAT & DISTRIBUTION", textTheme),
                        _buildHabitatRows(
                            d['location_zone'], d['ecosystem_type'], textTheme),
                        const SizedBox(height: 32),
                        _buildSectionHeader("ECOLOGICAL IMPORTANCE", textTheme),
                        _buildEcologicalImportance(importance, textTheme),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  // --- UI HELPERS ---
  Widget _buildClimateCompatibility(
      dynamic tempMin, dynamic tempMax, TextTheme textTheme) {
    final String minVal = tempMin != null ? "$tempMin°C" : "20°C";
    final String maxVal = tempMax != null ? "$tempMax°C" : "32°C";

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("MIN TEMP",
                    style: textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: Colors.black38,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(minVal,
                    style: textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF303D32))),
              ],
            ),
          ),
          Container(
            height: 30,
            width: 1,
            color: Colors.black12,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("MAX TEMP",
                    style: textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: Colors.black38,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(maxVal,
                    style: textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF303D32))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallHeader(
          String? n, String? s, String? c, TextTheme textTheme) =>
      Container(
        padding:
            const EdgeInsets.only(top: 45, bottom: 12, left: 16, right: 16),
        color: Colors.white,
        child: Row(children: [
          IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(context)),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(n ?? "Unknown",
                    style: textTheme.titleMedium
                        ?.copyWith(fontSize: 17, fontWeight: FontWeight.bold)),
                Text(s ?? "N/A",
                    style: textTheme.labelSmall?.copyWith(
                        color: Colors.black45,
                        fontSize: 11,
                        fontStyle: FontStyle.italic)),
              ])),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black12)),
              child: Text(c ?? "Plant",
                  style: textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF5D7A5D), fontSize: 10))),
        ]),
      );

  void _openFullScreenGallery(List<String> urls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        int currentIndex = initialIndex;
        final PageController pageController =
            PageController(initialPage: initialIndex);

        return StatefulBuilder(builder: (context, setState) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
            ),
            body: Stack(
              children: [
                PageView.builder(
                  controller: pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: urls.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      child: Center(
                        child: Image.network(
                          urls[index],
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
                if (currentIndex > 0)
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left,
                              color: Colors.white),
                          onPressed: () {
                            pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut);
                          },
                        ),
                      ),
                    ),
                  ),
                if (currentIndex < urls.length - 1)
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: IconButton(
                          icon: const Icon(Icons.chevron_right,
                              color: Colors.white),
                          onPressed: () {
                            pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut);
                          },
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${currentIndex + 1} / ${urls.length}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      }),
    );
  }

  Widget _buildImageHero(dynamic imageRaw) {
    List<String> urls = [];
    if (imageRaw is List) {
      urls = imageRaw.map((e) => e.toString()).toList();
    } else if (imageRaw is String) {
      if (imageRaw.trim().startsWith('[')) {
        try {
          List<dynamic> parsedList = jsonDecode(imageRaw);
          urls = parsedList.map((e) => e.toString()).toList();
        } catch (e) {
          String cleaned = imageRaw
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '')
              .replaceAll("'", "");
          urls = cleaned
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } else if (imageRaw.contains(',')) {
        urls = imageRaw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (imageRaw.isNotEmpty) {
        urls = [imageRaw];
      }
    }

    if (urls.isEmpty) {
      return Container(
          height: 250, width: double.infinity, color: Colors.black12);
    }

    if (urls.length == 1) {
      return SizedBox(
        height: 250,
        width: double.infinity,
        child: GestureDetector(
          onTap: () => _openFullScreenGallery(urls, 0),
          child: Image.network(urls[0],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black12)),
        ),
      );
    }

    return _ImageCarousel(
      urls: urls,
      onTapImage: (index) => _openFullScreenGallery(urls, index),
    );
  }

  Widget _buildConservationStatus(
      String? s, String? source, TextTheme textTheme) {
    String status = s ?? 'Common';
    String src = source ?? 'DAO List';

    Color bgColor = const Color(0xFF8B1E1E);
    Color cardBg = const Color(0xFFFFF7F7);
    Color borderColor = Colors.red[200]!;

    if (status.toLowerCase().contains("least concern") ||
        status.toLowerCase().contains("not threatened")) {
      bgColor = Colors.green;
      cardBg = const Color(0xFFF0FDF4);
      borderColor = Colors.green[200]!;
    } else if (status.toLowerCase().contains("vulnerable") ||
        status.toLowerCase().contains("near threatened")) {
      bgColor = Colors.orange;
      cardBg = const Color(0xFFFFFBEB);
      borderColor = Colors.orange[200]!;
    } else if (status.toLowerCase().contains("endangered")) {
      bgColor = const Color(0xFF8B1E1E);
      cardBg = const Color(0xFFFFF7F7);
      borderColor = Colors.red[200]!;
    } else {
      bgColor = Colors.blueGrey;
      cardBg = Colors.blueGrey[50]!;
      borderColor = Colors.blueGrey[200]!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.shield_outlined,
                size: 16, color: Color(0xFF5D7A5D)),
            const SizedBox(width: 8),
            Text("CONSERVATION STATUS",
                style: textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    color: const Color(0xFF5D7A5D),
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: bgColor, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(status,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("SOURCE",
                          style: TextStyle(fontSize: 8, color: Colors.black54)),
                      Text(src,
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
              if (status.toLowerCase().contains("endangered")) ...[
                const SizedBox(height: 16),
                RichText(
                    text: TextSpan(
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black87, height: 1.5),
                        children: [
                      const TextSpan(
                          text: "Protected Species: ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text:
                              "This plant is ${status.toLowerCase()} and protected under Philippine environmental laws (RA 9147 & RA 11038). Unauthorized collection or harm is prohibited.")
                    ]))
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String t, TextTheme textTheme) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(t,
          style: textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: const Color(0xFF5D7A5D),
              fontWeight: FontWeight.bold)));

  Widget _buildCharacteristicsGrid(Map d, TextTheme textTheme) =>
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
                child: _card(Icons.straighten, "HEIGHT", d['height'] ?? "N/A",
                    textTheme)),
            const SizedBox(width: 8),
            Expanded(
                child: _card(Icons.eco_outlined, "LEAF TYPE",
                    d['leaf_type'] ?? "N/A", textTheme)),
            const SizedBox(width: 8),
            Expanded(
                child: _card(Icons.event, "FLOWERING", d['flowering'] ?? "N/A",
                    textTheme)),
          ],
        ),
      );

  Widget _card(IconData i, String l, String v, TextTheme textTheme) =>
      Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black.withOpacity(0.05))),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F0),
                      borderRadius: BorderRadius.circular(4)),
                  child: Icon(i, size: 14, color: const Color(0xFF5D7A5D)),
                ),
                const SizedBox(height: 8),
                FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(l,
                        style: textTheme.labelSmall
                            ?.copyWith(fontSize: 8, color: Colors.black38))),
                const SizedBox(height: 2),
                FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(v,
                        style: textTheme.titleSmall?.copyWith(
                            fontSize: 12, fontWeight: FontWeight.w600)))
              ]));

  Widget _buildScientificClassification(Map d, TextTheme textTheme) =>
      Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _buildSectionHeader("SCIENTIFIC CLASSIFICATION", textTheme),
          GestureDetector(
            onTap: () => setState(
                () => _isClassificationExpanded = !_isClassificationExpanded),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(_isClassificationExpanded ? "Hide" : "Show",
                      style:
                          const TextStyle(fontSize: 10, color: Colors.black54)),
                  Icon(
                      _isClassificationExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 16,
                      color: Colors.black54),
                ],
              ),
            ),
          )
        ]),
        if (_isClassificationExpanded) ...[
          _row("KINGDOM", d['kingdom'] ?? "Plantae", textTheme, false),
          _row("FAMILY", d['family'] ?? "N/A", textTheme, false),
          _row("GENUS", d['genus'] ?? "N/A", textTheme, true),
          _row("SPECIES", d['species'] ?? "N/A", textTheme, true),
        ],
        const SizedBox(height: 24),
      ]);

  Widget _row(String l, String v, TextTheme textTheme, bool isItalic) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(l,
                style: textTheme.labelSmall
                    ?.copyWith(fontSize: 11, color: Colors.black45)),
            Text(v,
                style: textTheme.titleSmall?.copyWith(
                    fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                    fontSize: 13))
          ]));

  Widget _buildHabitatRows(String? z, String? e, TextTheme textTheme) =>
      Column(children: [
        if (z != null && z.isNotEmpty)
          _info(Icons.location_on_outlined, "HABITAT ZONE", z, textTheme),
        if (e != null && e.isNotEmpty)
          _info(Icons.park_outlined, "ECOSYSTEM TYPE", e, textTheme),
      ]);

  Widget _info(IconData i, String l, String v, TextTheme textTheme) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(0xFFE8F3E8),
              borderRadius: BorderRadius.circular(6)),
          child: Icon(i, size: 16, color: const Color(0xFF5D7A5D)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l,
                style: textTheme.labelSmall
                    ?.copyWith(fontSize: 9, color: Colors.black54)),
            Text(v,
                style: textTheme.titleSmall
                    ?.copyWith(fontSize: 13, fontWeight: FontWeight.w500))
          ]),
        )
      ]));

  Widget _buildEcologicalImportance(String text, TextTheme textTheme) =>
      ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F3E8),
                  border: Border(
                      left: BorderSide(color: Color(0xFF5D7A5D), width: 4))),
              child: Text(text,
                  style: textTheme.bodySmall?.copyWith(
                      fontSize: 12, height: 1.5, color: Colors.black87))));

  Widget _buildFooter() => const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
          child: Text(
        "Cavite Protected Area • Department of Environment and\nNatural Resources",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 9, color: Colors.black45, height: 1.4),
      )));
}

class _ImageCarousel extends StatefulWidget {
  final List<String> urls;
  final Function(int) onTapImage;

  const _ImageCarousel({required this.urls, required this.onTapImage});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < widget.urls.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.urls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => widget.onTapImage(index),
                child: Image.network(widget.urls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.black12)),
              );
            },
          ),
          if (_currentIndex > 0)
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.4),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _previousPage,
                  ),
                ),
              ),
            ),
          if (_currentIndex < widget.urls.length - 1)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.4),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _nextPage,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${_currentIndex + 1} / ${widget.urls.length}",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
