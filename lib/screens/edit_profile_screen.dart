// screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class ReportDesign {
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

  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color bg = Color(0xFFF6F7FB);
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

  static const Color holiday = Color(0xFF2563EB);
  static const Color holidaySoft = Color(0xFFEFF6FF);
  static const Color holidayBorder = Color(0xFFBFDBFE);

  static const Color comboOff = Color(0xFF0D9488);
  static const Color comboOffSoft = Color(0xFFF0FDFA);
  static const Color comboOffBorder = Color(0xFF99F6E4);

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

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _dateOfBirthController;
  late final TextEditingController _marriageAnniversaryController;
  late final TextEditingController _bloodGroupController;
  late final TextEditingController _panNumberController;
  late final TextEditingController _pfNumberController;
  late final TextEditingController _uanNumberController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _countryController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _ifscCodeController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyPhoneController;

  String? _selectedGender;
  String? _selectedMaritalStatus;
  bool? _spouseIsWorking;

  bool _isSaving = false;

  final List<String> _genderOptions = const ['male', 'female', 'other'];
  final List<String> _maritalStatusOptions =
  const ['single', 'married', 'divorced', 'widowed'];
  final List<String> _bloodGroupOptions =
  const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    final u = widget.user;
    _firstNameController = TextEditingController(text: u.firstName);
    _lastNameController = TextEditingController(text: u.lastName);
    _phoneController = TextEditingController(text: u.phone);
    _dateOfBirthController = TextEditingController(
      text: u.dateOfBirth != null
          ? DateFormat('yyyy-MM-dd').format(u.dateOfBirth!)
          : '',
    );
    _marriageAnniversaryController = TextEditingController(
      text: u.marriageAnniversary != null
          ? DateFormat('yyyy-MM-dd').format(u.marriageAnniversary!)
          : '',
    );
    _bloodGroupController = TextEditingController(text: u.bloodGroup ?? '');
    _panNumberController = TextEditingController(text: u.panNumber ?? '');
    _pfNumberController = TextEditingController(text: u.pfNumber ?? '');
    _uanNumberController = TextEditingController(text: u.uanNumber ?? '');

    _selectedGender = u.gender;
    _selectedMaritalStatus = u.maritalStatus;

    _streetController = TextEditingController(text: u.address?.street ?? '');
    _cityController = TextEditingController(text: u.address?.city ?? '');
    _stateController = TextEditingController(text: u.address?.state ?? '');
    _countryController = TextEditingController(text: u.address?.country ?? '');
    _postalCodeController =
        TextEditingController(text: u.address?.postalCode ?? '');

    _bankNameController =
        TextEditingController(text: u.bankDetails?.bankName ?? '');
    _accountNumberController =
        TextEditingController(text: u.bankDetails?.accountNumber ?? '');
    _ifscCodeController =
        TextEditingController(text: u.bankDetails?.ifscCode ?? '');

    _emergencyNameController =
        TextEditingController(text: u.emergencyContact?.name ?? '');
    _emergencyPhoneController =
        TextEditingController(text: u.emergencyContact?.phone ?? '');

    _spouseIsWorking = u.spouseDetails?.isWorking ?? false;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _marriageAnniversaryController.dispose();
    _bloodGroupController.dispose();
    _panNumberController.dispose();
    _pfNumberController.dispose();
    _uanNumberController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final parsed = controller.text.isNotEmpty
        ? DateFormat('yyyy-MM-dd').parse(controller.text)
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: parsed,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: ReportDesign.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: ReportDesign.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  /// Builds the update payload — no HTTP here.
  Map<String, dynamic>? _buildUpdatePayload() {
    final updateData = <String, dynamic>{};

    // Personal
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    if (first.isNotEmpty) updateData['firstName'] = first;
    if (last.isNotEmpty) updateData['lastName'] = last;
    if (_phoneController.text.trim().isNotEmpty) {
      updateData['phone'] = _phoneController.text.trim();
    }
    if (_selectedGender != null) updateData['gender'] = _selectedGender;
    if (_bloodGroupController.text.isNotEmpty) {
      updateData['bloodGroup'] = _bloodGroupController.text.trim();
    }
    if (_dateOfBirthController.text.isNotEmpty) {
      updateData['dateOfBirth'] = _dateOfBirthController.text;
    }

    // Marital
    if (_selectedMaritalStatus != null) {
      updateData['maritalStatus'] = _selectedMaritalStatus;
      if (_selectedMaritalStatus == 'married') {
        if (_marriageAnniversaryController.text.isEmpty) {
          _showErrorSnackBar(
              'Marriage anniversary is required for married status');
          return null;
        }
        updateData['marriageAnniversary'] =
            _marriageAnniversaryController.text;
        updateData['spouseDetails'] = {
          'isWorking': _spouseIsWorking ?? false,
        };
      } else {
        updateData['spouseDetails'] = {};
      }
    }

    // Address — only send when at least one field has content
    final address = {
      'street': _streetController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'country': _countryController.text.trim(),
      'postalCode': _postalCodeController.text.trim(),
    };
    if (address.values.any((v) => v.isNotEmpty)) {
      updateData['address'] = address;
    }

    // Government IDs
    if (_panNumberController.text.isNotEmpty) {
      updateData['panNumber'] = _panNumberController.text.trim();
    }
    if (_pfNumberController.text.isNotEmpty) {
      updateData['pfNumber'] = _pfNumberController.text.trim();
    }
    if (_uanNumberController.text.isNotEmpty) {
      updateData['uanNumber'] = _uanNumberController.text.trim();
    }

    // Bank
    final bank = {
      'bankName': _bankNameController.text.trim(),
      'accountNumber': _accountNumberController.text.trim(),
      'ifscCode': _ifscCodeController.text.trim(),
    };
    if (bank.values.any((v) => v.isNotEmpty)) {
      updateData['bankDetails'] = bank;
    }

    // Emergency contact
    final emergency = {
      'name': _emergencyNameController.text.trim(),
      'phone': _emergencyPhoneController.text.trim(),
    };
    if (emergency.values.any((v) => v.isNotEmpty)) {
      updateData['emergencyContact'] = emergency;
    }

    return updateData;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = _buildUpdatePayload();
    if (payload == null) return; // validation short-circuit
    if (payload.isEmpty) {
      _showErrorSnackBar('No changes to save');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _authService.updateProfile(payload); // ← API lives in service
      if (!mounted) return;
      _showSuccessSnackBar('Profile updated successfully!');
      Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.message);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to update profile: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        backgroundColor: ReportDesign.present,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(ReportDesign.md),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        backgroundColor: ReportDesign.absent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(ReportDesign.md),
      ),
    );
  }

  // ===================== UI HELPERS (ReportScreen style) =====================

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: ReportDesign.md),
      padding: const EdgeInsets.all(ReportDesign.md),
      decoration: BoxDecoration(
        color: ReportDesign.surface,
        borderRadius: BorderRadius.circular(ReportDesign.radiusLg),
        border: Border.all(color: ReportDesign.border, width: 1),
        boxShadow: ReportDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ReportDesign.primarySoft,
                  borderRadius:
                  BorderRadius.circular(ReportDesign.radiusSm - 2),
                  border: Border.all(
                    color: ReportDesign.primaryLight,
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: ReportDesign.primary, size: 16),
              ),
              const SizedBox(width: ReportDesign.sm + 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: ReportDesign.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: ReportDesign.md),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ReportDesign.sm + 2),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        onTap: onTap,
        readOnly: readOnly || onTap != null,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: ReportDesign.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: ReportDesign.textSecondary,
          ),
          floatingLabelStyle: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: ReportDesign.primary,
          ),
          filled: true,
          fillColor: ReportDesign.surfaceMuted,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: ReportDesign.md,
            vertical: ReportDesign.sm + 6,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
            borderSide: const BorderSide(color: ReportDesign.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
            borderSide: const BorderSide(color: ReportDesign.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
            borderSide:
            const BorderSide(color: ReportDesign.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
            borderSide:
            const BorderSide(color: ReportDesign.absent, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
            borderSide:
            const BorderSide(color: ReportDesign.absent, width: 1.5),
          ),
          suffixIcon: onTap != null
              ? const Icon(Icons.calendar_today_rounded,
              size: 16, color: ReportDesign.textMuted)
              : null,
        ),
      ),
    );
  }

  Widget _buildDropdownFormField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ReportDesign.sm + 2),
      child: DropdownButtonFormField<String>(
        value: value,
        validator: validator,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: ReportDesign.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: ReportDesign.textSecondary,
          ),
          filled: true,
          fillColor: ReportDesign.surfaceMuted,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: ReportDesign.md,
            vertical: ReportDesign.sm + 6,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
            borderSide: const BorderSide(color: ReportDesign.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
            borderSide: const BorderSide(color: ReportDesign.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
            borderSide:
            const BorderSide(color: ReportDesign.primary, width: 1.5),
          ),
        ),
        items: items
            .map((v) => DropdownMenuItem<String>(
          value: v,
          child: Text(v.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
        ))
            .toList(),
      ),
    );
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReportDesign.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  ReportDesign.md,
                  ReportDesign.md,
                  ReportDesign.md,
                  ReportDesign.xl,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ── Personal Information ──
                      _buildSectionCard(
                        title: 'Personal Information',
                        icon: Icons.person_outline_rounded,
                        children: [
                          _buildTextFormField(
                            controller: _firstNameController,
                            label: 'First Name *',
                            validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'First name is required'
                                : null,
                          ),
                          _buildTextFormField(
                            controller: _lastNameController,
                            label: 'Last Name *',
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Last name is required'
                                : null,
                          ),
                          _buildTextFormField(
                            controller: _phoneController,
                            label: 'Phone Number *',
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Phone number is required';
                              }
                              if (!RegExp(r'^[0-9]{10}$').hasMatch(v)) {
                                return 'Enter a valid 10-digit phone number';
                              }
                              return null;
                            },
                          ),
                          _buildDropdownFormField(
                            label: 'Gender',
                            value: _selectedGender,
                            items: _genderOptions,
                            onChanged: (v) =>
                                setState(() => _selectedGender = v),
                          ),
                          _buildTextFormField(
                            controller: _bloodGroupController,
                            label: 'Blood Group',
                            validator: (v) {
                              if (v != null &&
                                  v.isNotEmpty &&
                                  !_bloodGroupOptions.contains(v)) {
                                return 'Please select a valid blood group';
                              }
                              return null;
                            },
                          ),
                          _buildTextFormField(
                            controller: _dateOfBirthController,
                            label: 'Date of Birth',
                            onTap: () =>
                                _selectDate(context, _dateOfBirthController),
                          ),
                        ],
                      ),

                      // ── Marital Status ──
                      _buildSectionCard(
                        title: 'Marital Status',
                        icon: Icons.favorite_border_rounded,
                        children: [
                          _buildDropdownFormField(
                            label: 'Marital Status',
                            value: _selectedMaritalStatus,
                            items: _maritalStatusOptions,
                            onChanged: (v) => setState(
                                    () => _selectedMaritalStatus = v),
                          ),
                          if (_selectedMaritalStatus == 'married') ...[
                            _buildTextFormField(
                              controller: _marriageAnniversaryController,
                              label: 'Marriage Anniversary *',
                              onTap: () => _selectDate(
                                  context, _marriageAnniversaryController),
                              validator: (v) =>
                              (v == null || v.isEmpty)
                                  ? 'Marriage anniversary is required'
                                  : null,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: ReportDesign.sm + 2,
                                vertical: ReportDesign.xs,
                              ),
                              decoration: BoxDecoration(
                                color: ReportDesign.surfaceMuted,
                                borderRadius: BorderRadius.circular(
                                    ReportDesign.radiusSm),
                                border: Border.all(
                                    color: ReportDesign.border, width: 1),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.work_outline_rounded,
                                    size: 16,
                                    color: ReportDesign.textSecondary,
                                  ),
                                  const SizedBox(width: ReportDesign.sm),
                                  const Expanded(
                                    child: Text(
                                      'Is Spouse Working?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: ReportDesign.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: _spouseIsWorking ?? false,
                                    activeColor: ReportDesign.primary,
                                    onChanged: (v) => setState(
                                            () => _spouseIsWorking = v),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      // ── Address ──
                      _buildSectionCard(
                        title: 'Address',
                        icon: Icons.location_on_outlined,
                        children: [
                          _buildTextFormField(
                            controller: _streetController,
                            label: 'Street',
                            maxLines: 2,
                          ),
                          _buildTextFormField(
                              controller: _cityController, label: 'City'),
                          _buildTextFormField(
                              controller: _stateController, label: 'State'),
                          _buildTextFormField(
                              controller: _countryController,
                              label: 'Country'),
                          _buildTextFormField(
                            controller: _postalCodeController,
                            label: 'Postal Code',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v != null &&
                                  v.isNotEmpty &&
                                  !RegExp(r'^[0-9]{6}$').hasMatch(v)) {
                                return 'Enter a valid 6-digit postal code';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      // ── Bank Details ──
                      _buildSectionCard(
                        title: 'Bank Details',
                        icon: Icons.account_balance_outlined,
                        children: [
                          _buildTextFormField(
                              controller: _bankNameController,
                              label: 'Bank Name'),
                          _buildTextFormField(
                            controller: _accountNumberController,
                            label: 'Account Number',
                            keyboardType: TextInputType.number,
                          ),
                          _buildTextFormField(
                              controller: _ifscCodeController,
                              label: 'IFSC Code'),
                        ],
                      ),

                      // ── Government IDs ──
                      _buildSectionCard(
                        title: 'Government IDs',
                        icon: Icons.badge_outlined,
                        children: [
                          _buildTextFormField(
                            controller: _panNumberController,
                            label: 'PAN Number',
                            validator: (v) {
                              if (v != null &&
                                  v.isNotEmpty &&
                                  !RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$')
                                      .hasMatch(v)) {
                                return 'Enter a valid PAN (e.g., ABCDE1234F)';
                              }
                              return null;
                            },
                          ),
                          _buildTextFormField(
                              controller: _pfNumberController,
                              label: 'PF Number'),
                          _buildTextFormField(
                              controller: _uanNumberController,
                              label: 'UAN Number'),
                        ],
                      ),

                      // ── Emergency Contact ──
                      _buildSectionCard(
                        title: 'Emergency Contact',
                        icon: Icons.emergency_outlined,
                        children: [
                          _buildTextFormField(
                              controller: _emergencyNameController,
                              label: 'Name'),
                          _buildTextFormField(
                            controller: _emergencyPhoneController,
                            label: 'Phone',
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v != null &&
                                  v.isNotEmpty &&
                                  !RegExp(r'^[0-9]{10}$').hasMatch(v)) {
                                return 'Enter a valid 10-digit phone number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      // ── Save ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: _isSaving
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(_isSaving ? 'Saving...' : 'Save Changes',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.1,
                              )),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ReportDesign.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                            ReportDesign.primary.withOpacity(0.5),
                            padding: const EdgeInsets.symmetric(
                                vertical: ReportDesign.md),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  ReportDesign.radiusMd),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ReportDesign.primary, ReportDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(ReportDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: ReportDesign.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ReportDesign.md,
            ReportDesign.sm,
            ReportDesign.md,
            ReportDesign.md,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: ReportDesign.sm + 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Update your personal details',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isSaving)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}