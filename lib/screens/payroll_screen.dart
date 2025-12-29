import 'package:flutter/material.dart';
import '../services/api_exception.dart';
import '../services/payroll_api.dart';
import 'sal_slip_detail_screen.dart';

class PayrollListScreen extends StatefulWidget {
  const PayrollListScreen({super.key});

  @override
  State<PayrollListScreen> createState() => _PayrollListScreenState();
}

class _PayrollListScreenState extends State<PayrollListScreen> {
  final PayrollService _payrollService = PayrollService();

  bool loading = true;
  String? error;
  List<dynamic> payrolls = [];

  @override
  void initState() {
    super.initState();
    _loadPayrolls();
  }

  Future<void> _loadPayrolls() async {
    try {
      payrolls = await _payrollService.fetchMyPayrolls();
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = "Something went wrong";
    }

    setState(() => loading = false);
  }

  Future<void> _refresh() async {
    setState(() => loading = true);
    await _loadPayrolls();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Salary Slips"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loading ? null : _refresh,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(error!,
                style: const TextStyle(fontSize: 16, color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (payrolls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("No salary slips found",
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: payrolls.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final payroll = payrolls[index];
          return _payrollCard(payroll, context);
        },
      ),
    );
  }

  Widget _payrollCard(Map<String, dynamic> payroll, BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SalarySlipDetailScreen(payrollData: payroll),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${payroll['month']} ${payroll['year']}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Transaction: ${payroll['transactionId'] ?? 'N/A'}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Chip(
                    label: Text(
                      payroll['status'].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: _getStatusColor(payroll['status']),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Net Salary",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹ ${payroll['netSalary']?.toStringAsFixed(2) ?? '0.00'}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "Payment Method",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _getPaymentMethodIcon(payroll['paymentMethod']),
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            payroll['paymentMethod'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Tap to view details →",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon(String? method) {
    switch (method?.toLowerCase()) {
      case 'bank transfer':
        return Icons.account_balance;
      case 'upi':
        return Icons.payment;
      case 'cash':
        return Icons.money;
      default:
        return Icons.credit_card;
    }
  }
}