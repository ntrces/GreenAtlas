import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // REQUIRED: run 'flutter pub add intl'

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
  final _locationController = TextEditingController();
  final _maxAttendeesController = TextEditingController(text: "25");
  final _agendaController = TextEditingController();
  
  List<String> _selectedRoles = [];
  bool _isPublishing = false;

  // --- FIXED DATE PICKER LOGIC ---
  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Prevents scheduling in the past
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF517156)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // FIXED: Formats specifically for Supabase DATE type (YYYY-MM-DD)
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // --- FIXED TIME PICKER LOGIC ---
  Future<void> _selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        // Formats to human-readable string for the TEXT column in database
        _timeController.text = picked.format(context); 
      });
    }
  }

  Future<void> _publishMeeting() async {
    // Validation: Title and Date are mandatory
    if (_titleController.text.isEmpty || _dateController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Please fill in the title and date"), backgroundColor: Colors.redAccent)
       );
       return;
    }

    setState(() => _isPublishing = true);
    try {
      await _supabase.from('meetings').insert({
        'title': _titleController.text,
        'meeting_date': _dateController.text, // Sending the formatted YYYY-MM-DD string
        'meeting_time': _timeController.text,
        'location': _locationController.text,
        'max_attendees': int.tryParse(_maxAttendeesController.text) ?? 25,
        'agenda': _agendaController.text,
        'target_roles': _selectedRoles,
        'status': 'Scheduled',
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Meeting scheduled successfully!"), backgroundColor: Color(0xFF517156))
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Database insert failed: $e"); // Helpful for debugging schema mismatches
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EA), // Design Background
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("CREATE NEW MEETING", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 18)),
            ],
          ),
          const Text("Schedule a new meeting and send invitations to field staff", style: TextStyle(fontSize: 12, color: Colors.black45)),
          const SizedBox(height: 24),
          _buildField("MEETING TITLE *", _titleController, "e.g., Monthly Conservation Review"),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPickerField(
                  "DATE *", 
                  _dateController, 
                  Icons.calendar_today, 
                  _selectDate
                )
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPickerField(
                  "TIME *", 
                  _timeController, 
                  Icons.access_time, 
                  _selectTime
                )
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildField("LOCATION *", _locationController, "e.g., DENR Cavite Office")),
              const SizedBox(width: 16),
              Expanded(child: _buildField("MAX ATTENDEES *", _maxAttendeesController, "25")),
            ],
          ),
          const SizedBox(height: 16),
          _buildField("MEETING AGENDA *", _agendaController, "Describe the purpose...", maxLines: 3),
          const SizedBox(height: 24),
          const Text("TARGET ROLES *", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildRoleCheckboxes(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPublishing ? null : _publishMeeting,
              icon: const Icon(Icons.send_outlined, size: 18),
              label: Text(_isPublishing ? "PUBLISHING..." : "CREATE & ANNOUNCE MEETING"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF517156), // Design Button Color
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

  // Text field helper
  Widget _buildField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
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

  // Date/Time picker helper
  Widget _buildPickerField(String label, TextEditingController controller, IconData icon, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: true, // Forces user to use the UI picker
          onTap: onTap,
          decoration: InputDecoration(
            suffixIcon: Icon(icon, size: 18, color: Colors.black38),
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