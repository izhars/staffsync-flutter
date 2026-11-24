import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staffsync/screens/privacy_permissions_screen.dart';
import '../providers/theme_provider.dart';
import '../services/notification_preference_service.dart';
import 'appearance_screen.dart';
import 'app_update_screen.dart';
import 'my_shift_screen.dart';
import 'ChangePasswordPage.dart';
import 'devices_page.dart';
import 'notification_settings_page.dart';
import 'office_location_screen.dart';

// ===================== DESIGN TOKENS =====================
class SettingsDesign {
  // Spacing
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

// Border Radius
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

// Background & Surfaces
  static const Color bg = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);

// Text Colors
  static const Color textPrimary = Color(0xFF172033);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

// Brand Colors
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primarySoft = Color(0xFFEFF6FF);

// Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);

// Additional UI Colors
  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFDCFCE7);

  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFEF3C7);

  static const Color error = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEE2E2);

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: -4,
    ),
  ];
}

// ===================== SETTINGS PAGE =====================
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final LocalAuthentication _auth = LocalAuthentication();

  bool _twoFactorEnabled = false;
  bool _twoFactorBusy = false;
  bool _lockEnabled = false;
  bool _hapticEnabled = true;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _lockEnabled = prefs.getBool('app_lock_enabled') ?? false;
      _hapticEnabled = prefs.getBool('haptic_enabled') ?? true;
    });

    try {
      final pref = await NotificationPreferenceService().getPreferences();

      if (!mounted) return;

      setState(() {
        _twoFactorEnabled = pref.security.twoFactorEnabled;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ── App Lock toggle ──
  Future<void> _toggleLock(bool value) async {
    if (_busy) return;

    if (value) {
      setState(() => _busy = true);

      bool success = false;

      try {
        success = await _auth.authenticate(
          localizedReason: 'Verify to enable app lock',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
      } catch (_) {
        success = false;
      } finally {
        if (mounted) setState(() => _busy = false);
      }

      if (!success) {
        if (mounted) {
          _showError('Authentication failed. App lock not enabled.');
        }
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_lock_enabled', value);

    if (!mounted) return;

    setState(() => _lockEnabled = value);
  }

  // ── 2FA toggle ──
  Future<void> _toggle2FA(bool enable) async {
    if (_twoFactorBusy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(enable ? 'Enable 2FA?' : 'Disable 2FA?'),
        content: Text(
          enable
              ? 'You will receive a 6-digit code on your email whenever you sign in.'
              : 'You will no longer need a code to sign in. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: SettingsDesign.primary,
            ),
            child: Text(enable ? 'Enable' : 'Disable'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _twoFactorBusy = true);

    try {
      if (enable) {
        await NotificationPreferenceService().request2FASetupCode();
      } else {
        await NotificationPreferenceService().request2FADisableCode();
      }

      if (!mounted) return;

      final code = await _showOtpSheet(enable: enable);

      if (code == null || code.length != 6) {
        if (mounted) setState(() => _twoFactorBusy = false);
        return;
      }

      final updated = enable
          ? await NotificationPreferenceService().enableTwoFactor(code)
          : await NotificationPreferenceService().disableTwoFactor(code);

      if (!mounted) return;

      setState(() {
        _twoFactorEnabled = updated.security.twoFactorEnabled;
        _twoFactorBusy = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enable
                ? 'Two-factor authentication enabled'
                : 'Two-factor authentication disabled',
          ),
          backgroundColor: SettingsDesign.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _twoFactorBusy = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _toggleHaptic(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic_enabled', value);

    if (!mounted) return;

    setState(() => _hapticEnabled = value);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
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

  // ── Navigation helpers ──
  void _push(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _openChangePassword() => _push(const ChangePasswordPage());

  void _openDevices() => _push(const DevicesPage());

  void _openNotifications() => _push(const NotificationSettingsPage());

  void _openProfile() => _push(
    const _StubPage(
      title: 'Profile Information',
      icon: Icons.person_outline_rounded,
      description:
      'View and edit name, photo, employee ID, department, designation, '
          'reporting manager, joining date and emergency contacts.',
    ),
  );

  void _openPrivacy() => _push(const PrivacyPermissionsScreen());

  void _openShift() => _push(const MyShiftScreen());

  void _openGeofence() => _push(const GeoFenceMapScreen());

  void _openNewBuild() => _push(const AppUpdateScreen());

  void _openDocuments() => _push(
    const _StubPage(
      title: 'My Documents',
      icon: Icons.folder_outlined,
      description:
      'Employment documents, verification status and pending onboarding items.',
    ),
  );

  void _openPayslips() => _push(
    const _StubPage(
      title: 'Salary Slips',
      icon: Icons.receipt_long_outlined,
      description: 'Download monthly payslips and view compensation history.',
    ),
  );

  void _openPolicies() => _push(
    const _StubPage(
      title: 'Company Policies',
      icon: Icons.menu_book_outlined,
      description: 'Employee handbook, HR policies and code of conduct.',
    ),
  );

  void _openAppearance() => _push(const AppearanceScreen());

  void _openAbout() => _push(
    const _StubPage(
      title: 'About StaffSync',
      icon: Icons.info_outline_rounded,
      description: 'StaffSync v1.0.0 · Check for updates and release notes.',
    ),
  );

  void _openContact() => _push(
    const _StubPage(
      title: 'Contact HR / IT',
      icon: Icons.support_agent_rounded,
      description:
      'Reach HR for people-related queries and IT for technical issues.',
    ),
  );

  void _openTicket() => _push(
    const _StubPage(
      title: 'Raise a Support Ticket',
      icon: Icons.confirmation_number_outlined,
      description:
      'Report an issue, attendance problem or app bug to the support team.',
    ),
  );

  void _openFaq() => _push(
    const _StubPage(
      title: 'FAQs & User Guide',
      icon: Icons.help_outline_rounded,
      description: 'Common questions and step-by-step how-tos.',
    ),
  );

  void _openFeedback() => _push(
    const _StubPage(
      title: 'Send Feedback',
      icon: Icons.rate_review_outlined,
      description: 'Tell us how we can improve StaffSync.',
    ),
  );

  // ===================== BUILD =====================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : SettingsDesign.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(
              child: CircularProgressIndicator(
                color: SettingsDesign.primary,
              ),
            )
                : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // ── 1. ACCOUNT & PROFILE ──
                _buildSectionHeader('Account & Profile'),
                _buildCard(
                  child: Column(
                    children: [
                      _buildNavTile(
                        icon: Icons.person_outline_rounded,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'Profile Information',
                        subtitle:
                        'Name, photo, employee ID, department, designation',
                        onTap: _openProfile,
                      ),
                      _divider(),
                      _buildNavTile(
                        icon: Icons.password_rounded,
                        iconBg: const Color(0xFFEEF2FF),
                        iconColor: const Color(0xFF4F46E5),
                        title: 'Change Password',
                        subtitle: 'Update your account password securely',
                        onTap: _openChangePassword,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── 2. SECURITY & PRIVACY ──
                _buildSectionHeader('Security & Privacy'),
                _buildCard(
                  child: Column(
                    children: [
                      _buildSwitchTile(
                        icon: Icons.lock_outline_rounded,
                        iconBg: SettingsDesign.primarySoft,
                        iconColor: SettingsDesign.primary,
                        title: 'App Lock',
                        subtitle:
                        'Require biometrics or device PIN/pattern to open StaffSync',
                        value: _lockEnabled,
                        onChanged: _busy ? null : _toggleLock,
                        busy: _busy,
                      ),
                      _divider(),
                      _buildSwitchTile(
                        icon: Icons.verified_user_outlined,
                        iconBg: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFD97706),
                        title: 'Two-Factor Authentication',
                        subtitle: _twoFactorEnabled
                            ? 'Enabled · Code required at sign-in'
                            : 'Add an extra layer of security when signing in',
                        value: _twoFactorEnabled,
                        onChanged:
                        _twoFactorBusy ? null : _toggle2FA,
                        busy: _twoFactorBusy,
                      ),
                      _divider(),
                      _buildNavTile(
                        icon: Icons.devices_rounded,
                        iconBg: const Color(0xFFECFDF5),
                        iconColor: const Color(0xFF059669),
                        title: 'Logged-in Devices',
                        subtitle:
                        'Manage devices where your account is signed in',
                        onTap: _openDevices,
                      ),
                      _divider(),
                      _buildNavTile(
                        icon: Icons.shield_outlined,
                        iconBg: const Color(0xFFE0F2FE),
                        iconColor: const Color(0xFF0284C7),
                        title: 'Privacy & Permissions',
                        subtitle: 'Data policy and app permissions',
                        onTap: _openPrivacy,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── 3. NOTIFICATIONS ──
                _buildSectionHeader('Notifications'),
                _buildCard(
                  child: _buildNavTile(
                    icon: Icons.notifications_active_outlined,
                    iconBg: const Color(0xFFFFF7ED),
                    iconColor: const Color(0xFFEA580C),
                    title: 'Notification Preferences',
                    subtitle:
                    'Leave alerts, attendance reminders, shift updates, deadlines',
                    onTap: _openNotifications,
                  ),
                ),
                const SizedBox(height: 24),

                // ── 4. WORK PREFERENCES ──
                _buildSectionHeader('Work Preferences'),
                _buildCard(
                  child: Column(
                    children: [
                      _buildNavTile(
                        icon: Icons.schedule_rounded,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'Shift & Working Hours',
                        subtitle:
                        'Assigned shift, break policy and time zone',
                        onTap: _openShift,
                      ),
                      _divider(),
                      _buildNavTile(
                        icon: Icons.location_on_outlined,
                        iconBg: const Color(0xFFFEE2E2),
                        iconColor: const Color(0xFFDC2626),
                        title: 'Office Location & Geofence',
                        subtitle: 'Check-in location and radius',
                        onTap: _openGeofence,
                      ),
                      _divider(),
                      _buildNavTile(
                        icon: Icons.system_update_outlined,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'New Build Available',
                        subtitle:
                        'Download the latest application update',
                        onTap: _openNewBuild,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── 5. DOCUMENTS & EMPLOYMENT ──
                _buildSectionHeader('Documents & Employment'),
                _buildCard(
                  child: Column(
                    children: [
                      _buildNavTile(
                        icon: Icons.folder_outlined,
                        iconBg: const Color(0xFFFFF7ED),
                        iconColor: const Color(0xFFEA580C),
                        title: 'My Documents',
                        subtitle:
                        'Offer letter, ID proofs and verification status',
                        onTap: _openDocuments,
                      ),
                      _divider(),
                      _buildNavTile(
                        icon: Icons.receipt_long_outlined,
                        iconBg: const Color(0xFFECFDF5),
                        iconColor: const Color(0xFF059669),
                        title: 'Salary Slips',
                        subtitle: 'Download monthly payslips',
                        onTap: _openPayslips,
                      ),
                      _divider(),
                      _buildNavTile(
                        icon: Icons.menu_book_outlined,
                        iconBg: const Color(0xFFEEF2FF),
                        iconColor: const Color(0xFF4F46E5),
                        title: 'Company Policies',
                        subtitle: 'Employee handbook and HR policies',
                        onTap: _openPolicies,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── 6. APP PREFERENCES ──
                _buildSectionHeader('App Preferences'),
                _buildCard(
                  child: Column(
                    children: [
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) {
                          return _buildNavTile(
                            icon: Icons.palette_outlined,
                            iconBg: isDark
                                ? const Color(0xFF4C1D95).withOpacity(0.3)
                                : const Color(0xFFF3E8FF),
                            iconColor: const Color(0xFF9333EA),
                            title: 'Appearance',
                            subtitle:
                                '${themeProvider.themeModeName} · Display & theme',
                            onTap: _openAppearance,
                          );
                        },
                      ),
                      _divider(),
                      _buildSwitchTile(
                        icon: Icons.vibration_rounded,
                        iconBg: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFD97706),
                        title: 'Haptic Feedback',
                        subtitle: 'Vibrate on key interactions',
                        value: _hapticEnabled,
                        onChanged: _toggleHaptic,
                        busy: false,
                      ),
                      _divider(),
                      _buildNavTile(
                        icon: Icons.info_outline_rounded,
                        iconBg: const Color(0xFFF3F4F6),
                        iconColor: const Color(0xFF6B7280),
                        title: 'About StaffSync',
                        subtitle: 'Version 1.0.0 · Check for updates',
                        onTap: _openAbout,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── 7. HELP & SUPPORT ──
                _buildSectionHeader('Help & Support'),
                _buildCard(
                  child: Column(
                    children: [
                      _buildNavTile(
                        icon: Icons.support_agent_rounded,
                        iconBg: const Color(0xFFECFDF5),
                        iconColor: const Color(0xFF059669),
                        title: 'Contact HR / IT',
                        subtitle: 'Reach out to the right team',
                        onTap: _openContact,
                      ),
                      _divider(),
                      _buildNavTile(
                        icon: Icons.confirmation_number_outlined,
                        iconBg: const Color(0xFFFFF7ED),
                        iconColor: const Color(0xFFEA580C),
                        title: 'Raise a Support Ticket',
                        subtitle:
                        'Report an issue or attendance problem',
                        onTap: _openTicket,
                      ),
                      _divider(),
                      _buildNavTile(
                        icon: Icons.help_outline_rounded,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'FAQs & User Guide',
                        subtitle: 'Common questions and how-tos',
                        onTap: _openFaq,
                      ),
                      _divider(),
                      _buildNavTile(
                        icon: Icons.rate_review_outlined,
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF9333EA),
                        title: 'Send Feedback',
                        subtitle: 'Tell us how we can improve',
                        onTap: _openFeedback,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Footer ──
                Center(
                  child: Text(
                    'StaffSync · v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: SettingsDesign.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== BUILD HELPERS =====================
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            SettingsDesign.primary,
            SettingsDesign.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(SettingsDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: SettingsDesign.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SettingsDesign.md,
            SettingsDesign.sm,
            SettingsDesign.md,
            SettingsDesign.md,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius:
                BorderRadius.circular(SettingsDesign.radiusSm),
                child: InkWell(
                  borderRadius:
                  BorderRadius.circular(SettingsDesign.radiusSm),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: SettingsDesign.sm + 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Manage your account and preferences',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius:
                BorderRadius.circular(SettingsDesign.radiusSm),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      color: isDark ? const Color(0xFF2D3748) : SettingsDesign.border,
      indent: 68,
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: SettingsDesign.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : SettingsDesign.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2640) : SettingsDesign.surface,
        borderRadius: BorderRadius.circular(SettingsDesign.radiusLg),
        boxShadow: isDark ? [] : SettingsDesign.softShadow,
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : SettingsDesign.border,
        ),
      ),
      child: child,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required bool busy,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(SettingsDesign.radiusLg),
        onTap: onChanged == null ? null : () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Row(
            children: [
              _buildIcon(
                icon: icon,
                bg: iconBg,
                color: iconColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFF8FAFC) : SettingsDesign.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFF94A3B8) : SettingsDesign.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (busy)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SettingsDesign.primary,
                  ),
                )
              else
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: Colors.white,
                  activeTrackColor: SettingsDesign.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showOtpSheet({required bool enable}) async {
    final controller = TextEditingController();

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: SettingsDesign.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SettingsDesign.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  enable ? 'Verify to enable 2FA' : 'Verify to disable 2FA',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: SettingsDesign.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code sent to your email.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: SettingsDesign.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    filled: true,
                    fillColor: SettingsDesign.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: SettingsDesign.primary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    final code = controller.text.trim();

                    if (code.length == 6) {
                      Navigator.pop(ctx, code);
                    }
                  },
                  child: const Text(
                    'Verify',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(SettingsDesign.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildIcon(
                icon: icon,
                bg: iconBg,
                color: iconColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFF8FAFC) : SettingsDesign.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFF94A3B8) : SettingsDesign.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? const Color(0xFF64748B) : SettingsDesign.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon({
    required IconData icon,
    required Color bg,
    required Color color,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }
}

// ===================== PLACEHOLDER PAGE =====================
class _StubPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const _StubPage({
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0F19) : SettingsDesign.bg;
    final surface = isDark ? const Color(0xFF1E2640) : SettingsDesign.surface;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : SettingsDesign.textPrimary;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : SettingsDesign.textSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: bg,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: textPrimary,
            ),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.3) : SettingsDesign.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: SettingsDesign.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13.5,
                  color: textSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: SettingsDesign.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Coming soon',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: SettingsDesign.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}