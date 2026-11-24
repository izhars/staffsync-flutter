import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({Key? key}) : super(key: key);

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  bool _hapticEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadHapticSetting();
  }

  Future<void> _loadHapticSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _hapticEnabled = prefs.getBool('haptic_enabled') ?? true;
    });
  }

  Future<void> _toggleHaptic(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic_enabled', value);
    if (!mounted) return;
    setState(() => _hapticEnabled = value);
  }

  void _triggerHaptic() {
    if (_hapticEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    final bg = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC);
    final surface = isDark ? const Color(0xFF1E2640) : Colors.white;
    final border = isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primary = isDark ? const Color(0xFF14B8A6) : const Color(0xFF0F766E);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Appearance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── SECTION: CHOOSE THEME ──
          _buildSectionHeader('THEME MODE', textSecondary),
          const SizedBox(height: 8),

          _buildThemeCard(
            title: 'System Default',
            subtitle: 'Match device light/dark appearance automatically',
            icon: Icons.brightness_auto_rounded,
            iconColor: const Color(0xFF3B82F6),
            iconBg: isDark ? const Color(0xFF1E3A8A).withOpacity(0.3) : const Color(0xFFEFF6FF),
            isSelected: themeProvider.themeMode == ThemeMode.system,
            onTap: () {
              _triggerHaptic();
              themeProvider.setThemeMode(ThemeMode.system);
            },
            surface: surface,
            border: border,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            primary: primary,
          ),
          const SizedBox(height: 10),

          _buildThemeCard(
            title: 'Light Mode',
            subtitle: 'Crisp, bright daylight appearance',
            icon: Icons.wb_sunny_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: isDark ? const Color(0xFF78350F).withOpacity(0.3) : const Color(0xFFFFFBEB),
            isSelected: themeProvider.themeMode == ThemeMode.light,
            onTap: () {
              _triggerHaptic();
              themeProvider.setThemeMode(ThemeMode.light);
            },
            surface: surface,
            border: border,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            primary: primary,
          ),
          const SizedBox(height: 10),

          _buildThemeCard(
            title: 'Dark Mode',
            subtitle: 'Sleek dark theme, reduces eye strain and saves battery',
            icon: Icons.nightlight_round,
            iconColor: const Color(0xFF8B5CF6),
            iconBg: isDark ? const Color(0xFF4C1D95).withOpacity(0.3) : const Color(0xFFF5F3FF),
            isSelected: themeProvider.themeMode == ThemeMode.dark,
            onTap: () {
              _triggerHaptic();
              themeProvider.setThemeMode(ThemeMode.dark);
            },
            surface: surface,
            border: border,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            primary: primary,
          ),
          const SizedBox(height: 28),

          // ── SECTION: LIVE PREVIEW ──
          _buildSectionHeader('LIVE PREVIEW', textSecondary),
          const SizedBox(height: 8),
          _buildLivePreview(
            isDark: isDark,
            surface: surface,
            border: border,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            primary: primary,
          ),
          const SizedBox(height: 28),

          // ── SECTION: DISPLAY PREFERENCES ──
          _buildSectionHeader('PREFERENCES', textSecondary),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF78350F).withOpacity(0.3)
                            : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.vibration_rounded,
                        color: Color(0xFFD97706),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Haptic Feedback',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Provide subtle vibrations on touch',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _hapticEnabled,
                      onChanged: _toggleHaptic,
                      activeColor: Colors.white,
                      activeTrackColor: primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Informational note
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Theme preferences are saved automatically and applied immediately across all screens in StaffSync.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildThemeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required bool isSelected,
    required VoidCallback onTap,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color primary,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? primary : border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
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
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? primary : border,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreview({
    required bool isDark,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color primary,
  }) {
    final previewCardBg = isDark ? const Color(0xFF141C2E) : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'JD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Doe',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Product Designer · StaffSync Team',
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: previewCardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 16,
                  color: primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ready for today\'s daily standup call?',
                    style: TextStyle(
                      fontSize: 12,
                      color: textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Start Call',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Message',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
