import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/combo_off.dart';
// ===================== SHARED DESIGN TOKENS =====================
class ComboCardDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;

  static const Color primary = Color(0xFF475569);       // slate-600
  static const Color primaryDark = Color(0xFF334155);   // slate-700
  static const Color primarySoft = Color(0xFFF1F5F9);   // slate-100
  static const Color primaryLight = Color(0xFFCBD5E1);  // slate-300

  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFEAECEF);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Status
  static const Color success = Color(0xFF059669);
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

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

class ComboOffCard extends StatelessWidget {
  final ComboOff combo;
  final VoidCallback onDelete;

  const ComboOffCard({
    Key? key,
    required this.combo,
    required this.onDelete,
  }) : super(key: key);

  // ===================== STATE DERIVATIONS =====================

  (Color, Color, Color) get _statusStyle {
    switch (combo.status.toLowerCase()) {
      case 'approved':
        return (
        ComboCardDesign.success,
        ComboCardDesign.successSoft,
        ComboCardDesign.successBorder
        );
      case 'rejected':
        return (
        ComboCardDesign.danger,
        ComboCardDesign.dangerSoft,
        ComboCardDesign.dangerBorder
        );
      default:
        return (
        ComboCardDesign.warning,
        ComboCardDesign.warningSoft,
        ComboCardDesign.warningBorder
        );
    }
  }

  IconData get _statusIcon {
    switch (combo.status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_bottom_rounded;
    }
  }

  bool get _isPending => combo.status.toLowerCase() == 'pending';

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusSoft, statusBorder) = _statusStyle;

    return Container(
      margin: const EdgeInsets.only(bottom: ComboCardDesign.sm + 4),
      decoration: BoxDecoration(
        color: ComboCardDesign.surface,
        borderRadius: BorderRadius.circular(ComboCardDesign.radiusLg),
        border: Border.all(color: ComboCardDesign.border, width: 1),
        boxShadow: ComboCardDesign.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ComboCardDesign.radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Accent bar =====
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withOpacity(0.6)],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(ComboCardDesign.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Header row =====
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon tile
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: statusSoft,
                          borderRadius: BorderRadius.circular(
                            ComboCardDesign.radiusSm,
                          ),
                          border: Border.all(
                            color: statusBorder,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.work_off_rounded,
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: ComboCardDesign.sm + 4),

                      // Reason + date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              combo.reason,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: ComboCardDesign.textPrimary,
                                letterSpacing: -0.2,
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 11,
                                  color: ComboCardDesign.textMuted,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  DateFormat('EEE, MMM dd, yyyy')
                                      .format(combo.date.toLocal()),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: ComboCardDesign.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Delete (only when pending)
                      if (_isPending) ...[
                        const SizedBox(width: ComboCardDesign.xs),
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            ComboCardDesign.radiusSm,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              ComboCardDesign.radiusSm,
                            ),
                            onTap: onDelete,
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: ComboCardDesign.dangerSoft,
                                borderRadius: BorderRadius.circular(
                                  ComboCardDesign.radiusSm,
                                ),
                                border: Border.all(
                                  color: ComboCardDesign.dangerBorder,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: ComboCardDesign.danger,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: ComboCardDesign.md),
                  Container(
                    height: 1,
                    color: ComboCardDesign.border,
                  ),
                  const SizedBox(height: ComboCardDesign.md),

                  // ===== Footer row =====
                  Row(
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ComboCardDesign.sm + 2,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusSoft,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusBorder,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _statusIcon,
                              size: 13,
                              color: statusColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              combo.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 9.5,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Reviewed by
                      if (combo.approvedBy != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ComboCardDesign.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ComboCardDesign.surfaceMuted,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: ComboCardDesign.border,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 11,
                                color: ComboCardDesign.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Reviewed by HR',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: ComboCardDesign.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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