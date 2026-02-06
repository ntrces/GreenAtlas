import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme_constants.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleSignUp() async {
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _nameController.text.isEmpty ||
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
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (res.user != null) {
        await supabase.from('profiles').insert({
          'id': res.user!.id,
          'full_name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
        });

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
            "Welcome to GreenAtlas. Your account is ready. \n Please sign in to start exploring and protecting our ecosystem.",
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); 
                  Navigator.pop(context); 
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softGreen,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // Use constrained box to ensure content fits height but stays scrollable
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Branding
                   Container(
  width: 60, 
  height: 60, 
  decoration: const BoxDecoration(
    color: primaryForest, 
    shape: BoxShape.circle,
  ),
  // Added the Icon here
  child: Icon(Icons.eco_rounded, size: 50, color: Colors.white),
),
                    
                    const SizedBox(height: 12),
                    const Text("Create Account", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryForest)),
                    const SizedBox(height: 4),
                    const Text("Join NatureLink to explore our ecosystem", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 24),
                    

                    // Main Card
                    Container(
  padding: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(25),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2), // Increased opacity from 0.05 to 0.1
        blurRadius: 5, // Increased blur for a softer, more elevated feel
        spreadRadius: 1, // Added a slight spread
        offset: const Offset(2, 5), // Moved the shadow further down to show height
      ),
    ],
  ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(child: Text("Sign Up", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryForest))),
                          const SizedBox(height: 16),
                          
                          // Name Field
                          const Text("* Full Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryForest)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _nameController, 
                            decoration: ecoInputStyle(label: "John Doe", icon: Icons.person_outline).copyWith(
                              hintText: "John Doe",
                              labelText: null,
                              floatingLabelBehavior: FloatingLabelBehavior.never,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Email Field
                          const Text("* Email Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryForest)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _emailController, 
                            keyboardType: TextInputType.emailAddress,
                            decoration: ecoInputStyle(label: "your.email@example.com", icon: Icons.email_outlined).copyWith(
                              hintText: "your.email@example.com",
                              labelText: null,
                              floatingLabelBehavior: FloatingLabelBehavior.never,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Password Field
                          const Text("* Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryForest)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _passwordController, 
                            obscureText: _obscurePassword,
                            decoration: ecoInputStyle(label: "Create a strong password", icon: Icons.lock_outline).copyWith(
                              hintText: "Create a strong password",
                              labelText: null,
                              floatingLabelBehavior: FloatingLabelBehavior.never,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Confirm Password Field
                          const Text("* Confirm Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryForest)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _confirmPasswordController, 
                            obscureText: _obscurePassword,
                            decoration: ecoInputStyle(label: "Re-enter your password", icon: Icons.lock_reset_outlined).copyWith(
                              hintText: "Re-enter your password",
                              labelText: null,
                              floatingLabelBehavior: FloatingLabelBehavior.never,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Button
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
                    // Divider and Sign In
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey)),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("ALREADY HAVE AN ACCOUNT?", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold))),
                        Expanded(child: Divider(color: Colors.grey)),
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