import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'auth/TwoFactorScreen.dart';
import 'splash_screen.dart';
import 'forgot_pass_screen.dart';

// ===================== DESIGN TOKENS (from dashboard) =====================
const double _xs = 4;
const double _sm = 8;
const double _md = 8;
const double _lg = 24;
const double _xl = 32;

const double _radiusSm = 12;
const double _radiusMd = 18;
const double _radiusLg = 24;
const double _radiusXl = 28;

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

class SavedProfile {
  final String employeeId;
  final String displayName;
  final String? avatarUrl;
  final String password;
  final String? organizationCode;

  SavedProfile({
    required this.employeeId,
    required this.displayName,
    this.avatarUrl,
    required this.password,
    this.organizationCode,
  });

  Map<String, dynamic> toJson() => {
    'employeeId': employeeId,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'password': password,
    'organizationCode': organizationCode,
  };

  factory SavedProfile.fromJson(Map<String, dynamic> json) => SavedProfile(
    employeeId: json['employeeId'] ?? json['email'] ?? '',
    displayName: json['displayName'] ?? '',
    avatarUrl: json['avatarUrl'],
    password: json['password'] ?? '',
    organizationCode: json['organizationCode'],
  );
}

class SnapchatLoginScreen extends StatefulWidget {
  final Map<String, dynamic>? pendingNotificationData;

  const SnapchatLoginScreen({
    Key? key,
    this.pendingNotificationData,
  }) : super(key: key);

  @override
  State<SnapchatLoginScreen> createState() => _SnapchatLoginScreenState();
}

class _SnapchatLoginScreenState extends State<SnapchatLoginScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<SavedProfile> _savedProfiles = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  bool _loggingIn = false;

  @override
  void initState() {
    super.initState();
    _loadSavedProfiles();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();

    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  Future<void> _loadSavedProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final profilesJson = prefs.getStringList('saved_profiles') ?? [];

    setState(() {
      _savedProfiles = profilesJson
          .map((json) => SavedProfile.fromJson(jsonDecode(json)))
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _saveProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final profilesJson = _savedProfiles
        .map((profile) => jsonEncode(profile.toJson()))
        .toList();
    await prefs.setStringList('saved_profiles', profilesJson);
  }

  void _onLoginSuccess() {
    debugPrint(
        '✅ Login successful - Pending notification: ${widget.pendingNotificationData}');

    if (widget.pendingNotificationData != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => SplashScreen(
            initialNotificationData: widget.pendingNotificationData,
            isFromNotification: true,
          ),
        ),
            (route) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
            (route) => false,
      );
    }
  }

  Future<void> _loginWithProfile(SavedProfile profile) async {
    if (_loggingIn) return;

    setState(() {
      _loggingIn = true;
    });

    try {
      final fcmToken = await FirebaseService.getFcmToken();
      print('🔥 FCM Token retrieved: $fcmToken');

      final auth = context.read<AuthProvider>();

      final outcome = await auth.login(
        profile.employeeId,
        profile.password,
        fcmToken: fcmToken,
        organizationCode: profile.organizationCode,
      );

      if (!mounted) return;

      switch (outcome) {
      // ── 1. Normal success ─────────────────────────────────
        case LoginOutcome.success:
          _onLoginSuccess();
          break;

      // ── 2. Backend wants OTP ──────────────────────────────
        case LoginOutcome.twoFactorRequired:
          setState(() {
            _loggingIn = false;
          });

          final tf = auth.pendingTwoFactor;
          if (tf == null) {
            // Should never happen — defensive fallback
            _showErrorSnack('2FA state lost. Please try again.');
            break;
          }

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TwoFactorScreen(
                ticket: tf.ticket,
                maskedEmail: tf.maskedEmail,
                expiresInSeconds: tf.expiresInSeconds,
                pendingNotificationData: widget.pendingNotificationData,
              ),
            ),
          );

          // If the user came back from the 2FA screen without verifying,
          // _loggingIn is already false. If they verified successfully,
          // TwoFactorScreen itself navigates to /dashboard.
          break;

      // ── 3. Bad credentials / network / deactivated ────────
        case LoginOutcome.failed:
          setState(() {
            _loggingIn = false;
          });
          _showErrorSnack(
            auth.error ?? 'Invalid employee ID or password',
          );
          break;
      }
    } catch (e) {
      print('❌ Login error: $e');
      if (!mounted) return;

      final auth = context.read<AuthProvider>();
      setState(() {
        _loggingIn = false;
      });
      _showErrorSnack(auth.error ?? 'Login failed. Please try again.');
    }
  }

  /// Small helper so we don't duplicate the SnackBar code 3 times.
  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 13.5,
          ),
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _removeProfile(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        surfaceTintColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
        ),
        title: const Text(
          'Remove Account',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        content: Text(
          'Remove ${_savedProfiles[index].displayName} from saved accounts?',
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: _textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: _textSecondary,
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade500,
            ),
            child: const Text(
              'Remove',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _savedProfiles.removeAt(index);
        if (_currentPage >= _savedProfiles.length && _savedProfiles.isNotEmpty) {
          _currentPage = _savedProfiles.length - 1;
          _pageController.jumpToPage(_currentPage);
        }
      });
      await _saveProfiles();
    }
  }

  void _addNewAccount() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AddAccountScreen(
          onAccountAdded: (profile) {
            setState(() {
              final exists = _savedProfiles
                  .any((p) => p.employeeId == profile.employeeId);
              if (!exists) {
                _savedProfiles.add(profile);
                _saveProfiles();
              }
            });
          },
          pendingNotificationData: widget.pendingNotificationData,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _surface,
                    shape: BoxShape.circle,
                    boxShadow: _mediumShadow,
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_primary),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: _lg),
              Text(
                widget.pendingNotificationData != null
                    ? 'Opening from notification...'
                    : 'Loading profiles...',
                style: const TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: child,
                );
              },
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            _lg, _lg, _lg, _sm + 4),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: _sm + 2),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'My Accounts',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: _textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Tap a profile to sign in instantly',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: _textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: _sm),
                      if (_savedProfiles.isEmpty)
                        _buildEmptyState()
                      else
                        _buildProfileCards(),
                      const SizedBox(height: _lg),
                      if (_savedProfiles.isNotEmpty &&
                          _savedProfiles.length > 1)
                        _buildPageIndicators(),
                      const SizedBox(height: _lg),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Hero(
                          tag: 'add_account_button',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _addNewAccount,
                              borderRadius: BorderRadius.circular(_radiusMd),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: _primary,
                                  borderRadius: BorderRadius.circular(_radiusMd),
                                  boxShadow: _softShadow,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: _sm + 4),
                                    Text(
                                      'Add Account',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: _lg),
                      if (_savedProfiles.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Tap any profile to log in instantly',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: _textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (widget.pendingNotificationData != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(_radiusSm),
                          boxShadow: _softShadow,
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.notifications_active,
                                size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Notification',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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

  Widget _buildEmptyState() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: _primaryLight,
                shape: BoxShape.circle,
                boxShadow: _softShadow,
              ),
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: _primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: _xl),
          const Text(
            'No Saved Accounts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: _sm + 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              widget.pendingNotificationData != null
                  ? 'Add your account to view the notification content'
                  : 'Add your first account to enjoy quick and seamless login',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _textSecondary,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCards() {
    return SizedBox(
      height: 430,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _savedProfiles.length,
        itemBuilder: (context, index) {
          return _buildProfileCard(_savedProfiles[index], index);
        },
      ),
    );
  }

  Widget _buildProfileCard(SavedProfile profile, int index) {
    final isActive = _currentPage == index;

    // ✅ Show name even if not saved: fall back to employeeId
    final displayName = profile.displayName.trim().isEmpty
        ? profile.employeeId
        : profile.displayName;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () => _loginWithProfile(profile),
      child: AnimatedScale(
        scale: isActive ? 1.0 : 0.88,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: isActive ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 350),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(_radiusXl),
                boxShadow: _mediumShadow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Hero(
                        tag: 'avatar_${profile.employeeId}',
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: _primary,
                            shape: BoxShape.circle,
                            boxShadow: _softShadow,
                          ),
                          child: profile.avatarUrl != null
                              ? ClipOval(
                            child: Image.network(
                              profile.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildDefaultAvatar(initial),
                            ),
                          )
                              : _buildDefaultAvatar(initial),
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: () => _removeProfile(index),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade500,
                              shape: BoxShape.circle,
                              boxShadow: _softShadow,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: _lg),
                  // ✅ Name (fallback to employeeId if empty)
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: _sm),
                  Text(
                    profile.employeeId,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: _xl),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(_radiusMd),
                      boxShadow: _softShadow,
                    ),
                    child: _loggingIn && _currentPage == index
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.pendingNotificationData != null
                              ? Icons.notifications_active
                              : Icons.login_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: _sm),
                        Text(
                          widget.pendingNotificationData != null
                              ? 'Login for notification'
                              : 'Tap to Login',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
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

  Widget _buildDefaultAvatar(String initial) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _savedProfiles.length,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: _currentPage == index ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? _primary : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
            boxShadow: _currentPage == index ? _softShadow : null,
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Add Account Screen
// ────────────────────────────────────────────────────────────────
class AddAccountScreen extends StatefulWidget {
  final Function(SavedProfile) onAccountAdded;
  final Map<String, dynamic>? pendingNotificationData;

  const AddAccountScreen({
    super.key,
    required this.onAccountAdded,
    this.pendingNotificationData,
  });

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _companyCodeController = TextEditingController(text: 'STAFFSYNC');
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _saveAccount = true;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();

    // Restore last used organization code if available
    AuthService().getOrganizationCode().then((code) {
      if (code != null && code.isNotEmpty && mounted) {
        setState(() {
          _companyCodeController.text = code;
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _companyCodeController.dispose();
    _employeeIdController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // LOGIN FLOW
  // ─────────────────────────────────────────────────────────
  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final fcmToken = await FirebaseService.getFcmToken();
    final auth = context.read<AuthProvider>();

    final outcome = await auth.login(
      _employeeIdController.text.trim().toUpperCase(),
      _passwordController.text,
      fcmToken: fcmToken,
      organizationCode: _companyCodeController.text.trim().toUpperCase(),
    );

    if (!mounted) return;

    switch (outcome) {
    // ── 1. Normal success ─────────────────────────────
      case LoginOutcome.success:
        _persistProfileIfRequested();
        _onLoginSuccess();
        break;

    // ── 2. Backend wants OTP ──────────────────────────
      case LoginOutcome.twoFactorRequired:
        final tf = auth.pendingTwoFactor;
        if (tf == null) {
          _showErrorSnack('2FA state lost. Please try again.');
          break;
        }

        final verified = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => TwoFactorScreen(
              ticket: tf.ticket,
              maskedEmail: tf.maskedEmail,
              expiresInSeconds: tf.expiresInSeconds,
              pendingNotificationData: widget.pendingNotificationData,
            ),
          ),
        );

        // Only save the profile if 2FA actually succeeded.
        if (verified == true && mounted) {
          _persistProfileIfRequested();
        }
        break;

    // ── 3. Bad credentials / network / deactivated ────
      case LoginOutcome.failed:
        _showErrorSnack(
          auth.error ?? 'Invalid employee ID or password',
        );
        break;
    }
  }

  /// Save the profile only after successful authentication.
  void _persistProfileIfRequested() {
    if (!_saveAccount) return;

    final employeeId = _employeeIdController.text.trim().toUpperCase();
    final displayName = _nameController.text.trim().isEmpty
        ? employeeId
        : _nameController.text.trim();

    widget.onAccountAdded(
      SavedProfile(
        employeeId: employeeId,
        displayName: displayName,
        password: _passwordController.text,
        organizationCode: _companyCodeController.text.trim().toUpperCase(),
      ),
    );
  }

  /// Navigate onward after success — to notification or dashboard.
  void _onLoginSuccess() {
    if (widget.pendingNotificationData != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => SplashScreen(
            initialNotificationData: widget.pendingNotificationData,
            isFromNotification: true,
          ),
        ),
            (route) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
            (route) => false,
      );
    }
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 13.5,
          ),
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(_lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back + Title
                Row(
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
                    const SizedBox(width: _sm + 4),
                    const Text(
                      'Add Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _lg),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Info card
                      Container(
                        padding: const EdgeInsets.all(_lg),
                        decoration: BoxDecoration(
                          color: _primarySoft,
                          borderRadius: BorderRadius.circular(_radiusLg),
                          border: Border.all(color: _primaryLight, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                color: _primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.pendingNotificationData != null
                                    ? Icons.notifications_active
                                    : Icons.person_add_alt_rounded,
                                size: 34,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: _sm + 4),
                            Text(
                              widget.pendingNotificationData != null
                                  ? 'Login for Notification'
                                  : 'Create New Account',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: _xs),
                            Text(
                              widget.pendingNotificationData != null
                                  ? 'Login to view notification content'
                                  : 'Quick login for all your profiles',
                              style: const TextStyle(
                                fontSize: 13,
                                color: _textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: _xl),

                      // Display Name
                      _buildTextField(
                        controller: _nameController,
                        label: 'Display Name (Optional)',
                        hint: 'How should we call you?',
                        icon: Icons.badge_outlined,
                        iconColor: _primary,
                      ),
                      const SizedBox(height: 20),

                      // Company Code
                      _buildTextField(
                        controller: _companyCodeController,
                        label: 'Company Code',
                        hint: 'e.g., STAFFSYNC',
                        icon: Icons.business_outlined,
                        iconColor: _primary,
                        validator: Validators.required,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 20),

                      // Employee ID
                      _buildTextField(
                        controller: _employeeIdController,
                        label: 'Employee ID',
                        hint: 'e.g., SCAIPLE001',
                        icon: Icons.badge_outlined,
                        iconColor: _primary,
                        validator: Validators.employeeId,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 20),

                      // Password
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter your password',
                        icon: Icons.lock_outline_rounded,
                        iconColor: _primary,
                        validator: Validators.required,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
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
                      const SizedBox(height: _lg),

                      // Save Account Checkbox
                      Container(
                        padding: const EdgeInsets.all(_sm + 2),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(_radiusMd),
                          border: Border.all(color: _border, width: 1.5),
                          boxShadow: _softShadow,
                        ),
                        child: Row(
                          children: [
                            Transform.scale(
                              scale: 1.1,
                              child: Checkbox(
                                value: _saveAccount,
                                onChanged: (value) {
                                  setState(() {
                                    _saveAccount = value ?? true;
                                  });
                                },
                                activeColor: _primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(width: _sm + 2),
                            const Expanded(
                              child: Text(
                                'Save this account for quick access',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ForgotPasswordScreen(),
                                ),
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

                      if (authProvider.error != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(_radiusSm),
                            border: Border.all(
                              color: Colors.red.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                            _primary.withOpacity(0.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_radiusMd),
                            ),
                          ),
                          child: authProvider.isLoading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                              AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.pendingNotificationData != null
                                    ? Icons.notifications_active
                                    : Icons.login_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: _sm + 4),
                              Text(
                                widget.pendingNotificationData != null
                                    ? 'Login for Notification'
                                    : 'Sign In & Save',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
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

  // ─────────────────────────────────────────────────────────
  // TEXT FIELD HELPER
  // ─────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
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
          textCapitalization: textCapitalization,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: iconColor, size: 22),
            suffixIcon: suffixIcon,
            hintText: hint,
            hintStyle: const TextStyle(
              color: _textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: _surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
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
              borderSide:
              BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_radiusSm),
              borderSide:
              BorderSide(color: Colors.red.shade400, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}