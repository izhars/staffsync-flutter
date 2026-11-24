import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../screens/expense_list_screen.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSubmit;

  const ExpenseCard({
    Key? key,
    required this.expense,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onSubmit,
  }) : super(key: key);

  // ── Palette driven by status (unified semantic tokens) ──
  Color get _statusColor {
    if (expense.isApproved) return AppDesign.present;
    if (expense.isRejected) return AppDesign.absent;
    if (expense.isDraft) return AppDesign.late;
    return AppDesign.leave; // submitted / pending
  }

  Color get _statusSoft {
    if (expense.isApproved) return AppDesign.presentSoft;
    if (expense.isRejected) return AppDesign.absentSoft;
    if (expense.isDraft) return AppDesign.lateSoft;
    return AppDesign.leaveSoft;
  }

  Color get _statusBorder {
    if (expense.isApproved) return AppDesign.presentBorder;
    if (expense.isRejected) return AppDesign.absentBorder;
    if (expense.isDraft) return AppDesign.lateBorder;
    return AppDesign.leaveBorder;
  }

  IconData get _statusIcon {
    if (expense.isApproved) return Icons.check_circle_rounded;
    if (expense.isRejected) return Icons.cancel_rounded;
    if (expense.isDraft) return Icons.edit_note_rounded;
    return Icons.schedule_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        border: Border.all(color: AppDesign.border, width: 1),
        boxShadow: AppDesign.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDesign.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppDesign.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppDesign.sm + 4),
                _buildDescription(),
                const SizedBox(height: AppDesign.sm + 4),
                _buildCategoryAndDate(),
                if (expense.isEditable) ...[
                  const SizedBox(height: AppDesign.md),
                  _buildActionButtons(),
                ],
                if (expense.isRejected && expense.rejectionReason != null) ...[
                  const SizedBox(height: AppDesign.sm + 4),
                  _buildRejectionReason(),
                ],
                if (expense.isApproved && expense.approvedAt != null) ...[
                  const SizedBox(height: AppDesign.sm + 4),
                  _buildApprovalInfo(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header: amount + status pill ──
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppDesign.presentSoft,
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  border: Border.all(color: AppDesign.presentBorder, width: 1),
                ),
                child: const Icon(
                  Icons.currency_rupee_rounded,
                  color: AppDesign.present,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppDesign.sm + 4),
              Expanded(
                child: Text(
                  expense.formattedAmount,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppDesign.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDesign.sm + 2),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _statusSoft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _statusBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon, size: 11, color: _statusColor),
          const SizedBox(width: 4),
          Text(
            expense.statusText.toUpperCase(),
            style: AppDesign.chip.copyWith(color: _statusColor),
          ),
        ],
      ),
    );
  }

  // ── Description block ──
  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(AppDesign.sm + 4),
      decoration: BoxDecoration(
        color: AppDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        border: Border.all(color: AppDesign.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.description_rounded,
            size: 15,
            color: AppDesign.textMuted,
          ),
          const SizedBox(width: AppDesign.sm),
          Expanded(
            child: Text(
              expense.description,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppDesign.textPrimary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Category + date chips ──
  Widget _buildCategoryAndDate() {
    return Wrap(
      spacing: AppDesign.sm,
      runSpacing: AppDesign.sm,
      children: [
        if (expense.categoryName != null)
          _pill(
            icon: Icons.category_rounded,
            label: expense.categoryName!,
            color: AppDesign.primary,
            bg: AppDesign.primarySoft,
            border: AppDesign.primaryLight,
          ),
        _pill(
          icon: Icons.calendar_today_rounded,
          label: expense.formattedDate,
          color: AppDesign.textSecondary,
          bg: AppDesign.surfaceMuted,
          border: AppDesign.border,
        ),
      ],
    );
  }

  Widget _pill({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ──
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.only(top: AppDesign.sm + 4),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppDesign.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (onEdit != null)
            Expanded(
              child: _outlinedBtn(
                onPressed: onEdit!,
                icon: Icons.edit_rounded,
                label: 'Edit',
              ),
            ),
          if (onEdit != null && onSubmit != null) const SizedBox(width: AppDesign.sm),
          if (onSubmit != null)
            Expanded(
              child: _gradientBtn(
                onPressed: onSubmit!,
                icon: Icons.send_rounded,
                label: 'Submit',
              ),
            ),
          if (onDelete != null) ...[
            const SizedBox(width: AppDesign.sm),
            _deleteBtn(),
          ],
        ],
      ),
    );
  }

  Widget _outlinedBtn({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: -0.1,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppDesign.primary,
        side: const BorderSide(color: AppDesign.primaryLight, width: 1.4),
        backgroundColor: AppDesign.primarySoft,
        padding: const EdgeInsets.symmetric(vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        ),
      ),
    );
  }

  Widget _gradientBtn({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppDesign.primary, AppDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        boxShadow: [
          BoxShadow(
            color: AppDesign.primary.withOpacity(0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 15),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: -0.1,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.radiusSm),
          ),
        ),
      ),
    );
  }

  Widget _deleteBtn() {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.absentSoft,
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        border: Border.all(color: AppDesign.absentBorder, width: 1.2),
      ),
      child: IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.delete_rounded, size: 16),
        color: AppDesign.absent,
        tooltip: 'Delete',
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }

  // ── Rejection / approval banners ──
  Widget _buildRejectionReason() {
    return Container(
      padding: const EdgeInsets.all(AppDesign.sm + 4),
      decoration: BoxDecoration(
        color: AppDesign.absentSoft,
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        border: Border.all(color: AppDesign.absentBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppDesign.absent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: AppDesign.absent,
              size: 14,
            ),
          ),
          const SizedBox(width: AppDesign.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REJECTION REASON',
                  style: AppDesign.label.copyWith(color: AppDesign.absent),
                ),
                const SizedBox(height: 3),
                Text(
                  expense.rejectionReason!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppDesign.absent,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalInfo() {
    return Container(
      padding: const EdgeInsets.all(AppDesign.sm + 4),
      decoration: BoxDecoration(
        color: AppDesign.presentSoft,
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        border: Border.all(color: AppDesign.presentBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppDesign.present.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: AppDesign.present,
              size: 14,
            ),
          ),
          const SizedBox(width: AppDesign.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'APPROVED',
                  style: AppDesign.label.copyWith(color: AppDesign.present),
                ),
                const SizedBox(height: 3),
                Text(
                  'on ${DateFormat('dd MMM, yyyy').format(expense.approvedAt!)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppDesign.present,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}