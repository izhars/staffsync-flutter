import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../models/expense.dart';
import '../component/expense_card.dart';
import '../services/expense_api.dart';
import '../widgets/_full_screen_receipt.dart';
import 'create_expense_screen.dart';

class AppDesign {
  // ---- Spacing ----
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  // ---- Radii ----
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  // ---- Primary (indigo, matches Report page) ----
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primarySoft = Color(0xFFEEF2FF);
  static const Color primaryLight = Color(0xFFC7D2FE);

  // ---- Surfaces ----
  static const Color bg = Color(0xFFF6F7FB);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFEAECEF);

  // ---- Text ----
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // ---- Semantic (present / late / short / absent / leave / etc.) ----
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

  static const Color neutral = Color(0xFF6B7280);
  static const Color neutralSoft = Color(0xFFF3F4F6);
  static const Color neutralBorder = Color(0xFFE5E7EB);

  // ---- Shadows ----
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 14,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primary.withOpacity(0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -6,
    ),
  ];

  // ---- Text styles (Report-compatible sizes) ----
  static const TextStyle h1 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: -0.4,
  );

  static const TextStyle headerSubtitle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle label = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: textMuted,
    letterSpacing: 0.6,
  );

  static const TextStyle value = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textMuted,
    letterSpacing: 0.2,
  );

  static const TextStyle chip = TextStyle(
    fontSize: 9.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.4,
  );

  static const TextStyle button = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.1,
  );
}

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({Key? key}) : super(key: key);

  @override
  _ExpenseListScreenState createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen>
    with SingleTickerProviderStateMixin {
  final ExpenseService _expenseService = ExpenseService();
  final List<Expense> _expenses = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  final int _limit = 20;
  String? _selectedStatus;

  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  final List<Map<String, dynamic>> _statusOptions = [
    {'label': 'All', 'icon': Icons.all_inclusive_rounded},
    {'label': 'Draft', 'icon': Icons.edit_note_rounded},
    {'label': 'Submitted', 'icon': Icons.send_rounded},
    {'label': 'Approved', 'icon': Icons.check_circle_rounded},
    {'label': 'Rejected', 'icon': Icons.cancel_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  // ===================================================================
  // SKELETON LOADER
  // ===================================================================
  Widget _buildSkeletonLoader() {
    return Skeletonizer(
      enabled: true,
      child: Column(
        children: [
          // Header skeleton
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppDesign.primary, AppDesign.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(AppDesign.radiusXl),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDesign.md, AppDesign.sm, AppDesign.md, AppDesign.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 160, height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 100, height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Filter chips skeleton
          Container(
            height: 74,
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: AppDesign.bg,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  width: 92, height: 38,
                  decoration: BoxDecoration(
                    color: AppDesign.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppDesign.border),
                  ),
                ),
              ),
            ),
          ),
          // Card skeletons
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: 4,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppDesign.surface,
                    borderRadius: BorderRadius.circular(AppDesign.radiusLg),
                    boxShadow: AppDesign.softShadow,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: AppDesign.bg,
                                    borderRadius: BorderRadius.circular(
                                        AppDesign.radiusSm),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 110, height: 24,
                                  decoration: BoxDecoration(
                                    color: AppDesign.bg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 80, height: 24,
                              decoration: BoxDecoration(
                                color: AppDesign.bg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity, height: 44,
                          decoration: BoxDecoration(
                            color: AppDesign.bg,
                            borderRadius: BorderRadius.circular(
                                AppDesign.radiusSm),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // DATA
  // ===================================================================
  Future<void> _loadExpenses({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      if (refresh) {
        _page = 1;
        _expenses.clear();
        _hasMore = true;
      }
    });
    try {
      final newExpenses = await _expenseService.getMyExpenses(
        status: _selectedStatus?.toLowerCase(),
        page: _page,
        limit: _limit,
      );
      setState(() {
        if (refresh) _expenses.clear();
        _expenses.addAll(newExpenses);
        _hasMore = newExpenses.length == _limit;
        _page++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('Failed to load expenses', isError: true);
    }
  }

  Future<void> _submitExpense(String expenseId) async {
    try {
      final idx = _expenses.indexWhere((e) => e.id == expenseId);
      if (idx == -1) return;
      final original = _expenses[idx];
      setState(() => _isLoading = true);

      final updated = original.copyWith(
        status: 'submitted',
        submittedAt: DateTime.now(),
      );
      setState(() => _expenses[idx] = updated);

      await _expenseService.submitExpense(expenseId);
      _showSnackbar('Expense submitted successfully', isError: false);
    } catch (e) {
      _loadExpenses(refresh: true);
      _showSnackbar('Failed to submit expense', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteExpense(String expenseId) async {
    _showDeleteBottomSheet(expenseId);
  }

  // ===================================================================
  // DELETE SHEET
  // ===================================================================
  void _showDeleteBottomSheet(String expenseId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: const BoxDecoration(
          color: AppDesign.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDesign.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppDesign.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppDesign.absentSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppDesign.absent.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.delete_rounded,
                color: AppDesign.absent,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Delete Expense?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppDesign.textPrimary,
                  letterSpacing: -0.4,
                )),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone',
              style: TextStyle(
                fontSize: 13,
                color: AppDesign.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppDesign.textPrimary,
                      side: const BorderSide(color: AppDesign.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(AppDesign.radiusSm),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppDesign.absent, Color(0xFFB91C1C)],
                      ),
                      borderRadius:
                      BorderRadius.circular(AppDesign.radiusSm),
                      boxShadow: [
                        BoxShadow(
                          color: AppDesign.absent.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          setState(() => _isLoading = true);
                          await _expenseService.deleteExpense(expenseId);
                          setState(() =>
                              _expenses.removeWhere((e) => e.id == expenseId));
                          _showSnackbar('Expense deleted', isError: false);
                        } catch (e) {
                          _showSnackbar('Failed to delete', isError: true);
                        } finally {
                          setState(() => _isLoading = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(AppDesign.radiusSm),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // SNACKBAR
  // ===================================================================
  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppDesign.absent : AppDesign.present,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ===================================================================
  // NAVIGATION
  // ===================================================================
  Future<void> _navigateToCreateExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateExpenseScreen()),
    );
    if (result != null) _loadExpenses(refresh: true);
  }

  void _navigateToEditExpense(String expenseId) async {
    try {
      setState(() => _isLoading = true);
      final expense = await _expenseService.getExpenseById(expenseId);
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateExpenseScreen(expense: expense),
          ),
        );
        if (result != null) _loadExpenses(refresh: true);
      }
    } catch (e) {
      _showSnackbar('Failed to load expense for editing', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===================================================================
  // DETAILS BOTTOM SHEET
  // ===================================================================
  void _showExpenseDetailsBottomSheet(Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            final hasReceipt = expense.receiptPath != null &&
                expense.receiptPath!.isNotEmpty;

            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                color: AppDesign.bg,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppDesign.radiusXl),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppDesign.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // ── HERO CARD ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius:
                        BorderRadius.circular(AppDesign.radiusLg),
                        gradient: const LinearGradient(
                          colors: [AppDesign.primary, AppDesign.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppDesign.primary.withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: -6,
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.categoryName ?? 'Expense',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  expense.formattedDate,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.white.withOpacity(0.75),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  expense.formattedAmount,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.6,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _heroChip(
                                dot: _statusColor(expense.status),
                                label: expense.statusText.toUpperCase(),
                                strong: true,
                              ),
                              const SizedBox(height: 6),
                              _heroChip(
                                icon: hasReceipt
                                    ? Icons.receipt_long_rounded
                                    : Icons.receipt_long_outlined,
                                label: hasReceipt ? 'RECEIPT' : 'NO RECEIPT',
                                accent: hasReceipt
                                    ? AppDesign.present
                                    : Colors.white70,
                                strong: hasReceipt,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── DETAILS CARD ──
                    Container(
                      decoration: BoxDecoration(
                        color: AppDesign.surface,
                        borderRadius:
                        BorderRadius.circular(AppDesign.radiusLg),
                        border: Border.all(color: AppDesign.border, width: 1),
                        boxShadow: AppDesign.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(AppDesign.md),
                            child: Row(
                              children: [
                                _iconBox(Icons.info_outline_rounded),
                                const SizedBox(width: AppDesign.sm + 2),
                                const Text(
                                  'Details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppDesign.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(height: 1, color: AppDesign.border),
                          Padding(
                            padding: const EdgeInsets.all(AppDesign.md - 2),
                            child: Column(
                              children: [
                                _detailRow('Category',
                                    expense.categoryName ?? '—'),
                                _detailRow(
                                  'Description',
                                  expense.description.isNotEmpty
                                      ? expense.description
                                      : '—',
                                ),
                                if (expense.submittedAt != null)
                                  _detailRow(
                                    'Submitted',
                                    DateFormat('dd MMM, yyyy').format(
                                      expense.submittedAt!.toLocal(),
                                    ),
                                  ),
                                if (expense.approvedByName != null)
                                  _detailRow(
                                      'Approved by', expense.approvedByName!),
                                if (expense.rejectedByName != null)
                                  _detailRow(
                                      'Rejected by', expense.rejectedByName!),
                                if (expense.hrComments != null &&
                                    expense.hrComments!.isNotEmpty)
                                  _detailRow(
                                      'HR comments', expense.hrComments!),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── RECEIPT PREVIEW ──
                    if (hasReceipt) ...[
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: AppDesign.surface,
                          borderRadius:
                          BorderRadius.circular(AppDesign.radiusLg),
                          border: Border.all(color: AppDesign.border),
                          boxShadow: AppDesign.softShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(AppDesign.md),
                              child: Row(
                                children: [
                                  _iconBox(Icons.attach_file_rounded),
                                  const SizedBox(width: AppDesign.sm + 2),
                                  const Text(
                                    'Receipt',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppDesign.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(height: 1, color: AppDesign.border),
                            Padding(
                              padding: const EdgeInsets.all(AppDesign.md - 2),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        AppDesign.radiusMd),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: Image.network(
                                        expense.receiptPath!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                              color: AppDesign.bg,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.broken_image_rounded,
                                                size: 32,
                                                color: AppDesign.textMuted,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => FullScreenReceipt(
                                                imageUrl:
                                                expense.receiptPath!),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                          Icons.fullscreen_rounded,
                                          size: 16),
                                      label: const Text(
                                        'View full receipt',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppDesign.primary,
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

                    const SizedBox(height: 18),

                    // ── ACTION BUTTONS ──
                    Row(
                      children: [
                        if (expense.isEditable)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _navigateToEditExpense(expense.id!);
                              },
                              icon: const Icon(Icons.edit_rounded,
                                  size: 16),
                              label: const Text(
                                'Edit',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppDesign.primary,
                                side: BorderSide(
                                  color: AppDesign.primaryLight,
                                  width: 1.4,
                                ),
                                backgroundColor: AppDesign.primarySoft,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppDesign.radiusSm),
                                ),
                              ),
                            ),
                          ),
                        if (expense.isEditable && expense.isDraft)
                          const SizedBox(width: 10),
                        if (expense.isDraft)
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppDesign.primary,
                                    AppDesign.primaryDark
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                    AppDesign.radiusSm),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppDesign.primary
                                        .withOpacity(0.30),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _submitExpense(expense.id!);
                                },
                                icon: const Icon(Icons.send_rounded,
                                    size: 16),
                                label: const Text(
                                  'Submit',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppDesign.radiusSm),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    if (expense.isDraft) const SizedBox(height: 10),

                    if (expense.isDraft)
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteExpense(expense.id!);
                          },
                          icon: const Icon(Icons.delete_rounded,
                              color: AppDesign.absent, size: 16),
                          label: const Text(
                            'Delete expense',
                            style: TextStyle(
                              color: AppDesign.absent,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppDesign.primarySoft,
        borderRadius: BorderRadius.circular(AppDesign.radiusSm - 2),
        border: Border.all(color: AppDesign.primaryLight, width: 1),
      ),
      child: Icon(icon, color: AppDesign.primary, size: 16),
    );
  }

  Widget _heroChip({
    IconData? icon,
    Color? dot,
    required String label,
    Color? accent,
    bool strong = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(strong ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(strong ? 0.40 : 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null)
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
          if (icon != null) Icon(icon, size: 12, color: accent ?? Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: accent ?? Colors.white,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':     return AppDesign.late;
      case 'submitted': return AppDesign.leave;
      case 'approved':  return AppDesign.present;
      case 'rejected':  return AppDesign.absent;
      default:          return AppDesign.textMuted;
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppDesign.textMuted,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppDesign.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // HEADER (Report-style)
  // ===================================================================
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppDesign.primary, AppDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: AppDesign.primary.withOpacity(0.25),
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
            AppDesign.md, AppDesign.sm, AppDesign.md, AppDesign.md,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
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
              const SizedBox(width: AppDesign.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Expenses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_expenses.length} expense${_expenses.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withOpacity(0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  onTap: () => _loadExpenses(refresh: true),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
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

  // ===================================================================
  // FILTER CHIPS
  // ===================================================================
  Widget _buildFilterChips() {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(vertical: 14),
      color: AppDesign.bg,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _statusOptions.length,
        itemBuilder: (context, index) {
          final option = _statusOptions[index];
          final isSelected =
              _selectedStatus == option['label'].toString().toLowerCase() ||
                  (_selectedStatus == null && option['label'] == 'All');

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedStatus = option['label'] == 'All'
                        ? null
                        : option['label'].toString().toLowerCase();
                  });
                  _loadExpenses(refresh: true);
                },
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                    isSelected ? AppDesign.primary : AppDesign.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? AppDesign.primary
                          : AppDesign.border,
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: AppDesign.primary.withOpacity(0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: -2,
                      )
                    ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        option['icon'] as IconData,
                        size: 15,
                        color: isSelected
                            ? Colors.white
                            : AppDesign.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        option['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                          color: isSelected
                              ? Colors.white
                              : AppDesign.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===================================================================
  // EMPTY STATE
  // ===================================================================
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(
                color: AppDesign.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 46,
                color: AppDesign.primary,
              ),
            ),
            const SizedBox(height: AppDesign.lg),
            const Text(
              'No expenses yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppDesign.sm),
            const Text(
              'Tap the + button below to add your first expense',
              style: TextStyle(
                fontSize: 13,
                color: AppDesign.textMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedStatus != null) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  setState(() => _selectedStatus = null);
                  _loadExpenses(refresh: true);
                },
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text(
                  'Clear filters',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppDesign.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // LIST
  // ===================================================================
  Widget _buildExpenseList() {
    if (_expenses.isEmpty && !_isLoading) return _buildEmptyState();

    return ListView.builder(
      itemCount: _expenses.length + (_hasMore ? 1 : 0),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemBuilder: (context, index) {
        if (index < _expenses.length) {
          final expense = _expenses[index];
          return AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(milliseconds: 300 + (index * 50)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ExpenseCard(
                expense: expense,
                onTap: () => _showExpenseDetailsBottomSheet(expense),
                onEdit: expense.isEditable
                    ? () => _navigateToEditExpense(expense.id!)
                    : null,
                onDelete: expense.isDraft
                    ? () => _deleteExpense(expense.id!)
                    : null,
                onSubmit: expense.isEditable
                    ? () => _submitExpense(expense.id!)
                    : null,
              ),
            ),
          );
        }
        return _buildLoadingIndicator();
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _isLoading
            ? Column(
          children: [
            const CircularProgressIndicator(color: AppDesign.primary),
            const SizedBox(height: 12),
            const Text(
              'Loading expenses...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppDesign.textSecondary,
              ),
            ),
          ],
        )
            : _hasMore
            ? OutlinedButton.icon(
          onPressed: () => _loadExpenses(),
          icon: const Icon(Icons.arrow_downward_rounded, size: 16),
          label: const Text(
            'Load more',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppDesign.primary,
            side: BorderSide(
                color: AppDesign.primaryLight, width: 1.4),
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesign.radiusSm),
            ),
          ),
        )
            : Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppDesign.surface,
            borderRadius: BorderRadius.circular(AppDesign.radiusSm),
            border: Border.all(color: AppDesign.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 16,
                color: AppDesign.present,
              ),
              const SizedBox(width: 8),
              const Text(
                'All caught up!',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppDesign.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // BUILD
  // ===================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.bg,
      body: _isLoading && _expenses.isEmpty
          ? _buildSkeletonLoader()
          : Column(
        children: [
          _buildHeader(),
          _buildFilterChips(),
          Expanded(
            child: RefreshIndicator(
              color: AppDesign.primary,
              backgroundColor: AppDesign.surface,
              onRefresh: () => _loadExpenses(refresh: true),
              child: _buildExpenseList(),
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppDesign.primary, AppDesign.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: AppDesign.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _navigateToCreateExpense,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Add Expense',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
                fontSize: 13.5,
              ),
            ),
            foregroundColor: Colors.white,
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}