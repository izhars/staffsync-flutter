import 'package:flutter/material.dart';

class AssignmentRecord {
  final String id;
  final String employee;
  final DateTime assignedDate;
  final DateTime? returnedDate;
  final String condition;
  final String remarks;

  AssignmentRecord({
    required this.id,
    required this.employee,
    required this.assignedDate,
    this.returnedDate,
    required this.condition,
    required this.remarks,
  });

  factory AssignmentRecord.fromJson(Map<String, dynamic> json) {
    return AssignmentRecord(
      id: json['_id'],
      employee: json['employee'],
      assignedDate: DateTime.parse(json['assignedDate']),
      returnedDate: json['returnedDate'] != null
          ? DateTime.parse(json['returnedDate'])
          : null,
      condition: json['condition'],
      remarks: json['remarks'] ?? '',
    );
  }
}

class Asset {
  final String id;
  final String assetId;
  final String name;
  final String category;
  final String? brand;
  final String? model;
  final DateTime purchaseDate;
  final double purchasePrice;
  final String status;
  final String condition;
  final DateTime? assignedDate;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AssignmentRecord> assignmentHistory; // Add this
  final String? location; // Also missing from your model

  Asset({
    required this.id,
    required this.assetId,
    required this.name,
    required this.category,
    this.brand,
    this.model,
    required this.purchaseDate,
    required this.purchasePrice,
    required this.status,
    required this.condition,
    this.assignedDate,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    required this.assignmentHistory, // Add to constructor
    this.location, // Add location
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    // Parse assignment history
    final List<dynamic> historyJson = json['assignmentHistory'] ?? [];
    final assignmentHistory = historyJson
        .map((record) => AssignmentRecord.fromJson(record))
        .toList();

    return Asset(
      id: json['_id'],
      assetId: json['assetId']?.toString().trim() ?? '',
      name: json['name'],
      category: json['category'],
      brand: json['brand'],
      model: json['model'],
      purchaseDate: DateTime.parse(json['purchaseDate']),
      purchasePrice: json['purchasePrice'] is int
          ? (json['purchasePrice'] as int).toDouble()
          : json['purchasePrice'].toDouble(),
      status: json['status'],
      condition: json['condition'],
      assignedDate: json['assignedDate'] != null
          ? DateTime.parse(json['assignedDate'])
          : null,
      assignedTo: json['assignedTo'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      assignmentHistory: assignmentHistory, // Add this
      location: json['location'], // Add location
    );
  }

  // Add useful getters for assignment history
  AssignmentRecord? get currentAssignment {
    if (assignmentHistory.isEmpty) return null;

    // Sort by assigned date (most recent first)
    final sortedHistory = List<AssignmentRecord>.from(assignmentHistory)
      ..sort((a, b) => b.assignedDate.compareTo(a.assignedDate));

    return sortedHistory.firstWhere(
          (record) => record.returnedDate == null,
      orElse: () => sortedHistory.first, // Return most recent if all are returned
    );
  }

  bool get hasAssignmentHistory => assignmentHistory.isNotEmpty;

  int get totalAssignments => assignmentHistory.length;

  // Get assignment duration in days
  double get averageAssignmentDuration {
    if (assignmentHistory.isEmpty) return 0;

    final completedAssignments = assignmentHistory
        .where((record) => record.returnedDate != null)
        .toList();

    if (completedAssignments.isEmpty) return 0;

    final totalDays = completedAssignments.fold<double>(0, (sum, record) {
      final duration = record.returnedDate!.difference(record.assignedDate);
      return sum + duration.inDays;
    });

    return totalDays / completedAssignments.length;
  }

  // Rest of your existing getters...
  String get brandModelDisplay {
    if (brand != null && model != null) {
      return '$brand - $model';
    } else if (brand != null) {
      return brand!;
    } else if (model != null) {
      return model!;
    }
    return 'No details';
  }

  String get formattedPrice => '\$${purchasePrice.toStringAsFixed(2)}';

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(purchaseDate);

    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'assigned':
        return Colors.green;
      case 'available':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      case 'retired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String get statusText {
    switch (status) {
      case 'assigned':
        return 'Assigned';
      case 'available':
        return 'Available';
      case 'maintenance':
        return 'In Maintenance';
      case 'retired':
        return 'Retired';
      default:
        return status;
    }
  }
}