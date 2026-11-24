// lib/screens/policy_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/company_policy.dart';
import '../services/api_exception.dart';
import '../services/policy_service.dart';

// ===================== DESIGN TOKENS =====================
class PolicyDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  static const Color primary = Color(0xFF1E40AF); // Professional Blue
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color primarySoft = Color(0xFFEFF6FF);
  static const Color primaryLight = Color(0xFFBFDBFE);

  static const Color bg = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color success = Color(0xFF059669);
  static const Color successSoft = Color(0xFFD1FAE5);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFEF3C7);
}

class PolicyScreen extends StatefulWidget {
  const PolicyScreen({super.key});

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  final PolicyService _service = PolicyService();

  List<CompanyPolicy> _policies = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  String _selectedCategory = 'all';
  String _filterMode = 'all'; // all, pending, acknowledged
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPolicies();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPolicies({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() => _isRefreshing = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final list = await _service.getPolicies(
        category: _selectedCategory != 'all' ? _selectedCategory : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (!mounted) return;
      setState(() {
        _policies = list;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is ApiException ? e.message : e.toString();
        _isLoading = false;
      });
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _acknowledgePolicy(CompanyPolicy policy, String comments) async {
    try {
      final res = await _service.acknowledgePolicy(policy.id, comments: comments);
      if (!mounted) return;

      // Optimistic update
      setState(() {
        policy.isAcknowledged = true;
        policy.acknowledgedAt = DateTime.now();
        policy.acknowledgedVersion = policy.version;
      });

      _showSnackBar(
        res['message']?.toString() ?? 'Policy acknowledged successfully',
      );
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Failed to acknowledge policy';
      _showSnackBar(msg, isError: true);
    }
  }

  Future<void> _launchDocumentUrl(String url) async {
    if (url.isEmpty) {
      _showSnackBar('No document link available', isError: true);
      return;
    }
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not launch document viewer', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error opening file: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? PolicyDesign.danger : PolicyDesign.success,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PolicyDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(PolicyDesign.md),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<CompanyPolicy> get _filteredPolicies {
    return _policies.where((p) {
      // Category filter
      if (_selectedCategory != 'all' && p.category != _selectedCategory) {
        return false;
      }
      // Status filter tab
      if (_filterMode == 'pending' && p.isAcknowledged) {
        return false;
      }
      if (_filterMode == 'acknowledged' && !p.isAcknowledged) {
        return false;
      }
      // Search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = p.title.toLowerCase().contains(q);
        final matchesDesc = p.description.toLowerCase().contains(q);
        if (!matchesTitle && !matchesDesc) return false;
      }
      return true;
    }).toList();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPolicies;
    final totalMandatory = _policies.where((p) => p.isMandatory).length;
    final acknowledgedMandatory = _policies.where((p) => p.isMandatory && p.isAcknowledged).length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: PolicyDesign.bg,
        body: Column(
          children: [
            _buildHeader(totalMandatory, acknowledgedMandatory),
            _buildCategoryTabs(),
            _buildSearchAndFilterBar(),
            Expanded(
              child: _buildBody(filtered),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader(int totalMandatory, int ackMandatory) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [PolicyDesign.primary, PolicyDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(PolicyDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: PolicyDesign.primary.withValues(alpha: 0.25),
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
            PolicyDesign.md,
            PolicyDesign.sm,
            PolicyDesign.md,
            PolicyDesign.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(PolicyDesign.radiusSm),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(PolicyDesign.radiusSm),
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
                  const SizedBox(width: PolicyDesign.sm + 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Company Policies',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Review guidelines, versioning & mandatory sign-offs',
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
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(PolicyDesign.radiusSm),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(PolicyDesign.radiusSm),
                      onTap: () => _fetchPolicies(isRefresh: true),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: _isRefreshing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              if (totalMandatory > 0) ...[
                const SizedBox(height: PolicyDesign.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(PolicyDesign.radiusMd),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Compliance Progress: $ackMandatory of $totalMandatory signed',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: totalMandatory > 0 ? (ackMandatory / totalMandatory) : 1.0,
                                minHeight: 5,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Categories Filter Bar ───
  Widget _buildCategoryTabs() {
    final categories = [
      {'key': 'all', 'label': 'All', 'icon': Icons.apps_rounded},
      {'key': 'attendance', 'label': 'Attendance', 'icon': Icons.alarm_on_rounded},
      {'key': 'leave', 'label': 'Leave', 'icon': Icons.beach_access_rounded},
      {'key': 'payroll', 'label': 'Payroll', 'icon': Icons.account_balance_wallet_rounded},
      {'key': 'reimbursement', 'label': 'Reimbursement', 'icon': Icons.receipt_long_rounded},
      {'key': 'code_of_conduct', 'label': 'Code of Conduct', 'icon': Icons.verified_user_rounded},
      {'key': 'it_security', 'label': 'IT Security', 'icon': Icons.security_rounded},
      {'key': 'employment', 'label': 'Employment', 'icon': Icons.business_center_rounded},
      {'key': 'wfh', 'label': 'WFH', 'icon': Icons.home_work_rounded},
    ];

    return Container(
      color: PolicyDesign.bg,
      padding: const EdgeInsets.only(top: PolicyDesign.md, bottom: PolicyDesign.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: PolicyDesign.md),
        child: Row(
          children: categories.map((cat) {
            final isSelected = _selectedCategory == cat['key'];
            return GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = cat['key'] as String);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: PolicyDesign.sm),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? PolicyDesign.primarySoft : PolicyDesign.surface,
                  borderRadius: BorderRadius.circular(PolicyDesign.radiusMd),
                  border: Border.all(
                    color: isSelected ? PolicyDesign.primaryLight : PolicyDesign.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 15,
                      color: isSelected ? PolicyDesign.primary : PolicyDesign.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? PolicyDesign.primaryDark : PolicyDesign.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Search and Mode Filter Bar ───
  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(PolicyDesign.md, PolicyDesign.sm, PolicyDesign.md, PolicyDesign.sm),
      child: Row(
        children: [
          // Search box
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: PolicyDesign.surface,
                borderRadius: BorderRadius.circular(PolicyDesign.radiusSm),
                border: Border.all(color: PolicyDesign.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 18, color: PolicyDesign.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(fontSize: 13, color: PolicyDesign.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Search policies...',
                        hintStyle: TextStyle(fontSize: 12.5, color: PolicyDesign.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(Icons.close_rounded, size: 16, color: PolicyDesign.textMuted),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: PolicyDesign.sm),

          // Pending filter pill
          GestureDetector(
            onTap: () {
              setState(() {
                if (_filterMode == 'all') {
                  _filterMode = 'pending';
                } else if (_filterMode == 'pending') {
                  _filterMode = 'acknowledged';
                } else {
                  _filterMode = 'all';
                }
              });
            },
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _filterMode != 'all' ? PolicyDesign.primarySoft : PolicyDesign.surface,
                borderRadius: BorderRadius.circular(PolicyDesign.radiusSm),
                border: Border.all(
                  color: _filterMode != 'all' ? PolicyDesign.primaryLight : PolicyDesign.border,
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  Icon(
                    _filterMode == 'pending'
                        ? Icons.pending_actions_rounded
                        : _filterMode == 'acknowledged'
                            ? Icons.task_alt_rounded
                            : Icons.filter_list_rounded,
                    size: 16,
                    color: _filterMode != 'all' ? PolicyDesign.primary : PolicyDesign.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _filterMode == 'pending'
                        ? 'Pending'
                        : _filterMode == 'acknowledged'
                            ? 'Signed'
                            : 'Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _filterMode != 'all' ? PolicyDesign.primaryDark : PolicyDesign.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Body List ───
  Widget _buildBody(List<CompanyPolicy> policies) {
    if (_isLoading && !_isRefreshing) {
      return const Center(
        child: CircularProgressIndicator(
          color: PolicyDesign.primary,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_errorMessage != null && _policies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(PolicyDesign.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 36, color: PolicyDesign.danger),
              const SizedBox(height: PolicyDesign.sm),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: PolicyDesign.textMuted, fontSize: 13),
              ),
              const SizedBox(height: PolicyDesign.md),
              ElevatedButton.icon(
                onPressed: () => _fetchPolicies(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PolicyDesign.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (policies.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: PolicyDesign.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.description_outlined, size: 36, color: PolicyDesign.primary),
            ),
            const SizedBox(height: PolicyDesign.md),
            const Text(
              'No policies found',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: PolicyDesign.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'No matching policies in this category.',
              style: TextStyle(fontSize: 12, color: PolicyDesign.textMuted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: PolicyDesign.primary,
      onRefresh: () => _fetchPolicies(isRefresh: true),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(
          PolicyDesign.md,
          PolicyDesign.xs,
          PolicyDesign.md,
          PolicyDesign.lg,
        ),
        itemCount: policies.length,
        separatorBuilder: (_, __) => const SizedBox(height: PolicyDesign.sm + 4),
        itemBuilder: (context, index) {
          final p = policies[index];
          return _buildPolicyCard(p);
        },
      ),
    );
  }

  // ─── Policy Card ───
  Widget _buildPolicyCard(CompanyPolicy p) {
    return Container(
      decoration: BoxDecoration(
        color: PolicyDesign.surface,
        borderRadius: BorderRadius.circular(PolicyDesign.radiusMd),
        border: Border.all(color: PolicyDesign.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(PolicyDesign.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: category & version & mandatory pill
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: p.categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(PolicyDesign.radiusSm),
                ),
                child: Icon(p.categoryIcon, size: 18, color: p.categoryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          p.categoryDisplay.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: p.categoryColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: PolicyDesign.surfaceMuted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'v${p.version}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: PolicyDesign.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Effective: ${_formatDate(p.effectiveDate)}',
                      style: const TextStyle(fontSize: 11, color: PolicyDesign.textMuted),
                    ),
                  ],
                ),
              ),
              if (p.isMandatory)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: PolicyDesign.dangerSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'MANDATORY',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: PolicyDesign.danger,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            p.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: PolicyDesign.textPrimary,
              letterSpacing: -0.2,
            ),
          ),

          if (p.description.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              p.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: PolicyDesign.textSecondary,
                height: 1.45,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Acknowledged status row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: p.isAcknowledged ? PolicyDesign.successSoft : PolicyDesign.warningSoft,
              borderRadius: BorderRadius.circular(PolicyDesign.radiusSm),
            ),
            child: Row(
              children: [
                Icon(
                  p.isAcknowledged ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                  size: 15,
                  color: p.isAcknowledged ? PolicyDesign.success : PolicyDesign.warning,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    p.isAcknowledged
                        ? 'Acknowledged on ${_formatDate(p.acknowledgedAt)} (v${p.acknowledgedVersion ?? p.version})'
                        : p.isMandatory
                            ? 'Acknowledgement required'
                            : 'Optional review',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: p.isAcknowledged ? PolicyDesign.success : PolicyDesign.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openPolicyDetailSheet(p),
                  icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
                  label: const Text('Read Policy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PolicyDesign.primary,
                    side: const BorderSide(color: PolicyDesign.primaryLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PolicyDesign.radiusSm),
                    ),
                    textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (p.documentUrl.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _launchDocumentUrl(p.documentUrl),
                  icon: const Icon(Icons.download_rounded),
                  color: PolicyDesign.primary,
                  tooltip: 'Download Document',
                  style: IconButton.styleFrom(
                    backgroundColor: PolicyDesign.primarySoft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PolicyDesign.radiusSm),
                    ),
                  ),
                ),
              ],
              if (!p.isAcknowledged) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openPolicyDetailSheet(p),
                    icon: const Icon(Icons.draw_rounded, size: 16),
                    label: const Text('Sign-off'),
                    style: FilledButton.styleFrom(
                      backgroundColor: PolicyDesign.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(PolicyDesign.radiusSm),
                      ),
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── Bottom Sheet / Policy Reader Modal ───
  void _openPolicyDetailSheet(CompanyPolicy policy) {
    bool isAgreed = false;
    final commentsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: PolicyDesign.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(PolicyDesign.radiusXl)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(PolicyDesign.md, 0, PolicyDesign.md, PolicyDesign.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    policy.categoryDisplay.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: policy.categoryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'v${policy.version}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: PolicyDesign.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                policy.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: PolicyDesign.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                          color: PolicyDesign.textMuted,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: PolicyDesign.border),

                  // Content scroll
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(PolicyDesign.md),
                      children: [
                        // Metadata card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: PolicyDesign.surfaceMuted,
                            borderRadius: BorderRadius.circular(PolicyDesign.radiusSm),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _infoItem('Effective', _formatDate(policy.effectiveDate)),
                              _infoItem('Type', policy.isMandatory ? 'Mandatory' : 'Optional'),
                              _infoItem('File', policy.documentName.isNotEmpty ? policy.documentName : 'Attached'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'Policy Details & Scope',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: PolicyDesign.textPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          policy.description.isNotEmpty
                              ? policy.description
                              : 'Please download and review the official policy document for full terms and conditions.',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: PolicyDesign.textSecondary,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Download PDF Button
                        if (policy.documentUrl.isNotEmpty) ...[
                          OutlinedButton.icon(
                            onPressed: () => _launchDocumentUrl(policy.documentUrl),
                            icon: const Icon(Icons.file_present_rounded, color: PolicyDesign.primary),
                            label: Text(
                              'Open Official Document (${policy.documentName})',
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: PolicyDesign.primary,
                              side: const BorderSide(color: PolicyDesign.primaryLight),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(PolicyDesign.radiusSm),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Version history
                        if (policy.versionHistory.isNotEmpty) ...[
                          const Text(
                            'Revision History',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: PolicyDesign.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...policy.versionHistory.map((vh) => Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: PolicyDesign.surfaceMuted,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Text('v${vh.version}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        vh.summaryOfChanges.isNotEmpty ? vh.summaryOfChanges : 'Revision',
                                        style: const TextStyle(fontSize: 11.5, color: PolicyDesign.textSecondary),
                                      ),
                                    ),
                                    Text(_formatDate(vh.effectiveDate), style: const TextStyle(fontSize: 10, color: PolicyDesign.textMuted)),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 20),
                        ],

                        // Acknowledged card or Sign-off form
                        if (policy.isAcknowledged)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: PolicyDesign.successSoft,
                              borderRadius: BorderRadius.circular(PolicyDesign.radiusMd),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: PolicyDesign.success, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Policy Acknowledged',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: PolicyDesign.success),
                                      ),
                                      Text(
                                        'Signed on ${_formatDate(policy.acknowledgedAt)} for version ${policy.acknowledgedVersion ?? policy.version}',
                                        style: TextStyle(fontSize: 11.5, color: Colors.green.shade800),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: PolicyDesign.surfaceMuted,
                              borderRadius: BorderRadius.circular(PolicyDesign.radiusMd),
                              border: Border.all(color: PolicyDesign.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Employee Sign-off & Acknowledgement',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: PolicyDesign.textPrimary),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      value: isAgreed,
                                      onChanged: (val) => setModalState(() => isAgreed = val ?? false),
                                      activeColor: PolicyDesign.primary,
                                    ),
                                    const Expanded(
                                      child: Text(
                                        'I confirm that I have read, understood, and agree to adhere to this company policy and its guidelines.',
                                        style: TextStyle(fontSize: 12, color: PolicyDesign.textSecondary, height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: commentsController,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: InputDecoration(
                                    hintText: 'Optional notes or comments...',
                                    hintStyle: const TextStyle(fontSize: 11.5, color: PolicyDesign.textMuted),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: PolicyDesign.border),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: isAgreed
                                        ? () async {
                                            Navigator.pop(ctx);
                                            await _acknowledgePolicy(policy, commentsController.text);
                                          }
                                        : null,
                                    icon: const Icon(Icons.check_rounded, size: 18),
                                    label: const Text('Confirm & Sign Policy'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: PolicyDesign.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(PolicyDesign.radiusSm),
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
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: PolicyDesign.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PolicyDesign.textPrimary)),
      ],
    );
  }
}
