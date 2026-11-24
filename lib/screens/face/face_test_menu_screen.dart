import 'package:flutter/material.dart';
import 'face_enrollment_screen.dart';
import 'face_verify_screen.dart';

class FaceTestMenuScreen extends StatelessWidget {
  const FaceTestMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F9), // light background
      appBar: AppBar(
        title: const Text('Face · Test & Verify'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E2B3C),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Enrollment'),
          _buildMenuItem(
            context,
            icon: Icons.face_retouching_natural,
            title: 'Face Enrollment',
            subtitle: 'Capture 5 samples and register',
            accent: const Color(0xFF2A7A3B), // soft green
            onTap: () async {
              final result = await Navigator.push<FaceEnrollmentResult>(
                context,
                MaterialPageRoute(
                  builder: (_) => const FaceEnrollmentScreen(),
                ),
              );
              if (!context.mounted) return;
              _showResult(context, _describeEnrollment(result));
            },
          ),
          const SizedBox(height: 20),
          _buildMenuItem(
            context,
            icon: Icons.verified_user_outlined,
            title: 'Face Verify',
            subtitle: 'Send embedding to /face/verify (check-in / check-out)',
            accent: const Color(0xFF0F6B6B), // soft teal
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FaceVerifyScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10, top: 6),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF7F8C9B),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    ),
  );

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? subtitle,
        required Color accent,
        required VoidCallback onTap,
      }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E9F2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF1E2B3C),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF637689),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: Color(0xFFA7B7C9), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  String _describeEnrollment(FaceEnrollmentResult? r) {
    switch (r) {
      case FaceEnrollmentResult.success:
        return 'Enrollment complete ✅';
      case FaceEnrollmentResult.alreadyEnrolled:
        return 'Already enrolled — no changes made.';
      case FaceEnrollmentResult.cancelled:
      case null:
        return 'Enrollment cancelled.';
    }
  }

  void _showResult(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}