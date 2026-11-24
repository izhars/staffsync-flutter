import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/feedback.dart';
import '../services/feedback_service.dart';

// ===================== SHARED DESIGN TOKENS =====================
class FeedbackDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  // Primary amber palette (feedback = warm/personal)
  static const Color primary = Color(0xFFD97706);       // amber-600
  static const Color primaryDark = Color(0xFFB45309);   // amber-700
  static const Color primarySoft = Color(0xFFFFFBEB);   // amber-50
  static const Color primaryLight = Color(0xFFFDE68A);  // amber-200

  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color bg = Color(0xFFF6F7FB);
  static const Color border = Color(0xFFEAECEF);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color success = Color(0xFF059669);
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

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

// ===================== SCREEN =====================

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ✅ Real service from services/feedback_service.dart
  final FeedbackService _service = FeedbackService();

  String _selectedCategory = 'work_environment';
  bool _isAnonymous = false;
  bool _isLoading = false;

  // Each category gets a semantic (fg, soft, border) triple
  static const List<Map<String, dynamic>> _categoryList = [
    {
      'id': 'work_environment',
      'label': 'Work Environment',
      'icon': Icons.workspace_premium_rounded,
      'fg': Color(0xFF4F46E5),
      'soft': Color(0xFFEEF2FF),
      'border': Color(0xFFC7D2FE),
      'description': 'Office space, facilities, and atmosphere',
    },
    {
      'id': 'management',
      'label': 'Management',
      'icon': Icons.groups_rounded,
      'fg': Color(0xFF0D9488),
      'soft': Color(0xFFF0FDFA),
      'border': Color(0xFF99F6E4),
      'description': 'Leadership, communication, and support',
    },
    {
      'id': 'benefits',
      'label': 'Benefits',
      'icon': Icons.medical_information_rounded,
      'fg': Color(0xFFD97706),
      'soft': Color(0xFFFFFBEB),
      'border': Color(0xFFFDE68A),
      'description': 'Health, insurance, and perks',
    },
    {
      'id': 'career_growth',
      'label': 'Career Growth',
      'icon': Icons.trending_up_rounded,
      'fg': Color(0xFF7C3AED),
      'soft': Color(0xFFF5F3FF),
      'border': Color(0xFFDDD6FE),
      'description': 'Learning opportunities and advancement',
    },
    {
      'id': 'work_life',
      'label': 'Work-Life Balance',
      'icon': Icons.balance_rounded,
      'fg': Color(0xFF059669),
      'soft': Color(0xFFECFDF5),
      'border': Color(0xFFA7F3D0),
      'description': 'Flexibility and time management',
    },
    {
      'id': 'other',
      'label': 'Other',
      'icon': Icons.more_horiz_rounded,
      'fg': Color(0xFF6B7280),
      'soft': Color(0xFFF3F4F6),
      'border': Color(0xFFE5E7EB),
      'description': 'Any other feedback',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ===================== SUBMIT =====================

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final feedback = FeedbackModel(
      message: _messageController.text.trim(),
      category: _selectedCategory,
      isAnonymous: _isAnonymous,
    );

    try {
      final result = await _service.sendFeedback(feedback);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        _showSuccessDialog();
        _messageController.clear();
        setState(() {
          _selectedCategory = 'work_environment';
          _isAnonymous = false;
        });
      } else {
        _showErrorSnackbar('Something went wrong. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackbar(_friendlyError(e));
    }
  }

  /// Turn raw exception into a human-friendly message
  String _friendlyError(Object e) {
    final raw = e.toString();
    if (raw.contains('401') || raw.toLowerCase().contains('unauthorized')) {
      return 'Session expired. Please log in again.';
    }
    if (raw.contains('400') || raw.toLowerCase().contains('invalid category')) {
      return 'Invalid category selected. Please pick another topic.';
    }
    if (raw.contains('SocketException') || raw.toLowerCase().contains('network')) {
      return 'No internet connection. Please check your network.';
    }
    return 'Failed to submit feedback. Please try again.';
  }

  // ===================== SUCCESS DIALOG =====================

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: FadeTransition(
            opacity: animation,
            child: Dialog(
              backgroundColor: FeedbackDesign.surface,
              surfaceTintColor: FeedbackDesign.surface,
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(FeedbackDesign.radiusXl),
              ),
              child: Padding(
                padding: const EdgeInsets.all(FeedbackDesign.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: FeedbackDesign.successSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: FeedbackDesign.success,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: FeedbackDesign.lg),
                    const Text(
                      'Thank You!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: FeedbackDesign.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: FeedbackDesign.sm),
                    const Text(
                      'Your feedback has been submitted successfully.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: FeedbackDesign.textSecondary,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: FeedbackDesign.xs + 2),
                    const Text(
                      'We appreciate your input.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: FeedbackDesign.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: FeedbackDesign.lg),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FeedbackDesign.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              FeedbackDesign.radiusMd,
                            ),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: FeedbackDesign.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FeedbackDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(FeedbackDesign.md),
      ),
    );
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: FeedbackDesign.bg,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(FeedbackDesign.md),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIntroCard(),
                        const SizedBox(height: FeedbackDesign.lg),
                        _buildSectionLabel(
                          'CATEGORY',
                          'Pick a topic to share your thoughts',
                        ),
                        const SizedBox(height: FeedbackDesign.sm + 4),
                        _buildCategoryGrid(),
                        const SizedBox(height: FeedbackDesign.lg),
                        _buildSectionLabel(
                          'YOUR FEEDBACK',
                          'Be as specific as you can',
                        ),
                        const SizedBox(height: FeedbackDesign.sm + 4),
                        _buildMessageField(),
                        const SizedBox(height: FeedbackDesign.sm),
                        _buildCharacterCount(),
                        const SizedBox(height: FeedbackDesign.lg),
                        _buildAnonymousToggle(),
                        const SizedBox(height: FeedbackDesign.lg),
                        _buildSubmitButton(),
                        const SizedBox(height: FeedbackDesign.md),
                        _buildFooterNote(),
                        const SizedBox(height: FeedbackDesign.lg),
                      ],
                    ),
                  ),
                ),
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
          colors: [FeedbackDesign.primary, FeedbackDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(FeedbackDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: FeedbackDesign.primary.withOpacity(0.25),
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
            FeedbackDesign.md,
            FeedbackDesign.sm,
            FeedbackDesign.md,
            FeedbackDesign.md,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius:
                BorderRadius.circular(FeedbackDesign.radiusSm),
                child: InkWell(
                  borderRadius:
                  BorderRadius.circular(FeedbackDesign.radiusSm),
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
              const SizedBox(width: FeedbackDesign.sm + 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Feedback',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Help us improve your experience',
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
                BorderRadius.circular(FeedbackDesign.radiusSm),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.reviews_rounded,
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

  // ===================== INTRO CARD =====================

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(FeedbackDesign.md + 2),
      decoration: BoxDecoration(
        color: FeedbackDesign.surface,
        borderRadius: BorderRadius.circular(FeedbackDesign.radiusLg),
        border: Border.all(color: FeedbackDesign.border, width: 1),
        boxShadow: FeedbackDesign.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FeedbackDesign.primarySoft,
              borderRadius:
              BorderRadius.circular(FeedbackDesign.radiusSm),
              border: Border.all(
                color: FeedbackDesign.primaryLight,
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: FeedbackDesign.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: FeedbackDesign.sm + 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share your thoughts',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: FeedbackDesign.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Your feedback helps us improve the workplace experience for everyone.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: FeedbackDesign.textSecondary,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== SECTION LABEL =====================

  Widget _buildSectionLabel(String label, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: FeedbackDesign.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: FeedbackDesign.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: FeedbackDesign.textPrimary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: FeedbackDesign.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===================== CATEGORY GRID =====================

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: FeedbackDesign.sm + 4,
        mainAxisSpacing: FeedbackDesign.sm + 4,
        mainAxisExtent: 132,
      ),
      itemCount: _categoryList.length,
      itemBuilder: (context, index) {
        final cat = _categoryList[index];
        final isSelected = _selectedCategory == cat['id'];
        return _buildCategoryCard(cat, isSelected);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, bool isSelected) {
    final fg = category['fg'] as Color;
    final soft = category['soft'] as Color;
    final border = category['border'] as Color;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(FeedbackDesign.sm + 4),
        decoration: BoxDecoration(
          color: isSelected ? soft : FeedbackDesign.surface,
          borderRadius: BorderRadius.circular(FeedbackDesign.radiusMd),
          border: Border.all(
            color: isSelected ? fg.withOpacity(0.5) : FeedbackDesign.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: fg.withOpacity(0.15),
              blurRadius: 14,
              offset: const Offset(0, 6),
              spreadRadius: -4,
            ),
          ]
              : FeedbackDesign.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : fg.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(
                      FeedbackDesign.radiusSm - 2,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? fg.withOpacity(0.35)
                          : border,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: fg,
                    size: 18,
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? fg : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? fg : FeedbackDesign.border,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 12,
                  )
                      : null,
                ),
              ],
            ),
            const Spacer(),
            Text(
              category['label'] as String,
              style: const TextStyle(
                color: FeedbackDesign.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              category['description'] as String,
              style: const TextStyle(
                color: FeedbackDesign.textMuted,
                fontSize: 10.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ===================== MESSAGE FIELD =====================

  Widget _buildMessageField() {
    return Container(
      decoration: BoxDecoration(
        color: FeedbackDesign.surface,
        borderRadius: BorderRadius.circular(FeedbackDesign.radiusMd),
        border: Border.all(color: FeedbackDesign.border, width: 1),
        boxShadow: FeedbackDesign.softShadow,
      ),
      child: TextFormField(
        controller: _messageController,
        maxLines: 6,
        minLines: 6,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 14,
          color: FeedbackDesign.textPrimary,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
        decoration: const InputDecoration(
          hintText: 'Type your detailed feedback here...',
          hintStyle: TextStyle(
            color: FeedbackDesign.textMuted,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          contentPadding: EdgeInsets.all(FeedbackDesign.md),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your feedback';
          }
          if (value.trim().length < 10) {
            return 'Feedback should be at least 10 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCharacterCount() {
    final count = _messageController.text.length;
    final hasMin = count >= 10;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(
          hasMin
              ? Icons.check_circle_rounded
              : Icons.info_outline_rounded,
          size: 12,
          color: hasMin
              ? FeedbackDesign.success
              : FeedbackDesign.textMuted,
        ),
        const SizedBox(width: 5),
        Text(
          '$count characters',
          style: TextStyle(
            fontSize: 11,
            color: hasMin
                ? FeedbackDesign.success
                : FeedbackDesign.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  // ===================== ANONYMOUS TOGGLE =====================

  Widget _buildAnonymousToggle() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(FeedbackDesign.sm + 4),
      decoration: BoxDecoration(
        color: _isAnonymous
            ? FeedbackDesign.primarySoft
            : FeedbackDesign.surface,
        borderRadius: BorderRadius.circular(FeedbackDesign.radiusMd),
        border: Border.all(
          color: _isAnonymous
              ? FeedbackDesign.primaryLight
              : FeedbackDesign.border,
          width: _isAnonymous ? 1.5 : 1,
        ),
        boxShadow: FeedbackDesign.softShadow,
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isAnonymous
                  ? FeedbackDesign.primary.withOpacity(0.12)
                  : FeedbackDesign.surfaceMuted,
              borderRadius:
              BorderRadius.circular(FeedbackDesign.radiusSm),
              border: Border.all(
                color: _isAnonymous
                    ? FeedbackDesign.primaryLight
                    : FeedbackDesign.border,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.visibility_off_rounded,
              color: _isAnonymous
                  ? FeedbackDesign.primary
                  : FeedbackDesign.textMuted,
              size: 18,
            ),
          ),
          const SizedBox(width: FeedbackDesign.sm + 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submit anonymously',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: FeedbackDesign.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Your identity will remain confidential',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: FeedbackDesign.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: _isAnonymous,
              onChanged: (value) =>
                  setState(() => _isAnonymous = value),
              activeColor: FeedbackDesign.primary,
              activeTrackColor: FeedbackDesign.primaryLight,
              trackOutlineColor:
              MaterialStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== SUBMIT =====================

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: FeedbackDesign.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
          FeedbackDesign.primary.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(FeedbackDesign.radiusMd),
          ),
          shadowColor: Colors.transparent,
        ),
        child: _isLoading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_rounded, size: 18),
            SizedBox(width: FeedbackDesign.sm + 2),
            Text(
              'Submit Feedback',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FeedbackDesign.sm + 4,
        vertical: FeedbackDesign.sm,
      ),
      decoration: BoxDecoration(
        color: FeedbackDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(FeedbackDesign.radiusSm),
        border: Border.all(color: FeedbackDesign.border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.schedule_rounded,
            size: 12,
            color: FeedbackDesign.textMuted,
          ),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'All feedback is reviewed by HR within 48 hours',
              style: TextStyle(
                fontSize: 11.5,
                color: FeedbackDesign.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}