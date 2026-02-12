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
      // Listen to your Summary View for real-time RSVP counts
      stream: _supabase.from('meeting_summary').stream(primaryKey: ['meeting_id']).order('meeting_date'),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Sync Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF517156)));
        
        final meetings = snapshot.data!;
        
        if (meetings.isEmpty) {
          return Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 100),
              const Center(child: Text("No scheduled meetings found.", style: TextStyle(color: Colors.black26))),
            ],
          );
        }

        // Prevent index errors if list size changes
        if (_selectedMeetingIndex >= meetings.length) {
          _selectedMeetingIndex = 0;
        }
        
        final selectedM = meetings[_selectedMeetingIndex];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildDynamicMetricRow(meetings), // Dynamic KPI totals
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

  // --- UI COMPONENTS ---

  Widget _buildHeader(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
    children: [
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("MEETING COORDINATION & MANAGEMENT", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text("Schedule meetings • Track RSVP responses • Manage attendance", style: TextStyle(fontSize: 13, color: Colors.black38)),
      ]),
      ElevatedButton.icon(
        onPressed: () => showDialog(context: context, builder: (_) => const Dialog(child: CreateMeetingScreen())), 
        icon: const Icon(Icons.add, size: 18), 
        label: const Text("CREATE MEETING"), 
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF517156), 
          foregroundColor: Colors.white, 
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        )
      )
    ]
  );

  Widget _buildDynamicMetricRow(List<Map<String, dynamic>> meetings) {
    int totalAccepted = meetings.fold(0, (sum, m) => sum + ((m['accepted_count'] ?? 0) as int));
    int totalPending = meetings.fold(0, (sum, m) => sum + ((m['pending_count'] ?? 0) as int));
    int totalDeclined = meetings.fold(0, (sum, m) => sum + ((m['declined_count'] ?? 0) as int));
    int completed = meetings.where((m) => m['status'] == 'Completed').length;

    return Row(
      children: [
        _statCard(meetings.length.toString(), "Scheduled", "Upcoming", Colors.blue),
        _statCard(totalAccepted.toString(), "Accepted", "Confirmations", Colors.green),
        _statCard(totalPending.toString(), "Pending", "Awaiting", Colors.orange),
        _statCard(totalDeclined.toString(), "Declined", "Cannot attend", Colors.red),
        _statCard(completed.toString(), "Completed", "Past", Colors.black54),
      ],
    );
  }

  Widget _buildMeetingList(List<Map<String, dynamic>> meetings) => Container(
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(4)),
    child: Column(children: [
      _panelHeader("Upcoming Meetings", "${meetings.length} scheduled"),
      ...meetings.asMap().entries.map((entry) {
        final m = entry.value;
        bool isSel = _selectedMeetingIndex == entry.key;
        return InkWell(
          onTap: () => setState(() => _selectedMeetingIndex = entry.key),
          // FIXED: Renamed to match your helper method
          child: _buildMeetingTile(m, isSel), 
        );
      }),
    ]),
  );

  // FIXED: Method name unified with call in list
  Widget _buildMeetingTile(Map<String, dynamic> m, bool sel) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: sel ? const Color(0xFFF8FAF8) : Colors.transparent,
      border: Border(
        bottom: const BorderSide(color: Colors.black12), 
        left: BorderSide(color: const Color(0xFF517156), width: sel ? 4 : 0)
      )
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(m['title'] ?? "Meeting", style: const TextStyle(fontWeight: FontWeight.bold)),
        Text("${m['meeting_date'] ?? ''} • ${m['location'] ?? ''}", style: const TextStyle(fontSize: 12, color: Colors.black45)),
      ])),
      Text("${m['accepted_count'] ?? 0} / ${m['max_attendees'] ?? 0}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _buildMeetingDetailPanel(Map<String, dynamic> m) => Container(
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(4)),
    padding: const EdgeInsets.all(24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(m['title'] ?? "Untitled", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        IconButton(onPressed: () => _showEditDialog(m), icon: const Icon(Icons.edit_outlined, size: 20))
      ]),
      const Text("MTG-COORD • Active", style: TextStyle(fontSize: 11, color: Colors.blue)),
      const SizedBox(height: 24),
      _rsvpStatsRow(m),
      const SizedBox(height: 24),
      _buildAttendanceCapacity(m['accepted_count'] ?? 0, m['max_attendees'] ?? 1),
      const Divider(height: 40),
      _infoRow(Icons.calendar_today, "Date", m['meeting_date'] ?? "TBD"),
      _infoRow(Icons.location_on_outlined, "Location", m['location'] ?? "Unknown"),
      const SizedBox(height: 20),
      const Text("Agenda", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
      const SizedBox(height: 8),
      Text(m['agenda'] ?? "No agenda provided.", style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5)),
    ]),
  );

  // --- SHARED UI HELPERS ---

  Widget _statCard(String v, String t, String sub, Color c) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(4)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text(v, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: c)), const SizedBox(width: 8), Text(t, style: const TextStyle(fontWeight: FontWeight.w600))]),
        Text(sub, style: TextStyle(fontSize: 10, color: c.withOpacity(0.5), fontWeight: FontWeight.bold)),
      ]),
    ),
  );

  Widget _rsvpStatsRow(Map<String, dynamic> m) => Row(children: [
    _rsvpItem((m['accepted_count'] ?? 0).toString(), "Accepted", Colors.green),
    _rsvpItem((m['pending_count'] ?? 0).toString(), "Pending", Colors.orange),
    _rsvpItem((m['declined_count'] ?? 0).toString(), "Declined", Colors.red),
  ]);

  Widget _rsvpItem(String v, String l, Color c) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
    child: Column(children: [Text(v, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c)), Text(l, style: const TextStyle(fontSize: 10))]),
  ));

  Widget _buildAttendanceCapacity(int cur, int max) {
    double percent = (cur / (max > 0 ? max : 1)).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Attendance Capacity", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45)),
        Text("${(percent * 100).toInt()}% filled", style: const TextStyle(fontSize: 11, color: Colors.black38)),
      ]),
      const SizedBox(height: 8),
      LinearProgressIndicator(value: percent, color: const Color(0xFF517156), backgroundColor: Colors.black12, minHeight: 8)
    ]);
  }

  Widget _infoRow(IconData i, String l, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [Icon(i, size: 16, color: Colors.black38), const SizedBox(width: 12), Text("$l: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Text(v, style: const TextStyle(fontSize: 12))]),
  );

  Widget _panelHeader(String t, String s) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16), 
    decoration: const BoxDecoration(color: Color(0xFFF9FAFB), border: Border(bottom: BorderSide(color: Colors.black12))), 
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text(s, style: const TextStyle(color: Colors.black38, fontSize: 11))])
  );

  void _showEditDialog(Map<String, dynamic> data) {
    showDialog(context: context, builder: (_) => Dialog(child: EditMeetingScreen(meetingData: data)));
  }
}