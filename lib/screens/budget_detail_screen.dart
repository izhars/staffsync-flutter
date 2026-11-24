import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/project_service.dart';
import '../models/project_model.dart';

class BudgetDetailScreen extends StatefulWidget {
  final Project project;

  const BudgetDetailScreen({Key? key, required this.project}) : super(key: key);

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  final ProjectService _projectService = ProjectService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  DateTime? _selectedDate;
  List<dynamic> _expenses = [];
  double _totalSpent = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenseHistory();
  }

  Future<void> _loadExpenseHistory() async {
    setState(() => _isLoading = true);

    final result = await _projectService.getExpenseHistory(widget.project.id);

    if (result['success']) {
      final data = result['data'];
      setState(() {
        _expenses = data['expenses'] ?? [];
        _totalSpent = data['totalSpent']?.toDouble() ?? 0;
        _isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addExpense() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await _projectService.addExpense(
      projectId: widget.project.id,
      amount: amount,
      remark: _remarkController.text.trim().isEmpty ? null : _remarkController.text.trim(),
      date: _selectedDate,
    );

    if (result['success']) {
      _amountController.clear();
      _remarkController.clear();
      setState(() => _selectedDate = null);
      _loadExpenseHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense recorded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: widget.project.startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Widget _buildBudgetStatus(double allocated, double spent) {
    final remaining = allocated - spent;
    final utilization = allocated > 0 ? (spent / allocated) * 100 : 0;
    final isOverBudget = spent > allocated;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.project.code,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.project.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOverBudget ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOverBudget ? Colors.red.shade200 : Colors.green.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOverBudget ? Icons.warning_amber_rounded : Icons.check_circle,
                        color: isOverBudget ? Colors.red : Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOverBudget ? 'Over Budget' : 'Within Budget',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOverBudget ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildBudgetCard(
                    'Allocated',
                    allocated,
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBudgetCard(
                    'Spent',
                    spent,
                    Icons.payments,
                    isOverBudget ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBudgetCard(
                    'Remaining',
                    remaining > 0 ? remaining : 0,
                    Icons.savings,
                    remaining > 0 ? Colors.purple : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget Utilization',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${utilization.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        double width = utilization * constraints.maxWidth / 100;
                        if (width > constraints.maxWidth) width = constraints.maxWidth;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          height: 8,
                          width: width,
                          decoration: BoxDecoration(
                            color: utilization > 90
                                ? Colors.red
                                : utilization > 75
                                ? Colors.orange
                                : Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      '100%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${NumberFormat('#,##,###').format(amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(dynamic exp) {
    final date = DateTime.tryParse(exp['date'] ?? '') ?? DateTime.now();
    final recordedBy = exp['recordedBy'];
    final name = recordedBy != null
        ? '${recordedBy['firstName'] ?? ''} ${recordedBy['lastName'] ?? ''}'.trim()
        : 'Unknown';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt, color: Colors.blue),
          ),
          title: Row(
            children: [
              Text(
                '₹${NumberFormat('#,##,###').format(exp['amount'])}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              if (exp['remark'] != null && exp['remark'].toString().isNotEmpty)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      exp['remark'],
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(date),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allocated = widget.project.budgetAllocated?.toDouble() ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Budget Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenseHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue,
              Color(0xFFE3F2FD),
            ],
            stops: [0, 0.2],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadExpenseHistory,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Budget Summary
                _buildBudgetStatus(allocated, _totalSpent),
                const SizedBox(height: 24),

                // Add New Expense Form
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
                                color: Colors.blue.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_circle, color: Colors.blue),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Record New Expense',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Amount (₹)',
                            labelStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            prefixIcon: const Icon(Icons.currency_rupee, color: Colors.blue),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _remarkController,
                          decoration: InputDecoration(
                            labelText: 'Remark (optional)',
                            labelStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            prefixIcon: const Icon(Icons.note, color: Colors.blue),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      _selectedDate == null
                                          ? 'Today'
                                          : DateFormat('dd MMM yyyy').format(_selectedDate!),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _selectDate,
                              icon: const Icon(Icons.calendar_month),
                              label: const Text('Pick Date'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white, // 👈 text + icon color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _addExpense,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              shadowColor: Colors.blue.withOpacity(0.3),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Record Expense',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Expense History Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.history, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Expense History',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_expenses.length} items',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Expense List
                _isLoading
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                )
                    : _expenses.isEmpty
                    ? Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No expenses recorded yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first expense above',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
                    : Column(
                  children: _expenses.map((exp) => _buildExpenseCard(exp)).toList(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }
}