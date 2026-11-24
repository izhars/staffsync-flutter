import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../core/location_service.dart';
import '../services/notification_service.dart';
import 'snapchat_login_screen.dart';
import 'dashboard/dashboard_screen.dart';

class SplashDesign {
  // Spacing
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  // Radii
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  // Primary indigo palette (matches ReportDesign)
  static const Color primary = Color(0xFF4F46E5);       // indigo-600
  static const Color primaryDark = Color(0xFF4338CA);   // indigo-700
  static const Color primarySoft = Color(0xFFEEF2FF);   // indigo-50
  static const Color primaryLight = Color(0xFFC7D2FE);  // indigo-200

  // Surfaces
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color bg = Color(0xFFF6F7FB);
  static const Color border = Color(0xFFEAECEF);

  // Text
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Semantic (same names/values as ReportDesign)
  static const Color present = Color(0xFF059669);
  static const Color presentSoft = Color(0xFFECFDF5);
  static const Color presentBorder = Color(0xFFA7F3D0);

  static const Color late = Color(0xFFD97706);
  static const Color lateSoft = Color(0xFFFFFBEB);
  static const Color lateBorder = Color(0xFFFDE68A);

  static const Color absent = Color(0xFFDC2626);
  static const Color absentSoft = Color(0xFFFEF2F2);
  static const Color absentBorder = Color(0xFFFECACA);

  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFFBFDBFE);

  static const Color neutral = Color(0xFF6B7280);
  static const Color neutralSoft = Color(0xFFF3F4F6);
  static const Color neutralBorder = Color(0xFFE5E7EB);

  // Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 14,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 22,
      offset: const Offset(0, 8),
      spreadRadius: -6,
    ),
  ];

  static List<BoxShadow> get primaryGlow => [
    BoxShadow(
      color: primary.withOpacity(0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -6,
    ),
  ];

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Typography
  static const TextStyle displayLg = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.8,
  );

  static const TextStyle displayMd = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.4,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: textMuted,
    letterSpacing: 0.1,
  );

  static const TextStyle button = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
  );

  static const TextStyle label = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    color: textMuted,
    letterSpacing: 0.6,
  );
}

class SplashScreen extends StatefulWidget {
  final Map<String, dynamic>? initialNotificationData;
  final bool isFromNotification;

  const SplashScreen({
    super.key,
    this.initialNotificationData,
    required this.isFromNotification,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  bool _processing = true;
  bool _hasHandledNotification = false;
  String _statusMessage = 'Initializing...';

  bool _checkingLocation = true;
  bool _locationGranted = false;
  bool _locationActionInFlight = false;
  bool _initialLocationCheckDone = false;
  LocationAvailability _locationStatus = LocationAvailability.error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_checkingLocation &&
        !_locationGranted) {
      _checkLocation();
    }
  }

  // ==================== BOOTSTRAP ====================

  Future<void> _bootstrap() async {
    await _checkLocation();
    if (!_locationGranted) return;
    await _initializeApp();
  }

  Future<void> _checkLocation() async {
    if (mounted) setState(() => _checkingLocation = true);

    var result = await LocationService.checkAvailability();

    if (!result.isGranted &&
        result.status == LocationAvailability.serviceDisabled) {
      for (var i = 0; i < 3 && !result.isGranted; i++) {
        await Future.delayed(const Duration(milliseconds: 600));
        result = await LocationService.checkAvailability();
      }
    }

    if (!mounted) return;
    setState(() {
      _checkingLocation = false;
      _initialLocationCheckDone = true;
      _locationGranted = result.isGranted;
      _locationStatus = result.status;
    });

    if (_locationGranted &&
        _processing &&
        _statusMessage == 'Initializing...') {
      await _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    if (mounted) {
      setState(() {
        _processing = true;
        _statusMessage = 'Initializing...';
      });
    }

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        await _handleNotLoggedIn();
        return;
      }
      final sessionStatus = await _authService.checkSession();
      await _handleSessionStatus(sessionStatus);
    } catch (e) {
      await _showErrorDialog('Initialization Failed', e.toString());
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  // ==================== SESSION HANDLING ====================

  Future<void> _handleSessionStatus(SessionStatus status) async {
    switch (status) {
      case SessionStatus.valid:
        await _handleValidSession();
        break;
      case SessionStatus.requiresLogout:
      case SessionStatus.expired:
        await _showSessionExpiredDialog();
        break;
      case SessionStatus.invalid:
        await _navigateToLogin();
        break;
      case SessionStatus.deviceMismatch:
        await _showDeviceMismatchDialog();
        break;
      case SessionStatus.unknown:
        await _showNetworkErrorDialog();
        break;
    }
  }

  Future<void> _handleValidSession() async {
    final user = await _authService.getCurrentUser();
    if (user == null) {
      await _navigateToLogin();
      return;
    }

    // Dashboard will call NotificationNavigator.markAppReady() in initState.
    await _navigateToDashboard();

    // Now that the app is navigable, dispatch the pending notification.
    if (widget.isFromNotification &&
        widget.initialNotificationData != null &&
        !_hasHandledNotification) {
      _hasHandledNotification = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationNavigator.navigateFromNotification(
          widget.initialNotificationData!,
        );
      });
    }
  }


  Future<void> _handleNotLoggedIn() async {
    if (widget.isFromNotification && widget.initialNotificationData != null) {
      await _navigateToLoginWithNotification();
    } else {
      await _navigateToLogin();
    }
  }

  Future<void> _handleNotificationNavigation(Map<String, dynamic> data) async {
    final type = data['type']?.toString().toLowerCase();
    if (!mounted) return;
    switch (type) {
      case 'leave_update':
      case 'attendance_reminder':
      case 'announcement':
      case 'test_notification':
        await _navigateToDashboard();
        break;
      default:
        debugPrint('⚠️ Unknown notification type: $type');
        await _navigateToDashboard();
    }
  }

  // ==================== NAVIGATION ====================

  Future<void> _navigateToLogin() async {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SnapchatLoginScreen()),
          (route) => false,
    );
  }

  Future<void> _navigateToLoginWithNotification() async {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SnapchatLoginScreen(
          pendingNotificationData: widget.initialNotificationData,
        ),
      ),
          (route) => false,
    );
  }

  Future<void> _navigateToDashboard() async {
    if (!mounted) return;
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
    );

    // App navigation is complete — release any pending call notification.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationNavigator.markAppReady();
    });
  }

  // ==================== LOCATION ACTIONS ====================

  Future<void> _runThenRecheck(Future<void> Function() action) async {
    if (_locationActionInFlight) return;
    setState(() => _locationActionInFlight = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _locationActionInFlight = false);
    }
    await _checkLocation();
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) => _buildDialog(
        title: 'Exit App?',
        content:
        'Staff Sync needs location access to work correctly. You can '
            'close the app now and come back once it\'s enabled.',
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: SplashDesign.button),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Exit',
              style: SplashDesign.button
                  .copyWith(color: SplashDesign.absent),
            ),
          ),
        ],
      ),
    );
    if (shouldExit == true) SystemNavigator.pop();
  }

  // ==================== DIALOGS ====================

  AlertDialog _buildDialog({
    required String title,
    required String content,
    required List<Widget> actions,
    bool barrierDismissible = true,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SplashDesign.radiusLg),
      ),
      backgroundColor: SplashDesign.surface,
      title: Text(title, style: SplashDesign.h3),
      content: Text(content, style: SplashDesign.body),
      actions: actions,
    );
  }

  Future<void> _showSessionExpiredDialog() => _showLogoutDialog(
    title: 'Session Expired',
    content: 'Your session has expired. Please login again.',
  );

  Future<void> _showDeviceMismatchDialog() => _showLogoutDialog(
    title: 'Device Mismatch',
    content: 'Account is logged in on another device. Please login again.',
  );

  Future<void> _showLogoutDialog({
    required String title,
    required String content,
  }) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildDialog(
        title: title,
        content: content,
        actions: [
          TextButton(
            onPressed: () async {
              await _authService.logout();
              if (!mounted) return;
              Navigator.of(context).pop();
              await _navigateToLogin();
            },
            child: const Text('OK', style: SplashDesign.button),
          ),
        ],
      ),
    );
  }

  Future<void> _showNetworkErrorDialog() async {
    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildDialog(
        title: 'Connection Error',
        content:
        'Unable to connect to server. Please check your internet connection.',
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('retry'),
            child: const Text('Retry', style: SplashDesign.button),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('offline'),
            child: const Text('Try Anyway', style: SplashDesign.button),
          ),
        ],
      ),
    );
    if (result == 'retry') {
      await _initializeApp();
    } else if (result == 'offline') {
      await _navigateToDashboard();
    }
  }

  Future<void> _showErrorDialog(String title, String message) async {
    if (!mounted) return;
    setState(() => _statusMessage = 'Error: $message');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _buildDialog(
        title: title,
        content: message,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('retry'),
            child: const Text('Retry', style: SplashDesign.button),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('login'),
            child: const Text('Go to Login', style: SplashDesign.button),
          ),
        ],
      ),
    );
    if (result == 'retry') {
      await _initializeApp();
    } else if (result == 'login') {
      await _navigateToLogin();
    }
  }

  // ==================== LOCATION UI HELPERS ====================

  IconData get _locationIcon {
    switch (_locationStatus) {
      case LocationAvailability.serviceDisabled:
        return Icons.location_off_rounded;
      case LocationAvailability.permissionDenied:
      case LocationAvailability.permissionDeniedForever:
        return Icons.location_disabled_rounded;
      case LocationAvailability.timedOut:
        return Icons.timer_off_rounded;
      case LocationAvailability.granted:
      case LocationAvailability.error:
        return Icons.error_outline_rounded;
    }
  }

  IconData get _locationButtonIcon {
    switch (_locationStatus) {
      case LocationAvailability.serviceDisabled:
      case LocationAvailability.permissionDeniedForever:
        return Icons.settings_rounded;
      case LocationAvailability.permissionDenied:
        return Icons.check_circle_outline_rounded;
      case LocationAvailability.timedOut:
      case LocationAvailability.error:
      case LocationAvailability.granted:
        return Icons.refresh_rounded;
    }
  }

  String get _locationTitle {
    switch (_locationStatus) {
      case LocationAvailability.serviceDisabled:
        return 'Location Services Off';
      case LocationAvailability.permissionDenied:
        return 'Location Permission Needed';
      case LocationAvailability.permissionDeniedForever:
        return 'Location Permission Blocked';
      case LocationAvailability.timedOut:
        return 'Still Finding Your Location';
      case LocationAvailability.granted:
      case LocationAvailability.error:
        return 'Location Unavailable';
    }
  }

  String get _locationMessage {
    switch (_locationStatus) {
      case LocationAvailability.serviceDisabled:
        return 'Turn on location services on your device to continue using '
            'Staff Sync.';
      case LocationAvailability.permissionDenied:
        return 'Staff Sync needs location access to verify attendance. Please '
            'grant permission when prompted.';
      case LocationAvailability.permissionDeniedForever:
        return 'Location permission was permanently denied. Enable it from '
            'your device\'s app settings to continue.';
      case LocationAvailability.timedOut:
        return 'We\'re still looking for a GPS signal. If you\'re indoors, '
            'try stepping near a window or moving outside, then tap Retry.';
      case LocationAvailability.granted:
      case LocationAvailability.error:
        return 'Something went wrong while checking your location. Please try '
            'again.';
    }
  }

  VoidCallback? get _locationPrimaryOnPressed {
    switch (_locationStatus) {
      case LocationAvailability.serviceDisabled:
        return () => _runThenRecheck(
              () => LocationService.openLocationSettings(),
        );
      case LocationAvailability.permissionDeniedForever:
        return () => _runThenRecheck(
              () => LocationService.openAppSettings(),
        );
      case LocationAvailability.permissionDenied:
      case LocationAvailability.timedOut:
      case LocationAvailability.error:
      case LocationAvailability.granted:
        return () => _runThenRecheck(() async {});
    }
  }

  String get _locationPrimaryLabel {
    switch (_locationStatus) {
      case LocationAvailability.serviceDisabled:
        return 'Open Location Settings';
      case LocationAvailability.permissionDeniedForever:
        return 'Open App Settings';
      case LocationAvailability.permissionDenied:
        return 'Grant Permission';
      case LocationAvailability.timedOut:
      case LocationAvailability.error:
      case LocationAvailability.granted:
        return 'Retry';
    }
  }

  // Status accent colors
  Color get _accent {
    switch (_locationStatus) {
      case LocationAvailability.serviceDisabled:
        return SplashDesign.info;
      case LocationAvailability.permissionDenied:
      case LocationAvailability.timedOut:
        return SplashDesign.late;
      case LocationAvailability.permissionDeniedForever:
        return SplashDesign.absent;
      case LocationAvailability.granted:
      case LocationAvailability.error:
        return SplashDesign.neutral;
    }
  }

  Color get _accentSoft {
    switch (_locationStatus) {
      case LocationAvailability.serviceDisabled:
        return SplashDesign.infoSoft;
      case LocationAvailability.permissionDenied:
      case LocationAvailability.timedOut:
        return SplashDesign.lateSoft;
      case LocationAvailability.permissionDeniedForever:
        return SplashDesign.absentSoft;
      case LocationAvailability.granted:
      case LocationAvailability.error:
        return SplashDesign.neutralSoft;
    }
  }

  Color get _accentBorder {
    switch (_locationStatus) {
      case LocationAvailability.serviceDisabled:
        return SplashDesign.infoBorder;
      case LocationAvailability.permissionDenied:
      case LocationAvailability.timedOut:
        return SplashDesign.lateBorder;
      case LocationAvailability.permissionDeniedForever:
        return SplashDesign.absentBorder;
      case LocationAvailability.granted:
      case LocationAvailability.error:
        return SplashDesign.neutralBorder;
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_initialLocationCheckDone && _checkingLocation) {
      return Scaffold(
        backgroundColor: SplashDesign.surface,
        body: _buildBackdrop(
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(SplashDesign.primary),
            ),
          ),
        ),
      );
    }
    if (!_locationGranted) return _buildLocationGate();
    return _buildSplash();
  }

  // ===================== SHARED BACKDROP =====================

  Widget _buildBackdrop({required Widget child}) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [SplashDesign.primarySoft, Colors.white, Colors.white],
                stops: [0, 0.5, 1],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          top: -90,
          right: -70,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SplashDesign.primary.withOpacity(0.07),
            ),
          ),
        ),
        Positioned(
          bottom: -110,
          left: -90,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SplashDesign.info.withOpacity(0.05),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }

  // ===================== BRAND HEADER =====================

  Widget _buildBrandHeader({bool compact = false}) {
    final tile = compact ? 88.0 : 108.0;
    final logo = compact ? 54.0 : 70.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 18),
          child: child,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: tile,
            height: tile,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SplashDesign.surface,
              borderRadius: BorderRadius.circular(tile * 0.3),
              border: Border.all(color: SplashDesign.primaryLight, width: 1),
              boxShadow: [
                ...SplashDesign.primaryGlow,
                ...SplashDesign.softShadow,
              ],
            ),
            child: Image.asset(
              'assets/staff_syncc.png',
              width: logo,
              height: logo,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: compact ? SplashDesign.md : SplashDesign.lg),
          Text.rich(
            const TextSpan(
              children: [
                TextSpan(
                  text: 'Staff',
                  style: TextStyle(color: SplashDesign.textPrimary),
                ),
                TextSpan(
                  text: 'Sync',
                  style: TextStyle(color: SplashDesign.primary),
                ),
              ],
            ),
            style: TextStyle(
              fontSize: compact ? 28 : 36,
              fontWeight: FontWeight.w800,
              letterSpacing: compact ? -0.8 : -1.0,
              height: 1.1,
            ),
          ),
          const SizedBox(height: SplashDesign.sm - 2),
          const Text('SMART ATTENDANCE', style: SplashDesign.label),
        ],
      ),
    );
  }

  // ===================== LOCATION GATE =====================

  Widget _buildLocationGate() {
    final busy = _locationActionInFlight || _checkingLocation;

    return Scaffold(
      backgroundColor: SplashDesign.surface,
      body: _buildBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SplashDesign.lg,
                      vertical: SplashDesign.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBrandHeader(compact: true),
                        const SizedBox(height: SplashDesign.xl),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(SplashDesign.lg),
                          decoration: BoxDecoration(
                            color: SplashDesign.surface,
                            borderRadius:
                            BorderRadius.circular(SplashDesign.radiusXl),
                            border: Border.all(color: SplashDesign.border),
                            boxShadow: SplashDesign.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Compact header row: badge + title/message
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLocationBadge(),
                                  const SizedBox(width: SplashDesign.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _locationTitle,
                                          style: SplashDesign.h3,
                                        ),
                                        const SizedBox(height: SplashDesign.xs),
                                        Text(
                                          _locationMessage,
                                          style: SplashDesign.caption.copyWith(
                                            color: SplashDesign.textSecondary,
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: SplashDesign.lg),
                              _buildWhyChip(),
                              const SizedBox(height: SplashDesign.md),
                              _buildGradientButton(
                                label: _locationPrimaryLabel,
                                icon: _locationButtonIcon,
                                loading: busy,
                                onPressed:
                                busy ? null : _locationPrimaryOnPressed,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: SplashDesign.md),
                child: TextButton(
                  onPressed: _locationActionInFlight ? null : _confirmExit,
                  style: TextButton.styleFrom(
                    foregroundColor: SplashDesign.textMuted,
                  ),
                  child: const Text('Exit app', style: SplashDesign.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact tinted icon badge (accent reflects current status).
  Widget _buildLocationBadge() {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withOpacity(0.10),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentSoft,
              border: Border.all(color: _accentBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                _locationIcon,
                key: ValueKey(_locationIcon),
                size: 22,
                color: _accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyChip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: SplashDesign.md,
        vertical: SplashDesign.sm + 2,
      ),
      decoration: BoxDecoration(
        color: SplashDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(SplashDesign.radiusMd),
        border: Border.all(color: SplashDesign.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: SplashDesign.primarySoft,
              borderRadius: BorderRadius.circular(SplashDesign.radiusSm - 2),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              size: 14,
              color: SplashDesign.primary,
            ),
          ),
          const SizedBox(width: SplashDesign.sm + 2),
          const Expanded(
            child: Text(
              'Used only to verify your attendance location.',
              style: SplashDesign.caption,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== SPLASH =====================

  Widget _buildSplash() {
    final isError = !_processing && _statusMessage.startsWith('Error');

    return Scaffold(
      backgroundColor: SplashDesign.surface,
      body: _buildBackdrop(
        child: SafeArea(
          child: SizedBox.expand(
            child: Column(
              children: [
                const Spacer(flex: 5),
                _buildBrandHeader(),
                const SizedBox(height: SplashDesign.xl + SplashDesign.md),

                // Progress
                SizedBox(
                  width: 120,
                  height: 4,
                  child: _processing
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      backgroundColor: SplashDesign.primaryLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        SplashDesign.primary,
                      ),
                    ),
                  )
                      : null,
                ),
                const SizedBox(height: SplashDesign.md),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Padding(
                    key: ValueKey(_statusMessage),
                    padding: const EdgeInsets.symmetric(
                      horizontal: SplashDesign.xl,
                    ),
                    child: Text(
                      _statusMessage,
                      style: SplashDesign.caption.copyWith(
                        color: isError
                            ? SplashDesign.absent
                            : SplashDesign.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                if (widget.isFromNotification) ...[
                  const SizedBox(height: SplashDesign.lg),
                  _buildNotificationChip(),
                ],
                if (isError) ...[
                  const SizedBox(height: SplashDesign.lg),
                  SizedBox(
                    width: 180,
                    child: _buildGradientButton(
                      label: 'Retry',
                      icon: Icons.refresh_rounded,
                      loading: false,
                      onPressed: _initializeApp,
                    ),
                  ),
                ],
                const Spacer(flex: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================== SHARED SMALL WIDGETS =====================

  Widget _buildNotificationChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SplashDesign.md,
        vertical: SplashDesign.sm,
      ),
      decoration: BoxDecoration(
        color: SplashDesign.presentSoft,
        borderRadius: BorderRadius.circular(SplashDesign.radiusSm),
        border: Border.all(
          color: SplashDesign.presentBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.notifications_active_rounded,
            color: SplashDesign.present,
            size: 16,
          ),
          SizedBox(width: 6),
          Text(
            'Opened from notification',
            style: TextStyle(
              color: SplashDesign.present,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required bool loading,
    VoidCallback? onPressed,
  }) {
    final disabled = onPressed == null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: disabled && !loading ? 0.6 : 1,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: SplashDesign.primaryGradient,
          borderRadius: BorderRadius.circular(SplashDesign.radiusMd),
          boxShadow: SplashDesign.primaryGlow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(SplashDesign.radiusMd),
            onTap: onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: Colors.white),
                  const SizedBox(width: SplashDesign.sm),
                  Text(
                    label,
                    style: SplashDesign.button
                        .copyWith(color: Colors.white, fontSize: 14.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}