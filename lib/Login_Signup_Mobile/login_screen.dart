import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme_constants.dart';
import 'signup_screen.dart'; 
import '../User_Mobile/user_dashboard.dart'; 
import '../Employee_Mobile/Employee_dashboard.dart'; // REQUIRED: Add your employee import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // --- ROLE-BASED SIGN IN LOGIC ---
  Future<void> _handleSignIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email and password")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Authenticate with Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = response.user;
      if (user != null && mounted) {
        // 2. Fetch the role from your 'profiles' table
        final data = await _supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();

        final String role = data['role'] ?? 'user';

        // 3. Navigate based on the retrieved role
        if (role == 'employee') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EmployeePortal()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserDashboard()),
          );
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
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Branding
                    Container(
                      width: 60, height: 60,
                      decoration: const BoxDecoration(color: primaryForest, shape: BoxShape.circle),
                      child: const Icon(Icons.eco_rounded, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text("Welcome Back", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryForest)),
                    const Text("Sign in to explore the Green Atlas", style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 24),

                    // Login Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(child: Text("Sign In", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryForest))),
                          const SizedBox(height: 16),
                          _buildLabel("* Email Address"),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: ecoInputStyle(label: "Enter email", icon: Icons.email_outlined).copyWith(
                              hintText: "your.email@example.com",
                              labelText: null,
                              floatingLabelBehavior: FloatingLabelBehavior.never,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildLabel("* Password"),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: ecoInputStyle(label: "Enter password", icon: Icons.lock_outline).copyWith(
                              hintText: "Enter password",
                              labelText: null,
                              floatingLabelBehavior: FloatingLabelBehavior.never,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity, height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryForest,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Sign In", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    // Footer
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text("DON’T HAVE AN ACCOUNT?", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
                        const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryForest.withOpacity(0.1),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Create Account", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryForest)),
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

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4), 
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: primaryForest))
  );
}