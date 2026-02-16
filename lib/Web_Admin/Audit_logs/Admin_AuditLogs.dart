import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuditLogsView extends StatefulWidget {
  const AuditLogsView({super.key});

  @override
  State<AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends State<AuditLogsView> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _selectedLog;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AUDIT LOGS & ACCOUNTABILITY TRAIL", 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const Text("Tracking current and legacy account activities", 
              style: TextStyle(fontSize: 13, color: Colors.black38)),
          const SizedBox(height: 32),

          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('audit_logs').stream(primaryKey: ['id']).order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
              
              final allLogs = snapshot.data ?? [];

              // Role-based filtering
              final employeeLogs = allLogs.where((l) => 
                l['description'].toString().toLowerCase().contains('employee') || 
                l['category'] == 'Data'
              ).toList();

              final userLogs = allLogs.where((l) => 
                l['description'].toString().toLowerCase().contains('user') || 
                l['title'] == 'Legacy Account Sync' // Including older accounts
              ).toList();
              
              return Column(
                children: [
                  _buildMetricRow(allLogs),
                  const SizedBox(height: 32),

                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: const Color(0xFF4D6D4D),
                    indicatorColor: const Color(0xFF4D6D4D),
                    tabs: const [
                      Tab(text: "Employee Trail"),
                      Tab(text: "User Registrations"),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline Section
                      Expanded(
                        flex: 7,
                        child: SizedBox(
                          height: 600,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildTimeline(employeeLogs, "Employee Activity"),
                              _buildTimeline(userLogs, "User Records (Current & Legacy)"),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Detail Panel
                      Expanded(
                        flex: 3,
                        child: _buildDetailsPanel(_selectedLog),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<Map<String, dynamic>> logs, String title) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text("${logs.length} entries", style: const TextStyle(fontSize: 11, color: Colors.black26)),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 60),
            itemBuilder: (context, index) {
              final log = logs[index];
              bool isSelected = _selectedLog?['id'] == log['id'];
              return _logRow(log, isSelected);
            },
          ),
        ),
      ]),
    );
  }

  Widget _logRow(Map<String, dynamic> log, bool isSelected) {
    bool isLegacy = log['title'] == 'Legacy Account Sync';
    return InkWell(
      onTap: () => setState(() => _selectedLog = log),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: isSelected ? const Color(0xFFF0F9FF) : Colors.transparent,
        child: Row(children: [
          Icon(isLegacy ? Icons.history : Icons.person_add, color: isLegacy ? Colors.orange : Colors.blue),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(log['title'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(log['description'] ?? "", style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ])),
          Text(log['timestamp']?.toString().split(' ')[0] ?? "", style: const TextStyle(fontSize: 10, color: Colors.black26)),
        ]),
      ),
    );
  }

  // Helper methods for Metrics and Detail Panel
  Widget _buildMetricRow(List logs) => Row(children: [
    _card("${logs.length}", "Total Logs"), const SizedBox(width: 16),
    _card("${logs.where((l)=>l['title'] == 'Legacy Account Sync').length}", "Legacy Sync"),
  ]);

  Widget _card(String v, String t) => Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.black12)), child: Column(children: [Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text(t, style: const TextStyle(fontSize: 11, color: Colors.black38))])));

  Widget _buildDetailsPanel(Map<String, dynamic>? log) {
    if (log == null) return const Card(child: Center(child: Text("Select a log")));
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Audit Details", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _detail("Action", log['title']),
        _detail("Account Email", log['user']),
        _detail("Activity Date", log['timestamp']),
        _detail("System Status", log['result'], isGreen: log['result'] == "Success"),
      ]),
    );
  }

  Widget _detail(String l, String? v, {bool isGreen = false}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 10, color: Colors.black26)), Text(v ?? "N/A", style: TextStyle(fontWeight: FontWeight.bold, color: isGreen ? Colors.green : Colors.black87))]));
  
  Widget _buildErrorState(String e) => Center(child: Text("Sync Error: $e"));
}