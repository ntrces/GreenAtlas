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
  final Color softGreen = const Color(0xFFF1F8F2);

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
          final userData = await _supabase
              .from('profiles')
              .select('role, is_first_time')
              .eq('id', user.id)
              .maybeSingle();

          if (userData != null) {
            role = userData['role'] ?? 'user';
            isFirstTime = userData['is_first_time'] ?? false;
          }

          await _supabase.from('audit_logs').insert({
            'title': 'User Login',
            'description': 'User ($role) logged in successfully',
            'category': 'Authentication',
            'ip_address': 'Mobile App',
            'result': 'Success',
            'severity': 'Low',
            'user': user.email,
            'user_id': user.id,
            'timestamp': DateTime.now().toIso8601String(),
          });

          if (role == 'user' && isFirstTime == true) {
            // We moved the is_first_time update to completeprofile.dart
            // so they don't lose first-time status if they close the app during the intro.
          }
        } catch (dbError) {
          debugPrint("Audit/Profile error: $dbError");
        }

        if (!mounted) return;

        if (role == 'employee') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EmployeePortal()),
          );
        } else if (role == 'user' && isFirstTime == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Intro1Screen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserDashboard()),
          );
        }
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('email not confirmed')) {
        _showEmailNotConfirmedPopup();
      } else {
        _showSnackBar(e.message, Colors.redAccent);
      }
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

  void _showEmailNotConfirmedPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        title: Row(
          children: [
            Icon(Icons.mark_email_unread_outlined, color: sageGreen, size: 24),
            const SizedBox(width: 8),
            Text(
              "Verify Email",
              style: TextStyle(fontFamily: 'Poppins-Bold', fontSize: 18, color: darkGreen),
            ),
          ],
        ),
        content: const Text(
          "Please check your Gmail or email inbox for the confirmation link to verify your account.",
          style: TextStyle(fontFamily: 'Poppins-Light', fontSize: 14, color: Colors.black87, height: 1.4),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: sageGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                elevation: 0,
              ),
              child: const Text(
                "OK",
                style: TextStyle(fontFamily: 'Poppins-Bold', color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        Future.delayed(Duration.zero, () {
          if (!mounted) return;
          final isCapsOn = !HardwareKeyboard.instance.lockModesEnabled.contains(KeyboardLockMode.capsLock);
          if (_isCapsLockOn != isCapsOn) {
            setState(() {
              _isCapsLockOn = isCapsOn;
            });
          }
        });
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
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/logo2.png',
                        width: 55,
                        height: 55,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.eco, color: darkGreen, size: 35),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 28,
                      fontFamily: 'Poppins-Light',
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sign in to explore the GreenAtlas features",
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins-Light',
                      color: sageGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 360,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
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
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Poppins-Bold',
                              color: darkGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            "Enter your credentials to access your account",
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Poppins-Light',
                              color: sageGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 13),
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
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 18,
                                color: sageGreen,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        if (_isCapsLockOn)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.orange, size: 14),
                                SizedBox(width: 4),
                                Text("Caps Lock is ON"),
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
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text("Sign In",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Poppins-Bold')),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(
                                child: Divider(color: Color(0xFFE0E0E0))),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "DON'T HAVE AN ACCOUNT?",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'Poppins-Light',
                                ),
                              ),
                            ),
                            const Expanded(
                                child: Divider(color: Color(0xFFE0E0E0))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SignUpScreen())),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8F5E9),
                              foregroundColor: darkGreen,
                              elevation: 0,
                              side: const BorderSide(color: Color(0xFFC8E6C9)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text("Create Account",
                                style: TextStyle(
                                    fontSize: 16, fontFamily: 'Poppins-Bold')),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            text.replaceAll('*', '').trim(),
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins-Bold',
              color: darkGreen,
            ),
          ),
          if (text.contains('*'))
            Text(
              " *",
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins-Bold',
                color: darkGreen,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(
      {required String hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 14,
          fontFamily: 'Poppins-Light'),
      prefixIcon: Icon(icon, size: 20, color: sageGreen),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: sageGreen),
      ),
    );
  }
}
