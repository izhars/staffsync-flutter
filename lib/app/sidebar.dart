import 'dart:io';
import 'package:flutter/material.dart';
import 'package:staffsync/component/test.dart';
import 'package:staffsync/screens/QuotesListScreen.dart';
import 'package:staffsync/screens/aqi_screen.dart';
import 'package:staffsync/screens/assets_screen.dart';
import 'package:staffsync/screens/faq_screen.dart';
import 'package:staffsync/screens/notification_screen.dart';
import 'package:staffsync/screens/profile_screen.dart';
import '../screens/TranslationScreen.dart';
import '../screens/aqi_map_screen.dart';
import '../screens/about_page.dart';
import '../screens/help_and_support.dart';

class Sidebar extends StatelessWidget {
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

  // Check if device is tablet
  bool get _isTablet {
    final mediaQuery = MediaQuery.of(parentContext);
    final shortestSide = mediaQuery.size.shortestSide;
    return shortestSide > 600; // Typical tablet threshold
  }

  // Get drawer width based on device type
  double get _drawerWidth {
    if (_isTablet) {
      final screenWidth = MediaQuery.of(parentContext).size.width;
      // Use 30% of screen width for tablet, but max 400
      return screenWidth * 0.3 < 400 ? screenWidth * 0.3 : 400;
    }
    return 304; // Standard mobile width
  }

  void _navigateTo(Widget page) {
    Navigator.pop(parentContext);
    Navigator.push(
      parentContext,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _navigateToProfile() {
    Navigator.pop(parentContext);
    Navigator.push(
      parentContext,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _handleLogout() {
    Navigator.pop(parentContext);
    onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      width: _drawerWidth, // Responsive width
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.grey[900]!, Colors.grey[800]!]
                : [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea( // Add SafeArea to prevent pixel errors
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: _isTablet ? 40 : 20),

              // Profile Section
              _buildProfileSection(),

              SizedBox(height: _isTablet ? 40 : 32),

              // Menu Items
              Expanded(
                child: _buildMenuItems(),
              ),

              // Logout Button
              Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(parentContext).viewInsets.bottom > 0
                      ? MediaQuery.of(parentContext).viewInsets.bottom + 16
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

  Widget _buildProfileSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _isTablet ? 24 : 16),
      child: Column(
        children: [
          // Avatar
          GestureDetector(
            onTap: _navigateToProfile,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: _isTablet ? 50 : 42,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: _isTablet ? 48 : 40,
                  backgroundImage: avatarFile != null
                      ? FileImage(avatarFile!)
                      : const AssetImage('assets/profile.png') as ImageProvider,
                ),
              ),
            ),
          ),
          SizedBox(height: _isTablet ? 20 : 16),

          // User Name
          Text(
            userName,
            style: TextStyle(
              fontSize: _isTablet ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: _isTablet ? 8 : 4),

          // User Email
          Text(
            userEmail,
            style: TextStyle(
              fontSize: _isTablet ? 15 : 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: _isTablet ? 8 : 4),

          // Employee ID
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isTablet ? 16 : 12,
              vertical: _isTablet ? 6 : 4,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "ID: $employeeId",
              style: TextStyle(
                fontSize: _isTablet ? 13 : 12,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _isTablet ? 20 : 16),
        child: Column(
          children: [
            _buildMenuItem(
              icon: Icons.home_outlined,
              title: "Home",
              onTap: () => Navigator.pop(parentContext),
            ),
            _buildMenuItem(
              icon: Icons.person_outlined,
              title: "Profile",
              onTap: _navigateToProfile,
            ),
            _buildMenuItem(
              icon: Icons.settings_outlined,
              title: "Settings",
              onTap: () => _navigateTo(const SettingsPage()),
            ),
            _buildMenuItem(
              icon: Icons.help_outline,
              title: "Help & Support",
              onTap: () => _navigateTo(const HelpSupportPage()),
            ),
            _buildMenuItem(
              icon: Icons.info_outline,
              title: "About",
              onTap: () => _navigateTo(const AboutPage()),
            ),
            _buildMenuItem(
              icon: Icons.question_answer,
              title: "FAQ",
              onTap: () => _navigateTo(const FAQScreen()),
            ),
            _buildMenuItem(
              icon: Icons.air,
              title: "AQI",
              onTap: () => _navigateTo(AQIScreen()),
            ),
            _buildMenuItem(
              icon: Icons.map,
              title: "Map",
              onTap: () => _navigateTo(AQIMapScreen()),
            ),
            _buildMenuItem(
              icon: Icons.devices_rounded,
              title: "Assets",
              onTap: () => _navigateTo(const AssetsScreen()),
            ),
            _buildMenuItem(
              icon: Icons.adb,
              title: "Test",
              onTap: () => _navigateTo(const TestScreen()),
            ),
            _buildMenuItem(
              icon: Icons.notification_add,
              title: "Notification",
              onTap: () => _navigateTo(const NotificationScreen()),
            ),
            _buildMenuItem(
              icon: Icons.format_quote,
              title: "Quotes",
              onTap: () => _navigateTo(const QuotesListScreen()),
            ),
            SizedBox(height: _isTablet ? 20 : 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: _isTablet ? 10 : 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: _isTablet ? 14 : 12,
              horizontal: 12,
            ),
            child: Row(
              children: [
                Container(
                  width: _isTablet ? 48 : 40,
                  height: _isTablet ? 48 : 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.blue.shade700,
                    size: _isTablet ? 22 : 20,
                  ),
                ),
                SizedBox(width: _isTablet ? 16 : 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: _isTablet ? 16 : 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: _isTablet ? 22 : 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Material(
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _handleLogout,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: _isTablet ? 18 : 16,
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout,
                color: Colors.red.shade600,
                size: _isTablet ? 22 : 20,
              ),
              SizedBox(width: _isTablet ? 12 : 8),
              Text(
                "Logout",
                style: TextStyle(
                  fontSize: _isTablet ? 16 : 15,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: const Center(child: Text('Settings Page')),
  );
}