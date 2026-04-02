import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      _showError("Please fill in all required fields");
      return;
    }

    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(firstName) || !nameRegex.hasMatch(lastName)) {
      _showError("Names should only contain letters");
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showError("Please enter a valid email address");
      return;
    }

    if (!email.toLowerCase().endsWith('@gmail.com')) {
      _showError("Only @gmail.com addresses are allowed");
      return;
    }

    final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$&*~]).{8,}$');
    if (!passwordRegex.hasMatch(password)) {
      _showError("Password needs: 8+ chars, 1 Uppercase, 1 Number, 1 Special Char");
      return;
    }

    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final supabase = Supabase.instance.client;

      final existingEmail = await supabase
          .from('profiles')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      if (existingEmail != null) {
        _showError("This email is already registered.");
        setState(() => _isLoading = false);
        return;
      }
      
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'full_name': "$firstName $lastName",
        },
      );

      if (res.user != null) {
        try {
          await supabase.from('profiles').upsert({
            'id': res.user!.id,
            'full_name': "$firstName $lastName",
            'first_name': firstName,
            'last_name': lastName,
            'email': email,
            'role': 'user', 
          });
        } catch (dbError) {
          debugPrint("Profile DB Error (RLS likely): $dbError");
        }

        await supabase.auth.signOut();

        if (mounted) {
          _showVerificationPopup(email);
        }
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError("An unexpected error occurred.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showVerificationPopup(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // We use Center and TextTheme to avoid TextAlign and FontWeight
        final textStyle = Theme.of(context).textTheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          backgroundColor: Colors.white,
          title: Column(
            children: [
              const Icon(Icons.mark_email_unread_rounded, color: primaryForest, size: 60),
              const SizedBox(height: 15),
              Text(
                "Confirm Your Email", 
                style: textStyle.titleLarge?.copyWith(color: primaryForest),
              ),
              const Divider(color: softGreen, thickness: 1, indent: 20, endIndent: 20),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text(
                  "A verification link has been sent to:",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  email,
                  style: textStyle.bodyLarge?.copyWith(color: primaryForest),
                ),
              ),
              const SizedBox(height: 15),
              const Center(
                child: Text(
                  "Please click the link in your inbox to activate your GreenAtlas account. Check your spam folder if you don't see it!",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryForest,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(
                  "Got it!", 
                  style: textStyle.labelLarge?.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Text(
        text, 
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: primaryForest),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;

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
                    Container(
                      width: 80, height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
                      ),
                      child: Center(
                        child: Image.asset('assets/logo2.png', width: 80, height: 80, fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, color: primaryForest, size: 40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Create Account", 
                      style: textStyle.headlineSmall?.copyWith(color: primaryForest),
                    ),
                    const Text("Join the conservation effort", style: TextStyle(fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(25),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
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
                                    TextField(controller: _firstNameController, decoration: ecoInputStyle(label: "First Name", icon: Icons.person_outline)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("* Last Name"),
                                    TextField(controller: _lastNameController, decoration: ecoInputStyle(label: "Last Name", icon: Icons.person_outline)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          _buildLabel("* Email Address"),
                          TextField(
                            controller: _emailController, 
                            keyboardType: TextInputType.emailAddress, 
                            decoration: ecoInputStyle(label: "email@gmail.com", icon: Icons.email_outlined)
                          ),
                          _buildLabel("* Password"),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: ecoInputStyle(label: "••••••••", icon: Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          _buildLabel("* Confirm Password"),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: ecoInputStyle(label: "••••••••", icon: Icons.lock_reset_outlined).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity, height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignUp,
                              style: ElevatedButton.styleFrom(backgroundColor: primaryForest, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                : Text(
                                    "Create Account", 
                                    style: textStyle.labelLarge?.copyWith(color: Colors.white),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8), 
                          child: Text("ALREADY HAVE AN ACCOUNT?", style: TextStyle(fontSize: 9, color: Colors.grey))
                        ),
                        Expanded(child: Divider(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryForest.withOpacity(0.1), 
                          elevation: 0, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: Text(
                          "Sign In", 
                          style: textStyle.labelLarge?.copyWith(color: primaryForest),
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
}