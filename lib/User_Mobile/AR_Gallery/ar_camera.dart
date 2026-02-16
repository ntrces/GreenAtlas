import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

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
    return await _supabase.from('plants').select().eq('id', widget.plantData['id']).single();
  }

  void _launchAR(BuildContext context, String? url) {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AR Model Unavailable")));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
      appBar: AppBar(title: const Text("AR Mode"), backgroundColor: const Color(0xFFE8EDE8)),
      body: ModelViewer(src: url, ar: true, autoRotate: true, cameraControls: true),
    )));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getLatestPlantData(),
      initialData: widget.plantData,
      builder: (context, snapshot) {
        final d = snapshot.data ?? widget.plantData;
        final String importance = d['ecological_importance'] ?? "Pollinator attractor and biodiversity contributor.";

        return Scaffold(
          backgroundColor: const Color(0xFFF4F9F4),
          body: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildSmallHeader(d['common_name'], d['scientific_name'], d['category']),
              _buildSquareHero(d['image_url']),
              _buildARActionRow(d['ar_model_url']),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildConservationStatus(d['conservation_status']),
                _buildSectionHeader("ABOUT THIS PLANT"),
                Text(d['description'] ?? "", style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.5)),
                const SizedBox(height: 32),
                _buildScientificClassification(d),
                _buildSectionHeader("PHYSICAL CHARACTERISTICS"),
                _buildCharacteristicsGrid(d),
                _buildSectionHeader("HABITAT & DISTRIBUTION"),
                _buildHabitatRows(d['location_zone'], d['ecosystem_type']),
                _buildSectionHeader("ECOLOGICAL IMPORTANCE"),
                _buildEcologicalImportance(importance),
                const SizedBox(height: 40),
              ])),
            ]),
          ),
        );
      }
    );
  }

  // --- UI HELPERS ---
  Widget _buildSmallHeader(String? n, String? s, String? c) => Container(
    padding: const EdgeInsets.only(top: 45, bottom: 12, left: 16, right: 16), color: const Color(0xFFE8EDE8),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(n ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        Text(s ?? "N/A", style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black45)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: Text(c ?? "Plant", style: const TextStyle(color: Color(0xFF5D7A5D), fontSize: 10, fontWeight: FontWeight.bold))),
    ]),
  );

  Widget _buildSquareHero(String? url) => Center(child: Container(
    margin: const EdgeInsets.symmetric(vertical: 20), width: MediaQuery.of(context).size.width * 0.75,
    child: AspectRatio(aspectRatio: 1, child: ClipRRect(borderRadius: BorderRadius.circular(20), child: url != null ? Image.network(url, fit: BoxFit.cover) : Container(color: Colors.black12))),
  ));

  Widget _buildARActionRow(String? url) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: () => _launchAR(context, url), icon: const Icon(Icons.view_in_ar, color: Colors.white), label: const Text("Launch AR View", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D7A5D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))));

  Widget _buildCharacteristicsGrid(Map d) => GridView.count(
    shrinkWrap: true, crossAxisCount: 2, childAspectRatio: 2.2, mainAxisSpacing: 10, crossAxisSpacing: 10,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      _card(Icons.straighten, "HEIGHT", d['height'] ?? "N/A"),
      _card(Icons.eco_outlined, "LEAF TYPE", d['leaf_type'] ?? "N/A"),
      _card(Icons.event, "FLOWERING", d['flowering'] ?? "N/A"),
      _card(Icons.trending_up, "GROWTH", d['growth'] ?? "N/A"),
    ],
  );

  Widget _buildScientificClassification(Map d) => Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildSectionHeader("SCIENTIFIC CLASSIFICATION"), IconButton(icon: Icon(_isClassificationExpanded ? Icons.expand_less : Icons.expand_more), onPressed: () => setState(() => _isClassificationExpanded = !_isClassificationExpanded))]),
    if (_isClassificationExpanded) ...[
      _row("KINGDOM", d['kingdom'] ?? "Plantae"),
      _row("FAMILY", d['family'] ?? "N/A"),
      _row("GENUS", d['genus'] ?? "N/A", true),
      _row("SPECIES", d['species'] ?? "N/A", true),
    ],
    const SizedBox(height: 32),
  ]);

  Widget _buildEcologicalImportance(String text) => Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Color(0xFFEAF7EA), border: Border(left: BorderSide(color: Color(0xFF5D7A5D), width: 4))), child: Text(text, style: const TextStyle(fontSize: 13, height: 1.5)));

  Widget _card(IconData i, String l, String v) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, size: 14, color: const Color(0xFF5D7A5D)), Text(l, style: const TextStyle(fontSize: 8, color: Colors.black38)), Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: const TextStyle(fontWeight: FontWeight.bold))))]));
  Widget _row(String l, String v, [bool i = false]) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: const TextStyle(fontSize: 11, color: Colors.black45)), Text(v, style: TextStyle(fontWeight: FontWeight.bold, fontStyle: i ? FontStyle.italic : FontStyle.normal))]));
  Widget _buildSectionHeader(String t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black38)));
  Widget _buildConservationStatus(String? s) => Container(margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)), child: Text("Status: ${s ?? 'Common'}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));
  Widget _buildHabitatRows(String? z, String? e) => Column(children: [_info(Icons.park_outlined, "ECOSYSTEM", e ?? "N/A"), _info(Icons.location_on_outlined, "HABITAT ZONE", z ?? "N/A")]);
  Widget _info(IconData i, String l, String v) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Icon(i, size: 16, color: const Color(0xFF5D7A5D)), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 9, color: Colors.black38)), Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))])]));
}