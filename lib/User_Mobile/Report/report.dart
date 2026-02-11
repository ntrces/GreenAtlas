import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme_constants.dart';
import '../user_dashboard.dart';
import '../AR_Gallery/ar_gallery.dart';
import '../../UserProfile/user_profile.dart';
import 'view_report.dart';
import '../notification.dart';

// --- IMPORT THE NEW SCREEN YOU JUST CREATED ---
import 'submit_report1.dart'; 

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final supabase = Supabase.instance.client;
  int _selectedIndex = 2; // Fixed index for Report screen
  String _activeFilter = "All";

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const UserDashboard()));
    if (index == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ARGalleryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA),
      // --- PERSISTENT BOTTOM NAV ---
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

      // --- ➕ FLOATING ACTION BUTTON FIX ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigates directly to the legal info screen (submit_report1.dart)
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const SubmitReport1Screen())
          );
        },
        backgroundColor: const Color(0xFF4A634A),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('reports').stream(primaryKey: ['id']).order('created_at'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF4A634A)));
          
          final reports = snapshot.data!;
          final filteredReports = _activeFilter == "All" 
              ? reports 
              : reports.where((r) => r['status'] == _activeFilter).toList();

          return CustomScrollView(
            slivers: [
              // --- 1. BRANDING HEADER ---
              SliverAppBar(
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                toolbarHeight: 70,
                leadingWidth: 70,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Center(
                    child: Image.asset(
                      'logo2.png', // Reference directly to fix Web 404 doubling
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Color(0xFF2D3E2D), size: 30),
                    ),
                  ),
                ),
                title: const Text("Report", style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 22)),
                actions: [
                  _buildNotificationIcon(),
                  
                  _buildProfileIcon(),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 2. METRIC CARDS ---
                      Row(
                        children: [
                          _buildMetricCard(reports.length.toString(), "Total Reports", const Color(0xFF2D3E2D)),
                          const SizedBox(width: 10),
                          _buildMetricCard(reports.where((r) => r['status'] == 'Pending').length.toString(), "Pending", Colors.orange),
                          const SizedBox(width: 10),
                          _buildMetricCard(reports.where((r) => r['status'] == 'Resolved').length.toString(), "Resolved", Colors.green),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // --- 3. FILTER CHIPS ---
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip("All", icon: Icons.list),
                            _buildFilterChip("Pending", icon: Icons.access_time),
                            _buildFilterChip("Resolved", icon: Icons.check_circle_outline),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text("YOUR REPORTS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A634A), letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      
                      // --- 4. REPORT LIST ---
                      ...filteredReports.map((data) => _buildReportCard(data)).toList(),
                      
                      const SizedBox(height: 16),
                      // --- 5. EMERGENCY CONTACTS (ONLY ON "ALL" FILTER) ---
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

  Widget _buildMetricCard(String val, String lab, Color col) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: Column(children: [Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: col)), Text(lab, style: const TextStyle(fontSize: 11, color: Colors.black38))]),
    ),
  );

  Widget _buildFilterChip(String label, {IconData? icon}) {
    bool isSelected = _activeFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        avatar: icon != null ? Icon(icon, size: 18, color: isSelected ? Colors.white : const Color(0xFF4A634A)) : null,
        selected: isSelected,
        onSelected: (val) => setState(() => _activeFilter = label),
        selectedColor: const Color(0xFF4A634A),
        backgroundColor: const Color(0xFFEAF7EA),
        labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF4A634A), fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide.none),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> data) {
    final status = data['status'] ?? "Pending";
    final priority = data['priority'] ?? "High";

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ViewReportScreen(reportData: data))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.05))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Flexible(child: Text(data['incident_type'] ?? "Report", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3E2D)), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              _buildBadge(priority, priority == "High" ? Colors.red : Colors.orange),
              const SizedBox(width: 8),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 4),
          const Text("RPT-001", style: TextStyle(fontSize: 11, color: Colors.black26)),
          const SizedBox(height: 12),
          Text(data['description'] ?? "", maxLines: 2, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_outlined, "Zone A-2, Near river"),
          const SizedBox(height: 4),
          _buildInfoRow(Icons.calendar_today_outlined, "2026-01-26"),
        ]),
      ),
    );
  }

  Widget _buildBadge(String text, Color col) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.bold)),
  );

  Widget _buildStatusBadge(String status) {
    final isResolved = status == "Resolved";
    final col = isResolved ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: col.withOpacity(0.2))),
      child: Row(children: [
        Icon(isResolved ? Icons.check_circle_outline : Icons.access_time, size: 14, color: col),
        const SizedBox(width: 4),
        Text(status, style: TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) => Row(children: [
    Icon(icon, size: 14, color: Colors.black26),
    const SizedBox(width: 6),
    Text(text, style: const TextStyle(fontSize: 12, color: Colors.black38)),
  ]);

  Widget _buildNotificationIcon() => Stack(
  alignment: Alignment.center,
  children: [
    IconButton(icon: const Icon(Icons.notifications_none, color: Color(0xFF2D3E2D), size: 28), 
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()))),
    Positioned(right: 8, top: 12, child: Container(padding: const EdgeInsets.all(4), 
      decoration: const BoxDecoration(color: Color(0xFF5D7A5D), shape: BoxShape.circle), 
      child: const Text("2", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
  ],
);

  Widget _buildProfileIcon() => Padding(
    padding: const EdgeInsets.only(right: 16.0, left: 8),
    child: InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
      child: Container(height: 38, width: 38, decoration: BoxDecoration(color: const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)), child: const Icon(Icons.person_outline, color: Colors.black54)),
    ),
  );

  Widget _buildCollapsibleContacts() {
    if (_activeFilter != "All") return const SizedBox.shrink(); // Hide if not "All"
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text("EMERGENCY CONTACTS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A634A))),
          children: [
            _buildContactItem(Icons.phone_outlined, "DENR Cavite", "(046) 123-4567"),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildContactItem(Icons.phone_outlined, "Forest Rangers Hotline", "0917-XXX-XXXX"),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildContactItem(Icons.error_outline, "Emergency (Fire/Wildlife)", "911"),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String title, String subtitle) => ListTile(
    leading: Icon(icon, color: const Color(0xFF5D7A5D), size: 22),
    title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black45)),
    trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.black26),
  );
}