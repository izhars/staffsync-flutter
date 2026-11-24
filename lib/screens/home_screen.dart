// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:staffsync/screens/project_roles_screen.dart';
import '../component/add_role_dialog.dart';
import 'projects_screen.dart';
import 'team_mmodule.dart' hide ProjectDesign;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  static const List<Map<String, dynamic>> _tabs = [
    {'text': 'Projects', 'icon': Icons.folder_copy_outlined},
    {'text': 'Roles', 'icon': Icons.badge_outlined},
    {'text': 'Team', 'icon': Icons.groups_2_outlined},
    {'text': 'Reports', 'icon': Icons.insights_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _selectedIndex = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ProjectDesign.bg,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: const [
                  ProjectsScreen(),
                  ProjectRolesScreen(),
                  TeamMembersPage(),
                  _ReportsComingSoon(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ProjectDesign.primary, ProjectDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(ProjectDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: ProjectDesign.primary.withOpacity(0.25),
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
            ProjectDesign.sm,
            ProjectDesign.sm,
            ProjectDesign.sm,
            ProjectDesign.md,
          ),
          child: Column(
            children: [
              _buildTopRow(),
              const SizedBox(height: ProjectDesign.sm + 4),
              _buildTabBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        // Back button
        _buildIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: ProjectDesign.sm),

        // Title block
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Projects',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Manage your team and work',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Notification button
        _buildIconButton(
          icon: Icons.notifications_none_rounded,
          showDot: true,
          onTap: () {},
        ),
        const SizedBox(width: ProjectDesign.sm),
        // Search button
        _buildIconButton(
          icon: Icons.search_rounded,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool showDot = false,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              if (showDot)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ProjectDesign.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: ProjectDesign.surface,
          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.zero,
        labelColor: ProjectDesign.primary,
        unselectedLabelColor: Colors.white.withOpacity(0.85),
        labelPadding: EdgeInsets.zero,
        splashFactory: NoSplash.splashFactory,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
          letterSpacing: -0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
          letterSpacing: -0.1,
        ),
        tabs: _tabs.map((tab) {
          return Tab(
            height: 44,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tab['icon'] as IconData, size: 17),
                const SizedBox(height: 3),
                Text(tab['text'] as String),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // (Optional) kept for external callers – not used internally anymore
  void _showAddRoleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddRoleDialog(),
    );
  }
}

// ===================== REPORTS COMING SOON =====================

class _ReportsComingSoon extends StatelessWidget {
  const _ReportsComingSoon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ProjectDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(
                color: ProjectDesign.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insights_outlined,
                size: 46,
                color: ProjectDesign.primary,
              ),
            ),
            const SizedBox(height: ProjectDesign.lg),
            const Text(
              'Reports Module',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: ProjectDesign.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: ProjectDesign.sm),
            const Text(
              'View detailed analytics and project insights.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: ProjectDesign.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: ProjectDesign.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ProjectDesign.md,
                vertical: ProjectDesign.sm,
              ),
              decoration: BoxDecoration(
                color: ProjectDesign.primarySoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ProjectDesign.primaryLight,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: ProjectDesign.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: ProjectDesign.primary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}