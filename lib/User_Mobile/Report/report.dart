import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_eco_supabase/User_Mobile/Report/submit_report.dart';
import '../../theme_constants.dart';
import '../user_dashboard.dart';
import '../AR_Gallery/ar_gallery.dart';
import '../UserProfile/user_profile.dart'; 
import 'view_report.dart';
import '../notification.dart';


class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final supabase = Supabase.instance.client;
  int _selectedIndex = 2; // Fixed index for Report screen

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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.visibility_outlined), label: "AR Gallery"),
          BottomNavigationBarItem(icon: Icon(Icons.report_problem_outlined), label: "Report Issue"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SubmitReportScreen())),
        backgroundColor: const Color(0xFF4A634A),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('reports').stream(primaryKey: ['id']).order('created_at'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF4A634A)));
          final reports = snapshot.data!;

          return CustomScrollView(
            slivers: [
              // --- 1. PINNED BRANDING HEADER ---
SliverAppBar(
  floating: false,
  pinned: true,
  backgroundColor: Colors.white,
  surfaceTintColor: Colors.white,
  elevation: 0,
  toolbarHeight: 80,
  leadingWidth: 70,
  leading: const Padding(
    padding: EdgeInsets.only(left: 16.0),
    child: CircleAvatar(
      backgroundColor: Color(0xFF5D7A5D),
      backgroundImage: AssetImage('assets/logo1.png'), 
    ),
  ),
  title: const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("Welcome, User", 
        style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 22)),
      Text("Explore the Cavite Protected Area", 
        style: TextStyle(color: Colors.black54, fontSize: 12)),
    ],
  ),
  actions: [
    // --- NOTIFICATION BELL WITH BADGE ---
    Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF2D3E2D), size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen())),
          ),
          Positioned(
            right: 8,
            top: 15,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Text(
                "2", 
                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ],
      ),
    ),
    // --- USER PROFILE ICON ---
    Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileScreen())),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 40, width: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black12),
          ),
          child: const Icon(Icons.person_outline, color: Colors.black54),
        ),
      ),
    ),
  ],
),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 2. DYNAMIC SUMMARY METRICS ---
                      Row(
                        children: [
                          _buildMetricCard(reports.length.toString(), "Total Reports", Colors.black54),
                          const SizedBox(width: 10),
                          _buildMetricCard(reports.where((r) => r['status'] == 'Pending').length.toString(), "Pending", Colors.orange),
                          const SizedBox(width: 10),
                          _buildMetricCard(reports.where((r) => r['status'] == 'Resolved').length.toString(), "Resolved", Colors.green),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      const Text("YOUR REPORTS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A634A), letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      
                      // --- 3. REPORT LIST ---
                      ...reports.map((data) => InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ViewReportScreen(reportData: data))),
                        child: _buildReportCard(data),
                      )).toList(),

                      const SizedBox(height: 16),

                      // --- 4. WHITE COLLAPSIBLE EMERGENCY CONTACTS ---
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

  // --- UI BUILDER HELPERS ---

  Widget _buildMetricCard(String val, String lab, Color col) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
      child: Column(children: [Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: col)), Text(lab, style: const TextStyle(fontSize: 11, color: Colors.black38))]),
    ),
  );

  Widget _buildReportCard(Map<String, dynamic> data) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(data['incident_type'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3E2D))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(data['status'] ?? "Pending", style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(data['description'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Colors.black54)),
      ]),
    ),
  );

  Widget _buildCollapsibleContacts() => Container(
    decoration: BoxDecoration(
      color: Colors.white, // Changed to White
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.black12),
    ),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: const Text("EMERGENCY CONTACTS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A634A))),
        trailing: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4A634A)),
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

  Widget _buildContactItem(IconData icon, String title, String subtitle) => ListTile(
    leading: Icon(icon, color: const Color(0xFF5D7A5D), size: 22),
    title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black45)),
    trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.black26),
    onTap: () {}, // Add dialer logic here
  );
}