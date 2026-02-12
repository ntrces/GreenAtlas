import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class EditMeetingScreen extends StatefulWidget {
  final Map<String, dynamic> meetingData;
  const EditMeetingScreen({super.key, required this.meetingData});

  @override
  State<EditMeetingScreen> createState() => _EditMeetingScreenState();
}

class _EditMeetingScreenState extends State<EditMeetingScreen> {
  final _supabase = Supabase.instance.client;
  
  late TextEditingController _title, _date, _time, _loc, _max, _agenda;
  List<String> _selectedRoles = [];
  bool _isUpdating = false;
  PlatformFile? _newFile;
  String? _currentFileUrl;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing data
    _title = TextEditingController(text: widget.meetingData['title']);
    _date = TextEditingController(text: widget.meetingData['meeting_date']);
    _time = TextEditingController(text: widget.meetingData['meeting_time']);
    _loc = TextEditingController(text: widget.meetingData['location']);
    _max = TextEditingController(text: widget.meetingData['max_attendees'].toString());
    _agenda = TextEditingController(text: widget.meetingData['agenda']);
    _selectedRoles = List<String>.from(widget.meetingData['target_roles'] ?? []);
    _currentFileUrl = widget.meetingData['attachment_url'];
  }

  Future<void> _pickNewFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );
    if (result != null) setState(() => _newFile = result.files.first);
  }

  Future<void> _updateMeeting() async {
    setState(() => _isUpdating = true);
    try {
      String? finalFileUrl = _currentFileUrl;

      // Logic to handle file replacement
      if (_newFile != null) {
        final fileName = 'mtg_${DateTime.now().millisecondsSinceEpoch}_${_newFile!.name}';
        await _supabase.storage.from('meeting-attachments').uploadBinary(fileName, _newFile!.bytes!);
        finalFileUrl = _supabase.storage.from('meeting-attachments').getPublicUrl(fileName);
      }

      await _supabase.from('meetings').update({
        'title': _title.text,
        'meeting_date': _date.text,
        'meeting_time': _time.text,
        'location': _loc.text,
        'max_attendees': int.tryParse(_max.text) ?? 25,
        'agenda': _agenda.text,
        'attachment_url': finalFileUrl,
        'target_roles': _selectedRoles,
      }).eq('id', widget.meetingData['meeting_id']); // Unique ID from summary view

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Update Error: $e");
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFFEAF4EA), borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildLabel("MEETING TITLE *"),
            _buildTextField(_title, "Title"),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("DATE *"), _buildPickerField(_date, Icons.calendar_today, () {})])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("TIME *"), _buildPickerField(_time, Icons.access_time, () {})])),
            ]),
            const SizedBox(height: 12),
            _buildLabel("AGENDA & ATTACHMENT"),
            _buildEditAgendaBox(),
            const SizedBox(height: 12),
            _buildLabel("TARGET ROLES"),
            _buildRoleCheckboxes(),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditAgendaBox() => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
    child: Column(
      children: [
        TextField(
          controller: _agenda,
          maxLines: 2,
          decoration: const InputDecoration(contentPadding: EdgeInsets.all(12), border: InputBorder.none),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: _pickNewFile,
                icon: const Icon(Icons.attach_file, size: 16, color: Color(0xFF517156)),
                label: Text(
                  _newFile != null ? _newFile!.name : (_currentFileUrl != null ? "Change Attachment" : "Attach File"), 
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              if (_currentFileUrl != null || _newFile != null) 
                IconButton(
                  onPressed: () => setState(() { _newFile = null; _currentFileUrl = null; }), 
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent)
                )
            ],
          ),
        )
      ],
    ),
  );

  // (Helper methods _buildHeader, _buildLabel, etc. remain the same as CreateMeetingScreen)
  Widget _buildHeader() => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    const Text("EDIT MEETING", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3E2D))),
    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 18))
  ]);

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 6.0), child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)));

  Widget _buildTextField(TextEditingController ctrl, String hint) => TextField(controller: ctrl, decoration: InputDecoration(filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none)));

  Widget _buildPickerField(TextEditingController ctrl, IconData icon, VoidCallback tap) => TextField(controller: ctrl, readOnly: true, decoration: InputDecoration(suffixIcon: Icon(icon, size: 16), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none)));

  Widget _buildRoleCheckboxes() => Wrap(spacing: 8, children: ["Field Officer", "Admin"].map((r) => Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: _selectedRoles.contains(r), onChanged: (v) => setState(() => v! ? _selectedRoles.add(r) : _selectedRoles.remove(r))), Text(r, style: const TextStyle(fontSize: 11))])).toList());

  Widget _buildSaveButton() => SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: _isUpdating ? null : _updateMeeting, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF517156)), child: Text(_isUpdating ? "SAVING..." : "SAVE CHANGES", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));
}