import 'package:flutter/material.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ADMIN CONTROL PANEL", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const Text("System overview • Feb 6, 2026", style: TextStyle(fontSize: 13, color: Colors.black38)),
        const SizedBox(height: 32),
        
        // --- 📊 Statistics Cards ---
        Row(
          children: [
            _buildKPI("15", "Pending Validation", Colors.orange, "ACTION REQUIRED"),
            const SizedBox(width: 24),
            _buildKPI("8", "Public Reports", Colors.redAccent, "CRITICAL"),
            const SizedBox(width: 24),
            _buildKPI("156", "Plant Species", Colors.black87, "Database operational"),
            const SizedBox(width: 24),
            _buildKPI("342", "Audit Events", Colors.black87, "Last 30 days"),
          ],
        ),
        const SizedBox(height: 40),
        
        // --- Split Layout: Priority Queue & System Functions ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildPriorityQueue()),
            const SizedBox(width: 32),
            Expanded(flex: 5, child: _buildSystemFunctions()),
          ],
        )
      ],
    );
  }

  Widget _buildKPI(String val, String label, Color col, String status) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Text(val, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: col)), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.black38))]),
            const SizedBox(height: 12),
            Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: col, letterSpacing: 1)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: 0.6, backgroundColor: col.withOpacity(0.1), color: col, minHeight: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityQueue() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Priority Queue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("3 ITEMS", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          _queueItem(Icons.warning_amber_rounded, "CRITICAL", "3 illegal logging reports", Colors.red, "REVIEW NOW"),
          _queueItem(Icons.access_time, "HIGH", "15 diary entries awaiting validation", Colors.orange, "PROCESS QUEUE"),
          _queueItem(Icons.eco_outlined, "NORMAL", "2 new plant species for AR upload", Colors.green, "MANAGE DATA"),
        ],
      ),
    );
  }

  Widget _queueItem(IconData icon, String tag, String desc, Color col, String btnText) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(border: Border(left: BorderSide(color: col, width: 4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: col, size: 16), const SizedBox(width: 8), Text(tag, style: TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: col, foregroundColor: Colors.white, elevation: 0, minimumSize: const Size(double.infinity, 36)),
            child: Text(btnText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildSystemFunctions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("System Functions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _funcRow(Icons.verified_user_outlined, "Validation Queue", "Review field diary entries", true),
          _funcRow(Icons.storage_outlined, "Plant Data Management", "Update plant profiles & AR", false),
          _funcRow(Icons.warning_amber_rounded, "Public Enforcement", "Manage public reports", true),
          _funcRow(Icons.assignment_outlined, "Audit & Compliance Logs", "Accountability trails", false),
          _funcRow(Icons.calendar_today_outlined, "Meeting Coordination", "Schedule field staff RSVP", false, isCreate: true),
        ],
      ),
    );
  }

  Widget _funcRow(IconData icon, String title, String desc, bool hasBadge, {bool isCreate = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: const Color(0xFFF0F4F0), child: Icon(icon, color: const Color(0xFF4D6D4D), size: 18)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 11, color: Colors.black38)),
      trailing: Text(isCreate ? "+ CREATE" : "OPEN →", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4D6D4D))),
    );
  }
}