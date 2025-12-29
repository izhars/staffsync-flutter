import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../services/FirebaseService.dart';
import 'forgot_pass_screen.dart';

class SavedProfile {
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String password;

  SavedProfile({
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'password': password,
  };

  factory SavedProfile.fromJson(Map<String, dynamic> json) => SavedProfile(
    email: json['email'],
    displayName: json['displayName'],
    avatarUrl: json['avatarUrl'],
    password: json['password'] ?? '',
  );
}

class SnapchatLoginScreen extends StatefulWidget {
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

  // In your _loginWithProfile method
  // Fixed version of _loginWithProfile method
  Future<void> _loginWithProfile(SavedProfile profile) async {
    if (_loggingIn) return;

    setState(() {
      _loggingIn = true;
    });

    try {
      // Get FCM token ONCE at the beginning
      final fcmToken = await FirebaseService.getFcmToken();

      print('🔥 FCM Token retrieved: $fcmToken'); // Debug log

      // If password is empty, show dialog but keep fcmToken
      if (profile.password.isEmpty) {
        setState(() {
          _loggingIn = false;
        });
        await _showPasswordDialogForExistingProfile(profile, fcmToken);
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const LoadingDialog(),
      );

      // Pass FCM token to login
      final success = await context.read<AuthProvider>().login(
        profile.email,
        profile.password,
        fcmToken: fcmToken,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
                (route) => false,
          );
        } else {
          setState(() {
            _loggingIn = false;
          });
          // Retry with password dialog, keeping the same fcmToken
          await _showPasswordDialogForExistingProfile(profile, fcmToken);
        }
      }
    } catch (e) {
      print('❌ Login error: $e');
      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _loggingIn = false;
        });

        // Get FCM token again in case of error
        final fcmToken = await FirebaseService.getFcmToken();
        await _showPasswordDialogForExistingProfile(profile, fcmToken);
      }
    }
  }

// Updated dialog method that ensures fcmToken is always used
  Future<void> _showPasswordDialogForExistingProfile(
      SavedProfile profile,
      String? fcmToken,
      ) async {
    final password = await showDialog<String>(
      context: context,
      builder: (context) => PasswordDialog(
        displayName: profile.displayName,
        email: profile.email,
      ),
    );

    if (password != null && password.isNotEmpty) {
      setState(() {
        _loggingIn = true;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const LoadingDialog(),
      );

      print('🔥 Logging in with FCM token: $fcmToken'); // Debug log

      // Pass the fcmToken that was retrieved earlier
      final success = await context.read<AuthProvider>().login(
        profile.email,
        password,
        fcmToken: fcmToken,
      );

      if (mounted) {
        Navigator.pop(context);

        if (success) {
          // Update saved profile with password
          final updatedProfile = SavedProfile(
            email: profile.email,
            displayName: profile.displayName,
            avatarUrl: profile.avatarUrl,
            password: password,
          );

          final index = _savedProfiles.indexWhere((p) => p.email == profile.email);
          if (index != -1) {
            _savedProfiles[index] = updatedProfile;
            await _saveProfiles();
          }

          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
                (route) => false,
          );
        } else {
          setState(() {
            _loggingIn = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Invalid password. Please try again.',
                style: TextStyle(fontSize: 14),
              ),
              backgroundColor: const Color(0xFFFF6B9D),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } else {
      setState(() {
        _loggingIn = false;
      });
    }
  }

  void _removeProfile(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.white,
        title: const Text(
          'Remove Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
            fontSize: 20,
          ),
        ),
        content: Text(
          'Remove ${_savedProfiles[index].displayName} from saved accounts?',
          style: const TextStyle(color: Color(0xFF718096), fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF718096), fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF6B9D),
            ),
            child: const Text('Remove', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
              final exists = _savedProfiles.any((p) => p.email == profile.email);
              if (!exists) {
                _savedProfiles.add(profile);
                _saveProfiles();
              }
            });
          },
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
        backgroundColor: const Color(0xFFFAFBFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading profiles...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
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
        backgroundColor: const Color(0xFFFAFBFC),
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
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667EEA).withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.supervisor_account_rounded,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'My Accounts',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D3748),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Profile Cards
                  if (_savedProfiles.isEmpty)
                    _buildEmptyState()
                  else
                    _buildProfileCards(),

                  const SizedBox(height: 32),

                  // Page Indicators
                  if (_savedProfiles.isNotEmpty && _savedProfiles.length > 1)
                    _buildPageIndicators(),

                  const SizedBox(height: 28),

                  // Add Account Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Hero(
                      tag: 'add_account_button',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _addNewAccount,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF667EEA).withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Add Account',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Footer text
                  if (_savedProfiles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        '✨ Tap any profile to log in instantly',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
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
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF667EEA).withOpacity(0.1),
                    const Color(0xFF764BA2).withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          const Text(
            'No Saved Accounts',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Add your first account to enjoy quick and seamless login',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.6,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: isActive
                        ? const Color(0xFF667EEA).withOpacity(0.15)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: isActive ? 30 : 20,
                    offset: Offset(0, isActive ? 15 : 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar with remove button
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Hero(
                        tag: 'avatar_${profile.email}',
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667EEA).withOpacity(0.3),
                                blurRadius: 25,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: profile.avatarUrl != null
                              ? ClipOval(
                            child: Image.network(
                              profile.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildDefaultAvatar(profile),
                            ),
                          )
                              : _buildDefaultAvatar(profile),
                        ),
                      ),
                      // Remove button
                      Positioned(
                        top: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: () => _removeProfile(index),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B9D),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF6B9D).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Display Name
                  Text(
                    profile.displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D3748),
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Email
                  Text(
                    profile.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Login Indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10D9A0), Color(0xFF0BC586)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10D9A0).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _loggingIn && _currentPage == index
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.login_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Tap to Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
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

  Widget _buildDefaultAvatar(SavedProfile profile) {
    return Center(
      child: Text(
        profile.displayName[0].toUpperCase(),
        style: const TextStyle(
          fontSize: 60,
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
            gradient: _currentPage == index
                ? const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
                : null,
            color: _currentPage == index ? null : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
            boxShadow: _currentPage == index
                ? [
              BoxShadow(
                color: const Color(0xFF667EEA).withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ]
                : null,
          ),
        ),
      ),
    );
  }
}

// Loading Dialog Widget
class LoadingDialog extends StatelessWidget {
  const LoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              spreadRadius: 3,
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
              strokeWidth: 3,
            ),
            SizedBox(height: 18),
            Text(
              'Logging in...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Password Dialog Widget
class PasswordDialog extends StatefulWidget {
  final String displayName;
  final String email;

  const PasswordDialog({
    required this.displayName,
    required this.email,
  });

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final FocusNode _passwordFocusNode = FocusNode();
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Section
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${widget.displayName}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF718096),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  'Enter your password to continue',
                  style: TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                // Password Input
                TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: _obscurePassword,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      Navigator.pop(context, value);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter password',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 22, color: Color(0xFF667EEA)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 22,
                        color: Color(0xFF667EEA),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF718096),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667EEA).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          if (_passwordController.text.isNotEmpty) {
                            Navigator.pop(context, _passwordController.text);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Add Account Screen
class AddAccountScreen extends StatefulWidget {
  final Function(SavedProfile) onAccountAdded;

  const AddAccountScreen({required this.onAccountAdded});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
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
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      // Get FCM token
      final fcmToken = await FirebaseService.getFcmToken();

      final success = await context.read<AuthProvider>().login(
        _emailController.text.trim(),
        _passwordController.text,
        fcmToken: fcmToken,  // Pass it here
      );

      if (success && mounted) {
        if (_saveAccount) {
          final profile = SavedProfile(
            email: _emailController.text.trim(),
            displayName: _nameController.text.trim().isEmpty
                ? _emailController.text.split('@')[0]
                : _nameController.text.trim(),
            password: _passwordController.text,
          );
          widget.onAccountAdded(profile);
        }

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Bar
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2D3748)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Add Account',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667EEA).withOpacity(0.3),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_add_alt_rounded,
                                size: 42,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Create New Account',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Quick login for all your profiles',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.95),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Display Name
                      _buildTextField(
                        controller: _nameController,
                        label: 'Display Name (Optional)',
                        hint: 'How should we call you?',
                        icon: Icons.badge_outlined,
                        iconColor: const Color(0xFF667EEA),
                      ),

                      const SizedBox(height: 20),

                      // Email
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'john@example.com',
                        icon: Icons.email_outlined,
                        iconColor: const Color(0xFF667EEA),
                        validator: Validators.email,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 20),

                      // Password
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter your password',
                        icon: Icons.lock_outline_rounded,
                        iconColor: const Color(0xFF667EEA),
                        validator: Validators.required,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: const Color(0xFF667EEA),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Save Account Checkbox
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                                activeColor: const Color(0xFF667EEA),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Save this account for quick access',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF2D3748),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
                                );
                              },
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Error Message
                      if (authProvider.error != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5F5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFB8B8)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6B9D), size: 24),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  authProvider.error!,
                                  style: const TextStyle(
                                    color: Color(0xFFFF6B9D),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Login Button
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667EEA).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: authProvider.isLoading ? null : _login,
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              alignment: Alignment.center,
                              child: authProvider.isLoading
                                  ? const SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.login_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Sign In & Save',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: iconColor, size: 24),
            suffixIcon: suffixIcon,
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.grey[200]!,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF667EEA),
                width: 2.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFFF6B9D),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFFF6B9D),
                width: 2.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
