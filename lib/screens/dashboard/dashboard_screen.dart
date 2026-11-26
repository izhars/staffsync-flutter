import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:staffsync/app/sidebar.dart';
import 'package:staffsync/screens/announcement_screen.dart';
import 'package:staffsync/screens/combo_off_screen.dart';
import 'package:staffsync/screens/payroll_screen.dart';
import '../../app/app_screen.dart';
import '../../component/announcements_home_widget.dart';
import '../../component/app_info.dart';
import '../../component/bouncy_feature_card.dart';
import '../../component/celebration_ui.dart' hide CelebrationScreen;
import '../../component/enhanced_attendance_card.dart';
import '../../component/top_bar.dart';
import '../../component/upcoming_festivals.dart';
import '../../core/geocoding_service.dart';
import '../../core/location_service.dart';
import '../../models/user.dart';
import '../../services/api_exception.dart';
import '../../services/attendance_api.dart';
import '../../services/auth_service.dart';
import '../../services/avatar_api.dart';
import '../../services/geo_fence_service.dart';
import '../../services/notification_service.dart';
import '../../utils/device_info.dart';
import '../../widgets/day_time_widget.dart';
import '../../widgets/update_banner.dart';
import '../chat_home_screen.dart';
import '../face/face_capture_screen.dart';
import '../poll_screen.dart';
import '../award_screen.dart';
import '../celebration_screen.dart';
import '../employee_tasks_screen.dart';
import '../leave_screen.dart';
import '../holiday_screen.dart';
import '../report_screen.dart';
import '../face/face_enrollment_screen.dart';

// ===================== DESIGN TOKENS =====================

class DashboardDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 8;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 24;
  static const double radiusXl = 28;

  static const Color bg = Color(0xFFF6F7FB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFEAECEF);
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFFCCFBF1);
  static const Color primarySoft = Color(0xFFF0FDFA);

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 10),
      spreadRadius: -6,
    ),
  ];
}

// ===================== QUICK ACTION MODEL =====================

class _QuickAction {
  final String title;
  final String gif;
  final List<Color> gradient;
  final Color icon;
  final AppScreen screen;

  const _QuickAction({
    required this.title,
    required this.gif,
    required this.gradient,
    required this.icon,
    required this.screen,
  });
}

// ===================== DASHBOARD SCREEN =====================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Location & Address
  LatLng? _currentLatLng;
  String _address = "Waiting for location permission...";
  String? _deviceLocation;
  File? _currentAvatar;
  bool _loadingAddress = false;
  String? token;

  // Permission states
  bool _hasLocationPermission = false;
  bool _isLocationDenied = false;
  bool _isLocationPermanentlyDenied = false;

  // Loading States
  bool _isInitialLoading = true;
  bool _isAttendanceLoading = false;

  // Attendance State
  bool _isCheckedIn = false;
  bool _isCheckedOut = false;
  String? _checkInTime;
  String? _checkOutTime;
  double? _currentWorkHours;
  String? _statusMessage;
  double? _latenessMinutes;
  File? _avatarFile;
  bool _isLoadingAvatar = true;
  User? _currentUser;
  bool _isLoadingAddress = false;

  // Device & App Info
  String? _currentDate;
  String? _deviceModel;
  String? _deviceOS;
  Map<String, String>? _info;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // Live location stream + geocode debounce
  StreamSubscription<LatLng>? _locationSub;
  Timer? _addressDebounce;

  // Services
  final GeocodingService _geocodingService = GeocodingService();
  final AttendanceService _attendanceService = AttendanceService();
  final GeoFenceService _geoFenceService = GeoFenceService();

  // ===================== QUICK ACTIONS DATA =====================
  // Declared once as a static list so it doesn't rebuild every frame.
  static const List<_QuickAction> _quickActions = [
    _QuickAction(
      title: "Reports",
      gif: "assets/gifs/report.gif",
      gradient: [Color(0xFF90CAF9), Color(0xFFE3F2FD)],
      icon: Color(0xFF1E88E5),
      screen: AppScreen.report,
    ),
    _QuickAction(
      title: "Tasks",
      gif: "assets/gifs/task-management.gif",
      gradient: [Color(0xFFEF9A9A), Color(0xFFFFEBEE)],
      icon: Color(0xFFE53935),
      screen: AppScreen.tasks,
    ),
    _QuickAction(
      title: "Leaves",
      gif: "assets/gifs/calendar.gif",
      gradient: [Color(0xFFA5D6A7), Color(0xFFE8F5E9)],
      icon: Color(0xFF43A047),
      screen: AppScreen.leaves,
    ),
    _QuickAction(
      title: "Payroll",
      gif: "assets/gifs/salary.gif",
      gradient: [Color(0xFFCE93D8), Color(0xFFF3E5F5)],
      icon: Color(0xFF8E24AA),
      screen: AppScreen.payroll,
    ),
    _QuickAction(
      title: "Holiday",
      gif: "assets/gifs/island.gif",
      gradient: [Color(0xFF80CBC4), Color(0xFFE0F2F1)],
      icon: Color(0xFF00897B),
      screen: AppScreen.holiday,
    ),
    _QuickAction(
      title: "Polls",
      gif: "assets/gifs/voting.gif",
      gradient: [Color(0xFF9FA8DA), Color(0xFFE8EAF6)],
      icon: Color(0xFF3949AB),
      screen: AppScreen.polls,
    ),
    _QuickAction(
      title: "Announcement",
      gif: "assets/gifs/marketing.gif",
      gradient: [Color(0xFFF48FB1), Color(0xFFFCE4EC)],
      icon: Color(0xFFD81B60),
      screen: AppScreen.announcement,
    ),
    _QuickAction(
      title: "Combo Off",
      gif: "assets/gifs/beach.gif",
      gradient: [Color(0xFFB0BEC5), Color(0xFFECEFF1)],
      icon: Color(0xFF546E7A),
      screen: AppScreen.combooff,
    ),
    _QuickAction(
      title: "Award",
      gif: "assets/gifs/trophy.gif",
      gradient: [Color(0xFFBCAAA4), Color(0xFFEFEBE9)],
      icon: Color(0xFF6D4C41),
      screen: AppScreen.award,
    ),
  ];

  // ===================== LIFECYCLE =====================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _loadData();
    _initAnimations();
    _initializeData();
    _loadToken();
    _loadAvatarAndUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationNavigator.markAppReady();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_hasLocationPermission) _startLocationStream();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _locationSub?.cancel();
      _locationSub = null;
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _locationSub = null;
    _addressDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  // ===================== FACE CAPTURE =====================

  Future<List<double>?> _captureFace({
    required String title,
    required String subtitle,
  }) async {
    return Navigator.push<List<double>?>(
      context,
      MaterialPageRoute(
        builder: (_) => FaceCaptureScreen(title: title, subtitle: subtitle),
      ),
    );
  }

  Future<void> _promptEnrollment([String? customMessage]) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DashboardDesign.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DashboardDesign.radiusMd),
        ),
        title: const Text(
          "Face Biometric Required",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          customMessage ??
              "You haven't registered your face yet or HR has requested re-enrollment. Please complete face enrollment to use attendance punch.",
          style: const TextStyle(
            color: DashboardDesign.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DashboardDesign.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("Enroll Now"),
          ),
        ],
      ),
    );

    if (proceed == true && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FaceEnrollmentScreen()),
      );
    }
  }

  // ===================== LOCATION STREAM =====================

  void _startLocationStream() {
    _locationSub?.cancel();
    _locationSub = LocationService.locationStream().listen(
          (pos) {
        if (!mounted) return;
        setState(() {
          _currentLatLng = pos;
          _deviceLocation =
          "${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}";
          _loadingAddress = true;
        });
        _debouncedReverseGeocode(pos);
      },
      onError: (e) => debugPrint('Location stream error: $e'),
    );
  }

  void _debouncedReverseGeocode(LatLng pos) {
    _addressDebounce?.cancel();
    _addressDebounce = Timer(const Duration(milliseconds: 800), () async {
      try {
        final location = await _geocodingService.reverseGeocode(
          pos.latitude,
          pos.longitude,
        );
        if (!mounted) return;
        setState(() {
          _address = location.address ?? "Unknown location";
          _loadingAddress = false;
        });
      } catch (e) {
        debugPrint('Reverse geocode failed: $e');
        if (!mounted) return;
        setState(() => _loadingAddress = false);
      }
    });
  }

  // ===================== PERMISSIONS =====================

  Future<void> _checkLocationPermissions() async {
    try {
      final status = await Permission.location.status;

      setState(() {
        _hasLocationPermission = status.isGranted;
        _isLocationDenied = status.isDenied;
        _isLocationPermanentlyDenied = status.isPermanentlyDenied;
      });

      if (!_hasLocationPermission) {
        if (_isLocationDenied) {
          final result = await Permission.location.request();

          if (result.isGranted) {
            setState(() {
              _hasLocationPermission = true;
              _isLocationDenied = false;
              _address = "Getting location...";
            });
            _startLocationStream();
            await _getLocationAndAddress();
          } else if (result.isPermanentlyDenied) {
            setState(() {
              _isLocationPermanentlyDenied = true;
              _address =
              "Location permission permanently denied. Please enable in app settings.";
            });
            _showLocationPermissionDialog();
          } else {
            setState(() {
              _isLocationDenied = true;
              _address =
              "Location permission denied. Please enable to use location features.";
            });
          }
        } else if (_isLocationPermanentlyDenied) {
          _showLocationPermissionDialog();
        }
      } else {
        _startLocationStream();
        await _getLocationAndAddress();
      }
    } catch (e) {
      debugPrint('Error checking location permissions: $e');
      setState(() {
        _address = "Error checking permissions: $e";
      });
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: DashboardDesign.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DashboardDesign.radiusMd),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DashboardDesign.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: DashboardDesign.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Location Permission",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: DashboardDesign.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          "This app needs location permission for attendance tracking and location-based features. "
              "Please enable location permission in app settings.",
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: DashboardDesign.textSecondary,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: DashboardDesign.textSecondary,
            ),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DashboardDesign.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DashboardDesign.radiusSm),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              "Open Settings",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== USER / TOKEN / AVATAR =====================

  Future<void> _loadAvatarAndUser() async {
    try {
      final user = await AuthService().fetchMe();
      final hasLocal = await AvatarService.hasLocalAvatar();
      File? localAvatar;

      if (hasLocal) {
        localAvatar = await AvatarService.getAvatar();
      }

      setState(() {
        _currentUser = user;
        _avatarFile = localAvatar;
        _isLoadingAvatar = false;
      });
    } catch (e) {
      debugPrint('Error loading avatar for TopBar: $e');
      setState(() => _isLoadingAvatar = false);
    }
  }

  Future<void> _loadToken() async {
    final authService = AuthService();
    final fetchedToken = await authService.getToken();
    debugPrint('Fetched Token: $fetchedToken');
    setState(() {
      token = fetchedToken;
    });
  }

  Future<void> _loadData() async {
    setState(() => _loadingAddress = true);
    final user = await AuthService().getCurrentUser();
    final avatar = await AvatarService.getAvatar();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _currentAvatar = avatar;
        _loadingAddress = false;
      });
    }
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  Future<void> _initializeData() async {
    _setCurrentDate();
    await Future.wait([
      _loadAppInfo(),
      _initDeviceInfo(),
      _checkLocationPermissions(),
    ]);
    if (mounted) {
      setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _refreshData() async {
    _geoFenceService.clearCache();
    await _checkLocationPermissions();
    await _loadTodayAttendance();
  }

  Future<void> _loadAppInfo() async {
    final details = await AppInfo.getAppDetails();
    if (mounted) {
      setState(() => _info = details);
    }
  }

  void _setCurrentDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    setState(() {
      _currentDate =
      "${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}";
    });
  }

  Future<void> _initDeviceInfo() async {
    final model = await DeviceInfo.model();
    final os = await DeviceInfo.os();
    if (mounted) {
      setState(() {
        _deviceModel = model;
        _deviceOS = os;
      });
    }
  }

  Future<void> _getLocationAndAddress() async {
    try {
      setState(() {
        _loadingAddress = true;
        _address = "Getting location...";
      });

      final hasPermission = await Permission.location.isGranted;
      if (!hasPermission) {
        setState(() {
          _address = "Location permission required";
          _loadingAddress = false;
          _hasLocationPermission = false;
        });
        await _checkLocationPermissions();
        return;
      }

      final current = await LocationService.getCurrentLocation();
      if (current == null) {
        setState(() {
          _address = "Unable to get location";
          _loadingAddress = false;
        });
        return;
      }

      _currentLatLng = current;
      final location = await _geocodingService.reverseGeocode(
        current.latitude,
        current.longitude,
      );

      if (mounted) {
        setState(() {
          _address = location.address ?? "Unknown location";
          _deviceLocation =
          "${current.latitude.toStringAsFixed(4)}, ${current.longitude.toStringAsFixed(4)}";
          _loadingAddress = false;
          _hasLocationPermission = true;
        });
      }

      await _loadTodayAttendance();
    } catch (e) {
      if (mounted) {
        setState(() {
          _address = "Location error: $e";
          _loadingAddress = false;
        });
      }
      debugPrint("Error getting location: $e");
    }
  }

  Future<void> _loadTodayAttendance() async {
    try {
      final response = await _attendanceService.fetchTodayAttendance();

      if (response['success'] == true && mounted) {
        final attendance = response['attendance'];
        setState(() {
          _isCheckedIn = response['isCheckedIn'] ?? false;
          _isCheckedOut = response['isCheckedOut'] ?? false;

          if (attendance != null) {
            _checkInTime = response['checkInTimeFormatted'] ??
                attendance['checkInTimeFormatted'];
            _checkOutTime = response['checkOutTimeFormatted'] ??
                attendance['checkOutTimeFormatted'];
            _currentWorkHours = response['currentWorkHours']?.toDouble() ??
                attendance['workHours']?.toDouble() ??
                0.0;
            _latenessMinutes = attendance['lateBy']?.toDouble();
            _statusMessage = attendance['status'] ?? 'Present';
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching attendance: $e");
    }
  }

  Future<void> _checkIn() async {
    if (!_hasLocationPermission) {
      await _checkLocationPermissions();
      if (!_hasLocationPermission) {
        _showSnackBar(
            "Location permission required for check-in", Colors.red.shade400);
        return;
      }
    }

    setState(() => _isAttendanceLoading = true);

    final fresh = _currentLatLng ?? await LocationService.getCurrentLocation();
    if (fresh == null) {
      setState(() => _isAttendanceLoading = false);
      _showSnackBar("Location not available. Try again.", Colors.red.shade400);
      return;
    }
    _currentLatLng = fresh;

    try {
      final validation = await _geoFenceService.validateLocation(
        latitude: _currentLatLng!.latitude,
        longitude: _currentLatLng!.longitude,
        forceRefresh: false, // Fast-path: use cached fences to eliminate blocking HTTP roundtrip
      );

      if (!validation.isInside) {
        setState(() => _isAttendanceLoading = false);
        _showGeoFenceBlockedDialog(validation, 'check-in');
        return;
      }
    } catch (e) {
      setState(() => _isAttendanceLoading = false);
      _showSnackBar("❌ Could not verify location: $e", Colors.red.shade400);
      return;
    }

    final embedding = await _captureFace(
      title: 'Punch In',
      subtitle: 'Keep your face inside the frame',
    );
    if (embedding == null) {
      if (mounted) setState(() => _isAttendanceLoading = false);
      return;
    }

    try {
      final response = await _attendanceService.checkIn(
        faceEmbedding: embedding,
        latitude: _currentLatLng!.latitude,
        longitude: _currentLatLng!.longitude,
        address: _address,
        deviceInfo: "${_deviceOS ?? ''} | ${_deviceModel ?? ''}",
      );

      if (response['success'] == true && mounted) {
        setState(() {
          _isCheckedIn = true;
          _checkInTime = response['checkInTimeFormatted'] ??
              response['attendance']?['checkInTimeFormatted'];
          _statusMessage = response['message'];
          _latenessMinutes = response['lateBy']?.toDouble();
          _currentWorkHours = 0.0;
        });
        _showSnackBar("✅ Checked in successfully", Colors.green.shade500);
      }
    } on ApiException catch (e) {
      final reason = e.data?['reason'];
      if (reason == 'NOT_ENROLLED') {
        await _promptEnrollment(e.message);
      } else if (reason == 'FACE_MISMATCH') {
        _showSnackBar(
            "❌ Face didn't match. Please try again.", Colors.red.shade400);
      } else {
        _handleGeoFenceError(e, 'check-in');
      }
    } catch (e) {
      _showSnackBar("❌ check-in failed: $e", Colors.red.shade400);
    } finally {
      if (mounted) setState(() => _isAttendanceLoading = false);
    }
  }

  Future<void> _checkOut() async {
    if (!_hasLocationPermission) {
      await _checkLocationPermissions();
      if (!_hasLocationPermission) {
        _showSnackBar(
            "Location permission required for check-out", Colors.red.shade400);
        return;
      }
    }

    if (!_isCheckedIn) {
      _showSnackBar("Cannot check out without checking in first",
          Colors.orange.shade400);
      return;
    }

    setState(() => _isAttendanceLoading = true);

    final fresh = _currentLatLng ?? await LocationService.getCurrentLocation();
    if (fresh == null) {
      setState(() => _isAttendanceLoading = false);
      _showSnackBar("Location not available. Try again.", Colors.red.shade400);
      return;
    }
    _currentLatLng = fresh;

    try {
      final validation = await _geoFenceService.validateLocation(
        latitude: _currentLatLng!.latitude,
        longitude: _currentLatLng!.longitude,
        forceRefresh: false, // Fast-path: use cached fences to eliminate blocking HTTP roundtrip
      );

      if (!validation.isInside) {
        setState(() => _isAttendanceLoading = false);
        _showGeoFenceBlockedDialog(validation, 'check-out');
        return;
      }
    } catch (e) {
      setState(() => _isAttendanceLoading = false);
      _showSnackBar("❌ Could not verify location: $e", Colors.red.shade400);
      return;
    }

    final embedding = await _captureFace(
      title: 'Punch Out',
      subtitle: 'Keep your face inside the frame',
    );
    if (embedding == null) {
      if (mounted) setState(() => _isAttendanceLoading = false);
      return;
    }

    try {
      final response = await _attendanceService.checkOut(
        faceEmbedding: embedding,
        latitude: _currentLatLng!.latitude,
        longitude: _currentLatLng!.longitude,
        address: _address,
        deviceInfo: "${_deviceOS ?? ''} | ${_deviceModel ?? ''}",
      );

      if (response['success'] == true && mounted) {
        setState(() {
          _isCheckedOut = true;
          _checkOutTime = response['checkOutTimeFormatted'] ??
              response['attendance']['checkOut']['time'];
          _statusMessage = response['message'];
          _currentWorkHours = response['currentWorkHours']?.toDouble() ??
              response['attendance']['workHours']?.toDouble();
        });

        final locationInfo = response['location']?['matchedLocation'];
        final successMsg = locationInfo != null
            ? "✅ ${_statusMessage ?? 'Checked out'} from ${locationInfo['name']}"
            : "✅ ${_statusMessage ?? 'Checked out successfully'}";
        _showSnackBar(successMsg, Colors.green.shade500);
      }
    } on ApiException catch (e) {
      final reason = e.data?['reason'];
      if (reason == 'NOT_ENROLLED') {
        await _promptEnrollment(e.message);
      } else if (reason == 'FACE_MISMATCH') {
        _showSnackBar(
            "❌ Face didn't match. Please try again.", Colors.red.shade400);
      } else {
        _handleGeoFenceError(e, 'check-out');
      }
    } catch (e) {
      _showSnackBar("❌ check-out failed: $e", Colors.red.shade400);
    } finally {
      if (mounted) setState(() => _isAttendanceLoading = false);
    }
  }

  void _handleGeoFenceError(dynamic error, String action) {
    if (error is ApiException) {
      final data = error.data;

      if (error.statusCode == 403 && data != null) {
        final nearest = data['nearestLocation'];
        final message =
            data['message'] ?? 'You are outside the allowed location';

        _showDetailedDialog(
          title: 'Outside Office Location',
          message: message,
          nearestLocation: nearest,
          action: action,
        );
        return;
      }

      _showSnackBar(
          "❌ $action failed: ${error.message}", Colors.red.shade400);
      return;
    }

    _showSnackBar("❌ $action failed: $error", Colors.red.shade400);
  }

  void _showGeoFenceBlockedDialog(
      GeoFenceValidationResult result, String action) {
    if (!mounted) return;

    final nearest = result.nearestLocation;
    final distance = result.nearestDistance;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DashboardDesign.surface,
        surfaceTintColor: DashboardDesign.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DashboardDesign.radiusLg),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_off_rounded,
                color: Colors.red.shade500,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Outside Office Location',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: DashboardDesign.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are not within any allowed location. Please move closer to your office or the assigned route to $action.',
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: DashboardDesign.textSecondary,
              ),
            ),
            if (nearest != null && distance != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(DashboardDesign.radiusSm),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoLine(
                      Icons.location_on_rounded,
                      'Nearest Location',
                      nearest.name,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoLine(
                      Icons.straighten_rounded,
                      'Your Distance',
                      '${distance.round()} meters',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoLine(
                      Icons.check_circle_outline_rounded,
                      'Allowed Radius',
                      '${nearest.allowedRadius.round()} meters',
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: DashboardDesign.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DashboardDesign.radiusSm),
              ),
            ),
            child: const Text(
              'Got it',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailedDialog({
    required String title,
    required String message,
    required Map<String, dynamic>? nearestLocation,
    required String action,
  }) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DashboardDesign.surface,
        surfaceTintColor: DashboardDesign.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DashboardDesign.radiusLg),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_off_rounded,
                color: Colors.red.shade500,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: DashboardDesign.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: DashboardDesign.textSecondary,
              ),
            ),
            if (nearestLocation != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(DashboardDesign.radiusSm),
                  border: Border.all(color: Colors.orange.shade200, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoLine(
                      Icons.location_on_rounded,
                      'Nearest Location',
                      nearestLocation['name'] ?? 'Unknown',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoLine(
                      Icons.straighten_rounded,
                      'Your Distance',
                      '${nearestLocation['distance'] ?? '?'} meters',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoLine(
                      Icons.check_circle_outline_rounded,
                      'Allowed Radius',
                      '${nearestLocation['allowedRadius'] ?? '?'} meters',
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: DashboardDesign.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DashboardDesign.radiusSm),
              ),
            ),
            child: const Text(
              'Got it',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLine(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.orange.shade700),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.orange.shade900,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message, Color color) {
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
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DashboardDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigateTo(AppScreen screen) {
    final targetScreen = _screenMap[screen];
    if (targetScreen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetScreen),
      );
    }
  }

  final Map<AppScreen, Widget> _screenMap = {
    AppScreen.report: ReportScreen(),
    AppScreen.tasks: EmployeeTasksScreen(),
    AppScreen.leaves: LeavesScreen(),
    AppScreen.payroll: PayrollListScreen(),
    AppScreen.holiday: PremiumHolidayCalendar(),
    AppScreen.polls: PollScreen(),
    AppScreen.announcement: AnnouncementsPage(),
    AppScreen.combooff: ComboOffScreen(),
    AppScreen.award: AwardScreen(),
  };

  String _getStatusTitle() {
    if (_isCheckedOut) return "Session Complete";
    if (_isCheckedIn) {
      return (_latenessMinutes != null && _latenessMinutes! > 0)
          ? "Active Session (Late)"
          : "Active Session";
    }
    return "Ready to Check In";
  }

  String _formatTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString)
          .toUtc()
          .add(const Duration(hours: 5, minutes: 30));
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : hour;
      return "${displayHour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period";
    } catch (e) {
      return isoString;
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DashboardDesign.surface,
        surfaceTintColor: DashboardDesign.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DashboardDesign.radiusLg),
        ),
        elevation: 12,
        shadowColor: Colors.black.withOpacity(0.15),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.orange.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade200.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Logout?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: DashboardDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Are you sure you want to logout from your account?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: DashboardDesign.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DashboardDesign.textPrimary,
                    side: const BorderSide(color: DashboardDesign.border),
                    backgroundColor: DashboardDesign.surface,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(DashboardDesign.radiusSm),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(DashboardDesign.radiusSm),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await AuthService().logout();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0F19) : DashboardDesign.bg;

    return Scaffold(
      backgroundColor: bg,
      drawer: Sidebar(
        userName: _currentUser?.fullName ?? 'Loading...',
        userEmail: _currentUser?.email ?? 'Loading...',
        employeeId: _currentUser?.employeeId ?? '---',
        avatarFile: _avatarFile,
        avatarUrl: _currentUser?.profilePicture,
        onLogout: _handleLogout,
        parentContext: context,
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: TopBar(
          address: _address,
          isLoadingAddress: _loadingAddress,
          avatarUrl: _currentUser?.profilePicture,
        ),
      ),
      body: RefreshIndicator(
        color: DashboardDesign.primary,
        backgroundColor: DashboardDesign.surface,
        onRefresh: _refreshData,
        child: Skeletonizer(
          enabled: _isInitialLoading,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: DashboardDesign.lg),
              const DayTimeWidget(),
              const SizedBox(height: DashboardDesign.md),
              if (!_isInitialLoading) const UpdateBanner(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DashboardDesign.md,
                ),
                child: AttendanceSummaryCard(
                  statusTitle: _getStatusTitle(),
                  currentDate: _currentDate,
                  checkInTime: _checkInTime != null
                      ? _formatTime(_checkInTime!)
                      : null,
                  checkOutTime: _checkOutTime != null
                      ? _formatTime(_checkOutTime!)
                      : null,
                  currentWorkHours: _currentWorkHours,
                  latenessMinutes: _latenessMinutes,
                  statusMessage: _statusMessage,
                  deviceModel: _deviceModel,
                  deviceOS: _deviceOS,
                  deviceLocation: _deviceLocation,
                  isCheckedIn: _isCheckedIn,
                  isCheckedOut: _isCheckedOut,
                  isLoading: _isAttendanceLoading,
                  onCheckIn: _checkIn,
                  onCheckOut: _checkOut,
                ),
              ),

              const SizedBox(height: DashboardDesign.lg),

              // ─────────────────────────────────────────────
              // QUICK ACTIONS — horizontal scroll (compact)
              // ─────────────────────────────────────────────
              _buildSectionHeader(
                title: 'Quick Actions',
                subtitle: 'Swipe to explore all features',
              ),
              _buildHorizontalActions(),

              // ─────────────────────────────────────────────
              // ANNOUNCEMENTS
              // ─────────────────────────────────────────────
              _buildSectionHeader(
                title: 'Announcements',
                subtitle: 'Latest updates from your team',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: DashboardDesign.md,
                ),
                child: AnnouncementsHomeWidget(),
              ),

              // ─────────────────────────────────────────────
              // HOLIDAYS & FESTIVALS
              // ─────────────────────────────────────────────
              _buildSectionHeader(
                title: 'Holidays & Festivals',
                subtitle: 'Upcoming celebrations',
              ),
              const UpcomingFestivals(),
              const SizedBox(height: DashboardDesign.lg),

              // ─────────────────────────────────────────────
              // CELEBRATIONS
              // ─────────────────────────────────────────────
              _buildSectionHeader(
                title: 'Celebrations',
                subtitle: 'Moments worth celebrating',
              ),
              CelebrationWidget(
                showHeader: true,
                showViewAllButton: true,
                onViewAllPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CelebrationScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: DashboardDesign.lg),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== SECTION HEADER =====================

  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DashboardDesign.lg,
        DashboardDesign.lg,
        DashboardDesign.lg,
        DashboardDesign.sm + 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: DashboardDesign.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: DashboardDesign.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: DashboardDesign.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: DashboardDesign.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ===================== HORIZONTAL QUICK ACTIONS =====================

  Widget _buildHorizontalActions() {
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DashboardDesign.md),
        physics: const BouncingScrollPhysics(),
        itemCount: _quickActions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final action = _quickActions[i];
          return SizedBox(
            width: 104,
            child: BouncyFeatureCard(
              title: action.title,
              gifAssetPath: action.gif,
              gradientColors: action.gradient,
              iconColor: action.icon,
              onTap: () => _navigateTo(action.screen),
            ),
          );
        },
      ),
    );
  }
}