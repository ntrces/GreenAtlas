import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme_constants.dart';
import 'signup_screen.dart'; 
import '../User_Mobile/user_dashboard.dart'; 
import '../Employee_Mobile/Employee_Dashboard.dart'; 
import '../IntroPages/intro1.dart'; 

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
  
  bool _isCapsLockOn = false; 

  final Color darkGreen = const Color(0xFF303D32);
  final Color sageGreen = const Color(0xFF517156);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
        String role = 'user'; 
        bool isFirstTime = false;

        try {
          // * 1. Fetch current user profile data
          final userData = await _supabase
              .from('profiles')
              .select('role, is_first_time') 
              .eq('id', user.id)
              .maybeSingle();

          if (userData != null) {
            role = userData['role'] ?? 'user';
            isFirstTime = userData['is_first_time'] ?? false;
          }

          // * --- UPDATED "ONLY ONCE" LOGIC ---
          // * If it's a 'user' and it's their first time, update DB immediately
          if (role == 'user' && isFirstTime == true) {
            await _supabase
                .from('profiles')
                .update({'is_first_time': false})
                .eq('id', user.id);
          }
        } catch (dbError) {
          debugPrint("Profile fetch/update error: $dbError");
        }

        if (!mounted) return;

        // * 2. Routing Logic
        if (role == 'employee') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EmployeePortal()),
          );
        } 
        else if (role == 'user' && isFirstTime == true) {
          // * This will only trigger once because we set isFirstTime to false above
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Intro1Screen()),
          );
        } 
        else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserDashboard()),
          );
        }
      }
    } on AuthException catch (e) {
      _showSnackBar(e.message, Colors.redAccent);
    } catch (e) {
      _showSnackBar("Connection Error: Check your database.", Colors.redAccent);
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
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event.logicalKey == LogicalKeyboardKey.capsLock && event is KeyDownEvent) {
          setState(() {
            _isCapsLockOn = !_isCapsLockOn;
          });
        }
      },
      child: Scaffold(
        backgroundColor: softGreen, 
        resizeToAvoidBottomInset: true,
        body: Center( 
          child: SingleChildScrollView( 
            physics: const BouncingScrollPhysics(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  Container(
                    width: 70, height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/logo2.png',
                        width: 50, height: 50,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.eco, color: darkGreen, size: 35),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    "Welcome Back",
                    style: TextStyle(fontFamily: 'Poppins-Bold', fontSize: 28, color: darkGreen),
                  ),
                  Text(
                    "Sign in to explore the GreenAtlas features",
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: sageGreen),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    width: 360,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            "Sign In",
                            style: TextStyle(fontFamily: 'Poppins-Bold', fontSize: 16, color: darkGreen,),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            "Enter your credentials to access your account",
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: sageGreen),
                          ),
                        ),

                        const SizedBox(height: 20),

                        _buildLabel("Email Address *"),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (val) => setState(() {}),
                          decoration: _buildInputDecoration(
                            hintText: "your.email@example.com",
                            icon: Icons.email_outlined,
                          ),
                        ),

                        const SizedBox(height: 16),

                        _buildLabel("Password *"),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onChanged: (val) => setState(() {}),
                          decoration: _buildInputDecoration(
                            hintText: "Enter your password",
                            icon: Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                size: 18, color: sageGreen,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),

                        if (_isCapsLockOn)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
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

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: sageGreen,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _isLoading 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Sign In", style: TextStyle(fontFamily: 'Poppins-Bold', color: Colors.white, fontSize: 15, )),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            const Expanded(child: Divider(color: Colors.black12)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                "DON'T HAVE AN ACCOUNT?",
                                style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: sageGreen),
                              ),
                            ),
                            const Expanded(child: Divider(color: Colors.black12)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF2FAF2), 
                              elevation: 0,
                              side: const BorderSide(color: Color(0xFFE0EEE0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              "Create Account",
                              style: TextStyle(fontFamily: 'Poppins-Bold', fontSize: 14, color: darkGreen),
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
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: text.replaceAll('*', '').trim(),
              style: TextStyle(fontFamily: 'Poppins-Bold', fontSize: 13, color: darkGreen),
            ),
            if (text.contains('*'))
              const TextSpan(
                text: ' *',
                style: TextStyle(fontFamily: 'Poppins-Bold', fontSize: 13, color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText, 
      hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.black26),
      prefixIcon: Icon(icon, size: 18, color: sageGreen),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: sageGreen),
      ),
    );
  }
}