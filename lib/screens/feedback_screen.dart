import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FeedbackModel {
  final String message;
  final String category;
  final bool isAnonymous;

  FeedbackModel({
    required this.message,
    required this.category,
    required this.isAnonymous,
  });
}

class FeedbackService {
  Future<Map<String, dynamic>> sendFeedback(FeedbackModel feedback) async {
    await Future.delayed(const Duration(seconds: 2));
    return {'success': true, 'message': 'Feedback received successfully'};
  }
}

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _selectedCategory = 'work_environment';
  bool _isAnonymous = false;
  bool _isLoading = false;

  // Enhanced category data with gradients and better descriptions
  final List<Map<String, dynamic>> _categoryList = [
    {
      'id': 'work_environment',
      'label': 'Work Environment',
      'icon': Icons.workspace_premium_rounded,
      'color': Colors.blue,
      'gradient': [Color(0xFF6366F1), Color(0xFF4F46E5)],
      'description': 'Office space, facilities, and atmosphere'
    },
    {
      'id': 'management',
      'label': 'Management',
      'icon': Icons.groups_rounded,
      'color': Colors.teal,
      'gradient': [Color(0xFF0D9488), Color(0xFF0F766E)],
      'description': 'Leadership, communication, and support'
    },
    {
      'id': 'benefits',
      'label': 'Benefits',
      'icon': Icons.medical_information_rounded,
      'color': Colors.orange,
      'gradient': [Color(0xFFF59E0B), Color(0xFFD97706)],
      'description': 'Health, insurance, and perks'
    },
    {
      'id': 'career_growth',
      'label': 'Career Growth',
      'icon': Icons.trending_up_rounded,
      'color': Colors.purple,
      'gradient': [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      'description': 'Learning opportunities and advancement'
    },
    {
      'id': 'work_life',
      'label': 'Work-Life Balance',
      'icon': Icons.balance_rounded,
      'color': Colors.green,
      'gradient': [Color(0xFF10B981), Color(0xFF059669)],
      'description': 'Flexibility and time management'
    },
    {
      'id': 'other',
      'label': 'Other',
      'icon': Icons.more_horiz_rounded,
      'color': Colors.grey,
      'gradient': [Color(0xFF6B7280), Color(0xFF4B5563)],
      'description': 'Any other feedback'
    },
  ];

  void _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    final feedback = FeedbackModel(
      message: _messageController.text.trim(),
      category: _selectedCategory,
      isAnonymous: _isAnonymous,
    );

    final service = FeedbackService();
    final result = await service.sendFeedback(feedback);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success']) {
      _showSuccessDialog();
      _messageController.clear();
      setState(() {
        _selectedCategory = 'work_environment';
        _isAnonymous = false;
      });
    } else {
      _showErrorSnackbar(result['message']);
    }
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.fastOutSlowIn,
          ),
          child: FadeTransition(
            opacity: animation,
            child: AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4F46E5).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Thank You!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Your feedback has been submitted successfully.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "We appreciate your input.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              actions: [
                Center(
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 🔥 Added AppBar
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Feedback',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
          ],
        ),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              // future: filter / sort awards
            },
            icon: const Icon(Icons.reviews),
            tooltip: 'Feedback',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔥 REMOVED: Header with back button (now in AppBar)

                  const SizedBox(height: 12), // Small spacing after AppBar

                  // Main title
                  Text(
                    "Share your thoughts",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[900],
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    "Your feedback helps us improve the workplace experience for everyone.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Category section
                  Text(
                    "CATEGORY",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[500],
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 150,
                    ),
                    itemCount: _categoryList.length,
                    itemBuilder: (context, index) {
                      final cat = _categoryList[index];
                      final isSelected = _selectedCategory == cat['id'];
                      return _buildCategoryCard(cat, isSelected);
                    },
                  ),

                  const SizedBox(height: 40),

                  // Message section
                  Text(
                    "YOUR FEEDBACK",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[500],
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1.5,
                      ),
                    ),
                    child: TextFormField(
                      controller: _messageController,
                      maxLines: 6,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[900],
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: "Type your detailed feedback here...",
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 15,
                        ),
                        contentPadding: const EdgeInsets.all(20),
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
                  ),

                  const SizedBox(height: 32),

                  // Character count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "${_messageController.text.length} characters",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Anonymous toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isAnonymous
                            ? Color(0xFF4F46E5).withOpacity(0.3)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _isAnonymous
                                ? Color(0xFF4F46E5).withOpacity(0.1)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.visibility_off_rounded,
                            color: _isAnonymous
                                ? Color(0xFF4F46E5)
                                : Colors.grey[500],
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Submit anonymously",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[900],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Your identity will remain confidential",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _isAnonymous,
                          onChanged: (value) =>
                              setState(() => _isAnonymous = value),
                          activeColor: Color(0xFF4F46E5),
                          trackOutlineColor: MaterialStateProperty.all(
                            Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        shadowColor: Color(0xFF4F46E5).withOpacity(0.3),
                      ),
                      child: _isLoading
                          ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Submit Feedback",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info text
                  Center(
                    child: Text(
                      "All feedback is reviewed by HR within 48 hours",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, bool isSelected) {
    final gradientColors = category['gradient'] as List<Color>;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isSelected ? null : Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.grey[200]!,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : gradientColors[0].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category['icon'] as IconData,
                color: isSelected ? Colors.white : gradientColors[0],
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              category['label'] as String,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[900],
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category['description'] as String,
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withOpacity(0.9)
                    : Colors.grey[600],
                fontSize: 12,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}