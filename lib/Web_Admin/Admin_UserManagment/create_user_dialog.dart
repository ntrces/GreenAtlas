import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({super.key});
  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _supabase = Supabase.instance.client;
  
  // Controllers
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  
  String? _selectedRole;
  bool _isSaving = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstCtrl.dispose(); _lastCtrl.dispose();
    _emailCtrl.dispose(); _phoneCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  // Password Validation Logic
  bool _isPasswordValid(String p) => 
      RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$&*~]).{6,}$').hasMatch(p);

  Future<void> _createUser() async {
    // 1. Validation base on required database fields
    if (_emailCtrl.text.isEmpty || _selectedRole == null) {
      _showFeedback("Email and Role are required.", Colors.orange);
      return;
    }
    
    if (!_isPasswordValid(_passCtrl.text)) {
      _showFeedback("Password requires: 1 Capital, 1 Number, & 1 Special Char", Colors.redAccent);
      return;
    }

    setState(() => _isSaving = true);
    try {
      // 2. Register via Supabase Auth
      // Metadata keys match the NEW.raw_user_meta_data in your SQL
      final AuthResponse res = await _supabase.auth.signUp(
        email: _emailCtrl.text.trim(), 
        password: _passCtrl.text.trim(),
        data: {
          'first_name': _firstCtrl.text.trim(),
          'last_name': _lastCtrl.text.trim(),
          'full_name': '${_firstCtrl.text.trim()} ${_lastCtrl.text.trim()}',
          'role': _selectedRole!.toLowerCase(), // Saved base on DB Enum case
          'phone': _phoneCtrl.text.trim(),
        },
      );

      if (res.user != null && mounted) {
        Navigator.pop(context);
        _showFeedback("Success! ${_selectedRole} account created effectively.", Colors.green);
      }
    } on AuthException catch (e) {
      _showFeedback(e.message, Colors.redAccent);
    } catch (e) {
      if (mounted) {
        _showFeedback("Database Sync Error: Ensure Step 1 SQL is applied.", Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showFeedback(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFEAF2EA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 650, 
        padding: const EdgeInsets.all(32), 
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("CREATE NEW USER ACCOUNT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
              ]),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: _field("FIRST NAME", _firstCtrl)), 
                const SizedBox(width: 12), 
                Expanded(child: _field("LAST NAME", _lastCtrl))
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field("EMAIL *", _emailCtrl)), 
                const SizedBox(width: 12), 
                Expanded(child: _dropdown())
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field("PHONE", _phoneCtrl)), 
                const SizedBox(width: 12), 
                Expanded(child: _field("PASSWORD *", _passCtrl, obscure: _obscurePassword, isPass: true))
              ]),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, 
                height: 50, 
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _createUser, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF536D53), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ), 
                  child: _isSaving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text("CREATE ACCOUNT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                )
              ),
            ]
          )
        )
      ),
    );
  }

  Widget _field(String l, TextEditingController c, {bool obscure = false, bool isPass = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, 
    children: [
      Text(l, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)), 
      const SizedBox(height: 6), 
      TextField(
        controller: c, 
        obscureText: obscure, 
        decoration: InputDecoration(
          filled: true, 
          fillColor: Colors.white, 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: isPass ? IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ) : null,
        )
      )
    ]
  );

  Widget _dropdown() => Column(
    crossAxisAlignment: CrossAxisAlignment.start, 
    children: [
      const Text("ROLE *", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)), 
      const SizedBox(height: 6), 
      DropdownButtonFormField<String>(
        items: ["Admin", "Employee", "User"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), 
        onChanged: (v) => setState(() => _selectedRole = v), 
        decoration: InputDecoration(
          filled: true, 
          fillColor: Colors.white, 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        )
      )
    ]
  );
}