import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../component/combo_off_card.dart';
import '../models/combo_off.dart';
import '../services/combo_services.dart';

// ===================== SHARED DESIGN TOKENS =====================
class ComboDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  // Primary slate/indigo palette (combo off = rest day, cool neutral)
  static const Color primary = Color(0xFF475569);       // slate-600
  static const Color primaryDark = Color(0xFF334155);   // slate-700
  static const Color primarySoft = Color(0xFFF1F5F9);   // slate-100
  static const Color primaryLight = Color(0xFFCBD5E1);  // slate-300

  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color bg = Color(0xFFF6F7FB);
  static const Color border = Color(0xFFEAECEF);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Semantic states
  static const Color pending = Color(0xFFD97706);
  static const Color pendingSoft = Color(0xFFFFFBEB);
  static const Color pendingBorder = Color(0xFFFDE68A);

  static const Color success = Color(0xFF059669);
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  static const Color info = Color(0xFF4F46E5);
  static const Color infoSoft = Color(0xFFEEF2FF);
  static const Color infoBorder = Color(0xFFC7D2FE);

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

class ComboOffScreen extends StatefulWidget {
  const ComboOffScreen({Key? key}) : super(key: key);

  @override
  State<ComboOffScreen> createState() => _ComboOffScreenState();
}

class _ComboOffScreenState extends State<ComboOffScreen> {
  final ComboApi _comboApi = ComboApi();
  List<ComboOff> comboOffs = [];
  bool isLoading = true;
  String? errorMessage;

  final TextEditingController _reasonController = TextEditingController();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    fetchComboOffs();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // ===================== DATA =====================

  Future<void> fetchComboOffs() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final combos = await _comboApi.getMyComboOffs();
      if (!mounted) return;
      setState(() => comboOffs = combos);
    } catch (e) {
      _handleApiError(e, 'Failed to load combo offs');
      debugPrint('Fetch combo offs error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ===================== APPLY SHEET =====================

  void _showApplyDialog() {
    _reasonController.clear();
    selectedDate = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: ComboDesign.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(ComboDesign.radiusXl),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: ComboDesign.lg,
                  right: ComboDesign.lg,
                  top: ComboDesign.md,
                  bottom:
                  MediaQuery.of(context).viewInsets.bottom +
                      ComboDesign.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin:
                        const EdgeInsets.only(bottom: ComboDesign.md),
                        decoration: BoxDecoration(
                          color: ComboDesign.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: ComboDesign.primarySoft,
                            borderRadius: BorderRadius.circular(
                              ComboDesign.radiusSm,
                            ),
                            border: Border.all(
                              color: ComboDesign.primaryLight,
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.event_busy_rounded,
                            color: ComboDesign.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: ComboDesign.sm + 4),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Apply for Combo Off',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: ComboDesign.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Submit a request for a work date',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: ComboDesign.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: ComboDesign.surfaceMuted,
                          borderRadius: BorderRadius.circular(
                            ComboDesign.radiusSm - 2,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              ComboDesign.radiusSm - 2,
                            ),
                            onTap: () => Navigator.pop(sheetContext),
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.close_rounded,
                                color: ComboDesign.textSecondary,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: ComboDesign.lg),

                    // Reason field label
                    const Text(
                      'REASON',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: ComboDesign.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: ComboDesign.sm),
                    TextField(
                      controller: _reasonController,
                      maxLines: 3,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ComboDesign.textPrimary,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Explain the reason for your combo off...',
                        hintStyle: const TextStyle(
                          fontSize: 13.5,
                          color: ComboDesign.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: ComboDesign.surfaceMuted,
                        contentPadding:
                        const EdgeInsets.all(ComboDesign.md),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ComboDesign.radiusSm,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ComboDesign.radiusSm,
                          ),
                          borderSide: const BorderSide(
                            color: ComboDesign.border,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ComboDesign.radiusSm,
                          ),
                          borderSide: const BorderSide(
                            color: ComboDesign.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: ComboDesign.md),

                    // Date label
                    const Text(
                      'WORK DATE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: ComboDesign.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: ComboDesign.sm),
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        ComboDesign.radiusSm,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          ComboDesign.radiusSm,
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                            selectableDayPredicate: (DateTime date) {
                              final hasApplication = comboOffs.any((combo) {
                                return combo.date.year == date.year &&
                                    combo.date.month == date.month &&
                                    combo.date.day == date.day &&
                                    !combo.isRejected;
                              });
                              return !hasApplication;
                            },
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: ComboDesign.primary,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: ComboDesign.textPrimary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            setModalState(() => selectedDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(ComboDesign.md),
                          decoration: BoxDecoration(
                            color: ComboDesign.surfaceMuted,
                            borderRadius: BorderRadius.circular(
                              ComboDesign.radiusSm,
                            ),
                            border: Border.all(
                              color: selectedDate != null
                                  ? ComboDesign.primaryLight
                                  : ComboDesign.border,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: selectedDate != null
                                      ? ComboDesign.primarySoft
                                      : ComboDesign.surface,
                                  borderRadius: BorderRadius.circular(
                                    ComboDesign.radiusSm - 2,
                                  ),
                                  border: Border.all(
                                    color: selectedDate != null
                                        ? ComboDesign.primaryLight
                                        : ComboDesign.border,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.calendar_today_rounded,
                                  color: selectedDate != null
                                      ? ComboDesign.primary
                                      : ComboDesign.textMuted,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: ComboDesign.sm + 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedDate == null
                                          ? 'Select work date'
                                          : _formatSelectedDate(
                                          selectedDate!),
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight:
                                        selectedDate != null
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: selectedDate != null
                                            ? ComboDesign.textPrimary
                                            : ComboDesign.textMuted,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                    if (selectedDate == null) ...[
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Pick your preferred work date',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: ComboDesign.textMuted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: ComboDesign.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: ComboDesign.lg),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleSubmit(sheetContext),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text(
                          'Submit Application',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ComboDesign.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ComboDesign.radiusMd,
                            ),
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

  String _formatSelectedDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ===================== SUBMIT =====================

  Future<void> _handleSubmit(BuildContext sheetContext) async {
    if (_reasonController.text.isEmpty) {
      _showSnackBar(
        sheetContext,
        'Please enter a reason',
        ComboDesign.pending,
      );
      return;
    }

    if (_reasonController.text.length < 10) {
      _showSnackBar(
        sheetContext,
        'Please provide a more detailed reason (min 10 characters)',
        ComboDesign.pending,
      );
      return;
    }

    if (selectedDate == null) {
      _showSnackBar(
        sheetContext,
        'Please select a date',
        ComboDesign.pending,
      );
      return;
    }

    final isDuplicate = comboOffs.any((combo) {
      return combo.date.year == selectedDate!.year &&
          combo.date.month == selectedDate!.month &&
          combo.date.day == selectedDate!.day &&
          !combo.isRejected;
    });

    if (isDuplicate) {
      _showSnackBar(
        sheetContext,
        'You already applied for Combo Off on ${_formatSelectedDate(selectedDate!)}',
        ComboDesign.pending,
      );
      return;
    }

    Navigator.of(sheetContext).pop();
    if (!mounted) return;

    _showLoadingDialog();

    try {
      await _comboApi.applyComboOff(
        _reasonController.text,
        selectedDate!,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      _showSnackBar(
        context,
        'Combo Off applied successfully!',
        ComboDesign.success,
      );

      await fetchComboOffs();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();

      String errorMsg = 'Something went wrong!';
      if (e is Exception) {
        errorMsg = e.toString().replaceFirst('Exception: ', '');
      }

      _showSnackBar(context, errorMsg, ComboDesign.danger);
    }
  }

  // ===================== DELETE =====================

  Future<void> _handleDeleteComboOff(String comboId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ComboDesign.surface,
        surfaceTintColor: ComboDesign.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ComboDesign.radiusLg),
        ),
        title: const Text(
          'Delete Request?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: ComboDesign.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this combo off request? This action cannot be undone.',
          style: TextStyle(
            fontSize: 13.5,
            color: ComboDesign.textSecondary,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: ComboDesign.md,
          vertical: ComboDesign.sm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: ComboDesign.textSecondary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ComboDesign.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: ComboDesign.md,
                vertical: ComboDesign.sm + 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(ComboDesign.radiusSm),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    _showLoadingDialog();

    try {
      final success = await _comboApi.deleteComboOff(comboId);
      if (!mounted) return;
      Navigator.of(context).pop();

      if (success) {
        _showSnackBar(
          context,
          'Request deleted successfully',
          ComboDesign.success,
        );
        await fetchComboOffs();
      } else {
        _showSnackBar(
          context,
          'Failed to delete request',
          ComboDesign.danger,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _handleApiError(e, 'Failed to delete combo off');
    }
  }

  // ===================== LOADING / SNACKBAR / ERROR =====================

  void _showLoadingDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoadingDialog(),
    );
  }

  void _handleApiError(dynamic error, String defaultMessage) {
    String errorMsg = defaultMessage;

    if (error is Map<String, dynamic> && error.containsKey('message')) {
      errorMsg = error['message'];
    } else if (error.toString().contains('Exception: ')) {
      errorMsg = error.toString().replaceFirst('Exception: ', '');
    } else {
      errorMsg = error.toString();
    }

    if (mounted) {
      _showSnackBar(context, errorMsg, ComboDesign.danger);
      setState(() => errorMessage = errorMsg);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ComboDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(ComboDesign.md),
      ),
    );
  }

  int get _pendingCount =>
      comboOffs.where((c) => c.status == 'pending').length;
  int get _approvedCount =>
      comboOffs.where((c) => c.status == 'approved').length;
  int get _rejectedCount =>
      comboOffs.where((c) => c.status == 'rejected').length;

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ComboDesign.bg,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ComboDesign.primary,
                    ),
                  ),
                ),
              )
                  : (errorMessage != null && comboOffs.isEmpty)
                  ? _buildErrorWidget()
                  : Column(
                children: [
                  if (comboOffs.isNotEmpty)
                    _buildStatsCard(),
                  Expanded(
                    child: comboOffs.isEmpty
                        ? _buildEmptyWidget()
                        : RefreshIndicator(
                      onRefresh: fetchComboOffs,
                      color: ComboDesign.primary,
                      backgroundColor:
                      ComboDesign.surface,
                      child: ListView.builder(
                        physics:
                        const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          ComboDesign.md,
                          ComboDesign.sm,
                          ComboDesign.md,
                          ComboDesign.xl + ComboDesign.md,
                        ),
                        itemCount: comboOffs.length,
                        itemBuilder: (context, index) {
                          final combo =
                          comboOffs[index];
                          return ComboOffCard(
                            combo: combo,
                            onDelete: () =>
                                _handleDeleteComboOff(
                                  combo.id,
                                ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFab(),
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ComboDesign.primary, ComboDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(ComboDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: ComboDesign.primary.withOpacity(0.25),
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
            ComboDesign.md,
            ComboDesign.sm,
            ComboDesign.md,
            ComboDesign.md,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius:
                BorderRadius.circular(ComboDesign.radiusSm),
                child: InkWell(
                  borderRadius:
                  BorderRadius.circular(ComboDesign.radiusSm),
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
              const SizedBox(width: ComboDesign.sm + 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Combo Offs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Request and track your combo offs',
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
                BorderRadius.circular(ComboDesign.radiusSm),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.event_busy_rounded,
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

  // ===================== FAB =====================

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ComboDesign.radiusMd),
        boxShadow: [
          BoxShadow(
            color: ComboDesign.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _showApplyDialog,
        backgroundColor: ComboDesign.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Apply',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            letterSpacing: -0.1,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ComboDesign.radiusMd),
        ),
      ),
    );
  }

  // ===================== STATS =====================

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        ComboDesign.md,
        ComboDesign.md,
        ComboDesign.md,
        ComboDesign.sm,
      ),
      padding: const EdgeInsets.all(ComboDesign.md - 2),
      decoration: BoxDecoration(
        color: ComboDesign.surface,
        borderRadius: BorderRadius.circular(ComboDesign.radiusLg),
        border: Border.all(color: ComboDesign.border, width: 1),
        boxShadow: ComboDesign.softShadow,
      ),
      child: Row(
        children: [
          _buildStatItem(
            'Pending',
            _pendingCount,
            ComboDesign.pending,
            ComboDesign.pendingSoft,
            ComboDesign.pendingBorder,
            Icons.hourglass_bottom_rounded,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Approved',
            _approvedCount,
            ComboDesign.success,
            ComboDesign.successSoft,
            ComboDesign.successBorder,
            Icons.check_circle_rounded,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Rejected',
            _rejectedCount,
            ComboDesign.danger,
            ComboDesign.dangerSoft,
            ComboDesign.dangerBorder,
            Icons.cancel_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: ComboDesign.border,
    );
  }

  Widget _buildStatItem(
      String label,
      int count,
      Color color,
      Color bg,
      Color border,
      IconData icon,
      ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(
                ComboDesign.radiusSm - 2,
              ),
              border: Border.all(color: border, width: 1),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: ComboDesign.textMuted,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== EMPTY / ERROR =====================

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ComboDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: ComboDesign.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                size: 42,
                color: ComboDesign.primary,
              ),
            ),
            const SizedBox(height: ComboDesign.lg),
            const Text(
              'No Combo Offs Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ComboDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: ComboDesign.sm),
            const Text(
              'Tap the "Apply" button below to submit your first request.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: ComboDesign.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ComboDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: ComboDesign.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 42,
                color: ComboDesign.danger,
              ),
            ),
            const SizedBox(height: ComboDesign.lg),
            const Text(
              'Unable to Load Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ComboDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: ComboDesign.sm),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ComboDesign.md,
              ),
              child: Text(
                errorMessage ?? 'An unexpected error occurred',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: ComboDesign.textMuted,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: ComboDesign.lg),
            ElevatedButton.icon(
              onPressed: fetchComboOffs,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ComboDesign.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: ComboDesign.lg,
                  vertical: ComboDesign.sm + 4,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(ComboDesign.radiusSm),
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
}

// ===================== LOADING DIALOG =====================

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: ComboDesign.surface,
        surfaceTintColor: ComboDesign.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ComboDesign.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ComboDesign.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ComboDesign.primary,
                  ),
                ),
              ),
              const SizedBox(height: ComboDesign.md),
              const Text(
                'Processing...',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: ComboDesign.textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}