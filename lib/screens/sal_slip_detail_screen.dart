import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalarySlipDetailScreen extends StatelessWidget {
  final Map<String, dynamic> payrollData;

  const SalarySlipDetailScreen({
    super.key,
    required this.payrollData,
  });

  @override
  Widget build(BuildContext context) {
    final earnings = payrollData['earnings'] ?? {};
    final deductions = payrollData['deductions'] ?? {};
    final attendance = payrollData['attendance'] ?? {};
    final month = payrollData['month'];
    final year = payrollData['year'];
    final status = payrollData['status'];
    final netSalary = payrollData['netSalary'];
    final transactionId = payrollData['transactionId'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Salary Slip - $month $year"),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareSalarySlip(context),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadSalarySlip(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Gradient
            _buildHeader(context, month, year, status),

            // Summary Cards
            _buildSummaryCards(earnings, deductions, netSalary),

            // Detailed Sections
            _buildEarningsSection(earnings),
            _buildDeductionsSection(deductions),
            _buildAttendanceSection(attendance),
            _buildPaymentInfo(transactionId),

            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int month, int year, String status) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColorDark ?? Colors.blue[700]!,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Company Logo/Name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              "COMPANY NAME",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            "SALARY SLIP",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),

          // Period
          Text(
            "$month $year",
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.2),
              border: Border.all(color: _getStatusColor(status)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map earnings, Map deductions, double netSalary) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              "EARNINGS",
              "₹ ${(earnings['total'] ?? 0).toStringAsFixed(2)}",
              Colors.green,
              Icons.trending_up,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryCard(
              "DEDUCTIONS",
              "₹ ${(deductions['total'] ?? 0).toStringAsFixed(2)}",
              Colors.red,
              Icons.trending_down,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryCard(
              "NET SALARY",
              "₹ ${netSalary.toStringAsFixed(2)}",
              Colors.blue,
              Icons.account_balance_wallet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsSection(Map earnings) {
    final items = earnings.entries
        .where((e) => e.key != 'total')
        .toList();

    return _sectionContainer(
      title: "Earnings Breakdown",
      icon: Icons.add_circle_outline,
      color: Colors.green,
      children: [
        ...items.map((e) => _amountRow(e.key, e.value, Colors.green)),
        const Divider(height: 24),
        _amountRow("Total Earnings", earnings['total'] ?? 0, Colors.green,
            isTotal: true),
      ],
    );
  }

  Widget _buildDeductionsSection(Map deductions) {
    final items = deductions.entries
        .where((e) => e.key != 'total')
        .toList();

    return _sectionContainer(
      title: "Deductions",
      icon: Icons.remove_circle_outline,
      color: Colors.red,
      children: [
        ...items.map((e) => _amountRow(e.key, e.value, Colors.red)),
        const Divider(height: 24),
        _amountRow("Total Deductions", deductions['total'] ?? 0, Colors.red,
            isTotal: true),
      ],
    );
  }

  Widget _buildAttendanceSection(Map attendance) {
    return _sectionContainer(
      title: "Attendance Summary",
      icon: Icons.calendar_today,
      color: Colors.orange,
      children: [
        _attendanceRow("Total Working Days", attendance['workDays'] ?? 0,
            Icons.work),
        _attendanceRow("Present Days", attendance['presentDays'] ?? 0,
            Icons.check_circle),
        _attendanceRow("Absent Days", attendance['absentDays'] ?? 0,
            Icons.cancel),
        _attendanceRow("Leave Days", attendance['leaveDays'] ?? 0,
            Icons.beach_access),
        _attendanceRow("Half Days", attendance['halfDays'] ?? 0,
            Icons.access_time),
      ],
    );
  }

  Widget _buildPaymentInfo(String? transactionId) {
    return _sectionContainer(
      title: "Payment Information",
      icon: Icons.payment,
      color: Colors.purple,
      children: [
        ListTile(
          leading: const Icon(Icons.credit_card, color: Colors.blue),
          title: const Text("Payment Method"),
          subtitle: Text(payrollData['paymentMethod'] ?? "Not specified"),
        ),
        ListTile(
          leading: const Icon(Icons.receipt, color: Colors.green),
          title: const Text("Transaction ID"),
          subtitle: Text(transactionId ?? "N/A"),
        ),
        if (payrollData['paymentDate'] != null)
          ListTile(
            leading: const Icon(Icons.date_range, color: Colors.orange),
            title: const Text("Payment Date"),
            subtitle: Text(
              DateFormat('dd MMMM yyyy')
                  .format(DateTime.parse(payrollData['paymentDate'])),
            ),
          ),
      ],
    );
  }

  Widget _sectionContainer({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _amountRow(String label, dynamic value, Color color,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatLabel(label),
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey[700],
            ),
          ),
          Text(
            "₹ ${(value is num ? value : double.tryParse(value.toString()) ?? 0).toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceRow(String label, dynamic value, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.blue[700]),
      title: Text(
        _formatLabel(label),
        style: const TextStyle(fontSize: 14),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "Net Salary Received",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "₹ ${payrollData['netSalary']?.toStringAsFixed(2) ?? '0.00'}",
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "This is an electronically generated document",
            style: TextStyle(
              fontSize: 10,
              color: Colors.white54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLabel(String label) {
    return label
        .split(RegExp(r'(?=[A-Z])|_'))
        .map((word) =>
    word.isEmpty
        ? word
        : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }


  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _shareSalarySlip(BuildContext context) {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Share functionality coming soon")),
    );
  }

  void _downloadSalarySlip(BuildContext context) {
    // Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Download functionality coming soon")),
    );
  }
}