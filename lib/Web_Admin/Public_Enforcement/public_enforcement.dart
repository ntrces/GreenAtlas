import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublicEnforcementView extends StatefulWidget {
  const PublicEnforcementView({super.key});

  @override
  State<PublicEnforcementView> createState() => _PublicEnforcementViewState();
}

class _PublicEnforcementViewState extends State<PublicEnforcementView> {
  final _supabase = Supabase.instance.client;
  int _selectedReportIndex = 0;
  String _activeTab = "ALL";
  
  String? _newStatus;
  String? _assignedTeam;

  // --- DATABASE UPDATE LOGIC ---
  Future<void> _updateReport(String reportId) async {
    try {
      await _supabase.from('reports').update({
        'status': _newStatus,
        'assigned_team': _assignedTeam, 
      }).eq('id', reportId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Case updated successfully!"), backgroundColor: Color(0xFF517156))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: $e"), backgroundColor: Colors.redAccent)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 32),
        
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _supabase.from('reports').stream(primaryKey: ['id']).order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final reports = snapshot.data ?? [];

            // Filter logic matching the design tabs
            final filteredReports = reports.where((r) {
              if (_activeTab == "ALL") return true;
              if (_activeTab == "ACTIVE") return (r['status'] ?? "") == 'Investigating' || (r['status'] ?? "") == 'Pending';
              return (r['status'] ?? "").toString().toUpperCase() == _activeTab;
            }).toList();

            return Column(
              children: [
                _buildMetricRow(reports),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT SIDE: Incident List
                    Expanded(flex: 6, child: _buildIncidentList(filteredReports)),
                    const SizedBox(width: 32),
                    // RIGHT SIDE: Case Details with Image Preview
                    Expanded(
                      flex: 4, 
                      child: (filteredReports.isEmpty || _selectedReportIndex >= filteredReports.length)
                        ? const Card(child: Padding(padding: EdgeInsets.all(32), child: Text("No reports found")))
                        : _buildCaseDetails(filteredReports[_selectedReportIndex])
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildIncidentList(List<Map<String, dynamic>> reports) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        border: Border.all(color: Colors.black12), 
        borderRadius: BorderRadius.circular(4)
      ),
      child: Column(
        children: [
          _panelHeader("Incident Reports", "${reports.length} cases"),
          _buildFilterTabs(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              bool isSelected = _selectedReportIndex == index;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedReportIndex = index;
                    _newStatus = report['status'];
                    _assignedTeam = report['assigned_team'] ?? "Enforcement Team Alpha";
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF8FAF8) : Colors.transparent,
                    border: const Border(bottom: BorderSide(color: Colors.black12))
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("RPT-${(report['id'] ?? "0").toString().substring(0, 3)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            Text((report['created_at'] ?? "").toString().split('T')[0], style: const TextStyle(fontSize: 11, color: Colors.black38)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(report['incident_type'] ?? "Unknown Incident", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(report['location'] ?? "Unknown Location", style: const TextStyle(fontSize: 12, color: Colors.black45)),
                            Row(children: [
                              const Icon(Icons.person_outline, size: 12, color: Colors.black38),
                              const Text(" Anonymous Citizen • ", style: TextStyle(fontSize: 12, color: Colors.black38)),
                              if (report['evidence_url'] != null) const Icon(Icons.link, size: 12, color: Colors.blueAccent),
                              if (report['evidence_url'] != null) const Text(" Evidence", style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                            ]),
                          ],
                        ),
                      ),
                      Text((report['status'] ?? "PENDING").toString().toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(report['status']), fontSize: 11)),
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildCaseDetails(Map<String, dynamic> report) {
    final String? evidenceUrl = report['evidence_url'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        border: Border.all(color: Colors.black12), 
        borderRadius: BorderRadius.circular(4)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelHeader("Case Details", ""),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // EVIDENCE IMAGE PREVIEW
                if (evidenceUrl != null && evidenceUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(evidenceUrl, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100], child: const Icon(Icons.broken_image, color: Colors.black12))),
                      ),
                    ),
                  ),

                Text(report['incident_type'] ?? "Incident", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text("RPT-${(report['id'] ?? "0").toString().substring(0,3)} • ${report['created_at'] ?? 'N/A'}", style: const TextStyle(fontSize: 12, color: Colors.black38)),
                const SizedBox(height: 16),
                _statusBanner(report['status'] ?? "Pending"),
                const SizedBox(height: 24),
                _detailField("Location", report['location'] ?? "N/A"),
                _detailField("Incident Description", report['description'] ?? "No description provided."),
                _detailField("Current Assignment", report['assigned_team'] ?? "Unassigned"),
                const Divider(height: 40),
                const Text("Case Management", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black45)),
                const SizedBox(height: 16),
                _buildDropdown("Status", _newStatus ?? report['status'] ?? "Pending", ["Pending", "Investigating", "Resolved", "Forwarded"], (v) => setState(() => _newStatus = v)),
                const SizedBox(height: 16),
                _buildDropdown("Assign To", _assignedTeam ?? "Enforcement Team Alpha", ["Enforcement Team Alpha", "Team Beta", "Rangers"], (v) => setState(() => _assignedTeam = v)),
                const SizedBox(height: 24),
                
                // --- THE UPDATED BUTTON WITH BRAND COLOR #517156 ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateReport((report['id'] ?? "").toString()),
                    icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
                    label: const Text("UPDATE CASE STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.pressed)) return const Color(0xFF3B523E);
                        if (states.contains(WidgetState.hovered)) return const Color(0xFF628968);
                        return const Color(0xFF517156); // BRAND COLOR
                      }),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                      padding: WidgetStateProperty.all(const EdgeInsets.all(20)),
                      elevation: WidgetStateProperty.all(0),
                      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                      mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- REUSABLE UI HELPERS WITH DECORATION FIXES ---

  Widget _panelHeader(String title, String sub) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16), 
    decoration: const BoxDecoration(
      color: Colors.white, // FIX: MUST BE INSIDE DECORATION
      border: Border(bottom: BorderSide(color: Colors.black12))
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(sub, style: const TextStyle(color: Colors.black38, fontSize: 12))]),
  );

  Widget _statCard(String val, String title, String sub, Color color) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(20), 
      decoration: BoxDecoration(
        color: Colors.white, // FIX: MUST BE INSIDE DECORATION
        border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(4)
      ), 
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text(val, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))]), const SizedBox(height: 4), Text(sub, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color.withOpacity(0.6), letterSpacing: 1))])
    )
  );

  Widget _buildMetricRow(List<Map<String, dynamic>> reports) {
    int pending = reports.where((r) => r['status'] == 'Pending' || r['status'] == 'Investigating').length;
    int resolved = reports.where((r) => r['status'] == 'Resolved').length;
    int forwarded = reports.where((r) => r['status'] == 'Forwarded').length;
    return Row(children: [
      _statCard(pending.toString(), "Under Investigation", "ACTIVE CASES", Colors.orange),
      _statCard(resolved.toString(), "Resolved", "Cases closed", Colors.black87),
      _statCard(forwarded.toString(), "Forwarded", "External authorities", Colors.black87),
      _statCard("3", "High Priority", "URGENT ACTION", Colors.red),
    ]);
  }

  Widget _buildFilterTabs() => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: const Color(0xFFF9FAFB), child: Row(children: ["ALL", "ACTIVE", "RESOLVED", "FORWARDED"].map((tab) { bool active = _activeTab == tab; return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(tab, style: TextStyle(color: active ? Colors.white : Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)), selected: active, onSelected: (v) => setState(() => _activeTab = tab), selectedColor: const Color(0xFF4D6D4D), backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)))); }).toList()));
  Widget _statusBanner(String status) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFF9E6), borderRadius: BorderRadius.circular(4)), child: Row(children: [const Icon(Icons.access_time, size: 16, color: Colors.orange), const SizedBox(width: 8), Text(status, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13))]));
  Widget _detailField(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.black38, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.black12)), child: Text(value, style: const TextStyle(fontSize: 13)))]));
  Widget _buildDropdown(String label, String current, List<String> options, Function(String?) onChanged) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45)), const SizedBox(height: 8), DropdownButtonFormField<String>(value: current, items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(), onChanged: onChanged, decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12), border: OutlineInputBorder()))]);
  Color _getStatusColor(String? status) => status == "Investigating" ? Colors.orange : status == "Resolved" ? Colors.green : status == "Forwarded" ? Colors.blue : Colors.black38;
  Widget _buildHeader() => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("PUBLIC ENFORCEMENT MANAGEMENT", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))), Text("Citizen incident reports • violation tracking • Case management", style: TextStyle(fontSize: 13, color: Colors.black38))]), Row(children: [_miniMetric("Avg. resolution time:", "2.4 days"), const SizedBox(width: 24), _miniMetric("Response rate:", "98%")])]);
  Widget _miniMetric(String label, String val) => Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.black38)), Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D)))]);
}