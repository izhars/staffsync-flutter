import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/avatar_api.dart';
import '../models/user.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/face_service.dart';
import 'face/face_enrollment_screen.dart';
import 'face/face_verify_screen.dart';
import 'edit_profile_screen.dart';

// ===================== DESIGN TOKENS (from dashboard) =====================
const double _xs = 4;
const double _sm = 8;
const double _lg = 24;
const double _xl = 32;

const double _radiusSm = 12;
const double _radiusMd = 18;
const double _radiusLg = 24;

const Color _bg = Color(0xFFF6F7FB);
const Color _surface = Colors.white;
const Color _textPrimary = Color(0xFF1A1D26);
const Color _textSecondary = Color(0xFF6B7280);
const Color _textMuted = Color(0xFF9CA3AF);
const Color _border = Color(0xFFEAECEF);
const Color _primary = Color(0xFF0F766E);
const Color _primaryLight = Color(0xFFCCFBF1);
const Color _primarySoft = Color(0xFFF0FDFA);
const Color _error = Color(0xFFEF4444);
const Color _warning = Color(0xFFF59E0B);

final List<BoxShadow> _softShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 16,
    offset: const Offset(0, 6),
    spreadRadius: -4,
  ),
];

final List<BoxShadow> _mediumShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.06),
    blurRadius: 24,
    offset: const Offset(0, 10),
    spreadRadius: -6,
  ),
];
// =========================================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  File? _avatar;
  User? _user;
  bool _isLoading = true;
  bool _isUploading = false;
  bool _hasLocalAvatar = false;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  final ScrollController _scrollController = ScrollController();
  bool _showSalaryInfo = false;

  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  FaceStatusResult? _faceStatus;
  bool _loadingFaceStatus = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadProfile();
    _loadFaceStatus();
  }

  Future<void> _loadFaceStatus() async {
    try {
      if (!mounted) return;
      setState(() => _loadingFaceStatus = true);
      final status = await FaceService().getStatusDetailed();
      if (mounted) setState(() => _faceStatus = status);
    } catch (e) {
      debugPrint('Error loading face status: $e');
    } finally {
      if (mounted) setState(() => _loadingFaceStatus = false);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _authService.fetchMe(forceRefresh: true);
      final hasLocal = await AvatarService.hasLocalAvatar();
      File? localAvatar;

      if (hasLocal) {
        localAvatar = await AvatarService.getAvatar();
      }

      setState(() {
        _user = user;
        _avatar = localAvatar;
        _hasLocalAvatar = hasLocal;
        _isLoading = false;
      });

      _fadeController.forward();
      _scaleController.forward();
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load profile. Please try again.');
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    final fileSize = await imageFile.length();
    const maxSize = 5 * 1024 * 1024;

    if (fileSize > maxSize) {
      _showErrorSnackBar('Image size too large. Please select image under 5MB');
      return;
    }

    setState(() => _isUploading = true);

    try {
      await AvatarService.saveAvatar(imageFile);
      final result = await _authService.uploadProfilePicture(imageFile);

      if (result != null && result['success'] == true) {
        setState(() {
          _avatar = imageFile;
          _hasLocalAvatar = true;
          if (result['user'] != null) {
            _user = User.fromJson(result['user']);
          }
        });
        _showSuccessSnackBar('Profile picture updated successfully!');
      } else {
        throw Exception(result?['message'] ?? 'Upload failed');
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      setState(() {
        _avatar = imageFile;
        _hasLocalAvatar = true;
      });

      if (e.toString().contains('Invalid file type') ||
          e.toString().contains('Only image files')) {
        _showErrorSnackBar('Please select a valid image file (JPEG, PNG, GIF)');
      } else if (e.toString().contains('file size')) {
        _showErrorSnackBar('Image size too large. Please select image under 5MB');
      } else {
        _showSuccessSnackBar('Profile picture saved locally! Server sync failed.');
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _cropImage(File imageFile) async {
    if (!await imageFile.exists()) {
      _showErrorSnackBar('Image file not found');
      return;
    }

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: _primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            hideBottomControls: false,
            showCropGrid: true,
            statusBarColor: _primary,
            backgroundColor: Colors.white,
            cropFrameColor: _primary.withOpacity(0.8),
            cropFrameStrokeWidth: 2,
            cropGridColor: _primary.withOpacity(0.3),
            cropGridColumnCount: 2,
            cropGridRowCount: 2,
            cropGridStrokeWidth: 1,
            activeControlsWidgetColor: _primary,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
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
        await _uploadProfilePicture(File(croppedFile.path));
      }
    } catch (e) {
      _showErrorSnackBar('Failed to crop image: ${e.toString()}');
      debugPrint('Image cropping error: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (image != null) await _cropImage(File(image.path));
    } catch (e) {
      debugPrint('Gallery pick error: $e');
      _showErrorSnackBar('Failed to pick image from gallery');
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (image != null) await _cropImage(File(image.path));
    } catch (e) {
      debugPrint('Camera error: $e');
      _showErrorSnackBar('Failed to take photo');
    }
  }

  Future<void> _removeLocalAvatar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusLg)),
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(_radiusLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: _xl),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, color: _error, size: 30),
              ),
              const SizedBox(height: _lg),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: _xl),
                child: Text(
                  'Remove Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: _xl),
                child: Text(
                  'Are you sure you want to remove your local profile picture?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: _xl),
              const Divider(height: 1, color: _border),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(_radiusLg),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 70, color: _border),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(_radiusLg),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Remove',
                        style: TextStyle(
                          color: _error,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed ?? false) {
      try {
        await AvatarService.deleteAvatar();
        setState(() {
          _avatar = null;
          _hasLocalAvatar = false;
        });
        _showSuccessSnackBar('Profile picture removed');
      } catch (e) {
        _showErrorSnackBar('Failed to remove profile picture');
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_radiusLg),
            topRight: Radius.circular(_radiusLg),
          ),
          boxShadow: _mediumShadow,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: _lg),
                child: Text(
                  'Update Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: _sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _lg),
                child: Text(
                  _hasLocalAvatar
                      ? 'Local picture will be replaced'
                      : 'You can crop the image after selection',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: _lg),
              _buildBottomSheetOption(
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                subtitle: 'Select an existing photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              const Divider(height: 1, color: _border),
              _buildBottomSheetOption(
                icon: Icons.camera_alt,
                title: 'Take Photo',
                subtitle: 'Use your camera',
                onTap: () {
                  Navigator.pop(context);
                  _takePhotoWithCamera();
                },
              ),
              if (_hasLocalAvatar) ...[
                const Divider(height: 1, color: _border),
                _buildBottomSheetOption(
                  icon: Icons.delete_outline,
                  title: 'Remove Picture',
                  subtitle: 'Delete local profile picture',
                  onTap: () {
                    Navigator.pop(context);
                    _removeLocalAvatar();
                  },
                  color: _error,
                ),
              ],
              const SizedBox(height: _lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _lg, vertical: _sm),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _border),
                      foregroundColor: _textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_radiusSm),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final optionColor = color ?? _primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: optionColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _lg, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: optionColor,
                  borderRadius: BorderRadius.circular(_radiusSm),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: color ?? _textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _textMuted),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 13.5,
          ),
        ),
        backgroundColor: _primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusSm)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 13.5,
          ),
        ),
        backgroundColor: _error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusSm)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // FORMATTING HELPERS
  // ============================================================
  String formatDate(DateTime? date) {
    if (date == null) return 'Not specified';
    try {
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return 'Invalid date';
    }
  }

  String _fmtMoney(num? amount, String? currency) {
    if (amount == null) return '—';
    final symbol = _getCurrencySymbol(currency);
    return '$symbol${NumberFormat('#,##0').format(amount)}';
  }

  String _getCurrencySymbol(String? currency) {
    switch (currency?.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currency ?? '';
    }
  }

  String _cap(String? s) {
    if (s == null || s.isEmpty) return '—';
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: _isLoading ? _buildLoadingState() : _buildProfileContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surface,
              shape: BoxShape.circle,
              boxShadow: _mediumShadow,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_primary),
            ),
          ),
          const SizedBox(height: _lg),
          const Text(
            'Loading your profile...',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: _sm),
          const Text(
            'Please wait a moment',
            style: TextStyle(
              color: _textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_user == null) return _buildErrorState();

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) => false,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildSliverAppBar(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                sliver: SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _scaleController,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: Column(
                        children: _buildProfileCards(),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
        if (_isUploading) _buildUploadOverlay(),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 40, color: _error),
            ),
            const SizedBox(height: _lg),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "We couldn't load your profile information. "
                  'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: _xl),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _isLoading = true);
                _loadProfile();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: _xl, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_radiusSm),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 320,
      floating: false,
      pinned: true,
      backgroundColor: _primary,
      elevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double top = constraints.biggest.height;
          return FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Container(
              decoration: BoxDecoration(
                color: _primary,
                boxShadow: _mediumShadow,
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 16),
                      _buildProfileAvatar(),
                      const SizedBox(height: 20),
                      AnimatedOpacity(
                        opacity: top > 200 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          children: [
                            Text(
                              _user!.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: _sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.work_outline,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _user!.designation ?? 'Employee',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.95),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: _xs),
                            Text(
                              _user!.department?.name ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildStatusChip(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(_radiusSm),
            ),
            child: const Icon(Icons.edit, color: Colors.white, size: 18),
          ),
          onPressed: _navigateToEditProfile,
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(_radiusSm),
            ),
            child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
          ),
          onPressed: _handleLogout,
        ),
      ],
    );
  }

  void _navigateToEditProfile() async {
    if (_user == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(user: _user!)),
    );
    if (result == true) {
      await _loadProfile();
      _showSuccessSnackBar('Profile updated successfully');
    }
  }

  Widget _buildProfileAvatar() {
    return ScaleTransition(
      scale: _scaleController,
      child: GestureDetector(
        onTap: _showImageSourceDialog,
        child: Stack(
          children: [
            Hero(
              tag: 'profile_avatar',
              child: Container(
                width: 120,
                height: 120,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _surface,
                  boxShadow: _mediumShadow,
                ),
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: _surface,
                  backgroundImage: _getProfileImage(),
                  child: _getProfileImage() == null
                      ? Text(
                    _user!.fullName.isNotEmpty
                        ? _user!.fullName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: _primary,
                    ),
                  )
                      : null,
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                  boxShadow: _softShadow,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(_radiusLg),
            boxShadow: _mediumShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(_primary),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Uploading...',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: _sm),
              Text(
                _hasLocalAvatar ? 'Saving locally...' : 'Please wait',
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_hasLocalAvatar && _avatar != null) {
      try {
        return FileImage(_avatar!);
      } catch (e) {
        debugPrint('Error loading local avatar: $e');
      }
    }
    if (_user != null && _user!.profilePicture.isNotEmpty) {
      return NetworkImage(_user!.profilePicture);
    }
    return null;
  }

  Widget _buildStatusChip() {
    final isActive = _user!.status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.2) : _warning.withOpacity(0.9),
        borderRadius: BorderRadius.circular(_radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.schedule,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            _user!.status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARDS — matched to API response shape
  // ============================================================
  List<Widget> _buildProfileCards() {
    final cards = <Widget>[];

    // 1. Personal Information
    cards.add(_buildPersonalInfoCard());
    cards.add(const SizedBox(height: 16));

    // 2. Address (only if any of street/city/state/country/postal present)
    if (_hasAddress()) {
      cards.add(_buildAddressCard());
      cards.add(const SizedBox(height: 16));
    }

    // 3. Employment Details + Shift
    cards.add(_buildEmploymentCard());
    cards.add(const SizedBox(height: 16));

    // 4. Shift (if present)
    if (_user!.shift != null) {
      cards.add(_buildShiftCard());
      cards.add(const SizedBox(height: 16));
    }

    // 5. Salary (collapsible)
    if (_user!.salary != null) {
      if (_showSalaryInfo) {
        cards.add(_buildSalaryCard());
      } else {
        cards.add(_buildSalaryToggleCard());
      }
      cards.add(const SizedBox(height: 16));
    }

    // 6. Bank Details
    if (_user!.bankDetails != null) {
      cards.add(_buildBankDetailsCard());
      cards.add(const SizedBox(height: 16));
    }

    // 7. Leave Balance (only casual + combo exist)
    if (_user!.leaveBalance != null) {
      cards.add(_buildLeaveBalanceCard());
      cards.add(const SizedBox(height: 16));
    }

    // 8. Spouse Details
    if (_user!.spouseDetails != null) {
      cards.add(_buildSpouseDetailsCard());
      cards.add(const SizedBox(height: 16));
    }

    // 9. Biometric Face Recognition
    cards.add(_buildFaceBiometricCard());
    cards.add(const SizedBox(height: 16));

    // 10. Account Information
    cards.add(_buildAccountInfoCard());
    cards.add(const SizedBox(height: 32));

    return cards;
  }

  Widget _buildFaceBiometricCard() {
    final status = _faceStatus;
    final isEnrolled = status?.registered == true && status?.isActive == true;
    final isInactive = status?.hasRecord == true && status?.isActive == false;

    Color badgeBg;
    Color badgeText;
    String badgeLabel;
    IconData statusIcon;

    if (_loadingFaceStatus) {
      badgeBg = Colors.grey.shade100;
      badgeText = _textSecondary;
      badgeLabel = 'Checking status...';
      statusIcon = Icons.hourglass_top_rounded;
    } else if (isEnrolled) {
      badgeBg = const Color(0xFFE1F5EE);
      badgeText = const Color(0xFF0F6E56);
      badgeLabel = 'Enrolled & Active';
      statusIcon = Icons.check_circle_rounded;
    } else if (isInactive) {
      badgeBg = const Color(0xFFFAEEDA);
      badgeText = const Color(0xFF854F0B);
      badgeLabel = 'Re-enrollment Permitted';
      statusIcon = Icons.sync_problem_rounded;
    } else {
      badgeBg = const Color(0xFFFCEBEB);
      badgeText = const Color(0xFFA32D2D);
      badgeLabel = 'Not Enrolled';
      statusIcon = Icons.warning_amber_rounded;
    }

    return _buildCard(
      title: 'Biometric Face Recognition',
      icon: Icons.face_retouching_natural_rounded,
      children: [
        // Status Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: badgeBg.withOpacity(0.55),
            borderRadius: BorderRadius.circular(_radiusSm),
            border: Border.all(color: badgeText.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: badgeText, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badgeLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: badgeText,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEnrolled
                          ? 'Enrolled on ${status?.enrolledAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(status!.enrolledAt!) : 'previous session'}'
                          : isInactive
                              ? 'HR has reset your biometric. You can register fresh.'
                              : 'Register your face to enable instant biometric attendance check-in.',
                      style: TextStyle(
                        color: badgeText.withOpacity(0.9),
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadingFaceStatus ? null : _loadFaceStatus,
                icon: _loadingFaceStatus
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.refresh_rounded, color: badgeText, size: 20),
                tooltip: 'Refresh Status',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Action Buttons Row
        Row(
          children: [
            if (isEnrolled) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FaceVerifyScreen(
                          action: 'verify',
                          stayOnSuccess: true,
                        ),
                      ),
                    );
                    if (!mounted) return;
                    _loadFaceStatus();
                  },
                  icon: const Icon(Icons.verified_user_outlined, size: 16),
                  label: const Text('Test Face'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: const BorderSide(color: _primary),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_radiusSm),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<FaceEnrollmentResult>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FaceEnrollmentScreen(),
                    ),
                  );
                  if (!mounted) return;
                  if (result == FaceEnrollmentResult.success) {
                    await _loadFaceStatus();
                  }
                },
                icon: Icon(
                  isEnrolled ? Icons.restart_alt_rounded : Icons.camera_alt_outlined,
                  size: 16,
                ),
                label: Text(isEnrolled ? 'Re-enroll' : 'Enroll Face Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_radiusSm),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  bool _hasAddress() {
    final a = _user!.address;
    if (a == null) return false;
    return (a.street?.isNotEmpty ?? false) ||
        (a.city?.isNotEmpty ?? false) ||
        (a.state?.isNotEmpty ?? false) ||
        (a.country?.isNotEmpty ?? false) ||
        (a.postalCode?.isNotEmpty ?? false);
  }

  // ---------- Personal Information ----------
  Widget _buildPersonalInfoCard() {
    return _buildCard(
      title: 'Personal Information',
      icon: Icons.person_outline_rounded,
      children: [
        _buildInfoRow('Employee ID', _user!.employeeId, Icons.badge_outlined),
        _buildInfoRow('Email', _user!.email, Icons.email_outlined),
        _buildInfoRow('Phone', _user!.phone, Icons.phone_outlined),
        _buildInfoRow('Gender', _cap(_user!.gender), Icons.person_outline),
        _buildInfoRow('Date of Birth', formatDate(_user!.dateOfBirth), Icons.cake_outlined),
        _buildInfoRow('Marital Status', _cap(_user!.maritalStatus), Icons.favorite_outline),
        _buildInfoRow('Blood Group', _user!.bloodGroup, Icons.bloodtype_outlined),
      ],
    );
  }

  // ---------- Address ----------
  Widget _buildAddressCard() {
    final a = _user!.address!;
    return _buildCard(
      title: 'Address',
      icon: Icons.location_on_outlined,
      children: [
        if (a.street?.isNotEmpty ?? false)
          _buildInfoRow('Street', a.street, Icons.signpost_outlined),
        _buildInfoRow('City', a.city, Icons.location_city_outlined),
        _buildInfoRow('State', a.state, Icons.map_outlined),
        _buildInfoRow('Country', a.country, Icons.public_outlined),
        _buildInfoRow('Postal Code', a.postalCode, Icons.markunread_mailbox_outlined),
      ],
    );
  }

  // ---------- Employment ----------
  Widget _buildEmploymentCard() {
    return _buildCard(
      title: 'Employment Details',
      icon: Icons.work_outline_rounded,
      children: [
        _buildInfoRow('Date of Joining', formatDate(_user!.dateOfJoining), Icons.today_outlined),
        _buildInfoRow('Employment Type', _cap(_user!.employmentType), Icons.badge_outlined),
        _buildInfoRow('Role', _cap(_user!.role), Icons.shield_outlined),
        _buildInfoRow('Probation', _user!.isOnProbation == true ? 'On Probation' : 'Completed',
            Icons.timelapse_outlined),
        _buildInfoRow('PF Number', _user!.pfNumber, Icons.account_balance_outlined),
        _buildInfoRow('UAN Number', _user!.uanNumber, Icons.numbers_outlined),
        _buildInfoRow('PAN Number', _user!.panNumber, Icons.credit_card_outlined),
      ],
    );
  }

  // ---------- Shift ----------
  Widget _buildShiftCard() {
    final s = _user!.shift!;
    return _buildCard(
      title: 'Shift Schedule',
      icon: Icons.schedule_rounded,
      children: [
        _buildInfoRow('Shift Name', s.name, Icons.work_outline),
        _buildInfoRow('Timing', s.displayTiming ?? '${s.startTime} - ${s.endTime}',
            Icons.access_time_rounded),
        _buildInfoRow('Shift Code', s.code, Icons.qr_code_2_outlined),
        _buildInfoRow('Break Duration', '${s.breakDuration} minutes', Icons.coffee_outlined),
        _buildInfoRow('Grace Period', '${s.gracePeriod} minutes', Icons.hourglass_bottom_outlined),
      ],
    );
  }

  // ---------- Salary (collapsible) ----------
  Widget _buildSalaryToggleCard() {
    return _buildCard(
      title: 'Salary Information',
      icon: Icons.payments_outlined,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Tap to view salary breakdown',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _showSalaryInfo = true),
                icon: const Icon(Icons.visibility_outlined, size: 16, color: _primary),
                label: const Text(
                  'Show',
                  style: TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSalaryCard() {
    final sal = _user!.salary!;
    final currency = sal.currency;

    return _buildCard(
      title: 'Salary Information',
      icon: Icons.payments_outlined,
      children: [
        // Earnings group
        _sectionLabel('Earnings'),
        _buildInfoRow('Basic', _fmtMoney(sal.basic, currency), Icons.money_outlined),
        _buildInfoRow('HRA', _fmtMoney(sal.hra, currency), Icons.home_outlined),
        _buildInfoRow('Medical Conveyance', _fmtMoney(sal.medicalConveyance, currency),
            Icons.medical_services_outlined),
        _buildInfoRow('Conveyance Allowance', _fmtMoney(sal.conveyanceAllowance, currency),
            Icons.directions_car_outlined),
        _buildInfoRow('Special Allowance', _fmtMoney(sal.specialAllowance, currency),
            Icons.add_circle_outline),
        _buildInfoRow('Gross Salary', _fmtMoney(sal.grossSalary, currency), Icons.summarize_outlined,
            isHighlighted: false),

        const SizedBox(height: 8),
        // Deductions group
        _sectionLabel('Deductions'),
        _buildInfoRow('Employee EPF', _fmtMoney(sal.employeeEPF, currency),
            Icons.remove_circle_outline),
        _buildInfoRow('Benevolent Fund', _fmtMoney(sal.benevolentFund, currency),
            Icons.volunteer_activism_outlined),

        const SizedBox(height: 8),
        // Employer contributions
        _sectionLabel('Employer Contributions'),
        _buildInfoRow('Employer EPF', _fmtMoney(sal.employerEPF, currency),
            Icons.account_balance_wallet_outlined),
        _buildInfoRow('Gratuity', _fmtMoney(sal.gratuity, currency), Icons.card_giftcard_outlined),
        _buildInfoRow('Cost To Company', _fmtMoney(sal.costToCompany, currency),
            Icons.business_center_outlined),

        const Divider(color: _border, height: 24),

        // Net
        _buildInfoRow('Net Salary', _fmtMoney(sal.netSalary, currency),
            Icons.account_balance_wallet_outlined, isHighlighted: true),
        _buildInfoRow('Pay Frequency', _cap(sal.payFrequency), Icons.schedule_outlined),

        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _showSalaryInfo = false),
            icon: const Icon(Icons.visibility_off_outlined, size: 16, color: _textSecondary),
            label: const Text(
              'Hide Salary',
              style: TextStyle(
                color: _textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _textMuted,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  // ---------- Bank ----------
  Widget _buildBankDetailsCard() {
    final b = _user!.bankDetails!;
    return _buildCard(
      title: 'Bank Details',
      icon: Icons.account_balance_outlined,
      children: [
        _buildInfoRow('Account Holder', b.accountHolderName, Icons.person_outline),
        _buildInfoRow('Bank Name', b.bankName, Icons.account_balance),
        _buildInfoRow('Account Number', _maskAccount(b.accountNumber), Icons.credit_card_outlined),
        _buildInfoRow('IFSC Code', b.ifscCode, Icons.code_outlined),
      ],
    );
  }

  String _maskAccount(String? acc) {
    if (acc == null || acc.length < 4) return acc ?? '—';
    final last4 = acc.substring(acc.length - 4);
    return '•••• •••• $last4';
  }

  // ---------- Leave Balance (casual + combo only) ----------
  Widget _buildLeaveBalanceCard() {
    final lb = _user!.leaveBalance!;
    return _buildCard(
      title: 'Leave Balance',
      icon: Icons.event_available_outlined,
      children: [
        _buildInfoRow(
          'Casual Leave',
          '${lb.casual ?? 0} ${(lb.casual ?? 0) == 1 ? "day" : "days"}',
          Icons.beach_access_outlined,
          isHighlighted: true,
        ),
        _buildInfoRow(
          'Combo Off',
          '${lb.combo ?? 0} ${(lb.combo ?? 0) == 1 ? "day" : "days"}',
          Icons.event_busy_outlined,
        ),
      ],
    );
  }

  // ---------- Spouse ----------
  Widget _buildSpouseDetailsCard() {
    return _buildCard(
      title: 'Spouse Details',
      icon: Icons.people_outline,
      children: [
        _buildInfoRow(
          'Is Working',
          _user!.spouseDetails?.isWorking == true ? 'Yes' : 'No',
          Icons.work_outline,
        ),
      ],
    );
  }

  // ---------- Account Info ----------
  Widget _buildAccountInfoCard() {
    return _buildCard(
      title: 'Account Information',
      icon: Icons.info_outline_rounded,
      children: [
        _buildInfoRow('Created', formatDate(_user!.createdAt), Icons.calendar_today_outlined),
        _buildInfoRow('Updated', formatDate(_user!.updatedAt), Icons.update_outlined),
        _buildInfoRow('Last Login', formatDate(_user!.lastLogin), Icons.login_outlined),
        _buildInfoRow(
          'Verified',
          _user!.isVerified ? 'Yes' : 'No',
          _user!.isVerified ? Icons.verified_outlined : Icons.warning_outlined,
          isHighlighted: false,
        ),
      ],
    );
  }

  // ============================================================
  // GENERIC CARD / ROW
  // ============================================================
  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(_radiusLg),
        boxShadow: _softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(_lg, _lg, _lg, _sm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primarySoft,
                    borderRadius: BorderRadius.circular(_radiusSm),
                  ),
                  child: Icon(icon, color: _primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _lg),
            child: Column(children: children),
          ),
          const SizedBox(height: _sm),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      String label,
      String? value,
      IconData icon, {
        bool isHighlighted = false,
      }) {
    final display = (value == null || value.isEmpty || value == '—') ? '—' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isHighlighted ? _primary : _textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isHighlighted ? _primary : _textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              display,
              style: TextStyle(
                fontSize: 13,
                color: isHighlighted ? _primary : _textPrimary,
                fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusLg)),
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(_radiusLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: _xl),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: _primary, size: 28),
              ),
              const SizedBox(height: _lg),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: _xl),
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: _xl),
                child: Text(
                  'Are you sure you want to logout?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: _xl),
              const Divider(height: 1, color: _border),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(_radiusLg),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 70, color: _border),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(_radiusLg),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          color: _error,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed ?? false) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (Route<dynamic> route) => false,
      );
    }
  }
}