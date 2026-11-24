import 'package:flutter/material.dart';
import '../models/onboarding_model.dart';
import '../screens/onboarding_screen.dart';

class DocumentTile extends StatelessWidget {
  final DocumentModel doc;
  final VoidCallback onDelete;

  const DocumentTile({
    super.key,
    required this.doc,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final verified = doc.verified;

    return Container(
      margin: const EdgeInsets.only(bottom: OnboardingDesign.sm),
      padding: const EdgeInsets.all(OnboardingDesign.md + 4),
      decoration: BoxDecoration(
        color: OnboardingDesign.surface,
        borderRadius: BorderRadius.circular(OnboardingDesign.radiusMd),
        border: Border.all(
          color: verified ? OnboardingDesign.primaryLight : OnboardingDesign.border,
        ),
        boxShadow: OnboardingDesign.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: verified
                  ? OnboardingDesign.successSoft
                  : OnboardingDesign.warningSoft,
              borderRadius: BorderRadius.circular(OnboardingDesign.radiusSm),
            ),
            child: Icon(
              verified ? Icons.verified_rounded : Icons.description_rounded,
              color: verified ? OnboardingDesign.success : OnboardingDesign.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: OnboardingDesign.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.type.isNotEmpty
                      ? '${doc.type[0].toUpperCase()}${doc.type.substring(1)}'
                      : doc.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: OnboardingDesign.textPrimary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doc.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: OnboardingDesign.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: OnboardingDesign.sm),
          if (verified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: OnboardingDesign.successSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Verified',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: OnboardingDesign.success,
                  letterSpacing: 0.3,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: OnboardingDesign.danger, size: 20),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}