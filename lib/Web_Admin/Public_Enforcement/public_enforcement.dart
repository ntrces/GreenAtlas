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
          // Realtime stream
          stream: _supabase.from('reports').stream(primaryKey: ['id']).order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            
            final reports = snapshot.data ?? [];

            // Filter logic
            final filteredReports = reports.where((r) {
              if (_activeTab == "ALL") return true;
              if (_activeTab == "ACTIVE") return (r['status'] ?? "") == 'Investigating' || (r['status'] ?? "") == 'Pending';
              return (r['status'] ?? "").toString().toUpperCase() == _activeTab;
            }).toList();

            // SAFETY: Ensure selection is valid after filtering
            if (_selectedReportIndex >= filteredReports.length) {
              _selectedReportIndex = 0;
            }

            return Column(
              children: [
                _buildMetricRow(reports),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: _buildIncidentList(filteredReports)),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 4, 
                      child: filteredReports.isEmpty
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(4)
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
                Text(report['incident_type'] ?? "Incident", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _statusBanner(report['status'] ?? "Pending"),
                const SizedBox(height: 24),
                _detailField("Location", report['location'] ?? "N/A"),
                _detailField("Description", report['description'] ?? "No description."),
                const Divider(height: 40),
                _buildDropdown("Status", _newStatus ?? report['status'] ?? "Pending", ["Pending", "Investigating", "Resolved"], (v) => setState(() => _newStatus = v)),
                const SizedBox(height: 16),
                _buildDropdown("Assign To", _assignedTeam ?? report['assigned_team'] ?? "Enforcement Team Alpha", ["Enforcement Team Alpha", "Team Beta", "Rangers"], (v) => setState(() => _assignedTeam = v)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _updateReport(report['id'].toString()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF517156),
                      padding: const EdgeInsets.all(20),
                    ),
                    child: const Text("UPDATE CASE STATUS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- REUSABLE HELPERS ---
  Widget _panelHeader(String title, String sub) => Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(sub, style: const TextStyle(color: Colors.black38, fontSize: 12))]),
  );

  Widget _statCard(String val, String title, String sub, Color color) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(20), 
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(4)), 
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text(val, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))]), Text(sub, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color.withOpacity(0.6)))])
    )
  );

  Widget _buildMetricRow(List<Map<String, dynamic>> reports) {
    int pending = reports.where((r) => r['status'] == 'Pending' || r['status'] == 'Investigating').length;
    int resolved = reports.where((r) => r['status'] == 'Resolved').length;
    return Row(children: [
      _statCard(pending.toString(), "Active", "UNDER INVESTIGATION", Colors.orange),
      _statCard(resolved.toString(), "Resolved", "CASES CLOSED", Colors.green),
      _statCard("3", "High Priority", "URGENT ACTION", Colors.red),
    ]);
  }

  Widget _buildFilterTabs() => Container(padding: const EdgeInsets.all(8), color: const Color(0xFFF9FAFB), child: Row(children: ["ALL", "ACTIVE", "RESOLVED"].map((tab) { bool active = _activeTab == tab; return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(tab, style: TextStyle(color: active ? Colors.white : Colors.black87, fontSize: 11)), selected: active, onSelected: (v) => setState(() => _activeTab = tab), selectedColor: const Color(0xFF4D6D4D))); }).toList()));
  Widget _statusBanner(String status) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFF9E6), borderRadius: BorderRadius.circular(4)), child: Text(status, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)));
  Widget _detailField(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black38)), Text(value, style: const TextStyle(fontSize: 13))]));
  Widget _buildDropdown(String label, String current, List<String> options, Function(String?) onChanged) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), DropdownButtonFormField<String>(value: current, items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged)]);
  Color _getStatusColor(String? status) => status == "Investigating" ? Colors.orange : status == "Resolved" ? Colors.green : Colors.black38;
  Widget _buildHeader() => const Text("PUBLIC ENFORCEMENT MANAGEMENT", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
}