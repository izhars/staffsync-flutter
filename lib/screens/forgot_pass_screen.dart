import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';

// ===================== DESIGN TOKENS (from dashboard) =====================
const double _xs = 4;
const double _sm = 8;
const double _lg = 24;
const double _xl = 32;

const double _radiusSm = 12;
const double _radiusMd = 18;
const double _radiusLg = 24;

const Color _bg = Color(0xFFF6F7FB);
const Color _surface = Colors.white;
const Color _textPrimary = Color(0xFF1A1D26);
const Color _textSecondary = Color(0xFF6B7280);
const Color _textMuted = Color(0xFF9CA3AF);
const Color _border = Color(0xFFEAECEF);
const Color _primary = Color(0xFF0F766E);
const Color _primaryLight = Color(0xFFCCFBF1);
const Color _primarySoft = Color(0xFFF0FDFA);

final List<BoxShadow> _softShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 16,
    offset: const Offset(0, 6),
    spreadRadius: -4,
  ),
];

final List<BoxShadow> _mediumShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.06),
    blurRadius: 24,
    offset: const Offset(0, 10),
    spreadRadius: -6,
  ),
];
// =========================================================================

class ForgotPasswordScreen extends StatefulWidget {
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthProvider>().forgotPassword(
      _emailController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Password reset link sent to your email',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: _primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusSm),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _sm, vertical: _sm),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(_radiusSm),
                      boxShadow: _softShadow,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: _textPrimary,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: _lg),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Icon Container
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: _primary,
                              borderRadius: BorderRadius.circular(_radiusLg),
                              boxShadow: _mediumShadow,
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),

                        const SizedBox(height: _xl),

                        // Title
                        const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),

                        const SizedBox(height: _sm + 4),

                        // Description
                        const Text(
                          "No worries! Enter your email address and we'll send you instructions to reset your password.",
                          style: TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: _xl),

                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Email Label
                              const Text(
                                "Email Address",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(height: _sm),

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                validator: Validators.email,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                  color: _textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Enter your email",
                                  hintStyle: const TextStyle(
                                    color: _textMuted,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: _textSecondary,
                                    size: 22,
                                  ),
                                  filled: true,
                                  fillColor: _surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(_radiusSm),
                                    borderSide: const BorderSide(
                                      color: _border,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(_radiusSm),
                                    borderSide: const BorderSide(
                                      color: _primary,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(_radiusSm),
                                    borderSide: BorderSide(
                                      color: Colors.red.shade400,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(_radiusSm),
                                    borderSide: BorderSide(
                                      color: Colors.red.shade400,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),

                              // Error Message
                              if (authProvider.error != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius:
                                    BorderRadius.circular(_radiusSm),
                                    border: Border.all(
                                        color: Colors.red.shade200, width: 1),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        color: Colors.red.shade500,
                                        size: 22,
                                      ),
                                      const SizedBox(width: _sm + 4),
                                      Expanded(
                                        child: Text(
                                          authProvider.error!,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: _lg),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: authProvider.isLoading
                                    ? Container(
                                  decoration: BoxDecoration(
                                    color: _primary.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(
                                        _radiusMd),
                                  ),
                                  alignment: Alignment.center,
                                  child: const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                )
                                    : ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          _radiusMd),
                                    ),
                                  ),
                                  child: const Text(
                                    "Send Reset Link",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: _xl),

                        // Back to Login
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: _primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: _sm,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_rounded, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  "Back to Login",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: _lg),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}