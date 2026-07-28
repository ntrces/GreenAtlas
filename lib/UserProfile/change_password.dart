import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../theme_constants.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _isLoading = false;

  Future<void> _handleUpdatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;

      // 1. Re-authenticate to verify current password
      await _supabase.auth.signInWithPassword(
        email: user!.email!,
        password: _currentPasswordController.text,
      );

      // 2. Update to new password
      await _supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      // 3. NEW: Connect to audit_logs
      await _supabase.from('audit_logs').insert({
        'title': 'Password Changed',
        'description': 'User successfully updated their account password.',
        'category': 'Security',
        'ip_address': 'Mobile App',
        'result': 'Success',
        'severity': 'Medium',
        'user': user.email,
        'user_id': user.id,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      String message = e.message;
      if (e.message.contains("Invalid login credentials")) {
        message = "The current password you entered is incorrect.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: getScaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: getCardBg(isDark),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: getTextColor(isDark)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Security",
          style: textTheme.titleLarge?.copyWith(
            color: getTextColor(isDark),
            fontSize: 18,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: getCardBg(isDark),
              borderRadius: BorderRadius.circular(15),
              border:
                  Border.all(color: isDark ? Colors.white12 : const Color(0xFF5D7A5D).withOpacity(0.1)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Text(
                        "CHANGE PASSWORD",
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          color: isDark ? leafAccent : const Color(0xFF2D3E2D),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            size: 20, color: getSubtextColor(isDark)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Center(
                    child: Text(
                      "Enter your current password and choose a new one",
                      style: TextStyle(fontSize: 12, color: getSubtextColor(isDark)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildPasswordField(
                    label: "CURRENT PASSWORD",
                    controller: _currentPasswordController,
                    obscure: _obscureCurrent,
                    onToggle: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    label: "NEW PASSWORD",
                    controller: _newPasswordController,
                    obscure: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    label: "CONFIRM NEW PASSWORD",
                    controller: _confirmPasswordController,
                    obscure: true,
                    showToggle: false,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleUpdatePassword,
                      icon: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: isDark ? Colors.black : Colors.white, strokeWidth: 2))
                          : Icon(Icons.vpn_key_outlined,
                              size: 18, color: isDark ? Colors.black : Colors.white),
                      label: Text(
                        "UPDATE PASSWORD",
                        style: textTheme.labelLarge?.copyWith(
                          color: isDark ? Colors.black : Colors.white,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? leafAccent : const Color(0xFF5D7A5D),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
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

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required bool isDark,
    VoidCallback? onToggle,
    bool showToggle = true,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall
              ?.copyWith(fontSize: 11, color: getSubtextColor(isDark)),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(fontSize: 14, color: getTextColor(isDark)),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF253326) : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFD6E8D6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? leafAccent : const Color(0xFF5D7A5D)),
            ),
            suffixIcon: showToggle
                ? IconButton(
                    icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: isDark ? leafAccent : const Color(0xFF5D7A5D)),
                    onPressed: onToggle,
                  )
                : null,
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return "Field is required";
            if (label == "NEW PASSWORD" && val.length < 6)
              return "Password too short (min 6 chars)";
            if (label == "CONFIRM NEW PASSWORD" &&
                val != _newPasswordController.text)
              return "Passwords do not match";
            return null;
          },
        ),
      ],
    );
  }
}
