import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditUserDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  const EditUserDialog({super.key, required this.user});
  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _supabase = Supabase.instance.client;
  late TextEditingController _nameCtrl, _phoneCtrl;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user['full_name'] ?? "");
    _phoneCtrl = TextEditingController(text: widget.user['phone'] ?? "");

    // Normalization logic: maps lowercase DB value to Title Case UI
    String raw = (widget.user['role'] ?? "user").toString().toLowerCase();
    if (raw == 'admin') _selectedRole = "Admin";
    else if (raw == 'employee') _selectedRole = "Employee";
    else _selectedRole = "User";
  }

  Future<void> _update() async {
    await _supabase.from('profiles').update({
      'full_name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'role': _selectedRole!.toLowerCase(), 
    }).eq('id', widget.user['id']);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFEAF2EA),
      child: Container(width: 500, padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("EDIT ACCOUNT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _field("FULL NAME", _nameCtrl),
        const SizedBox(height: 12),
        _dropdown(),
        const SizedBox(height: 12),
        _field("PHONE NUMBER", _phoneCtrl),
        const SizedBox(height: 32),
        ElevatedButton(onPressed: _update, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF536D53), minimumSize: const Size(double.infinity, 50)), child: const Text("UPDATE", style: TextStyle(color: Colors.white))),
      ])),
    );
  }

  Widget _field(String l, TextEditingController c) => TextField(controller: c, decoration: InputDecoration(labelText: l, filled: true, fillColor: Colors.white, border: const OutlineInputBorder()));
  Widget _dropdown() => DropdownButtonFormField<String>(value: _selectedRole, items: ["Admin", "Employee", "User"].map((e)=>DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v)=>setState(()=>_selectedRole=v), decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: const OutlineInputBorder()));
}