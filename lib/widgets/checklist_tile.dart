import 'package:flutter/material.dart';
import '../models/onboarding_model.dart';
import '../screens/onboarding_screen.dart';

class ChecklistTile extends StatelessWidget {
  final ChecklistItemModel item;
  final bool busy;
  final VoidCallback onToggle;

  const ChecklistTile({
    super.key,
    required this.item,
    required this.busy,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final completed = item.completed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: OnboardingDesign.sm),
      padding: const EdgeInsets.all(OnboardingDesign.md + 4),
      decoration: BoxDecoration(
        color: completed ? OnboardingDesign.primarySoft : OnboardingDesign.surface,
        borderRadius: BorderRadius.circular(OnboardingDesign.radiusMd),
        border: Border.all(
          color: completed ? OnboardingDesign.primaryLight : OnboardingDesign.border,
        ),
        boxShadow: OnboardingDesign.softShadow,
      ),
      child: Row(
        children: [
          _CheckButton(checked: completed, busy: busy, onTap: onToggle),
          const SizedBox(width: OnboardingDesign.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: completed
                        ? OnboardingDesign.textMuted
                        : OnboardingDesign.textPrimary,
                    decoration:
                    completed ? TextDecoration.lineThrough : null,
                    decorationColor: OnboardingDesign.textMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: OnboardingDesign.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          if (item.required) ...[
            const SizedBox(width: OnboardingDesign.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: OnboardingDesign.dangerSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Required',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: OnboardingDesign.danger,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  final bool checked;
  final bool busy;
  final VoidCallback onTap;

  const _CheckButton({
    required this.checked,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: checked ? OnboardingDesign.primary : OnboardingDesign.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: checked ? OnboardingDesign.primary : OnboardingDesign.border,
            width: 1.5,
          ),
        ),
        child: busy
            ? const Padding(
          padding: EdgeInsets.all(6),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: OnboardingDesign.primary,
          ),
        )
            : checked
            ? const Icon(Icons.check_rounded,
            size: 17, color: Colors.white)
            : null,
      ),
    );
  }
}