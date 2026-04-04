import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme_constants.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // * Manual state for Caps Lock
  bool _isCapsLockOn = false; 

  final Color darkGreen = const Color(0xFF303D32);
  final Color sageGreen = const Color(0xFF517156);
  final Color lightBgGreen = const Color(0xFFE5F5E8);

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // * Removed _updateUI that used lockModes to avoid the error.

  Future<void> _handleSignUp() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }
    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': "$firstName $lastName"},
      );
      if (res.user != null) {
        await supabase.from('profiles').upsert({'id': res.user!.id, 'email': email, 'role': 'user'});
        await supabase.auth.signOut();
        if (mounted) _showVerificationPopup(email);
      }
    } catch (e) {
      _showError("Sign up failed");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  void _showVerificationPopup(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Check Email", style: TextStyle(fontFamily: 'Poppins-Bold')),
        content: Text("Link sent to $email"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // * Wrap the entire Scaffold in a KeyboardListener
    return KeyboardListener(
      focusNode: FocusNode(), // * Needs a focus node to capture keys
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        // * Manually toggle state when the Caps Lock key is pressed
        if (event.logicalKey == LogicalKeyboardKey.capsLock && event is KeyDownEvent) {
          setState(() {
            _isCapsLockOn = !_isCapsLockOn;
          });
        }
      },
      child: Scaffold(
        backgroundColor: softGreen,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 76, height: 76,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Center(child: Image.asset('assets/logo2.png', width: 57)),
                ),
                const SizedBox(height: 11),
                Text(
                  "Create Account", 
                  style: TextStyle(fontFamily: 'Poppins-Bold', fontSize: 28, color: darkGreen),
                ),
                Text(
                  "Join GreenAtlas to explore and protect our ecosystem", 
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13.5, color: sageGreen),
                ),
                const SizedBox(height: 25),

                Container(
                  width: 364,
                  padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 23),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11.4),
                    border: Border.all(color: const Color(0x26303D32), width: 1.32),
                    boxShadow: const [BoxShadow(color: Color(0x40000000), offset: Offset(4, 4), blurRadius: 4)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text("Sign Up", style: TextStyle(fontFamily: 'Poppins-Bold', fontSize: 15.2, color: darkGreen)),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text("Fill in your details to get started", style: TextStyle(fontFamily: 'Inter', fontSize: 15.2, color: sageGreen)),
                      ),
                      const SizedBox(height: 23),

                      Row(
                        children: [
                          Expanded(child: _buildFieldColumn("First Name", _firstNameController, "First")),
                          const SizedBox(width: 11.4),
                          Expanded(child: _buildFieldColumn("Last Name", _lastNameController, "Last")),
                        ],
                      ),
                      const SizedBox(height: 15.2),
                      _buildFieldColumn("Email Address", _emailController, "your.email@example.com", icon: Icons.email_outlined),
                      const SizedBox(height: 15.2),
                      
                      _buildFieldColumn("Password", _passwordController, "••••••••", isPassword: true, obscure: _obscurePassword, toggle: () => setState(() => _obscurePassword = !_obscurePassword)),
                      
                      // * --- CAPS LOCK NOTIFICATION ---
                      if (_isCapsLockOn)
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 14),
                              SizedBox(width: 4),
                              Text(
                                "Caps Lock is ON",
                                style: TextStyle(color: Colors.orange, fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 4),
                      Text(
                        "Must be 8+ characters with uppercase, lowercase, numbers, and special characters.",
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, height: 16 / 12, color: Colors.grey[600]),
                      ),

                      const SizedBox(height: 15.2),
                      _buildFieldColumn("Confirm Password", _confirmPasswordController, "••••••••", isPassword: true, obscure: _obscureConfirmPassword, toggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
                      
                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity, height: 47.5,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignUp,
                          style: ElevatedButton.styleFrom(backgroundColor: sageGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7.6))),
                          child: _isLoading 
                            ? const SizedBox(height: 19, width: 19, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Create Account", style: TextStyle(fontFamily: 'Poppins-Bold', color: Colors.white, fontSize: 15.2)),
                        ),
                      ),

                      const SizedBox(height: 23),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.black12)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 9.5),
                            child: Text("ALREADY HAVE AN ACCOUNT?", style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, color: sageGreen)),
                          ),
                          const Expanded(child: Divider(color: Colors.black12)),
                        ],
                      ),
                      const SizedBox(height: 23),
                      Center(
                        child: SizedBox(
                          width: 317, height: 38,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: lightBgGreen,
                              elevation: 0,
                              side: const BorderSide(color: Color(0x26303D32)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.7)),
                            ),
                            child: Text("Sign In", style: TextStyle(fontFamily: 'Inter-SemiBold', fontSize: 13.3, color: darkGreen)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, TextEditingController controller) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text, 
          style: TextStyle(fontFamily: 'Poppins-Bold', fontSize: 13.3, color: darkGreen),
        ),
        // * Replaced the dynamic logic with a simple check to keep it light
        if (controller.text.isEmpty)
          const Text(
            " *",
            style: TextStyle(color: Colors.red, fontSize: 13.3),
          ),
      ],
    );
  }

  Widget _buildFieldColumn(String label, TextEditingController controller, String hint, {bool isPassword = false, bool? obscure, VoidCallback? toggle, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, controller),
        const SizedBox(height: 4),
        SizedBox(
          height: 45.6,
          child: TextField(
            controller: controller,
            obscureText: obscure ?? false,
            // * Trigger setState on change to keep the red * updated
            onChanged: (val) => setState(() {}), 
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13.3, color: Colors.black26),
              prefixIcon: icon != null ? Icon(icon, size: 17.1, color: sageGreen) : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 11.4),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7.6), borderSide: const BorderSide(color: Colors.black12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7.6), borderSide: BorderSide(color: sageGreen)),
              suffixIcon: isPassword ? IconButton(icon: Icon(obscure! ? Icons.visibility_off : Icons.visibility, size: 17.1, color: sageGreen), onPressed: toggle) : null,
            ),
          ),
        ),
      ],
    );
  }
}