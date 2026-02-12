import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditMeetingScreen extends StatefulWidget {
  final Map<String, dynamic> meetingData;
  const EditMeetingScreen({super.key, required this.meetingData});

  @override
  State<EditMeetingScreen> createState() => _EditMeetingScreenState();
}

class _EditMeetingScreenState extends State<EditMeetingScreen> {
  final _supabase = Supabase.instance.client;
  late TextEditingController _titleController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _locationController;
  late TextEditingController _maxAttendeesController;
  late TextEditingController _agendaController;
  
  List<String> _selectedRoles = [];
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing database data
    _titleController = TextEditingController(text: widget.meetingData['title']);
    _dateController = TextEditingController(text: widget.meetingData['meeting_date']);
    _timeController = TextEditingController(text: widget.meetingData['meeting_time']);
    _locationController = TextEditingController(text: widget.meetingData['location']);
    _maxAttendeesController = TextEditingController(text: widget.meetingData['max_attendees'].toString());
    _agendaController = TextEditingController(text: widget.meetingData['agenda']);
    _selectedRoles = List<String>.from(widget.meetingData['target_roles'] ?? []);
  }

  Future<void> _updateMeeting() async {
    setState(() => _isUpdating = true);
    try {
      await _supabase.from('meetings').update({
        'title': _titleController.text,
        'meeting_date': _dateController.text,
        'meeting_time': _timeController.text,
        'location': _locationController.text,
        'max_attendees': int.tryParse(_maxAttendeesController.text) ?? 25,
        'agenda': _agendaController.text,
        'target_roles': _selectedRoles,
      }).eq('id', widget.meetingData['meeting_id']); // Unique ID from summary view
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Update failed: $e");
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("EDIT MEETING", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 18)),
            ],
          ),
          const Text("Update meeting details and notify attendees", style: TextStyle(fontSize: 12, color: Colors.black45)),
          const SizedBox(height: 24),
          _field("MEETING TITLE *", _titleController, "e.g., Monthly Conservation Review"),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _field("DATE *", _dateController, "")),
              const SizedBox(width: 16),
              Expanded(child: _field("TIME *", _timeController, "")),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _field("LOCATION *", _locationController, "")),
              const SizedBox(width: 16),
              Expanded(child: _field("MAX ATTENDEES *", _maxAttendeesController, "")),
            ],
          ),
          const SizedBox(height: 16),
          _field("MEETING AGENDA *", _agendaController, "", maxLines: 3),
          const SizedBox(height: 24),
          const Text("TARGET ROLES *", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          _buildRoleCheckboxes(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUpdating ? null : _updateMeeting,
              icon: const Icon(Icons.send_outlined, size: 18),
              label: Text(_isUpdating ? "SAVING..." : "UPDATE MEETING"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF517156),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: const OutlineInputBorder(borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCheckboxes() {
    return Row(
      children: ["Field Officer", "Admin", "System Admin"].map((role) {
        return Row(
          children: [
            Checkbox(
              value: _selectedRoles.contains(role),
              activeColor: const Color(0xFF517156),
              onChanged: (val) {
                setState(() => val! ? _selectedRoles.add(role) : _selectedRoles.remove(role));
              },
            ),
            Text(role, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
          ],
        );
      }).toList(),
    );
  }
}