import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../theme_constants.dart';
import 'signup_screen.dart';
import '../User_Mobile/user_dashboard.dart';
import '../Employee_Mobile/Employee_Dashboard.dart';
import '../IntroPages/intro1.dart';
import '../IntroPages/completeprofile.dart';

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
        } catch (e) {
          debugPrint("Audit log error: $e");
        }

        if (mounted) {
          _showSnackBar("Welcome back!", Colors.green);

          if (role == 'admin' || role == 'employee') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const EmployeePortal()),
            );
          } else {
            if (isFirstTime) {
              await _supabase
                  .from('profiles')
                  .update({'is_first_time': false})
                  .eq('id', user.id);

              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Intro1Screen()),
                );
              }
            } else {
              try {
                final profile = await _supabase
                    .from('profiles')
                    .select('first_name, phone, municipality')
                    .eq('id', user.id)
                    .single();

                final isMissingInfo =
                    (profile['first_name'] == null || profile['first_name'].toString().trim().isEmpty) ||
                    (profile['phone'] == null || profile['phone'].toString().trim().isEmpty) ||
                    (profile['municipality'] == null || profile['municipality'].toString().trim().isEmpty);

                if (isMissingInfo) {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
                    );
                  }
                  return;
                }
              } catch (_) {}

              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const UserDashboard()),
                );
              }
            }
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showSnackBar(e.message, Colors.redAccent);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("An unexpected error occurred: $e", Colors.redAccent);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: getScaffoldBg(isDark),
      body: SafeArea(
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (KeyEvent event) {
            final isCaps = HardwareKeyboard.instance.lockModesEnabled.contains(KeyboardLockMode.capsLock);
            if (_isCapsLockOn != isCaps) {
              setState(() => _isCapsLockOn = isCaps);
            }
          },
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF253326) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/logo2.png',
                          width: 55,
                          height: 55,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.eco, color: isDark ? leafAccent : darkGreen, size: 35),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: 28,
                        fontFamily: 'Poppins-Light',
                        color: getTextColor(isDark),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sign in to explore the GreenAtlas features",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins-Light',
                        color: getSubtextColor(isDark),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 360,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: getCardBg(isDark),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                        border: Border.all(color: isDark ? Colors.white12 : Colors.transparent),
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
                                color: getTextColor(isDark),
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
                                color: getSubtextColor(isDark),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildLabel("Email Address *", isDark),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: getTextColor(isDark)),
                            onChanged: (val) => setState(() {}),
                            decoration: _buildInputDecoration(
                              hintText: "your.email@example.com",
                              icon: Icons.email_outlined,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildLabel("Password *", isDark),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: getTextColor(isDark)),
                            onChanged: (val) => setState(() {}),
                            decoration: _buildInputDecoration(
                              hintText: "Enter your password",
                              icon: Icons.lock_outline,
                              isDark: isDark,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 18,
                                  color: isDark ? leafAccent : sageGreen,
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
                                  Text("Caps Lock is ON", style: TextStyle(color: Colors.orange)),
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
                                backgroundColor: isDark ? leafAccent : sageGreen,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: isDark ? Colors.black : Colors.white, strokeWidth: 2))
                                  : Text("Sign In",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'Poppins-Bold',
                                          color: isDark ? Colors.black : Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                  child: Divider(color: isDark ? Colors.white24 : const Color(0xFFE0E0E0))),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  "DON'T HAVE AN ACCOUNT?",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: getSubtextColor(isDark),
                                    fontFamily: 'Poppins-Light',
                                  ),
                                ),
                              ),
                              Expanded(
                                  child: Divider(color: isDark ? Colors.white24 : const Color(0xFFE0E0E0))),
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
                                backgroundColor: isDark ? const Color(0xFF253326) : const Color(0xFFE8F5E9),
                                foregroundColor: isDark ? leafAccent : darkGreen,
                                elevation: 0,
                                side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFC8E6C9)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                              ),
                              child: Text("Create Account",
                                  style: TextStyle(
                                      fontSize: 16, fontFamily: 'Poppins-Bold', color: isDark ? leafAccent : darkGreen)),
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
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            text.replaceAll('*', '').trim(),
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins-Bold',
              color: getTextColor(isDark),
            ),
          ),
          if (text.contains('*'))
            Text(
              " *",
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins-Bold',
                color: isDark ? leafAccent : darkGreen,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(
      {required String hintText, required IconData icon, required bool isDark}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
          color: getSubtextColor(isDark),
          fontSize: 14,
          fontFamily: 'Poppins-Light'),
      prefixIcon: Icon(icon, size: 20, color: isDark ? leafAccent : sageGreen),
      filled: true,
      fillColor: isDark ? const Color(0xFF253326) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: isDark ? leafAccent : sageGreen),
      ),
    );
  }
}
