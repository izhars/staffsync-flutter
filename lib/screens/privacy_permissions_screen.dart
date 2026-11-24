// lib/features/privacy/privacy_permissions_screen.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:local_auth/local_auth.dart';

// ===================== DESIGN TOKENS (mirrors DashboardDesign) =====================

class PermissionDesign {
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

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);

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

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle sectionSubtitle = TextStyle(
    fontSize: 12.5,
    color: textMuted,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle tileTitle = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.1,
  );

  static const TextStyle tileSubtitle = TextStyle(
    fontSize: 12.5,
    color: textSecondary,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11.5,
    color: textMuted,
    fontWeight: FontWeight.w500,
  );
}

// ===================== SCREEN =====================

class PrivacyPermissionsScreen extends StatefulWidget {
  const PrivacyPermissionsScreen({super.key});

  @override
  State<PrivacyPermissionsScreen> createState() =>
      _PrivacyPermissionsScreenState();
}

class _PrivacyPermissionsScreenState extends State<PrivacyPermissionsScreen> {
  final Map<Permission, PermStatus> _statuses = {};
  bool _loading = true;

  // Biometrics are not part of permission_handler; track separately.
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  final List<PermissionItem> _permissions = [
    PermissionItem(
      icon: Icons.photo_camera_outlined,
      name: 'Camera',
      why: 'Capture selfies for attendance verification.',
      permission: Permission.camera,
    ),
    PermissionItem(
      icon: Icons.location_on_outlined,
      name: 'Location',
      why: 'Verify you are within the office geo-fence.',
      permission: Permission.locationWhenInUse,
    ),
    PermissionItem(
      icon: Icons.notifications_none_rounded,
      name: 'Notifications',
      why: 'Receive important workplace updates.',
      permission: Permission.notification,
    ),
    PermissionItem(
      icon: Icons.photo_library_outlined,
      name: 'Photos & Media',
      why: 'Upload documents and profile pictures.',
      permission: Permission.photos,
    ),
  ];

  final List<PrivacyInfoItem> _privacyItems = [
    PrivacyInfoItem(
      icon: Icons.person_outline_rounded,
      title: 'Personal Information',
      description: 'Employee profile and account details.',
      details:
      'Your name, contact details and employment information are stored securely and used only for HR operations within StaffSync.',
    ),
    PrivacyInfoItem(
      icon: Icons.place_outlined,
      title: 'Location Data',
      description: 'Used for geo-fenced attendance verification.',
      details:
      'Location is accessed only while clocking in/out and is never tracked continuously.',
    ),
    PrivacyInfoItem(
      icon: Icons.face_retouching_natural_outlined,
      title: 'Face Verification',
      description: 'Used for identity verification during attendance.',
      details:
      'Face data is processed on-device and not stored on our servers unless explicitly required by your organization.',
    ),
    PrivacyInfoItem(
      icon: Icons.notifications_active_outlined,
      title: 'Notifications',
      description: 'Used for important workplace updates.',
      details:
      'Push notifications keep you informed about approvals, announcements and reminders.',
    ),
    PrivacyInfoItem(
      icon: Icons.lock_outline_rounded,
      title: 'Data Security',
      description: 'How StaffSync protects employee information.',
      details:
      'All data is encrypted in transit (TLS) and at rest. Access is strictly role-based and audited.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
    _checkBiometrics();
  }

  Future<void> _checkAllPermissions() async {
    setState(() => _loading = true);
    final result = <Permission, PermStatus>{};
    for (final p in _permissions) {
      result[p.permission] = await _resolveStatus(p.permission);
    }
    if (!mounted) return;
    setState(() {
      _statuses
        ..clear()
        ..addAll(result);
      _loading = false;
    });
  }

  Future<void> _checkBiometrics() async {
    try {
      final available = await _localAuth.canCheckBiometrics;
      if (!mounted) return;
      setState(() => _biometricAvailable = available);
    } catch (_) {
      if (!mounted) return;
      setState(() => _biometricAvailable = false);
    }
  }

  Future<PermStatus> _resolveStatus(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted || status.isLimited) return PermStatus.allowed;
    if (status.isPermanentlyDenied) return PermStatus.permanentlyDenied;
    if (status.isDenied) return PermStatus.denied;
    if (status.isRestricted) return PermStatus.denied;
    return PermStatus.notRequested;
  }

  Future<void> _requestPermission(PermissionItem item) async {
    final current = _statuses[item.permission] ?? PermStatus.notRequested;
    if (current == PermStatus.permanentlyDenied) {
      await openAppSettings();
      return;
    }
    final newStatus = await item.permission.request();
    if (!mounted) return;
    setState(() {
      _statuses[item.permission] = _mapStatus(newStatus);
    });
    if (newStatus.isPermanentlyDenied && mounted) {
      _showPermanentlyDeniedSnack(item);
    }
  }

  PermStatus _mapStatus(PermissionStatus status) {
    if (status.isGranted || status.isLimited) return PermStatus.allowed;
    if (status.isPermanentlyDenied) return PermStatus.permanentlyDenied;
    if (status.isDenied || status.isRestricted) return PermStatus.denied;
    return PermStatus.notRequested;
  }

  void _showPermanentlyDeniedSnack(PermissionItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} is disabled. Enable it in App Settings.'),
        action: SnackBarAction(
          label: 'Open Settings',
          onPressed: () => openAppSettings(),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PermissionDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _toggleBiometrics() async {
    if (!_biometricAvailable) {
      await openAppSettings();
      return;
    }
    if (_biometricEnabled) {
      setState(() => _biometricEnabled = false);
      return;
    }
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Enable biometric sign-in for StaffSync',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!mounted) return;
      if (ok) {
        setState(() => _biometricEnabled = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication canceled.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to enable biometrics: $e')),
      );
    }
  }

  void _openPrivacyDetails(PrivacyInfoItem item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: PermissionDesign.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PermissionDesign.radiusXl),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          PermissionDesign.lg,
          0,
          PermissionDesign.lg,
          PermissionDesign.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: PermissionDesign.primarySoft,
                    borderRadius:
                    BorderRadius.circular(PermissionDesign.radiusSm),
                  ),
                  child: Icon(item.icon,
                      size: 20, color: PermissionDesign.primary),
                ),
                const SizedBox(width: PermissionDesign.sm + 4),
                Expanded(
                  child: Text(item.title, style: PermissionDesign.tileTitle),
                ),
              ],
            ),
            const SizedBox(height: PermissionDesign.md + 4),
            Text(item.description, style: PermissionDesign.tileSubtitle),
            const SizedBox(height: PermissionDesign.sm + 4),
            Text(
              item.details,
              style: PermissionDesign.caption.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PermissionDesign.bg,
      appBar: AppBar(
        backgroundColor: PermissionDesign.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Privacy & Permissions',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: PermissionDesign.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: PermissionDesign.textPrimary),
      ),
      body: RefreshIndicator(
        color: PermissionDesign.primary,
        backgroundColor: PermissionDesign.surface,
        onRefresh: () async {
          await _checkAllPermissions();
          await _checkBiometrics();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: PermissionDesign.xl),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: PermissionDesign.lg),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PermissionDesign.md,
              ),
              child: _header(),
            ),
            _buildSectionHeader(
              title: 'Data Privacy',
              subtitle: 'How your information is handled',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PermissionDesign.md,
              ),
              child: _dataPrivacyCard(),
            ),
            _buildSectionHeader(
              title: 'App Permissions',
              subtitle: 'Control device access',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PermissionDesign.md,
              ),
              child: _appPermissionsCard(),
            ),
            const SizedBox(height: PermissionDesign.lg),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PermissionDesign.md,
              ),
              child: _privacyFooter(),
            ),
            const SizedBox(height: PermissionDesign.lg),
          ],
        ),
      ),
    );
  }

  // ===================== SECTION HEADER =====================

  Widget _buildSectionHeader({required String title, String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PermissionDesign.lg,
        PermissionDesign.lg,
        PermissionDesign.lg,
        PermissionDesign.sm + 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: PermissionDesign.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: PermissionDesign.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: PermissionDesign.sectionTitle),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: PermissionDesign.sectionSubtitle),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== HEADER CARD =====================

  Widget _header() {
    return _Card(
      padding: const EdgeInsets.all(PermissionDesign.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(PermissionDesign.sm + 4),
            decoration: BoxDecoration(
              color: PermissionDesign.primarySoft,
              borderRadius: BorderRadius.circular(PermissionDesign.radiusSm),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: PermissionDesign.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: PermissionDesign.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Your privacy, controlled by you',
                  style: PermissionDesign.tileTitle,
                ),
                SizedBox(height: 4),
                Text(
                  'Manage your personal data and device access. '
                      'StaffSync only requests what is essential.',
                  style: PermissionDesign.tileSubtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== DATA PRIVACY =====================

  Widget _dataPrivacyCard() {
    return _Card(
      padding: const EdgeInsets.symmetric(vertical: PermissionDesign.xs),
      child: Column(
        children: [
          for (var i = 0; i < _privacyItems.length; i++) ...[
            _buildPrivacyTile(_privacyItems[i]),
            if (i != _privacyItems.length - 1)
              Divider(
                height: 1,
                indent: 56,
                color: PermissionDesign.border,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrivacyTile(PrivacyInfoItem item) {
    return _ListTile(
      leading: _iconBadge(item.icon),
      title: item.title,
      subtitle: item.description,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: PermissionDesign.textMuted,
        size: 20,
      ),
      onTap: () => _openPrivacyDetails(item),
    );
  }

  // ===================== APP PERMISSIONS =====================

  Widget _appPermissionsCard() {
    return _Card(
      padding: const EdgeInsets.symmetric(vertical: PermissionDesign.xs),
      child: Column(
        children: [
          for (var i = 0; i < _permissions.length; i++) ...[
            _buildPermissionTile(_permissions[i]),
            Divider(
              height: 1,
              indent: 56,
              color: PermissionDesign.border,
            ),
          ],
          _buildBiometricTile(),
        ],
      ),
    );
  }

  Widget _buildPermissionTile(PermissionItem item) {
    final status = _statuses[item.permission] ?? PermStatus.loading;
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: _ListTile(
        leading: _iconBadge(item.icon),
        title: item.name,
        subtitle: item.why,
        trailing: _loading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: PermissionDesign.primary,
          ),
        )
            : _statusAction(item, status),
      ),
    );
  }

  Widget _buildBiometricTile() {
    final label = !_biometricAvailable
        ? 'Unavailable'
        : (_biometricEnabled ? 'Enabled' : 'Available');
    final color = !_biometricAvailable
        ? PermissionDesign.danger
        : (_biometricEnabled
        ? PermissionDesign.success
        : PermissionDesign.primary);

    return _ListTile(
      leading: _iconBadge(Icons.fingerprint_rounded),
      title: 'Biometrics',
      subtitle: 'Secure sign-in and identity checks.',
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _statusChip(label, color),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _toggleBiometrics,
            child: Text(
              !_biometricAvailable
                  ? 'Settings'
                  : (_biometricEnabled ? 'Disable' : 'Enable'),
              style: const TextStyle(
                color: PermissionDesign.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusAction(PermissionItem item, PermStatus status) {
    final (label, color) = switch (status) {
      PermStatus.allowed => ('Allowed', PermissionDesign.success),
      PermStatus.denied => ('Denied', PermissionDesign.warning),
      PermStatus.permanentlyDenied => ('Disabled', PermissionDesign.danger),
      PermStatus.notRequested => ('Allow', PermissionDesign.primary),
      PermStatus.loading => ('—', PermissionDesign.textMuted),
    };

    final actionText = switch (status) {
      PermStatus.allowed => 'Manage',
      PermStatus.permanentlyDenied => 'Settings',
      _ => 'Allow',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _statusChip(label, color),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: status == PermStatus.loading
              ? null
              : () => _requestPermission(item),
          child: Text(
            actionText,
            style: const TextStyle(
              color: PermissionDesign.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ===================== FOOTER =====================

  Widget _privacyFooter() {
    return _Card(
      padding: const EdgeInsets.all(PermissionDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: PermissionDesign.textSecondary,
              ),
              SizedBox(width: PermissionDesign.sm),
              Text(
                'Your data stays protected',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: PermissionDesign.textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: PermissionDesign.sm),
          const Text(
            'StaffSync never sells your data. All information is encrypted '
                'and used strictly for employment purposes.',
            style: TextStyle(
              fontSize: 12.5,
              color: PermissionDesign.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: PermissionDesign.md + 4),
          Row(
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: PermissionDesign.primary,
                ),
                onPressed: () {
                  // TODO: Open privacy policy
                },
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Last updated Nov 2026',
                style: PermissionDesign.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBadge(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: PermissionDesign.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 20,
        color: PermissionDesign.primary,
      ),
    );
  }
}

// ===================== SHARED WIDGETS =====================

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PermissionDesign.surface,
        borderRadius: BorderRadius.circular(PermissionDesign.radiusMd),
        border: Border.all(color: PermissionDesign.border),
        boxShadow: PermissionDesign.softShadow,
      ),
      padding: padding ?? const EdgeInsets.all(PermissionDesign.lg),
      child: child,
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PermissionDesign.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PermissionDesign.md + 4,
          vertical: PermissionDesign.sm + 4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading,
            const SizedBox(width: PermissionDesign.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: PermissionDesign.tileTitle),
                  const SizedBox(height: 2),
                  Text(subtitle, style: PermissionDesign.tileSubtitle),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: PermissionDesign.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

// ===================== MODELS =====================

class PrivacyInfoItem {
  PrivacyInfoItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.details,
  });
  final IconData icon;
  final String title;
  final String description;
  final String details;
}

class PermissionItem {
  PermissionItem({
    required this.icon,
    required this.name,
    required this.why,
    required this.permission,
  });
  final IconData icon;
  final String name;
  final String why;
  final Permission permission;
}

enum PermStatus { allowed, denied, permanentlyDenied, notRequested, loading }