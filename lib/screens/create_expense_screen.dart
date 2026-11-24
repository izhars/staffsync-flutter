import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../utils/validators.dart';
import '../models/expense.dart';
import '../services/expense_api.dart';
import 'expense_list_screen.dart';

// ===================== DESIGN TOKENS (mirrors ReportDesign) =====================

class ExpenseDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primarySoft = Color(0xFFEEF2FF);
  static const Color primaryLight = Color(0xFFC7D2FE);

  static const Color bg = Color(0xFFF6F7FB);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFEAECEF);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color present = Color(0xFF059669);
  static const Color presentSoft = Color(0xFFECFDF5);
  static const Color presentBorder = Color(0xFFA7F3D0);

  static const Color late = Color(0xFFD97706);
  static const Color lateSoft = Color(0xFFFFFBEB);
  static const Color lateBorder = Color(0xFFFDE68A);

  static const Color short = Color(0xFFEA580C);
  static const Color shortSoft = Color(0xFFFFF7ED);
  static const Color shortBorder = Color(0xFFFED7AA);

  static const Color absent = Color(0xFFDC2626);
  static const Color absentSoft = Color(0xFFFEF2F2);
  static const Color absentBorder = Color(0xFFFECACA);

  static const Color leave = Color(0xFF7C3AED);
  static const Color leaveSoft = Color(0xFFF5F3FF);
  static const Color leaveBorder = Color(0xFFDDD6FE);

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 14,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];
}

class CreateExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const CreateExpenseScreen({Key? key, this.expense}) : super(key: key);

  @override
  State<CreateExpenseScreen> createState() => _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends State<CreateExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final ExpenseService _expenseService = ExpenseService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  List<Category> _categories = [];
  String? _selectedCategoryId;
  File? _receiptImage;
  bool _isSubmitting = false;
  bool _isLoadingCategories = true;
  DateTime _selectedDate = DateTime.now();

  bool get _isEditMode => widget.expense != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _initializeEditMode();
    } else {
      _dateController.text = _formatDate(_selectedDate);
    }
    _fetchCategories();
  }

  void _initializeEditMode() {
    final expense = widget.expense!;
    _amountController.text = expense.amount.toString();
    _descriptionController.text = expense.description;
    _selectedCategoryId = expense.categoryId;
    _selectedDate = expense.date;
    _dateController.text = _formatDate(_selectedDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  Future<void> _fetchCategories() async {
    try {
      final categories = await _expenseService.getCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      _showSnackbar('Failed to load categories', isError: true);
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ExpenseDesign.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: ExpenseDesign.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = _formatDate(pickedDate);
      });
    }
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: ExpenseDesign.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ExpenseDesign.radiusXl),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ExpenseDesign.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Receipt',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: ExpenseDesign.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          size: 22, color: ExpenseDesign.textSecondary),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    _buildImageSourceCard(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      subtitle: 'Choose from photos',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    _buildImageSourceCard(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      subtitle: 'Take a photo',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    if (_receiptImage != null)
                      _buildImageSourceCard(
                        icon: Icons.crop_rounded,
                        label: 'Crop',
                        subtitle: 'Crop current image',
                        color: ExpenseDesign.late,
                        onTap: () {
                          Navigator.pop(context);
                          _cropImage();
                        },
                      ),
                    if (_receiptImage != null)
                      _buildImageSourceCard(
                        icon: Icons.delete_rounded,
                        label: 'Remove',
                        subtitle: 'Delete image',
                        color: ExpenseDesign.absent,
                        onTap: () {
                          Navigator.pop(context);
                          _removeImage();
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final primaryColor = color ?? ExpenseDesign.primary;
    final softColor = color == ExpenseDesign.absent
        ? ExpenseDesign.absentSoft
        : color == ExpenseDesign.late
        ? ExpenseDesign.lateSoft
        : ExpenseDesign.primarySoft;
    final borderColor = color == ExpenseDesign.absent
        ? ExpenseDesign.absentBorder
        : color == ExpenseDesign.late
        ? ExpenseDesign.lateBorder
        : ExpenseDesign.primaryLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ExpenseDesign.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: softColor,
            borderRadius: BorderRadius.circular(ExpenseDesign.radiusLg),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: primaryColor),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: ExpenseDesign.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: ExpenseDesign.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (pickedFile != null) {
        await _cropImage(File(pickedFile.path));
      }
    } catch (e) {
      _showSnackbar('Failed to pick image', isError: true);
    }
  }

  Future<void> _cropImage([File? imageToCrop]) async {
    final image = imageToCrop ?? _receiptImage;
    if (image == null) return;
    if (!await image.exists()) {
      _showSnackbar('Image file not found', isError: true);
      return;
    }

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Receipt',
            toolbarColor: ExpenseDesign.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            showCropGrid: true,
            statusBarColor: ExpenseDesign.primary,
            backgroundColor: Colors.white,
            cropFrameColor: ExpenseDesign.primary.withOpacity(0.8),
            cropFrameStrokeWidth: 2,
            cropGridColor: ExpenseDesign.primary.withOpacity(0.3),
            cropGridColumnCount: 2,
            cropGridRowCount: 2,
            cropGridStrokeWidth: 1,
            activeControlsWidgetColor: ExpenseDesign.primary,
          ),
          IOSUiSettings(
            title: 'Crop Receipt',
            aspectRatioLockEnabled: false,
            resetButtonHidden: false,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            showCancelConfirmationDialog: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() => _receiptImage = File(croppedFile.path));
        _showSnackbar('Image cropped successfully', isError: false);
      }
    } catch (e) {
      _showSnackbar('Failed to crop image', isError: true);
    }
  }

  void _removeImage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ExpenseDesign.surface,
        surfaceTintColor: ExpenseDesign.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ExpenseDesign.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ExpenseDesign.lateSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ExpenseDesign.lateBorder),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: ExpenseDesign.late, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Remove Receipt',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: ExpenseDesign.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to remove this receipt image?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: ExpenseDesign.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: ExpenseDesign.textSecondary,
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _receiptImage = null);
              _showSnackbar('Receipt removed', isError: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ExpenseDesign.absent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ExpenseDesign.radiusSm),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      _showSnackbar('Please select a category', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_isEditMode) {
        final expense = await _expenseService.updateExpense(
          expenseId: widget.expense!.id!,
          amount: double.parse(_amountController.text),
          description: _descriptionController.text.trim(),
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          receipt: _receiptImage,
        );
        _showSnackbar('Expense updated successfully', isError: false);
        Navigator.pop(context, expense);
      } else {
        final expense = await _expenseService.createExpense(
          amount: double.parse(_amountController.text),
          description: _descriptionController.text.trim(),
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          receipt: _receiptImage,
        );
        _showSnackbar('Expense created successfully', isError: false);
        Navigator.pop(context, expense);
      }
    } catch (e) {
      final message =
      _isEditMode ? 'Failed to update expense' : 'Failed to create expense';
      _showSnackbar(message, isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
        isError ? ExpenseDesign.absent : ExpenseDesign.present,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ExpenseDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── HEADER (Report-style) ──
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDesign.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ExpenseDesign.primary, ExpenseDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ExpenseDesign.radiusLg),
        boxShadow: [
          BoxShadow(
            color: ExpenseDesign.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(ExpenseDesign.radiusSm),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Icon(
              _isEditMode ? Icons.edit_rounded : Icons.receipt_long_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppDesign.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditMode ? 'Edit Expense' : 'New Expense',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isEditMode ? 'Update your expense' : 'Track your spending',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withOpacity(0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── INPUT DECORATION ──
  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: ExpenseDesign.textSecondary,
      ),
      hintStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: ExpenseDesign.textMuted,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ExpenseDesign.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: ExpenseDesign.primary, size: 18),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ExpenseDesign.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ExpenseDesign.radiusMd),
        borderSide: const BorderSide(color: ExpenseDesign.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ExpenseDesign.radiusMd),
        borderSide:
        const BorderSide(color: ExpenseDesign.primary, width: 1.6),
      ),
      filled: true,
      fillColor: ExpenseDesign.surface,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _fieldShell({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: ExpenseDesign.surface,
        borderRadius: BorderRadius.circular(ExpenseDesign.radiusMd),
        boxShadow: ExpenseDesign.softShadow,
      ),
      child: child,
    );
  }

  Widget _buildAmountField() {
    return _fieldShell(
      child: TextFormField(
        controller: _amountController,
        decoration: _inputDecoration(
          label: 'Amount',
          icon: Icons.currency_rupee,
        ),
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: ExpenseDesign.textPrimary,
          letterSpacing: -0.3,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: Validators.validateAmount,
      ),
    );
  }

  Widget _buildDateField() {
    return _fieldShell(
      child: TextFormField(
        controller: _dateController,
        decoration: _inputDecoration(
          label: 'Date',
          icon: Icons.calendar_today_rounded,
        ),
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: ExpenseDesign.textPrimary,
        ),
        readOnly: true,
        onTap: _pickDate,
        validator: (value) => Validators.validateRequired(value, 'Date'),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    if (_isLoadingCategories) {
      return _fieldShell(
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: CircularProgressIndicator(color: ExpenseDesign.primary),
          ),
        ),
      );
    }

    return _fieldShell(
      child: DropdownButtonFormField<String>(
        value: _selectedCategoryId,
        decoration: _inputDecoration(
          label: 'Category',
          icon: Icons.category_rounded,
        ),
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: ExpenseDesign.textPrimary,
        ),
        items: _categories
            .map(
              (c) => DropdownMenuItem<String>(
            value: c.id,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ExpenseDesign.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.label_rounded,
                    size: 14,
                    color: ExpenseDesign.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  c.name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: ExpenseDesign.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        )
            .toList(),
        onChanged: (value) => setState(() => _selectedCategoryId = value),
        validator: (value) =>
        value == null || value.isEmpty ? 'Please select a category' : null,
      ),
    );
  }

  Widget _buildDescriptionField() {
    return _fieldShell(
      child: TextFormField(
        controller: _descriptionController,
        decoration: _inputDecoration(
          label: 'Description',
          hint: 'What did you spend on?',
          icon: Icons.notes_rounded,
        ),
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: ExpenseDesign.textPrimary,
          height: 1.4,
        ),
        maxLines: 3,
        validator: Validators.validateDescription,
      ),
    );
  }

  Widget _buildReceiptSection() {
    final hasExistingReceipt = _isEditMode &&
        widget.expense?.receiptPath != null &&
        widget.expense!.receiptPath!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: ExpenseDesign.surface,
        borderRadius: BorderRadius.circular(ExpenseDesign.radiusLg),
        border: Border.all(color: ExpenseDesign.border, width: 1),
        boxShadow: ExpenseDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(ExpenseDesign.md),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: ExpenseDesign.primarySoft,
                    borderRadius:
                    BorderRadius.circular(ExpenseDesign.radiusSm - 2),
                    border: Border.all(
                      color: ExpenseDesign.primaryLight,
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.attach_file_rounded,
                    size: 16,
                    color: ExpenseDesign.primary,
                  ),
                ),
                const SizedBox(width: ExpenseDesign.sm + 2),
                const Text(
                  'Receipt',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ExpenseDesign.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ExpenseDesign.surfaceMuted,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: ExpenseDesign.border),
                  ),
                  child: const Text(
                    'OPTIONAL',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: ExpenseDesign.textMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: ExpenseDesign.border),
          Padding(
            padding: const EdgeInsets.all(ExpenseDesign.md - 2),
            child: _receiptImage != null
                ? _buildImagePreview(_receiptImage!)
                : hasExistingReceipt
                ? _buildExistingReceipt()
                : _buildAddReceiptButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(File image) {
    return Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(ExpenseDesign.radiusMd),
              child: Image.file(
                image,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: ExpenseDesign.surfaceMuted,
                  child: const Icon(Icons.error_outline_rounded,
                      size: 40, color: ExpenseDesign.textMuted),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  _buildImageActionButton(
                    icon: Icons.crop_rounded,
                    color: ExpenseDesign.late,
                    onTap: () => _cropImage(),
                  ),
                  const SizedBox(width: 8),
                  _buildImageActionButton(
                    icon: Icons.delete_rounded,
                    color: ExpenseDesign.absent,
                    onTap: _removeImage,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Tap crop icon to adjust or delete icon to remove',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: ExpenseDesign.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildImageActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ExpenseDesign.surface,
            shape: BoxShape.circle,
            boxShadow: ExpenseDesign.softShadow,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildExistingReceipt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Existing Receipt',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: ExpenseDesign.textMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ExpenseDesign.surfaceMuted,
            border: Border.all(color: ExpenseDesign.border),
            borderRadius: BorderRadius.circular(ExpenseDesign.radiusSm),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ExpenseDesign.primarySoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: ExpenseDesign.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.expense!.receiptPath!.split('/').last,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: ExpenseDesign.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap below to replace',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: ExpenseDesign.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildAddReceiptButton(),
      ],
    );
  }

  Widget _buildAddReceiptButton() {
    return InkWell(
      onTap: _showImagePickerBottomSheet,
      borderRadius: BorderRadius.circular(ExpenseDesign.radiusMd),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ExpenseDesign.primarySoft,
          border: Border.all(
            color: ExpenseDesign.primaryLight,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(ExpenseDesign.radiusMd),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ExpenseDesign.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                size: 28,
                color: ExpenseDesign.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isEditMode ? 'Replace Receipt' : 'Add Receipt',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: ExpenseDesign.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Take a photo or choose from gallery\nYou can crop the image after selection',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: ExpenseDesign.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ExpenseDesign.primary, ExpenseDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ExpenseDesign.radiusMd),
        boxShadow: [
          BoxShadow(
            color: ExpenseDesign.primary.withOpacity(0.30),
            blurRadius: 14,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _saveExpense,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ExpenseDesign.radiusMd),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isEditMode ? Icons.save_rounded : Icons.check_circle_rounded,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Text(
              _isEditMode ? 'Update Expense' : 'Create Expense',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExpenseDesign.bg,
      appBar: AppBar(
        backgroundColor: ExpenseDesign.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: ExpenseDesign.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDesign.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: AppDesign.md),
                _buildAmountField(),
                const SizedBox(height: AppDesign.sm + 4),
                _buildDateField(),
                const SizedBox(height: AppDesign.sm + 4),
                _buildCategoryDropdown(),
                const SizedBox(height: AppDesign.sm + 4),
                _buildDescriptionField(),
                const SizedBox(height: AppDesign.md),
                _buildReceiptSection(),
                const SizedBox(height: AppDesign.lg),
                _buildSubmitButton(),
                const SizedBox(height: AppDesign.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}