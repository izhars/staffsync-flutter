import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../component/connectivity_wrapper.dart';
import '../models/Asset.dart';
import '../services/assets_service.dart';
import '../services/connectivity_service.dart';

// ===================== SHARED DESIGN TOKENS =====================
// (Copy this class into a shared file, e.g. `lib/theme/report_design.dart`,
// and import it from both ReportScreen and AssetsScreen.)
class AssetsDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primarySoft = Color(0xFFEEF2FF);
  static const Color primaryLight = Color(0xFFC7D2FE);

  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color bg = Color(0xFFF6F7FB);
  static const Color border = Color(0xFFEAECEF);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color present = Color(0xFF059669);
  static const Color presentSoft = Color(0xFFECFDF5);
  static const Color presentBorder = Color(0xFFA7F3D0);

  static const Color late = Color(0xFFD97706);
  static const Color lateSoft = Color(0xFFFFFBEB);
  static const Color lateBorder = Color(0xFFFDE68A);

  static const Color short = Color(0xFFEA580C);
  static const Color shortSoft = Color(0xFFFFF7ED);
  static const Color shortBorder = Color(0xFFFED7AA);

  static const Color absent = Color(0xFFDC2626);
  static const Color absentSoft = Color(0xFFFEF2F2);
  static const Color absentBorder = Color(0xFFFECACA);

  static const Color leave = Color(0xFF7C3AED);
  static const Color leaveSoft = Color(0xFFF5F3FF);
  static const Color leaveBorder = Color(0xFFDDD6FE);

  static const Color holiday = Color(0xFF2563EB);
  static const Color holidaySoft = Color(0xFFEFF6FF);
  static const Color holidayBorder = Color(0xFFBFDBFE);

  static const Color comboOff = Color(0xFF0D9488);
  static const Color comboOffSoft = Color(0xFFF0FDFA);
  static const Color comboOffBorder = Color(0xFF99F6E4);

  static const Color neutral = Color(0xFF6B7280);
  static const Color neutralSoft = Color(0xFFF3F4F6);
  static const Color neutralBorder = Color(0xFFE5E7EB);

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
}

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({Key? key}) : super(key: key);

  @override
  _AssetsScreenState createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  final AssetsService _assetsService = AssetsService();
  final ConnectivityService _connectivityService = ConnectivityService();
  List<Asset> _assets = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadAssets();
    _connectivityService.connectionStream.listen((hasConnection) {
      if (hasConnection && !_isLoading && _errorMessage != null) {
        _loadAssets();
      }
    });
  }

  Future<void> _loadAssets() async {
    try {
      final hasConnection = await _connectivityService.hasConnection();
      if (!hasConnection) {
        setState(() {
          _errorMessage =
          'No internet connection. Please check your connection and try again.';
          _isLoading = false;
        });
        return;
      }
      final assets = await _assetsService.getMyAssets();
      setState(() {
        _assets = assets;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load assets. Please try again.';
        _isLoading = false;
      });
    }
  }

  List<Asset> get _filteredAssets {
    if (_selectedFilter == 'all') return _assets;
    return _assets.where((asset) => asset.category == _selectedFilter).toList();
  }

  Set<String> get _categories =>
      _assets.map((asset) => asset.category).toSet();

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AssetsDesign.bg,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ConnectivityWrapper(
                onRetry: _loadAssets,
                child: _isLoading
                    ? _buildLoadingState()
                    : _errorMessage != null
                    ? _buildErrorState()
                    : _buildSuccessState(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== HEADER (mirrors ReportScreen) =====================

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AssetsDesign.primary, AssetsDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AssetsDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: AssetsDesign.primary.withOpacity(0.25),
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
            AssetsDesign.md,
            AssetsDesign.sm,
            AssetsDesign.md,
            AssetsDesign.md,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius:
                    BorderRadius.circular(AssetsDesign.radiusSm),
                    child: InkWell(
                      borderRadius:
                      BorderRadius.circular(AssetsDesign.radiusSm),
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AssetsDesign.sm + 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Assets',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Hardware & equipment assigned to you',
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
                    BorderRadius.circular(AssetsDesign.radiusSm),
                    child: InkWell(
                      borderRadius:
                      BorderRadius.circular(AssetsDesign.radiusSm),
                      onTap: _loadAssets,
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AssetsDesign.md),
              // Segmented pill bar for filters (replaces FilterChip row)
              _buildFilterBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = <Map<String, String>>[
      {'key': 'all', 'label': 'All (${_assets.length})'},
      ..._categories.map((c) {
        final count = _assets.where((a) => a.category == c).length;
        return {'key': c, 'label': '${_capitalizeFirst(c)} ($count)'};
      }),
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AssetsDesign.radiusMd),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, i) {
          final f = filters[i];
          final isSelected = _selectedFilter == f['key'];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
              const EdgeInsets.symmetric(horizontal: AssetsDesign.md),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? AssetsDesign.surface
                    : Colors.transparent,
                borderRadius:
                BorderRadius.circular(AssetsDesign.radiusSm),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                    : null,
              ),
              child: Text(
                f['label']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? AssetsDesign.primary
                      : Colors.white.withOpacity(0.85),
                  letterSpacing: -0.1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===================== LOADING / ERROR / EMPTY =====================

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 3,
        color: AssetsDesign.primary,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AssetsDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(
                color: AssetsDesign.absentSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 46,
                color: AssetsDesign.absent,
              ),
            ),
            const SizedBox(height: AssetsDesign.lg),
            const Text(
              'Failed to load assets',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AssetsDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AssetsDesign.sm),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AssetsDesign.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AssetsDesign.lg),
            ElevatedButton.icon(
              onPressed: _loadAssets,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AssetsDesign.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AssetsDesign.lg,
                  vertical: AssetsDesign.sm + 4,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(AssetsDesign.radiusSm),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    if (_assets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AssetsDesign.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: const BoxDecoration(
                  color: AssetsDesign.neutralSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 46,
                  color: AssetsDesign.textMuted,
                ),
              ),
              const SizedBox(height: AssetsDesign.lg),
              const Text(
                'No assets assigned yet',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AssetsDesign.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AssetsDesign.sm),
              const Text(
                'Check back later or contact IT support',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AssetsDesign.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssets,
      color: AssetsDesign.primary,
      backgroundColor: AssetsDesign.surface,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AssetsDesign.md,
          AssetsDesign.md,
          AssetsDesign.md,
          AssetsDesign.xl,
        ),
        children: [
          _buildStatsCard(),
          const SizedBox(height: AssetsDesign.md),
          ..._filteredAssets.map(
                (a) => Padding(
              padding: const EdgeInsets.only(bottom: AssetsDesign.md),
              child: _buildAssetCard(a),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== STATS CARD =====================

  Widget _buildStatsCard() {
    final totalValue = _assets.fold<double>(
      0,
          (sum, asset) => sum + (asset.purchasePrice ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(AssetsDesign.md),
      decoration: BoxDecoration(
        color: AssetsDesign.surface,
        borderRadius: BorderRadius.circular(AssetsDesign.radiusLg),
        border: Border.all(color: AssetsDesign.border, width: 1),
        boxShadow: AssetsDesign.softShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatTile(
              icon: Icons.inventory_2_rounded,
              label: 'TOTAL ASSETS',
              value: '₹${_assets.length}',
              color: AssetsDesign.primary,
              bg: AssetsDesign.primarySoft,
              border: AssetsDesign.primaryLight,
            ),
          ),
          const SizedBox(width: AssetsDesign.sm + 2),
          Expanded(
            child: _buildStatTile(
              icon: Icons.currency_rupee,
              label: 'TOTAL VALUE',
              value: '\₹${totalValue.toStringAsFixed(0)}',
              color: AssetsDesign.present,
              bg: AssetsDesign.presentSoft,
              border: AssetsDesign.presentBorder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.all(AssetsDesign.sm + 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AssetsDesign.radiusSm + 2),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: AssetsDesign.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===================== ASSET CARD =====================

  Widget _buildAssetCard(Asset asset) {
    final catColor = _getCategoryColor(asset.category);

    return Material(
      color: AssetsDesign.surface,
      borderRadius: BorderRadius.circular(AssetsDesign.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AssetsDesign.radiusLg),
        onTap: () => _showAssetDetails(asset),
        child: Container(
          padding: const EdgeInsets.all(AssetsDesign.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AssetsDesign.radiusLg),
            border: Border.all(color: AssetsDesign.border, width: 1),
            boxShadow: AssetsDesign.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.15),
                      borderRadius:
                      BorderRadius.circular(AssetsDesign.radiusSm),
                    ),
                    child: Icon(
                      _getCategoryIcon(asset.category),
                      color: catColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AssetsDesign.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AssetsDesign.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          asset.brandModelDisplay,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AssetsDesign.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AssetsDesign.sm),
                  _buildStatusBadge(asset.status),
                ],
              ),
              const SizedBox(height: AssetsDesign.md),
              Container(height: 1, color: AssetsDesign.border),
              const SizedBox(height: AssetsDesign.sm + 2),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.category_outlined,
                    _capitalizeFirst(asset.category),
                  ),
                  const SizedBox(width: AssetsDesign.sm),
                  _buildInfoChip(
                    Icons.verified_outlined,
                    _capitalizeFirst(asset.condition),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: AssetsDesign.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(asset.assignedDate),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AssetsDesign.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final (color, bg, border) = _statusStyle(status);
    final icon = _statusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AssetsDesign.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AssetsDesign.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AssetsDesign.neutralSoft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AssetsDesign.neutralBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AssetsDesign.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AssetsDesign.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== DETAILS SHEET =====================

  void _showAssetDetails(Asset asset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AssetsDesign.radiusXl),
        ),
      ),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AssetsDesign.radiusXl),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: AssetsDesign.surface.withOpacity(0.94),
            child: DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) => SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: AssetsDesign.lg,
                    right: AssetsDesign.lg,
                    bottom:
                    MediaQuery.of(context).viewInsets.bottom + AssetsDesign.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          margin: const EdgeInsets.symmetric(
                              vertical: AssetsDesign.sm + 4),
                          decoration: BoxDecoration(
                            color: AssetsDesign.neutralBorder,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      _buildDetailHeader(asset),
                      const SizedBox(height: AssetsDesign.lg),
                      _buildSectionCard(
                        title: 'Asset Details',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailTile('Brand', asset.brand ?? 'N/A'),
                            _buildDetailTile('Model', asset.model ?? 'N/A'),
                            _buildDetailTile(
                              'Category',
                              _capitalizeFirst(asset.category),
                            ),
                            _buildDetailTile(
                              'Condition',
                              _capitalizeFirst(asset.condition),
                              leading: Icon(
                                _getConditionIcon(asset.condition),
                                color: _getConditionColor(asset.condition),
                                size: 18,
                              ),
                            ),
                            if (asset.location != null &&
                                asset.location!.isNotEmpty)
                              _buildDetailTile('Location', asset.location!),
                            if (asset.purchaseDate != null)
                              _buildDetailTile(
                                'Purchase Date',
                                _formatDate(asset.purchaseDate),
                                leading: const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                ),
                              ),
                            if (asset.assignedDate != null)
                              _buildDetailTile(
                                'Assigned Date',
                                _formatDate(asset.assignedDate),
                                leading: const Icon(
                                  Icons.date_range_outlined,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (asset.hasAssignmentHistory) ...[
                        const SizedBox(height: AssetsDesign.md),
                        _buildSectionCard(
                          title: 'Assignment History',
                          subtitle:
                          'Total: ${asset.totalAssignments}',
                          child: Column(
                            children: [
                              ...asset.assignmentHistory
                                  .map((r) => _buildAssignmentHistoryCard(r))
                                  .toList(),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AssetsDesign.xl),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Close Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AssetsDesign.neutralSoft,
                            foregroundColor: AssetsDesign.textPrimary,
                            padding: const EdgeInsets.symmetric(
                                vertical: AssetsDesign.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AssetsDesign.radiusMd),
                            ),
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AssetsDesign.md),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailHeader(Asset asset) {
    final catColor = _getCategoryColor(asset.category);
    return Container(
      padding: const EdgeInsets.all(AssetsDesign.md),
      decoration: BoxDecoration(
        color: AssetsDesign.primarySoft,
        borderRadius: BorderRadius.circular(AssetsDesign.radiusLg),
        border: Border.all(color: AssetsDesign.primaryLight, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AssetsDesign.radiusMd),
            ),
            child: Icon(
              _getCategoryIcon(asset.category),
              color: catColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AssetsDesign.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AssetsDesign.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'ID: ${asset.assetId}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AssetsDesign.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(asset.status),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AssetsDesign.surface,
        borderRadius: BorderRadius.circular(AssetsDesign.radiusLg),
        border: Border.all(color: AssetsDesign.border, width: 1),
        boxShadow: AssetsDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AssetsDesign.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AssetsDesign.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AssetsDesign.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Container(height: 1, color: AssetsDesign.border),
          Padding(
            padding: const EdgeInsets.all(AssetsDesign.md),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(String label, String value, {Widget? leading}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AssetsDesign.xs + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: AssetsDesign.sm + 4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AssetsDesign.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AssetsDesign.textPrimary,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentHistoryCard(AssignmentRecord record) {
    final returned = record.returnedDate != null;
    final (color, bg, border) = returned
        ? (AssetsDesign.neutral, AssetsDesign.neutralSoft,
    AssetsDesign.neutralBorder)
        : (AssetsDesign.present, AssetsDesign.presentSoft,
    AssetsDesign.presentBorder);

    return Container(
      margin: const EdgeInsets.only(bottom: AssetsDesign.sm),
      padding: const EdgeInsets.all(AssetsDesign.sm + 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AssetsDesign.radiusMd),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Employee: ${record.employee.substring(0, 8)}...',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AssetsDesign.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AssetsDesign.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  returned ? 'RETURNED' : 'ACTIVE',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AssetsDesign.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned: ${_formatDateShort(record.assignedDate)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AssetsDesign.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (record.returnedDate != null)
                      Text(
                        'Returned: ${_formatDateShort(record.returnedDate!)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AssetsDesign.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AssetsDesign.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: _getConditionColor(record.condition)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  record.condition.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: _getConditionColor(record.condition),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          if (record.remarks.isNotEmpty) ...[
            const SizedBox(height: AssetsDesign.sm),
            Text(
              record.remarks,
              style: const TextStyle(
                fontSize: 11,
                color: AssetsDesign.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===================== STATUS / COLOR HELPERS =====================

  (Color, Color, Color) _statusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return (AssetsDesign.present, AssetsDesign.presentSoft,
        AssetsDesign.presentBorder);
      case 'available':
        return (AssetsDesign.holiday, AssetsDesign.holidaySoft,
        AssetsDesign.holidayBorder);
      case 'maintenance':
        return (AssetsDesign.late, AssetsDesign.lateSoft,
        AssetsDesign.lateBorder);
      case 'retired':
        return (AssetsDesign.absent, AssetsDesign.absentSoft,
        AssetsDesign.absentBorder);
      default:
        return (AssetsDesign.neutral, AssetsDesign.neutralSoft,
        AssetsDesign.neutralBorder);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Icons.check_circle_rounded;
      case 'available':
        return Icons.circle_outlined;
      case 'maintenance':
        return Icons.build_circle_rounded;
      case 'retired':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'laptop':
        return AssetsDesign.holiday;
      case 'desktop':
        return AssetsDesign.primary;
      case 'mobile':
      case 'phone':
        return AssetsDesign.present;
      case 'tablet':
        return AssetsDesign.short;
      case 'accessories':
        return AssetsDesign.leave;
      case 'furniture':
        return AssetsDesign.comboOff;
      default:
        return AssetsDesign.neutral;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'laptop':
        return Icons.laptop_mac_rounded;
      case 'desktop':
        return Icons.desktop_windows_rounded;
      case 'mobile':
      case 'phone':
        return Icons.phone_android_rounded;
      case 'tablet':
        return Icons.tablet_mac_rounded;
      case 'accessories':
        return Icons.headphones_rounded;
      case 'furniture':
        return Icons.chair_alt_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent':
        return AssetsDesign.present;
      case 'good':
        return AssetsDesign.holiday;
      case 'fair':
        return AssetsDesign.late;
      case 'poor':
        return AssetsDesign.absent;
      default:
        return AssetsDesign.neutral;
    }
  }

  IconData _getConditionIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent':
        return Icons.star_rounded;
      case 'good':
        return Icons.star_half_rounded;
      case 'fair':
        return Icons.star_border_rounded;
      case 'poor':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    try {
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return 'N/A';
    }
  }

  String _formatDateShort(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}