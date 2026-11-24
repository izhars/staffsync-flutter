// lib/models/company_policy.dart
import 'package:flutter/material.dart';

class PolicyVersionItem {
  final String version;
  final String documentUrl;
  final String documentName;
  final String summaryOfChanges;
  final DateTime effectiveDate;
  final DateTime? publishedAt;

  PolicyVersionItem({
    required this.version,
    required this.documentUrl,
    required this.documentName,
    required this.summaryOfChanges,
    required this.effectiveDate,
    this.publishedAt,
  });

  factory PolicyVersionItem.fromJson(Map<String, dynamic> json) {
    return PolicyVersionItem(
      version: json['version']?.toString() ?? '1.0',
      documentUrl: json['documentUrl']?.toString() ?? '',
      documentName: json['documentName']?.toString() ?? '',
      summaryOfChanges: json['summaryOfChanges']?.toString() ?? '',
      effectiveDate: json['effectiveDate'] != null
          ? DateTime.tryParse(json['effectiveDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
    );
  }
}

class CompanyPolicy {
  final String id;
  final String title;
  final String description;
  final String category;
  final String documentUrl;
  final String documentName;
  final int fileSize;
  final String mimeType;
  final String version;
  final DateTime effectiveDate;
  final bool isMandatory;
  final String status;
  bool isAcknowledged;
  DateTime? acknowledgedAt;
  String? acknowledgedVersion;
  final List<PolicyVersionItem> versionHistory;
  final DateTime? createdAt;

  CompanyPolicy({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.documentUrl,
    required this.documentName,
    required this.fileSize,
    required this.mimeType,
    required this.version,
    required this.effectiveDate,
    required this.isMandatory,
    required this.status,
    required this.isAcknowledged,
    this.acknowledgedAt,
    this.acknowledgedVersion,
    this.versionHistory = const [],
    this.createdAt,
  });

  factory CompanyPolicy.fromJson(Map<String, dynamic> json) {
    final userAck = json['userAcknowledgement'] as Map<String, dynamic>?;

    final versionsList = (json['versionHistory'] as List<dynamic>?)
            ?.map((v) => PolicyVersionItem.fromJson(v as Map<String, dynamic>))
            .toList() ??
        [];

    return CompanyPolicy(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Company Policy',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
      documentUrl: json['documentUrl']?.toString() ?? '',
      documentName: json['documentName']?.toString() ?? 'Policy_Document.pdf',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      mimeType: json['mimeType']?.toString() ?? 'application/pdf',
      version: json['version']?.toString() ?? '1.0',
      effectiveDate: json['effectiveDate'] != null
          ? DateTime.tryParse(json['effectiveDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isMandatory: json['isMandatory'] == true,
      status: json['status']?.toString() ?? 'published',
      isAcknowledged: json['isAcknowledged'] == true,
      acknowledgedAt: userAck?['acknowledgedAt'] != null
          ? DateTime.tryParse(userAck!['acknowledgedAt'].toString())
          : null,
      acknowledgedVersion: userAck?['policyVersion']?.toString(),
      versionHistory: versionsList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  String get categoryDisplay {
    switch (category) {
      case 'attendance':
        return 'Attendance';
      case 'leave':
        return 'Leave';
      case 'payroll':
        return 'Payroll';
      case 'reimbursement':
        return 'Reimbursement';
      case 'code_of_conduct':
        return 'Code of Conduct';
      case 'it_security':
        return 'IT Security';
      case 'employment':
        return 'Employment';
      case 'wfh':
        return 'WFH';
      default:
        return 'General';
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case 'attendance':
        return Icons.alarm_on_rounded;
      case 'leave':
        return Icons.beach_access_rounded;
      case 'payroll':
        return Icons.account_balance_wallet_rounded;
      case 'reimbursement':
        return Icons.receipt_long_rounded;
      case 'code_of_conduct':
        return Icons.verified_user_rounded;
      case 'it_security':
        return Icons.security_rounded;
      case 'employment':
        return Icons.business_center_rounded;
      case 'wfh':
        return Icons.home_work_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'attendance':
        return const Color(0xFF1E40AF);
      case 'leave':
        return const Color(0xFFD97706);
      case 'payroll':
        return const Color(0xFF0F766E);
      case 'reimbursement':
        return const Color(0xFF7C3AED);
      case 'code_of_conduct':
        return const Color(0xFFDC2626);
      case 'it_security':
        return const Color(0xFF0284C7);
      case 'employment':
        return const Color(0xFF059669);
      case 'wfh':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF4B5563);
    }
  }
}
