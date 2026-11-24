import 'dart:io';
import 'package:flutter/material.dart';
import 'package:staffsync/screens/daily_task_screen.dart';
import 'package:staffsync/screens/onboarding_screen.dart';
import 'package:staffsync/screens/quotes_list_screen.dart';
import 'package:staffsync/screens/assets_screen.dart';
import 'package:staffsync/screens/expense_list_screen.dart';
import 'package:staffsync/screens/faq_screen.dart';
import 'package:staffsync/screens/home_screen.dart';
import 'package:staffsync/screens/notification_screen.dart';
import 'package:staffsync/screens/profile_screen.dart';
import '../screens/SettingsPage.dart';
import '../screens/about_page.dart';
import '../screens/chat_home_screen.dart';
import '../screens/face/face_test_menu_screen.dart';
import '../screens/help_and_support.dart';
import '../screens/policy_screen.dart';
import '../services/avatar_api.dart';

// ===================== DESIGN TOKENS =====================

class SidebarDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 28;

  // Palette
  static const Color primary = Color(0xFF0F766E);       // teal-700
  static const Color primaryDark = Color(0xFF115E59);   // teal-800
  static const Color primarySoft = Color(0xFFF0FDFA);   // teal-50
  static const Color primaryLight = Color(0xFFCCFBF1);  // teal-100

  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);  // slate-50
  static const Color border = Color(0xFFEAECEF);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  // Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get avatarShadow => [
    BoxShadow(
      color: primary.withOpacity(0.2),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];
}

class Sidebar extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String employeeId;
  final File? avatarFile;
  final String? avatarUrl;
  final VoidCallback onLogout;
  final BuildContext parentContext;

  const Sidebar({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.employeeId,
    this.avatarFile,
    this.avatarUrl,
    required this.onLogout,
    required this.parentContext,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  File? _localAvatar;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _refreshAvatar();
  }

  Future<void> _refreshAvatar() async {
    try {
      final hasLocal = await AvatarService.hasLocalAvatar();
      if (hasLocal) {
        final file = await AvatarService.getAvatar();
        if (!mounted) return;
        setState(() {
          _localAvatar = file;
          _loaded = true;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _localAvatar = null;
          _loaded = true;
        });
      }
    } catch (e) {
      debugPrint('Sidebar avatar refresh error: $e');
      if (!mounted) return;
      setState(() => _loaded = true);
    }
  }

  bool get _isTablet {
    final mediaQuery = MediaQuery.of(widget.parentContext);
    final shortestSide = mediaQuery.size.shortestSide;
    return shortestSide > 600;
  }

  double get _drawerWidth {
    if (_isTablet) {
      final screenWidth = MediaQuery.of(widget.parentContext).size.width;
      return screenWidth * 0.3 < 400 ? screenWidth * 0.3 : 400;
    }
    return 304;
  }

  void _navigateTo(Widget page) {
    Navigator.pop(widget.parentContext);
    Navigator.push(
      widget.parentContext,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _navigateToProfile() {
    Navigator.pop(widget.parentContext);
    Navigator.push(
      widget.parentContext,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _navigateToOnboarding() {
    Navigator.pop(widget.parentContext);
    Navigator.push(
      widget.parentContext,
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }

  void _handleLogout() {
    Navigator.pop(widget.parentContext);
    widget.onLogout();
  }

  ImageProvider? _getProfileImage() {
    // Prefer freshly-loaded local file (Option A)
    if (_loaded && _localAvatar != null) {
      try {
        return FileImage(_localAvatar!);
      } catch (e) {
        debugPrint('Error loading refreshed avatar in sidebar: $e');
      }
    }

    // Fall back to what was passed in
    if (widget.avatarFile != null) {
      try {
        return FileImage(widget.avatarFile!);
      } catch (e) {
        debugPrint('Error loading local avatar in sidebar: $e');
      }
    }

    if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) {
      return NetworkImage(widget.avatarUrl!);
    }

    return const AssetImage('assets/profile.png');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E2640) : SidebarDesign.surface;

    return Drawer(
      width: _drawerWidth,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(SidebarDesign.radiusXl),
          bottomRight: Radius.circular(SidebarDesign.radiusXl),
        ),
      ),
      backgroundColor: surface,
      surfaceTintColor: surface,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(SidebarDesign.radiusXl),
            bottomRight: Radius.circular(SidebarDesign.radiusXl),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: _isTablet ? 32 : 20),

              // ===================== PROFILE HEADER =====================
              _buildProfileSection(),

              SizedBox(height: _isTablet ? 28 : 22),

              // Divider
              _buildDivider(),

              SizedBox(height: _isTablet ? 12 : 8),

              // ===================== MENU ITEMS =====================
              Expanded(child: _buildMenuItems()),

              // ===================== LOGOUT BUTTON =====================
              Padding(
                padding: EdgeInsets.only(
                  left: SidebarDesign.md,
                  right: SidebarDesign.md,
                  bottom: MediaQuery.of(widget.parentContext).viewInsets.bottom > 0
                      ? MediaQuery.of(widget.parentContext).viewInsets.bottom + 16
                      : 16,
                ),
                child: _buildLogoutButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _isTablet ? 24 : 20),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              isDark ? const Color(0xFF2D3748) : SidebarDesign.border,
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  // ===================== PROFILE SECTION =====================

  Widget _buildProfileSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _isTablet ? 24 : 20),
      child: Column(
        children: [
          GestureDetector(
            onTap: _navigateToProfile,
            child: Stack(
              children: [
                // Avatar with gradient ring
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        SidebarDesign.primary,
                        SidebarDesign.primaryDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: SidebarDesign.avatarShadow,
                  ),
                  child: CircleAvatar(
                    radius: _isTablet ? 48 : 42,
                    backgroundColor: SidebarDesign.surface,
                    child: CircleAvatar(
                      radius: _isTablet ? 45 : 39,
                      backgroundColor: SidebarDesign.primarySoft,
                      backgroundImage: _getProfileImage(),
                      child: _getProfileImage() == null
                          ? Text(
                        widget.userName.isNotEmpty
                            ? widget.userName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: _isTablet ? 28 : 24,
                          fontWeight: FontWeight.w800,
                          color: SidebarDesign.primary,
                          letterSpacing: -0.5,
                        ),
                      )
                          : null,
                    ),
                  ),
                ),

                // Online / edit badge
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: SidebarDesign.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: SidebarDesign.surface,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: SidebarDesign.primary.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: _isTablet ? 12 : 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: _isTablet ? 18 : 14),

          // User name
          Text(
            widget.userName,
            style: TextStyle(
              fontSize: _isTablet ? 19 : 17,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFF8FAFC)
                  : SidebarDesign.textPrimary,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // User email
          Text(
            widget.userEmail,
            style: TextStyle(
              fontSize: _isTablet ? 14 : 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF94A3B8)
                  : SidebarDesign.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: _isTablet ? 12 : 10),

          // Employee ID pill
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isTablet ? 14 : 12,
              vertical: _isTablet ? 6 : 5,
            ),
            decoration: BoxDecoration(
              color: SidebarDesign.primarySoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: SidebarDesign.primaryLight,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.badge_outlined,
                  color: SidebarDesign.primary,
                  size: _isTablet ? 14 : 12,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.employeeId,
                  style: TextStyle(
                    fontSize: _isTablet ? 12.5 : 11.5,
                    color: SidebarDesign.primaryDark,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== MENU ITEMS =====================

  Widget _buildMenuItems() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: _isTablet ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('MAIN'),
          _buildMenuItem(
            icon: Icons.home_outlined,
            title: "Home",
            onTap: () => Navigator.pop(widget.parentContext),
          ),
          _buildMenuItem(
            icon: Icons.person_outlined,
            title: "Profile",
            onTap: _navigateToProfile,
          ),
          _buildMenuItem(
            icon: Icons.open_in_browser,
            title: "Onboarding",
            onTap: _navigateToOnboarding,
          ),
          _buildMenuItem(
            icon: Icons.notification_add_outlined,
            title: "Notification",
            onTap: () => _navigateTo(const NotificationScreen()),
          ),

          SizedBox(height: _isTablet ? 16 : 12),
          _buildSectionLabel('WORK'),
          _buildMenuItem(
            icon: Icons.monetization_on_outlined,
            title: "Expenses",
            onTap: () => _navigateTo(const ExpenseListScreen()),
          ),
          _buildMenuItem(
            icon: Icons.forum_outlined,
            title: "Chat & Calls",
            onTap: () => _navigateTo(const ChatHomeScreen()),
          ),
          _buildMenuItem(
            icon: Icons.work_outline_rounded,
            title: "Project",
            onTap: () => _navigateTo(HomeScreen()),
          ),
          _buildMenuItem(
            icon: Icons.task_alt_rounded,
            title: "Task",
            onTap: () => _navigateTo(DailyTasksScreen()),
          ),
          _buildMenuItem(
            icon: Icons.face_retouching_natural,
            title: "Face",
            onTap: () => _navigateTo(FaceTestMenuScreen()),
          ),
          _buildMenuItem(
            icon: Icons.devices_rounded,
            title: "Assets",
            onTap: () => _navigateTo(const AssetsScreen()),
          ),
          _buildMenuItem(
            icon: Icons.policy_outlined,
            title: "Company Policies",
            onTap: () => _navigateTo(const PolicyScreen()),
          ),
          SizedBox(height: _isTablet ? 16 : 12),
          _buildMenuItem(
            icon: Icons.format_quote_rounded,
            title: "Quotes",
            onTap: () => _navigateTo(const QuotesListScreen()),
          ),

          SizedBox(height: _isTablet ? 16 : 12),
          _buildSectionLabel('SUPPORT'),
          _buildMenuItem(
            icon: Icons.help_outline_rounded,
            title: "Help & Support",
            onTap: () => _navigateTo(const HelpSupportPage()),
          ),
          _buildMenuItem(
            icon: Icons.question_answer_outlined,
            title: "FAQ",
            onTap: () => _navigateTo(const FAQScreen()),
          ),
          _buildMenuItem(
            icon: Icons.info_outline_rounded,
            title: "About",
            onTap: () => _navigateTo(const AboutPage()),
          ),

          SizedBox(height: _isTablet ? 16 : 12),
          _buildSectionLabel('DEVELOPER'),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: "Settings",
            onTap: () => _navigateTo(const SettingsPage()),
          ),
          SizedBox(height: _isTablet ? 20 : 16),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(
        left: _isTablet ? 16 : 14,
        top: _isTablet ? 8 : 6,
        bottom: _isTablet ? 8 : 6,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: _isTablet ? 11 : 10,
          fontWeight: FontWeight.w800,
          color: SidebarDesign.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : SidebarDesign.textPrimary;
    final iconBg = isDark ? const Color(0xFF28334E) : SidebarDesign.primarySoft;

    return Padding(
      padding: EdgeInsets.only(bottom: _isTablet ? 4 : 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(SidebarDesign.radiusMd),
          onTap: onTap,
          splashColor: SidebarDesign.primarySoft,
          highlightColor: SidebarDesign.primarySoft,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _isTablet ? 12 : 10,
              vertical: _isTablet ? 11 : 10,
            ),
            child: Row(
              children: [
                Container(
                  width: _isTablet ? 40 : 36,
                  height: _isTablet ? 40 : 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(
                      SidebarDesign.radiusSm,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: SidebarDesign.primary,
                    size: _isTablet ? 20 : 18,
                  ),
                ),
                SizedBox(width: _isTablet ? 14 : 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: _isTablet ? 15 : 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? const Color(0xFF64748B) : SidebarDesign.textMuted.withOpacity(0.6),
                  size: _isTablet ? 20 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================== LOGOUT BUTTON =====================

  Widget _buildLogoutButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dangerBg = isDark ? const Color(0xFF7F1D1D).withOpacity(0.25) : SidebarDesign.dangerSoft;
    final dangerBorder = isDark ? const Color(0xFF991B1B) : SidebarDesign.dangerBorder;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(SidebarDesign.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(SidebarDesign.radiusMd),
        onTap: _handleLogout,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: _isTablet ? 15 : 14,
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            color: dangerBg,
            borderRadius: BorderRadius.circular(SidebarDesign.radiusMd),
            border: Border.all(
              color: dangerBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: SidebarDesign.danger,
                size: _isTablet ? 20 : 18,
              ),
              SizedBox(width: _isTablet ? 10 : 8),
              Text(
                "Logout",
                style: TextStyle(
                  fontSize: _isTablet ? 15 : 14,
                  color: SidebarDesign.danger,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}