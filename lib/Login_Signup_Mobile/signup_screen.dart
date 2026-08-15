import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../theme_constants.dart';
import 'login_screen.dart';

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
  bool _isCapsLockOn = false;

  final Color darkGreen = const Color(0xFF303D32);
  final Color sageGreen = const Color(0xFF517156);
  final Color lightBgGreen = const Color(0xFFE5F5E8);
  final Color softGreen = const Color(0xFFF1F8F2);

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Handles the Sign Up process and Audit Log connection
  Future<void> _handleSignUp() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }
    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    // Name Validation: No numbers allowed
    final nameRegExp = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegExp.hasMatch(firstName) || !nameRegExp.hasMatch(lastName)) {
      _showError(
          "Names should only contain letters and cannot include numbers.");
      return;
    }

    // Email Validation: Only allow @gmail.com
    if (!email.toLowerCase().endsWith("@gmail.com")) {
      _showError("Only @gmail.com email addresses are allowed.");
      return;
    }

    // Password Validation Criteria:
    // Min 8 chars, 1 uppercase, 1 lowercase, 1 digit, 1 special char
    final passwordRegExp = RegExp(
        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    if (!passwordRegExp.hasMatch(password)) {
      _showError(
          "Password must be at least 8 characters long and include an uppercase letter, lowercase letter, number, and special character.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // 1. Create Auth User
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'full_name': '$firstName $lastName',
        },
      );

      final user = response.user;

      if (user != null) {
        // Explicitly request OTP code email dispatch
        try {
          await supabase.auth.resend(type: OtpType.signup, email: email);
        } catch (e) {
          debugPrint("Resend OTP notice: $e");
        }

        await supabase.from('audit_logs').insert({
          'title': 'User Registration',
          'description': 'New user account created ($email)',
          'category': 'Authentication',
          'ip_address': 'Mobile App',
          'result': 'Success',
          'severity': 'Low',
          'user': email,
          'user_id': user.id,
          'timestamp': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          _showEmailConfirmationDialog();
        }
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains("sending confirmation mail") || e.message.toLowerCase().contains("unexpected_failure")) {
        if (mounted) {
          _showEmailConfirmationDialog();
        }
      } else {
        _showError(e.message);
      }
    } catch (e) {
      _showError("An unexpected error occurred: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showEmailConfirmationDialog() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final email = _emailController.text.trim();
    final otpController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: getCardBg(isDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? leafAccent : sageGreen).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mark_email_read_outlined, color: isDark ? leafAccent : sageGreen, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Verify Your Gmail",
                  style: TextStyle(fontFamily: 'Poppins-Bold', fontSize: 17, color: getTextColor(isDark)),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "A verification code has been sent to:",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: getSubtextColor(isDark)),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(fontFamily: 'Poppins-Bold', fontSize: 13.5, color: isDark ? leafAccent : darkGreen),
                ),
                const SizedBox(height: 12),
                Text(
                  "Please check your Gmail inbox and enter the 6-digit verification code below to verify your account:",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: getSubtextColor(isDark), height: 1.35),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins-Bold',
                    fontSize: 20,
                    letterSpacing: 8,
                    color: getTextColor(isDark),
                  ),
                  decoration: InputDecoration(
                    hintText: "123456",
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      letterSpacing: 4,
                      color: getSubtextColor(isDark).withOpacity(0.4),
                    ),
                    counterText: "",
                    filled: true,
                    fillColor: isDark ? const Color(0xFF182219) : const Color(0xFFEAF7EA),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? leafAccent : sageGreen, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? leafAccent : sageGreen, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: isVerifying
                          ? null
                          : () async {
                              try {
                                final supabase = Supabase.instance.client;
                                await supabase.auth.resend(
                                  type: OtpType.signup,
                                  email: email,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("New verification email/code sent! Check your inbox.")),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error resending email: $e"), backgroundColor: Colors.redAccent),
                                  );
                                }
                              }
                            },
                      child: Text("Resend Email", style: TextStyle(color: isDark ? leafAccent : sageGreen, fontSize: 12.5)),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: isVerifying
                          ? null
                          : () async {
                              final code = otpController.text.trim();
                              if (code.length < 6) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please enter the full 6-digit code or use the link in email"), backgroundColor: Colors.orange),
                                );
                                return;
                              }

                              setDialogState(() => isVerifying = true);
                              try {
                                final supabase = Supabase.instance.client;
                                await supabase.auth.verifyOTP(
                                  type: OtpType.signup,
                                  token: code,
                                  email: email,
                                );

                                if (mounted) {
                                  Navigator.pop(dialogContext); // Close dialog
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Gmail verified successfully! You can now sign in."),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.pop(context); // Return to login screen
                                }
                              } on AuthException catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Verification failed: ${e.message}"), backgroundColor: Colors.redAccent),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Invalid verification code: $e"), backgroundColor: Colors.redAccent),
                                  );
                                }
                              } finally {
                                setDialogState(() => isVerifying = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? leafAccent : sageGreen,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: isVerifying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("Verify Code", style: TextStyle(fontFamily: 'Poppins-Bold', fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext); // Close dialog
                      Navigator.pop(context); // Go back to Login screen
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: (isDark ? leafAccent : sageGreen).withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      "Already Clicked Email Link? Sign In Now",
                      style: TextStyle(fontSize: 12, color: isDark ? leafAccent : sageGreen, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        Future.delayed(Duration.zero, () {
          if (!mounted) return;
          final isCapsOn = HardwareKeyboard.instance.lockModesEnabled
              .contains(KeyboardLockMode.capsLock);
          if (_isCapsLockOn != isCapsOn) {
            setState(() {
              _isCapsLockOn = isCapsOn;
            });
          }
        });
      },
      child: Scaffold(
        backgroundColor: getScaffoldBg(isDark),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF253326) : Colors.white,
                      shape: BoxShape.circle),
                  child: Center(
                      child: Image.asset('assets/logo2.png',
                          width: 57,
                          errorBuilder: (_, __, ___) => Icon(Icons.eco,
                              color: isDark ? leafAccent : darkGreen,
                              size: 35))),
                ),
                const SizedBox(height: 11),
                Text(
                  "Create Account",
                  style: TextStyle(
                      fontFamily: 'Poppins-Bold',
                      fontSize: 28,
                      color: getTextColor(isDark)),
                ),
                Text(
                  "Join GreenAtlas to explore and protect our ecosystem",
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      color: getSubtextColor(isDark)),
                ),
                const SizedBox(height: 25),
                Container(
                  width: 364,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 23, vertical: 23),
                  decoration: BoxDecoration(
                    color: getCardBg(isDark),
                    borderRadius: BorderRadius.circular(11.4),
                    border: Border.all(
                        color:
                            isDark ? Colors.white12 : const Color(0x26303D32),
                        width: 1.32),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x40000000),
                          offset: Offset(4, 4),
                          blurRadius: 4)
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text("Sign Up",
                            style: TextStyle(
                                fontFamily: 'Poppins-Bold',
                                fontSize: 15.2,
                                color: getTextColor(isDark))),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text("Fill in your details to get started",
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15.2,
                                color: getSubtextColor(isDark))),
                      ),
                      const SizedBox(height: 23),
                      Row(
                        children: [
                          Expanded(
                              child: _buildFieldColumn("First Name",
                                  _firstNameController, "First", isDark)),
                          const SizedBox(width: 11.4),
                          Expanded(
                              child: _buildFieldColumn("Last Name",
                                  _lastNameController, "Last", isDark)),
                        ],
                      ),
                      const SizedBox(height: 15.2),
                      _buildFieldColumn("Email Address", _emailController,
                          "your.email@example.com", isDark,
                          icon: Icons.email_outlined),
                      const SizedBox(height: 15.2),
                      _buildFieldColumn(
                          "Password", _passwordController, "••••••••", isDark,
                          isPassword: true,
                          obscure: _obscurePassword,
                          toggle: () => setState(
                              () => _obscurePassword = !_obscurePassword)),
                      if (_isCapsLockOn)
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.orange, size: 14),
                              SizedBox(width: 4),
                              Text("Caps Lock is ON",
                                  style: TextStyle(
                                      color: Colors.orange, fontSize: 12)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        "Must be 8+ characters with uppercase, lowercase, numbers, and special characters.",
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            height: 16 / 12,
                            color: getSubtextColor(isDark)),
                      ),
                      const SizedBox(height: 15.2),
                      _buildFieldColumn("Confirm Password",
                          _confirmPasswordController, "••••••••", isDark,
                          isPassword: true,
                          obscure: _obscureConfirmPassword,
                          toggle: () => setState(() => _obscureConfirmPassword =
                              !_obscureConfirmPassword)),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 47.5,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignUp,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? leafAccent : sageGreen,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7.6))),
                          child: _isLoading
                              ? SizedBox(
                                  height: 19,
                                  width: 19,
                                  child: CircularProgressIndicator(
                                      color:
                                          isDark ? Colors.black : Colors.white,
                                      strokeWidth: 2))
                              : Text("Create Account",
                                  style: TextStyle(
                                      fontFamily: 'Poppins-Bold',
                                      color:
                                          isDark ? Colors.black : Colors.white,
                                      fontSize: 15.2)),
                        ),
                      ),
                      const SizedBox(height: 23),
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black12)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 9.5),
                            child: Text("ALREADY HAVE AN ACCOUNT?",
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 9.5,
                                    color: getSubtextColor(isDark))),
                          ),
                          Expanded(
                              child: Divider(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black12)),
                        ],
                      ),
                      const SizedBox(height: 23),
                      Center(
                        child: SizedBox(
                          width: 317,
                          height: 38,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF253326)
                                  : lightBgGreen,
                              elevation: 0,
                              side: BorderSide(
                                  color: isDark
                                      ? Colors.white24
                                      : const Color(0x26303D32)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.7)),
                            ),
                            child: Text("Sign In",
                                style: TextStyle(
                                    fontFamily: 'Inter-SemiBold',
                                    fontSize: 13.3,
                                    color: isDark ? leafAccent : darkGreen)),
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

  Widget _buildLabel(
      String text, TextEditingController controller, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: text,
              style: TextStyle(
                  fontFamily: 'Poppins-Bold',
                  fontSize: 13.3,
                  color: getTextColor(isDark)),
            ),
            if (controller.text.isEmpty)
              const TextSpan(
                  text: " *",
                  style: TextStyle(color: Colors.red, fontSize: 13.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldColumn(
      String label, TextEditingController controller, String hint, bool isDark,
      {bool isPassword = false,
      bool? obscure,
      VoidCallback? toggle,
      IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, controller, isDark),
        SizedBox(
          height: 45.6,
          child: TextField(
            controller: controller,
            obscureText: obscure ?? false,
            style: TextStyle(fontSize: 13.3, color: getTextColor(isDark)),
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.3,
                  color: getSubtextColor(isDark)),
              prefixIcon: icon != null
                  ? Icon(icon,
                      size: 17.1, color: isDark ? leafAccent : sageGreen)
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF253326) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 11.4),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.6),
                  borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black12)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.6),
                  borderSide:
                      BorderSide(color: isDark ? leafAccent : sageGreen)),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                          obscure! ? Icons.visibility_off : Icons.visibility,
                          size: 17.1,
                          color: isDark ? leafAccent : sageGreen),
                      onPressed: toggle)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
