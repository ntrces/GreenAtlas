import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme_constants.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Only First and Last Name controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleSignUp() async {
    // Basic validation
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final supabase = Supabase.instance.client;
      
      // 1. Perform Auth Sign Up
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (res.user != null) {
        final String fullName = "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";

        // 2. Insert profile data
        await supabase.from('profiles').insert({
          'id': res.user!.id,
          'full_name': fullName,
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'user', 
        });

        // 3. FORCE SIGN OUT - This prevents the auto-login redirect
        await supabase.auth.signOut();

        if (mounted) {
          _showSuccessPopup();
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Database Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          backgroundColor: Colors.white,
          title: const Column(
            children: [
              Icon(Icons.check_circle_rounded, color: primaryForest, size: 60),
              SizedBox(height: 12),
              Text("Account Created!", style: TextStyle(color: primaryForest, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "Welcome to GreenAtlas. Your account is ready. \n Please sign in to start exploring.",
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Wipes the stack and forces user to the login screen
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryForest,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Go to Sign In", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryForest)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softGreen,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      // ⚪ THE LOGO CARD
Container(
  width: 80,
  height: 80,
  decoration: const BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 20,
        offset: Offset(0, 10),
      )
    ],
  ),
  child: Center(
    child: Image.asset(
      'logo2.png', // Reference directly to fix Web 404 path doubling
      width: 80,   // SET TO 60
      height: 80,  // SET TO 60
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Red icon indicates the asset is still not being found by the engine
        return const Icon(Icons.broken_image, color: Colors.red, size: 40);
      },
    ),
  ),
),
                    const SizedBox(height: 12),
                    const Text("Create Account", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryForest)),
                    const Text("Join the conservation effort", style: TextStyle(fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("* First Name"),
                                    TextField(
                                      controller: _firstNameController,
                                      decoration: ecoInputStyle(label: "Jane", icon: Icons.person_outline).copyWith(
                                        hintText: "Jane", 
                                        labelText: null, 
                                        floatingLabelBehavior: FloatingLabelBehavior.never
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("* Last Name"),
                                    TextField(
                                      controller: _lastNameController,
                                      decoration: ecoInputStyle(label: "Doe", icon: Icons.person_outline).copyWith(
                                        hintText: "Doe", 
                                        labelText: null, 
                                        floatingLabelBehavior: FloatingLabelBehavior.never
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          _buildLabel("* Email Address"),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: ecoInputStyle(label: "email@example.com", icon: Icons.email_outlined).copyWith(hintText: "email@example.com", labelText: null, floatingLabelBehavior: FloatingLabelBehavior.never),
                          ),

                          _buildLabel("* Password"),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: ecoInputStyle(label: "Strong password", icon: Icons.lock_outline).copyWith(
                              hintText: "Strong password", labelText: null, floatingLabelBehavior: FloatingLabelBehavior.never,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),

                          _buildLabel("* Confirm Password"),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscurePassword,
                            decoration: ecoInputStyle(label: "Repeat password", icon: Icons.lock_reset_outlined).copyWith(hintText: "Repeat password", labelText: null, floatingLabelBehavior: FloatingLabelBehavior.never),
                          ),

                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryForest,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                : const Text("Create Account", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.grey)),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("ALREADY HAVE AN ACCOUNT?", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold))),
                        const Expanded(child: Divider(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryForest.withOpacity(0.1),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Sign In", style: TextStyle(color: primaryForest, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}