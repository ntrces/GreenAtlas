import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme_constants.dart';
import 'signup_screen.dart'; 
import '../IntroPages/intro1.dart'; 
import '../User_Mobile/user_dashboard.dart'; 
import '../Employee_Mobile/Employee_Dashboard.dart'; 

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

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Please enter both email and password", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        final userData = await _supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();

        final String role = userData['role'] ?? 'user';

        if (!mounted) return;

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
      _showSnackBar(e.message, Colors.redAccent);
    } catch (e) {
      _showSnackBar("An unexpected error occurred: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                    Container(
                      width: 80, height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/logo2.png',
                          width: 80, height: 80, fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, color: primaryForest, size: 40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Welcome Back", 
                      style: textTheme.headlineSmall?.copyWith(color: primaryForest),
                    ),
                    Text(
                      "Sign in to explore the Green Atlas", 
                      style: textTheme.bodySmall?.copyWith(color: Colors.black54, fontSize: 12),
                    ),
                    const SizedBox(height: 24),

                    // Login Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(25),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              "Sign In", 
                              style: textTheme.titleMedium?.copyWith(color: primaryForest),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildLabel("* Email Address", textTheme),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: ecoInputStyle(label: "Enter email", icon: Icons.email_outlined),
                          ),
                          const SizedBox(height: 12),
                          _buildLabel("* Password", textTheme),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: ecoInputStyle(label: "Enter password", icon: Icons.lock_outline).copyWith(
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
                                : Text(
                                    "Sign In", 
                                    style: textTheme.labelLarge?.copyWith(color: Colors.white),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8), 
                          child: Text("DON’T HAVE AN ACCOUNT?"), // Styled via default or global theme
                        ),
                        Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
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
                        child: Text(
                          "Create Account", 
                          style: textTheme.labelLarge?.copyWith(color: primaryForest),
                        ),
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

  Widget _buildLabel(String text, TextTheme textTheme) => Padding(
    padding: const EdgeInsets.only(bottom: 4), 
    child: Text(
      text, 
      style: textTheme.labelSmall?.copyWith(color: primaryForest, fontSize: 11),
    ),
  );
}