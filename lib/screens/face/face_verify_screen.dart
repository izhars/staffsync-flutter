// screens/face/face_verify_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_exception.dart';
import '../../services/face_service.dart';
import 'face_capture_screen.dart';
import 'face_enrollment_screen.dart';

enum _VerifyState { idle, verifying, success, failed, notEnrolled }

// ===================== DESIGN TOKENS =====================

class _VerifyDesign {
  static const Color bg = Color(0xFF0B0D12);
  static const Color surface = Color(0xFF15181F);
  static const Color surfaceRaised = Color(0xFF1D212B);
  static const Color border = Color(0xFF2A2E38);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA3A9B7);
  static const Color textMuted = Color(0xFF6B7280);

  static const Color accent = Color(0xFF34D399);
  static const Color accentSoft = Color(0xFF0F2A22);

  static const Color warning = Color(0xFFFBBF24);
  static const Color warningSoft = Color(0xFF2E2410);

  static const Color danger = Color(0xFFF87171);
  static const Color dangerSoft = Color(0xFF2E1416);

  static const Color info = Color(0xFF60A5FA);
  static const Color infoSoft = Color(0xFF15202E);

  static const double radiusMd = 16;
  static const double radiusLg = 22;
}

class FaceVerifyScreen extends StatefulWidget {
  /// Backend action string (e.g. 'identity', 'unlock').
  final String action;

  /// If true, after success the screen stays open showing the result.
  /// If false, it pops with the [FaceVerifyResult].
  final bool stayOnSuccess;

  const FaceVerifyScreen({
    super.key,
    this.action = 'verify',
    this.stayOnSuccess = true,
  });

  @override
  State<FaceVerifyScreen> createState() => _FaceVerifyScreenState();
}

class _FaceVerifyScreenState extends State<FaceVerifyScreen> {
  final FaceService _api = FaceService();

  _VerifyState _state = _VerifyState.idle;
  FaceVerifyResult? _result;
  String? _error;
  Map<String, dynamic>? _nearestLocation;

  Future<void> _start() async {
    final embedding = await Navigator.push<List<double>?>(
      context,
      MaterialPageRoute(
        builder: (_) => const FaceCaptureScreen(
          title: 'Verify your face',
          subtitle: 'Keep your face inside the frame',
        ),
      ),
    );
    if (embedding == null) return;
    await _verify(embedding);
  }

  Future<void> _verify(List<double> embedding) async {
    setState(() {
      _state = _VerifyState.verifying;
      _error = null;
      _nearestLocation = null;
    });

    try {
      final res = await _api.verifyFace(
        embedding: embedding,
        action: widget.action,
      );
      if (!mounted) return;

      setState(() {
        _result = res;
        _state = res.success ? _VerifyState.success : _VerifyState.failed;
        _error = res.success ? null : res.message;
      });

      if (res.success && !widget.stayOnSuccess) {
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) Navigator.pop(context, res);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      final reason = e.data?['reason'];
      if (reason == 'NOT_ENROLLED') {
        setState(() => _state = _VerifyState.notEnrolled);
      } else {
        setState(() {
          _state = _VerifyState.failed;
          _error = e.data?['message'] ?? e.message;
          _nearestLocation = e.data?['nearestLocation'];
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _VerifyState.failed;
        _error = e.toString();
      });
    }
  }

  Future<void> _goToEnrollment() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FaceEnrollmentScreen()),
    );
    if (mounted) setState(() => _state = _VerifyState.idle);
  }

  void _reset() {
    setState(() {
      _state = _VerifyState.idle;
      _result = null;
      _error = null;
      _nearestLocation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _VerifyDesign.bg,
      appBar: AppBar(
        backgroundColor: _VerifyDesign.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Face Verification',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _VerifyState.idle:
        return _buildIdle();
      case _VerifyState.verifying:
        return _buildVerifying();
      case _VerifyState.success:
        return _buildSuccess();
      case _VerifyState.failed:
        return _buildFailed();
      case _VerifyState.notEnrolled:
        return _buildNotEnrolled();
    }
  }

  // ── IDLE ────────────────────────────────────────────────
  Widget _buildIdle() {
    return Center(
      key: const ValueKey('idle'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeroIcon(
              Icons.face_retouching_natural_rounded,
              _VerifyDesign.info,
              _VerifyDesign.infoSoft,
            ),
            const SizedBox(height: 24),
            const Text(
              'Verify Your Face',
              style: TextStyle(
                color: _VerifyDesign.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'We\'ll capture a few frames of your face and match it against your registered profile.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _VerifyDesign.textSecondary,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            _buildPrimaryButton(
              label: 'Start Verification',
              icon: Icons.camera_alt_rounded,
              color: _VerifyDesign.accent,
              onTap: _start,
            ),
          ],
        ),
      ),
    );
  }

  // ── VERIFYING ───────────────────────────────────────────
  Widget _buildVerifying() {
    return Center(
      key: const ValueKey('verifying'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor:
                AlwaysStoppedAnimation<Color>(_VerifyDesign.info),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Verifying…',
              style: TextStyle(
                color: _VerifyDesign.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Matching your face against your profile.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _VerifyDesign.textSecondary,
                fontSize: 13.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SUCCESS ─────────────────────────────────────────────
  Widget _buildSuccess() {
    final similarity = _result?.similarity;
    return Center(
      key: const ValueKey('success'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeroIcon(
              Icons.check_circle_rounded,
              _VerifyDesign.accent,
              _VerifyDesign.accentSoft,
            ),
            const SizedBox(height: 24),
            const Text(
              'Verified',
              style: TextStyle(
                color: _VerifyDesign.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              similarity != null
                  ? 'Match confidence: ${(similarity * 100).toStringAsFixed(1)}%'
                  : (_result?.message.isNotEmpty == true
                  ? _result!.message
                  : 'Your face matched our records.'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _VerifyDesign.textSecondary,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            _buildPrimaryButton(
              label: 'Done',
              icon: Icons.check_rounded,
              color: _VerifyDesign.accent,
              onTap: () {
                if (widget.stayOnSuccess) {
                  _reset();
                } else {
                  Navigator.pop(context, _result);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── FAILED ──────────────────────────────────────────────
  Widget _buildFailed() {
    return Center(
      key: const ValueKey('failed'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeroIcon(
              Icons.error_rounded,
              _VerifyDesign.danger,
              _VerifyDesign.dangerSoft,
            ),
            const SizedBox(height: 24),
            const Text(
              "Face didn't match",
              style: TextStyle(
                color: _VerifyDesign.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _error?.isNotEmpty == true
                  ? _error!
                  : 'Please make sure your face is well-lit and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _VerifyDesign.textSecondary,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_nearestLocation != null) ...[
              const SizedBox(height: 18),
              _buildNearestLocationCard(),
            ],
            const SizedBox(height: 32),
            _buildPrimaryButton(
              label: 'Try Again',
              icon: Icons.refresh_rounded,
              color: _VerifyDesign.danger,
              onTap: _start,
            ),
          ],
        ),
      ),
    );
  }

  // ── NOT ENROLLED ────────────────────────────────────────
  Widget _buildNotEnrolled() {
    return Center(
      key: const ValueKey('notEnrolled'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeroIcon(
              Icons.person_add_alt_1_rounded,
              _VerifyDesign.warning,
              _VerifyDesign.warningSoft,
            ),
            const SizedBox(height: 24),
            const Text(
              'Face Not Registered',
              style: TextStyle(
                color: _VerifyDesign.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "You haven't registered your face yet. Register it first to use face verification.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _VerifyDesign.textSecondary,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            _buildPrimaryButton(
              label: 'Register Now',
              icon: Icons.arrow_forward_rounded,
              color: _VerifyDesign.warning,
              onTap: _goToEnrollment,
            ),
          ],
        ),
      ),
    );
  }

  // ── SHARED WIDGETS ──────────────────────────────────────
  Widget _buildHeroIcon(IconData icon, Color color, Color softColor) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: softColor,
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
      ),
      child: Icon(icon, color: color, size: 44),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_VerifyDesign.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_VerifyDesign.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(_VerifyDesign.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.black.withOpacity(0.8), size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.85),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearestLocationCard() {
    final name = _nearestLocation?['name'] ?? 'Unknown';
    final distance = _nearestLocation?['distance'] ?? '?';
    final allowed = _nearestLocation?['allowedRadius'] ?? '?';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _VerifyDesign.warningSoft,
        borderRadius: BorderRadius.circular(_VerifyDesign.radiusMd),
        border: Border.all(color: _VerifyDesign.warning.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoLine(Icons.location_on_rounded, 'Nearest location', name),
          const SizedBox(height: 8),
          _buildInfoLine(
              Icons.straighten_rounded, 'Your distance', '$distance m'),
          const SizedBox(height: 8),
          _buildInfoLine(
              Icons.check_circle_outline_rounded, 'Allowed radius', '$allowed m'),
        ],
      ),
    );
  }

  Widget _buildInfoLine(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _VerifyDesign.warning),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: _VerifyDesign.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: _VerifyDesign.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}