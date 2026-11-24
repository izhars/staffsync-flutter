class Validators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  // ────────────────────────────────────────────────────────────
  // Employee ID — matches backend schema: ^[A-Z]+[0-9]+$
  // Example valid: SCAIPLE001, HR001, EMP123
  // ────────────────────────────────────────────────────────────
  static String? employeeId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Employee ID is required';
    }

    final id = value.trim().toUpperCase();

    // Must be letters followed by numbers (e.g., SCAIPLE001)
    final regex = RegExp(r'^[A-Z]+[0-9]+$');
    if (!regex.hasMatch(id)) {
      return 'Format: letters followed by numbers (e.g., SCAIPLE001)';
    }

    // Reasonable length guard (adjust if your IDs are longer/shorter)
    if (id.length < 4 || id.length > 20) {
      return 'Employee ID must be 4–20 characters';
    }

    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegExp = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    if (!phoneRegExp.hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }

    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }

    if (value.length < 3) {
      return 'Description must be at least 3 characters';
    }

    return null;
  }
}