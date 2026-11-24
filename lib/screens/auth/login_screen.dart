import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../forgot_pass_screen.dart';
import 'TwoFactorScreen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ===================== DESIGN TOKENS (from dashboard) =====================
  static const double _xs = 4;
  static const double _sm = 8;
  static const double _lg = 24;
  static const double _xl = 32;

  static const double _radiusSm = 12;
  static const double _radiusMd = 18;
  static const double _radiusLg = 24;

  static const Color _bg = Color(0xFFF6F7FB);
  static const Color _surface = Colors.white;
  static const Color _textPrimary = Color(0xFF1A1D26);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _textMuted = Color(0xFF9CA3AF);
  static const Color _border = Color(0xFFEAECEF);
  static const Color _primary = Color(0xFF0F766E);
  static const Color _primaryLight = Color(0xFFCCFBF1);
  static const Color _primarySoft = Color(0xFFF0FDFA);

  static List<BoxShadow> get _softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> get _mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 10),
      spreadRadius: -6,
    ),
  ];
  // =========================================================================

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    _emailController.addListener(() {
      context.read<AuthProvider>().clearError();
    });
    _passwordController.addListener(() {
      context.read<AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final outcome = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    switch (outcome) {
      case LoginOutcome.success:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case LoginOutcome.twoFactorRequired:
        final tf = auth.pendingTwoFactor!;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TwoFactorScreen(
              ticket: tf.ticket,
              maskedEmail: tf.maskedEmail,
              expiresInSeconds: tf.expiresInSeconds,
            ),
          ),
        );
        break;
      case LoginOutcome.failed:
      // error is already in auth.error, shown by the widget
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: _lg),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo/Icon
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(_radiusLg),
                          boxShadow: _mediumShadow,
                        ),
                        child: const Icon(
                          Icons.lock_open_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),

                      const SizedBox(height: _xl),

                      // Welcome Text
                      const Text(
                        "Welcome Back",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),

                      const SizedBox(height: _sm),

                      const Text(
                        "Sign in to continue",
                        style: TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: _xl),

                      // Form Card
                      Container(
                        padding: const EdgeInsets.all(_lg),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(_radiusLg),
                          boxShadow: _mediumShadow,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email
                              _buildTextField(
                                controller: _emailController,
                                label: "Email",
                                hint: "john@example.com",
                                icon: Icons.email_outlined,
                                validator: Validators.email,
                                keyboardType: TextInputType.emailAddress,
                              ),

                              const SizedBox(height: 20),

                              // Password
                              _buildTextField(
                                controller: _passwordController,
                                label: "Password",
                                hint: "Enter your password",
                                icon: Icons.lock_outline,
                                validator: Validators.required,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: _textSecondary,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),

                              // Error
                              if (authProvider.error != null) ...[
                                const SizedBox(height: 20),
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

                              const SizedBox(height: _xl),

                              // Sign In button
                              SizedBox(
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
                                  onPressed: _login,
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
                                    "Sign In",
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
                      ),

                      const SizedBox(height: _sm + 4),

                      // Forgot Password
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ForgotPasswordScreen()),
                          );
                        },
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: _sm),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _textSecondary, size: 22),
            suffixIcon: suffixIcon,
            hintText: hint,
            hintStyle: const TextStyle(
              color: _textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: _surface,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_radiusSm),
              borderSide: const BorderSide(color: _border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_radiusSm),
              borderSide: const BorderSide(color: _primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_radiusSm),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_radiusSm),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}