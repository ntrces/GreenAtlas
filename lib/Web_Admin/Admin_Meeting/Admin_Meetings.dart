import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Create_Meeting.dart';
import 'Edit_Meeting.dart';

class MeetingCoordinationView extends StatefulWidget {
  const MeetingCoordinationView({super.key});
  @override
  State<MeetingCoordinationView> createState() => _MeetingCoordinationViewState();
}

class _MeetingCoordinationViewState extends State<MeetingCoordinationView> {
  final _supabase = Supabase.instance.client;
  int _selectedMeetingIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('meeting_summary').stream(primaryKey: ['meeting_id']).order('meeting_date'),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Sync Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF517156)));
        
        final meetings = snapshot.data!;
        if (meetings.isEmpty) return _buildEmptyState(context);

        if (_selectedMeetingIndex >= meetings.length) _selectedMeetingIndex = 0;
        final selectedM = meetings[_selectedMeetingIndex];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildDynamicMetricRow(meetings),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: _buildMeetingList(meetings)),
                const SizedBox(width: 32),
                Expanded(flex: 4, child: _buildMeetingDetailPanel(selectedM)),
              ],
            ),
          ],
        );
      },
    );
  }

  // --- KPI & HEADER UI ---
  Widget _buildHeader(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
    children: [
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("MEETING COORDINATION & MANAGEMENT", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text("Track attendance • View detailed RSVP status by name", style: TextStyle(fontSize: 13, color: Colors.black38)),
      ]),
      ElevatedButton.icon(
        onPressed: () => showDialog(context: context, builder: (_) => const Dialog(child: CreateMeetingScreen())), 
        icon: const Icon(Icons.add, size: 18), 
        label: const Text("CREATE MEETING"), 
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF517156), foregroundColor: Colors.white)
      )
    ]
  );

  Widget _buildDynamicMetricRow(List<Map<String, dynamic>> meetings) {
    int totalAccepted = meetings.fold(0, (sum, m) => sum + (m['accepted_count'] as int));
    int totalDeclined = meetings.fold(0, (sum, m) => sum + (m['declined_count'] as int));
    return Row(
      children: [
        _statCard(meetings.length.toString(), "Scheduled", "Upcoming", Colors.blue),
        _statCard(totalAccepted.toString(), "Accepted", "Confirmations", Colors.green),
        _statCard(totalDeclined.toString(), "Declined", "Cancellations", Colors.red),
      ],
    );
  }

  Widget _buildMeetingDetailPanel(Map<String, dynamic> m) => Container(
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(4)),
    padding: const EdgeInsets.all(24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(m['title'] ?? "Untitled", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const Divider(height: 32),
      
      // REAL-TIME LIST SECTION
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('meeting_user_details')
            .stream(primaryKey: ['meeting_id', 'user_id'])
            .eq('meeting_id', m['meeting_id']), 
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text("Error loading attendee details.");
          
          final allResponses = snapshot.data ?? [];
          final accepted = allResponses.where((u) => u['user_status'] == 'Accepted').toList();
          final declined = allResponses.where((u) => u['user_status'] == 'Declined').toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ATTENDING LIST
              _sectionLabel("ATTENDING", Colors.green, accepted.length),
              if (accepted.isEmpty) _emptyNote("No confirmations yet.")
              else ...accepted.map((u) => _attendeeTile(u, Icons.check_circle, Colors.green)),

              const SizedBox(height: 24),

              // 2. DECLINED LIST
              _sectionLabel("NOT ATTENDING", Colors.red, declined.length),
              if (declined.isEmpty) _emptyNote("No declinations yet.")
              else ...declined.map((u) => _attendeeTile(u, Icons.cancel, Colors.red)),
            ],
          );
        },
      ),
    ]),
  );

  // --- SUB-COMPONENTS ---
  Widget _sectionLabel(String label, Color color, int count) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text("$label ($count)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color)),
  );

  Widget _emptyNote(String text) => Text(text, style: const TextStyle(fontSize: 12, color: Colors.black26));

  Widget _attendeeTile(Map<String, dynamic> u, IconData icon, Color color) => ListTile(
    contentPadding: EdgeInsets.zero,
    visualDensity: VisualDensity.compact,
    leading: const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 14)),
    title: Text(u['attendee_name'] ?? "Anonymous", style: const TextStyle(fontSize: 13)),
    trailing: Icon(icon, color: color, size: 16),
  );

  Widget _buildMeetingList(List<Map<String, dynamic>> meetings) => Container(
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12)),
    child: Column(children: meetings.asMap().entries.map((e) => InkWell(
      onTap: () => setState(() => _selectedMeetingIndex = e.key),
      child: _buildMeetingTile(e.value, _selectedMeetingIndex == e.key),
    )).toList()),
  );

  Widget _buildMeetingTile(Map<String, dynamic> m, bool sel) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: sel ? const Color(0xFFF8FAF8) : Colors.transparent, border: Border(bottom: const BorderSide(color: Colors.black12), left: BorderSide(color: const Color(0xFF517156), width: sel ? 4 : 0))),
    child: Row(children: [
      Expanded(child: Text(m['title'] ?? "Meeting", style: const TextStyle(fontWeight: FontWeight.bold))),
      Text("${m['accepted_count']} / ${m['max_attendees']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
    ]),
  );

  Widget _statCard(String v, String t, String sub, Color c) => Expanded(child: Container(margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(4)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: c)), Text(t, style: const TextStyle(fontWeight: FontWeight.w600)), Text(sub, style: TextStyle(fontSize: 10, color: c.withOpacity(0.5)))])));
  Widget _panelHeader(String t, String s) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Color(0xFFF9FAFB), border: Border(bottom: BorderSide(color: Colors.black12))), child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)));
  Widget _buildEmptyState(BuildContext context) => Column(children: [_buildHeader(context), const SizedBox(height: 100), const Center(child: Text("No meetings found."))]);
}