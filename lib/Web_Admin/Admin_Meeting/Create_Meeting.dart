import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _supabase = Supabase.instance.client;
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _locationController = TextEditingController(); // Now connected to UI
  final _maxAttendeesController = TextEditingController(text: "25");
  final _agendaController = TextEditingController();
  
  List<String> _selectedRoles = ["Field Officer"]; 
  bool _isPublishing = false;
  PlatformFile? _selectedFile;

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF517156))),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateController.text = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _selectTime() async {
    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _timeController.text = picked.format(context));
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
    if (result != null) setState(() => _selectedFile = result.files.first);
  }

  Future<void> _publishMeeting() async {
    if (_titleController.text.isEmpty || _dateController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title, Date, and Location are required"), backgroundColor: Colors.orange)
      );
      return;
    }
    
    setState(() => _isPublishing = true);
    try {
      String? fileUrl;
      // 1. Upload Attachment if exists
      if (_selectedFile != null && _selectedFile!.bytes != null) {
        final fileName = 'mtg_${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.name}';
        await _supabase.storage.from('meeting-attachments').uploadBinary(
          fileName, 
          _selectedFile!.bytes!,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
        fileUrl = _supabase.storage.from('meeting-attachments').getPublicUrl(fileName);
      }

      // 2. Insert into Database
      await _supabase.from('meetings').insert({
        'title': _titleController.text.trim(),
        'meeting_date': _dateController.text,
        'meeting_time': _timeController.text,
        'location': _locationController.text.trim(),
        'max_attendees': int.tryParse(_maxAttendeesController.text) ?? 25,
        'agenda': _agendaController.text.trim(),
        'attachment_url': fileUrl,
        'target_roles': _selectedRoles,
        'status': 'Scheduled',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Meeting Created Successfully"), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Database Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView( // Added scroll for small screens
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("CREATE NEW MEETING", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3E2D))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 20))
            ]),
            const SizedBox(height: 24),
            _label("MEETING TITLE *"),
            _field(_titleController, "e.g., Monthly Review"),
            const SizedBox(height: 16),
            
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("DATE *"), _picker(_dateController, Icons.calendar_today, _selectDate)])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("TIME *"), _picker(_timeController, Icons.access_time, _selectTime)])),
            ]),
            
            const SizedBox(height: 16),
            _label("LOCATION *"), // Added missing location field
            _field(_locationController, "e.g., Conference Room B or Zoom Link"),
            const SizedBox(height: 16),
            
            _label("AGENDA & ATTACHMENT"),
            _agendaBox(),
            const SizedBox(height: 16),
            _label("TARGET ROLES"),
            _roles(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, 
              height: 50, 
              child: ElevatedButton(
                onPressed: _isPublishing ? null : _publishMeeting, 
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF517156)), 
                child: Text(_isPublishing ? "PUBLISHING..." : "CREATE & ANNOUNCE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
              )
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)));
  
  Widget _field(TextEditingController c, String h) => TextField(controller: c, decoration: InputDecoration(hintText: h, filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.black12))));
  
  Widget _picker(TextEditingController c, IconData i, VoidCallback t) => TextField(controller: c, readOnly: true, onTap: t, decoration: InputDecoration(suffixIcon: Icon(i, size: 18), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.black12))));
  
  Widget _agendaBox() => Container(
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(4)), 
    child: Column(children: [
      TextField(controller: _agendaController, maxLines: 2, decoration: const InputDecoration(contentPadding: EdgeInsets.all(12), border: InputBorder.none, hintText: "Enter agenda details...")), 
      const Divider(height: 1), 
      Row(children: [
        TextButton.icon(
          onPressed: _pickFile, 
          icon: const Icon(Icons.attach_file, size: 16, color: Color(0xFF517156)), 
          label: Expanded(child: Text(_selectedFile?.name ?? "Attach Briefing File", style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))
        )
      ])
    ])
  );

  Widget _roles() => Wrap(
    spacing: 8, 
    children: ["Field Officer", "Admin"].map((r) => Row(
      mainAxisSize: MainAxisSize.min, 
      children: [
        Checkbox(
          value: _selectedRoles.contains(r), 
          activeColor: const Color(0xFF517156), 
          onChanged: (v) => setState(() => v! ? _selectedRoles.add(r) : _selectedRoles.remove(r))
        ), 
        Text(r, style: const TextStyle(fontSize: 12))
      ]
    )).toList()
  );
}