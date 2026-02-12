import 'package:flutter/material.dart';

class AuditLogsView extends StatelessWidget {
  const AuditLogsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("AUDIT & COMPLIANCE LOGS", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const Text("System accountability trail • Data integrity tracking", style: TextStyle(fontSize: 13, color: Colors.black38)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
          child: Column(
            children: [
              _buildLogHeader(),
              _logItem("Feb 12, 14:30", "DENR Admin", "Updated 'Philippine Orchid' AR Model", "SUCCESS", Colors.green),
              _logItem("Feb 12, 11:20", "System", "Auto-backup database", "COMPLETED", Colors.blue),
              _logItem("Feb 11, 09:15", "Admin User 2", "Deleted flagged poacher report #RPT-092", "WARNING", Colors.orange),
              _logItem("Feb 11, 08:00", "Unknown IP", "Failed login attempt", "CRITICAL", Colors.red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogHeader() => const Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Expanded(flex: 2, child: Text("Timestamp", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        Expanded(flex: 2, child: Text("Actor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        Expanded(flex: 4, child: Text("Action Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        Expanded(flex: 2, child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
      ],
    ),
  );

  Widget _logItem(String time, String actor, String action, String status, Color col) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black12))),
    child: Row(
      children: [
        Expanded(flex: 2, child: Text(time, style: const TextStyle(fontSize: 13))),
        Expanded(flex: 2, child: Text(actor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        Expanded(flex: 4, child: Text(action, style: const TextStyle(fontSize: 13))),
        Expanded(flex: 2, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(status, style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center),
        )),
      ],
    ),
  );
}