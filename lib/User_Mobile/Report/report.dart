import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../user_dashboard.dart';
import '../AR_Gallery/ar_gallery.dart';
import '../../UserProfile/user_profile.dart';
import 'view_report.dart';
import '../notification.dart';
import 'submit_report1.dart'; 

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final supabase = Supabase.instance.client;
  int _selectedIndex = 2; 
  String _activeFilter = "All";

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserDashboard()));
    if (index == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ARGalleryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF2D3E2D),
        unselectedItemColor: Colors.black38,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.visibility_outlined), label: "AR Gallery"),
          BottomNavigationBarItem(icon: Icon(Icons.report_problem_outlined), label: "Report Issue"),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitReport1Screen())),
        backgroundColor: const Color(0xFF4A634A),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('reports').stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF4A634A)));
          
          final reports = snapshot.data!;
          final filteredReports = _activeFilter == "All" 
              ? reports 
              : reports.where((r) => r['status'] == _activeFilter).toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: false, pinned: true,
                backgroundColor: Colors.white, elevation: 0,
                toolbarHeight: 70, leadingWidth: 70,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Center(
                    child: Image.asset('logo2.png', width: 40, height: 40, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Color(0xFF2D3E2D), size: 30)),
                  ),
                ),
                title: const Text("Report", style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 22)),
                actions: [_buildNotificationIcon(), _buildProfileIcon()],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- UPDATED METRIC CARDS: INCLUDES INVESTIGATING ---
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildMetricCard(reports.length.toString(), "Total", const Color(0xFF2D3E2D)),
                            const SizedBox(width: 8),
                            _buildMetricCard(reports.where((r) => r['status'] == 'Pending').length.toString(), "Pending", Colors.orange),
                            const SizedBox(width: 8),
                            _buildMetricCard(reports.where((r) => r['status'] == 'Investigating').length.toString(), "Active", Colors.blue),
                            const SizedBox(width: 8),
                            _buildMetricCard(reports.where((r) => r['status'] == 'Resolved').length.toString(), "Resolved", Colors.green),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // --- UPDATED FILTER CHIPS: INCLUDES INVESTIGATING ---
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip("All", icon: Icons.list),
                            _buildFilterChip("Pending", icon: Icons.access_time),
                            _buildFilterChip("Investigating", icon: Icons.search),
                            _buildFilterChip("Resolved", icon: Icons.check_circle_outline),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text("YOUR REPORTS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4A634A), letterSpacing: 0.8)),
                      const SizedBox(height: 12),
                      
                      if (filteredReports.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No reports found for this status."))),

                      ...filteredReports.map((data) => _buildReportCard(data)).toList(),
                      
                      const SizedBox(height: 16),
                      _buildCollapsibleContacts(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildMetricCard(String val, String lab, Color col) => Container(
    width: 90, padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.05))),
    child: Column(children: [
      Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: col)),
      Text(lab, style: const TextStyle(fontSize: 10, color: Colors.black38, fontWeight: FontWeight.w600))
    ]),
  );

  Widget _buildFilterChip(String label, {IconData? icon}) {
    bool isSelected = _activeFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        avatar: icon != null ? Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF4A634A)) : null,
        selected: isSelected,
        onSelected: (val) => setState(() => _activeFilter = label),
        selectedColor: const Color(0xFF4A634A),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF4A634A), fontSize: 13, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> data) {
    final status = data['status'] ?? "Pending";
    final type = data['incident_type'] ?? "Incident";
    final id = "RPT-${(data['id'] ?? "000").toString().padLeft(3, '0').substring(0,3)}";

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ViewReportScreen(reportData: data))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3E2D)), overflow: TextOverflow.ellipsis)),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 4),
          Text(id, style: const TextStyle(fontSize: 11, color: Colors.black26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(data['description'] ?? "", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoRow(Icons.location_on_outlined, data['location'] ?? "N/A"),
              const Spacer(),
              _buildInfoRow(Icons.calendar_today_outlined, (data['created_at'] ?? "").toString().split('T')[0]),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color col;
    IconData icon;
    
    // Mapping status to colors from Admin panel
    switch (status) {
      case "Resolved":
        col = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case "Investigating":
        col = Colors.blue;
        icon = Icons.search;
        break;
      case "Forwarded":
        col = Colors.purple;
        icon = Icons.forward_to_inbox;
        break;
      default: // Pending
        col = Colors.orange;
        icon = Icons.access_time;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: col),
        const SizedBox(width: 4),
        Text(status.toUpperCase(), style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  // (Notification, Profile, Contacts helpers remain identical)
  Widget _buildInfoRow(IconData icon, String text) => Row(children: [Icon(icon, size: 14, color: Colors.black26), const SizedBox(width: 6), Text(text, style: const TextStyle(fontSize: 11, color: Colors.black45))]);
  Widget _buildNotificationIcon() => Stack(alignment: Alignment.center, children: [IconButton(icon: const Icon(Icons.notifications_none, color: Color(0xFF2D3E2D), size: 28), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())))]);
  Widget _buildProfileIcon() => Padding(padding: const EdgeInsets.only(right: 16.0, left: 8), child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())), child: Container(height: 38, width: 38, decoration: BoxDecoration(color: const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)), child: const Icon(Icons.person_outline, color: Colors.black54))));
  Widget _buildCollapsibleContacts() { if (_activeFilter != "All") return const SizedBox.shrink(); return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)), child: Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: ExpansionTile(title: const Text("EMERGENCY CONTACTS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4A634A), letterSpacing: 0.5)), children: [_buildContactItem(Icons.phone_outlined, "DENR Cavite", "(046) 123-4567"), const Divider(height: 1, indent: 16, endIndent: 16), _buildContactItem(Icons.phone_outlined, "Forest Rangers Hotline", "0917-XXX-XXXX"), const Divider(height: 1, indent: 16, endIndent: 16), _buildContactItem(Icons.error_outline, "Emergency (Fire/Wildlife)", "911")]))); }
  Widget _buildContactItem(IconData icon, String title, String subtitle) => ListTile(leading: Icon(icon, color: const Color(0xFF5D7A5D), size: 22), title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))), subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black45)), trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.black26));
}