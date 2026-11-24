import 'package:flutter/material.dart';
import '../services/auth_service.dart';

// Re-using the same tokens as Settings/Dashboard
class _CPDesign {
  static const Color bg = Color(0xFFF6F7FB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFEAECEF);
  static const Color primary = Color(0xFF0F766E);

  static const double radiusMd = 18;
  static const double radiusLg = 24;

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: -4,
    ),
  ];
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showPasswords = false;
  bool _loading = false;

  final AuthService _auth = AuthService();

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _auth.changePassword(
        _currentCtrl.text,
        _newCtrl.text,
        _confirmCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Password changed successfully ✅',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.green.shade500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CPDesign.bg,
      appBar: AppBar(
        backgroundColor: _CPDesign.bg,
        surfaceTintColor: _CPDesign.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: _CPDesign.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: _CPDesign.textPrimary,
            ),
          ),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _CPDesign.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                    BorderRadius.circular(_CPDesign.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: _CPDesign.primary.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Secure your account',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Use a strong password you don\'t reuse elsewhere.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.white70,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Form card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _CPDesign.surface,
                    borderRadius: BorderRadius.circular(_CPDesign.radiusLg),
                    border: Border.all(color: _CPDesign.border),
                    boxShadow: _CPDesign.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PasswordField(
                        controller: _currentCtrl,
                        label: 'Current Password',
                        hint: 'Enter current password',
                        obscure: !_showPasswords,
                        icon: Icons.lock_outline_rounded,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Current password required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _PasswordField(
                        controller: _newCtrl,
                        label: 'New Password',
                        hint: 'At least 8 characters',
                        obscure: !_showPasswords,
                        icon: Icons.lock_reset_rounded,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'New password required';
                          }
                          if (v.length < 8) return 'Minimum 8 characters';
                          if (v == _currentCtrl.text) {
                            return 'Must differ from current password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _PasswordField(
                        controller: _confirmCtrl,
                        label: 'Confirm New Password',
                        hint: 'Re-enter new password',
                        obscure: !_showPasswords,
                        icon: Icons.lock_person_outlined,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please confirm new password';
                          }
                          if (v != _newCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _showPasswords,
                        onChanged: _loading
                            ? null
                            : (v) =>
                            setState(() => _showPasswords = v ?? false),
                        title: const Text(
                          'Show passwords',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: _CPDesign.textSecondary,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: _CPDesign.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _CPDesign.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(_CPDesign.radiusMd),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final IconData icon;
  final String? Function(String?) validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.obscure,
    required this.icon,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      validator: validator,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: _CPDesign.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 13.5,
          color: _CPDesign.textSecondary,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          fontSize: 14,
          color: _CPDesign.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, size: 20, color: _CPDesign.primary),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _CPDesign.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _CPDesign.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.6),
        ),
      ),
    );
  }
}