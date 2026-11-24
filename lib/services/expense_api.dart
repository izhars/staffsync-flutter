import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'network_service.dart';
import '../models/expense.dart';

class ExpenseService {
  final NetworkService _network = NetworkService();

  Future<List<Category>> getCategories() async {
    final response = await _network.get('/expense-categories');
    final List<dynamic> data = response['data'];
    return data.map((json) => Category.fromJson(json)).toList();
  }

  // ----------------------------
  // CREATE EXPENSE
  // ----------------------------
  Future<Expense> createExpense({
    required double amount,
    required String description,
    required String categoryId,
    required DateTime date,
    File? receipt,
  }) async {
    print('[EXPENSE] Creating expense: amount=$amount, category=$categoryId, date=$date');

    final data = <String, String>{
      'amount': amount.toString(),
      'description': description,
      'category': categoryId,
      'date': date.toIso8601String().split('T')[0],
    };

    print('[EXPENSE] Data to send: $data');

    if (receipt != null) {
      print('[EXPENSE] Receipt file detected');
      print('[EXPENSE] File path: ${receipt.path}');
      print('[EXPENSE] File extension: ${path.extension(receipt.path)}');

      final exists = await receipt.exists();
      final length = exists ? await receipt.length() : 0;

      print('[EXPENSE] File exists: $exists, size: $length bytes');

      final mimeType = lookupMimeType(receipt.path);
      print('[EXPENSE] File MIME type: $mimeType');

      if (!exists) {
        throw Exception('[EXPENSE] Receipt file does not exist');
      }

      try {
        print('[EXPENSE] Uploading expense with receipt...');
        final response = await _network.uploadFile(
          '/expenses',
          receipt.path,
          data,
          'receipt',
        );

        print('[EXPENSE] Upload response: $response');

        if (response['success'] == true) {
          print('[EXPENSE] Expense created successfully with receipt');
          return Expense.fromJson(response['data']);
        } else {
          throw Exception(response['message'] ?? 'Failed to create expense');
        }
      } catch (e) {
        print('[EXPENSE] Error uploading with receipt: $e');
        rethrow;
      }
    } else {
      try {
        print('[EXPENSE] Creating expense without receipt...');
        final response = await _network.post('/expenses', data);

        print('[EXPENSE] Response: $response');

        if (response['success'] == true) {
          print('[EXPENSE] Expense created successfully without receipt');
          return Expense.fromJson(response['data']);
        } else {
          throw Exception(response['message'] ?? 'Failed to create expense');
        }
      } catch (e) {
        print('[EXPENSE] Error creating without receipt: $e');
        rethrow;
      }
    }
  }

  // ----------------------------
  // UPDATE EXPENSE
  // ----------------------------
  Future<Expense> updateExpense({
    required String expenseId,
    double? amount,
    String? description,
    String? categoryId,
    DateTime? date,
    File? receipt,
  }) async {
    final updateData = <String, String>{};

    if (amount != null) updateData['amount'] = amount.toString();
    if (description != null) updateData['description'] = description;
    if (categoryId != null) updateData['category'] = categoryId;
    if (date != null) updateData['date'] = date.toIso8601String().split('T')[0];

    print('[EXPENSE] Updating expense $expenseId with data: $updateData');

    if (receipt != null) {
      try {
        if (!await receipt.exists()) {
          throw Exception('Receipt file does not exist');
        }

        print('[EXPENSE] Updating expense with receipt: ${receipt.path}');

        // Use PUT method for update with file
        final response = await _network.uploadFileWithMethod(
          '/expenses/$expenseId',
          receipt.path,
          updateData,
          'receipt',
          'PUT', // Use PUT method instead of POST
        );

        print('[EXPENSE] Update response: $response');

        if (response['success'] == true) {
          return Expense.fromJson(response['data']);
        } else {
          throw Exception(response['message'] ?? 'Failed to update expense');
        }
      } catch (e) {
        print('[EXPENSE] Error updating with receipt: $e');
        rethrow;
      }
    } else {
      try {
        print('[EXPENSE] Updating expense without receipt');

        final response = await _network.put('/expenses/$expenseId', {
          'amount': amount,
          'description': description,
          'category': categoryId,
          'date': date?.toIso8601String().split('T')[0],
        });

        print('[EXPENSE] Update response: $response');

        if (response['success'] == true) {
          return Expense.fromJson(response['data']);
        } else {
          throw Exception(response['message'] ?? 'Failed to update expense');
        }
      } catch (e) {
        print('[EXPENSE] Error updating without receipt: $e');
        rethrow;
      }
    }
  }

  // ----------------------------
  // DELETE EXPENSE
  // ----------------------------
  Future<void> deleteExpense(String expenseId) async {
    print('[EXPENSE] Deleting expense $expenseId');

    final response = await _network.delete('/expenses/$expenseId');

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete expense');
    }

    print('[EXPENSE] Expense deleted: $expenseId');
  }

  // ----------------------------
  // SUBMIT EXPENSE
  // ----------------------------
  Future<Expense> submitExpense(String expenseId) async {
    print('[EXPENSE] Submitting expense $expenseId');

    final response = await _network.post('/expenses/$expenseId/submit', {});

    if (response['success'] == true) {
      print('[EXPENSE] Expense submitted');
      return Expense.fromJson(response['data']);
    } else {
      throw Exception(response['message'] ?? 'Failed to submit expense');
    }
  }

  // ----------------------------
  // GET USER EXPENSES
  // ----------------------------
  Future<List<Expense>> getMyExpenses({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status,
      if (category != null) 'category': category,
      if (startDate != null) 'startDate': startDate.toIso8601String().split('T')[0],
      if (endDate != null) 'endDate': endDate.toIso8601String().split('T')[0],
    };

    final url = '/expenses/me?${Uri(queryParameters: queryParams).query}';
    print('[EXPENSE] Fetching expenses: $url');

    final response = await _network.get(url);

    if (response['success'] == true) {
      final List<dynamic> expensesJson = response['data'];
      print('[EXPENSE] Fetched ${expensesJson.length} expenses');
      return expensesJson.map((json) => Expense.fromJson(json)).toList();
    } else {
      throw Exception(response['message'] ?? 'Failed to fetch expenses');
    }
  }

  // ----------------------------
  // GET SINGLE EXPENSE
  // ----------------------------
  Future<Expense> getExpenseById(String expenseId) async {
    print('[EXPENSE] Fetching expense $expenseId');

    final response = await _network.get('/expenses/$expenseId');

    if (response['success'] == true) {
      return Expense.fromJson(response['data']);
    } else {
      throw Exception(response['message'] ?? 'Failed to fetch expense');
    }
  }

  // ----------------------------
  // GET EXPENSE STATS
  // ----------------------------
  Future<Map<String, dynamic>> getExpenseStats() async {
    print('[EXPENSE] Fetching expense stats');

    final response = await _network.get('/expenses/stats');

    if (response['success'] == true) {
      return response['data'];
    } else {
      return _calculateStats();
    }
  }

  Future<Map<String, dynamic>> _calculateStats() async {
    print('[EXPENSE] Calculating stats locally');

    final expenses = await getMyExpenses();

    double totalAmount = 0;
    double approvedAmount = 0;
    double pendingAmount = 0;

    int draftCount = 0;
    int submittedCount = 0;
    int approvedCount = 0;
    int rejectedCount = 0;

    for (var expense in expenses) {
      totalAmount += expense.amount;

      switch (expense.status) {
        case 'draft':
          draftCount++;
          break;
        case 'submitted':
          submittedCount++;
          pendingAmount += expense.amount;
          break;
        case 'approved':
          approvedCount++;
          approvedAmount += expense.amount;
          break;
        case 'rejected':
          rejectedCount++;
          break;
      }
    }

    return {
      'totalAmount': totalAmount,
      'approvedAmount': approvedAmount,
      'pendingAmount': pendingAmount,
      'draftCount': draftCount,
      'submittedCount': submittedCount,
      'approvedCount': approvedCount,
      'rejectedCount': rejectedCount,
      'totalCount': expenses.length,
    };
  }
}
