import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../services/face_recognition_service.dart';
import '../../services/face_service.dart';
import '../../services/network_service.dart';
import 'liveness_tracker.dart';

enum FaceEnrollmentResult { success, alreadyEnrolled, cancelled }

/// Visual state driving color + icon for the status pill.
enum _CaptureState { idle, good, warning, error }

/// Mirrors DashboardDesign so both screens look identical.
/// TODO: replace with `import '.../dashboard_screen.dart'` (DashboardDesign)
/// or move DashboardDesign into its own file and import it in both places.
class _D {
  static const double sm = 8;
  static const double lg = 24;
  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 24;

  static const Color bg = Color(0xFFF6F7FB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFEAECEF);
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFFCCFBF1);
  static const Color primarySoft = Color(0xFFF0FDFA);

  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: -4,
    ),
  ];
}

class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _camera;
  final FaceRecognitionService _faceRecognition = FaceRecognitionService();
  late final FaceService _api;
  final LivenessTracker _liveness = LivenessTracker();

  // Frame pipeline state
  bool _processing = false; // guards ML work: one frame at a time
  bool _streaming = false;
  bool _finalizing = false;
  bool _livenessPassed = false; // liveness is checked ONCE, not per sample
  int _missStreak = 0;
  int _rejects = 0;
  int _spoofStrikes = 0;
  int? _trackingId; // ML Kit tracking id locked in when liveness passes
  DateTime _noticeUntil = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastCapture = DateTime.fromMillisecondsSinceEpoch(0);

  // UI state
  bool _faceAligned = false;
  bool _cameraReady = false;
  bool _fatalError = false;
  String _status = 'Position your face inside the oval';
  _CaptureState _captureState = _CaptureState.idle;

  final List<List<double>> _capturedEmbeddings = [];

  // --- Tuning ---------------------------------------------------------------
  static const int _requiredSamples = 6;
  static const int _keepCount = 5;
  static const double _consistencyThreshold = 0.5;
  static const int _maxRejects = 4; // restart samples after N bad frames

  // Anti-spoof
  static const double _minLiveScore = 0.5; // tune with real test photos/videos
  static const int _maxSpoofStrikes = 4; // low-score samples before restarting
  static const int _maxLostFrames = 6; // face gone this long => redo liveness

  static const Duration _frameGap = Duration(milliseconds: 50);
  static const Duration _sampleGap = Duration(milliseconds: 150);

  static const double _minFaceRatio = 0.20;
  static const double _maxFaceRatio = 1.0;
  static const double _maxCenterOffsetX = 0.24;
  static const double _maxCenterOffsetY = 0.24;
  static const double _maxYawDegrees = 20.0;
  static const double _maxPitchDegrees = 20.0;

  static const Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _api = FaceService(network: NetworkService());
    _init();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  /// Important message that shouldn't be overwritten by the next frame.
  void _showNotice(String text, _CaptureState state) {
    _setStatus(text, state, force: true);
    _noticeUntil = DateTime.now().add(const Duration(milliseconds: 1800));
  }

  void _setStatus(String text, _CaptureState state, {bool force = false}) {
    if (!mounted) return;
    if (!force && DateTime.now().isBefore(_noticeUntil)) return;
    if (_status == text && _captureState == state) return;
    setState(() {
      _status = text;
      _captureState = state;
    });
  }

  void _setAligned(bool v) {
    if (!mounted || _faceAligned == v) return;
    setState(() => _faceAligned = v);
  }

  void _resetCapture() {
    _capturedEmbeddings.clear();
    _livenessPassed = false;
    _rejects = 0;
    _spoofStrikes = 0;
    _trackingId = null;
    _liveness.start();
    if (mounted) setState(() {});
  }

  Future<Map?> _fetchStatusSafe() async {
    try {
      return await _api.getFaceStatus();
    } catch (_) {
      return null; // non-fatal: continue enrollment
    }
  }

  // ---------------------------------------------------------------------------
  // Init: status check, model load and camera discovery run in parallel
  // ---------------------------------------------------------------------------
  Future<void> _init() async {
    try {
      final statusFuture = _fetchStatusSafe();
      final modelFuture = _faceRecognition.loadModel();
      final camerasFuture = availableCameras();

      final status = await statusFuture;
      if (status != null && status['registered'] == true) {
        if (!mounted) return;
        final enrolledAt = status['data']?['enrolledAt']?.toString();
        await _showAlreadyEnrolledDialog(enrolledAt);
        if (!mounted) return;
        Navigator.pop(context, FaceEnrollmentResult.alreadyEnrolled);
        return;
      }

      await modelFuture;
      final cameras = await camerasFuture;
      if (cameras.isEmpty) {
        _setStatus('No camera available on this device', _CaptureState.error);
        if (mounted) setState(() => _fatalError = true);
        return;
      }

      final front = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _camera = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _camera!.initialize();
      if (!mounted) return;

      _liveness.start();
      await _startStream();
      if (mounted) {
        setState(() => _cameraReady = true);
        _setStatus('Position your face inside the oval', _CaptureState.idle);
      }
    } catch (e) {
      _setStatus('Camera init failed', _CaptureState.error);
      if (mounted) setState(() => _fatalError = true);
    }
  }

  Future<void> _startStream() async {
    if (_camera == null || _streaming) return;
    try {
      await _camera!.startImageStream(_onFrame);
      _streaming = true;
    } catch (_) {}
  }

  Future<void> _stopStream() async {
    if (_camera == null || !_streaming) return;
    try {
      await _camera!.stopImageStream();
    } catch (_) {}
    _streaming = false;
  }

  InputImage? _buildInputImage(CameraImage image, CameraController cam) {
    final sensorOrientation = cam.description.sensorOrientation;
    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rc = _orientations[cam.value.deviceOrientation] ?? 0;
      if (cam.description.lensDirection == CameraLensDirection.front) {
        rc = (sensorOrientation + rc) % 360;
      } else {
        rc = (sensorOrientation - rc + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rc);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || image.planes.length != 1) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  double _cosine(List<double> a, List<double> b) {
    double dot = 0, magA = 0, magB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }
    if (magA == 0 || magB == 0) return 0;
    return dot / (sqrt(magA) * sqrt(magB));
  }

  List<double> _meanOf(List<List<double>> vecs) {
    final dim = vecs.first.length;
    final avg = List<double>.filled(dim, 0);
    for (final v in vecs) {
      for (int i = 0; i < dim; i++) {
        avg[i] += v[i];
      }
    }
    for (int i = 0; i < dim; i++) {
      avg[i] /= vecs.length;
    }
    return avg;
  }

  // ---------------------------------------------------------------------------
  // Frame pipeline
  // ---------------------------------------------------------------------------

  /// Entry point from the camera stream. Drops frames while a previous one is
  /// still being processed (the old code stacked up detections => lag).
  Future<void> _onFrame(CameraImage image) async {
    if (_processing || _finalizing || !mounted) return;
    final now = DateTime.now();
    if (now.difference(_lastFrame) < _frameGap) return;
    _lastFrame = now;

    _processing = true;
    try {
      await _handleFrame(image);
    } catch (_) {
      _setStatus('Capture error — try again', _CaptureState.warning);
    } finally {
      _processing = false;
    }
  }

  Future<void> _handleFrame(CameraImage image) async {
    final cam = _camera;
    if (cam == null) return;

    final inputImage = _buildInputImage(image, cam);
    if (inputImage == null) return;

    final Face? face = await _faceRecognition.detectFace(inputImage);
    if (!mounted || _finalizing) return;

    // Tolerate a few missed detections before showing a warning (no flicker).
    if (face == null) {
      _missStreak++;
      // Face left the frame after liveness: someone/something could be swapped
      // in, so throw away the samples and require liveness again.
      if (_livenessPassed && _missStreak >= _maxLostFrames) {
        _resetCapture();
      }
      if (_missStreak >= 4) {
        _setAligned(false);
        _setStatus('No face detected', _CaptureState.warning);
      }
      return;
    }
    _missStreak = 0;

    final box = face.boundingBox;
    final rot = inputImage.metadata!.rotation.rawValue;
    final isRotated90 = rot == 90 || rot == 270;
    final frameW = isRotated90 ? image.height.toDouble() : image.width.toDouble();
    final frameH = isRotated90 ? image.width.toDouble() : image.height.toDouble();
    final minFrameDim = min(frameW, frameH);

    // 1) Size gates
    if (min(box.width, box.height) < minFrameDim * _minFaceRatio) {
      _setAligned(false);
      _setStatus('Move closer to the camera', _CaptureState.warning);
      return;
    }
    if (max(box.width, box.height) > minFrameDim * _maxFaceRatio) {
      _setAligned(false);
      _setStatus('Move back a little', _CaptureState.warning);
      return;
    }

    // 2) Centering gate
    final offsetX = ((box.left + box.width / 2) - frameW / 2).abs() / frameW;
    final offsetY = ((box.top + box.height / 2) - frameH / 2).abs() / frameH;
    if (offsetX > _maxCenterOffsetX || offsetY > _maxCenterOffsetY) {
      _setAligned(false);
      _setStatus('Center your face in the oval', _CaptureState.warning);
      return;
    }

    // 3) Liveness — verified once. Runs BEFORE the pose gate because the
    //    turn-left/right challenges need the head turned.
    if (!_livenessPassed) {
      _setAligned(true);
      if (_liveness.expired) _liveness.start();
      if (!_liveness.feed(face)) {
        _setStatus(_liveness.prompt, _CaptureState.warning);
        return;
      }
      _livenessPassed = true;
      _trackingId = face.trackingId; // lock identity of the live face
      HapticFeedback.selectionClick();
    }

    // 4) Same face throughout? (blocks swapping in a photo after liveness)
    if (_trackingId != null &&
        face.trackingId != null &&
        face.trackingId != _trackingId) {
      _resetCapture();
      _showNotice('Face changed — please start again', _CaptureState.warning);
      return;
    }

    // 5) Pose gate (for sample capture only)
    final yaw = face.headEulerAngleY ?? 0.0;
    final pitch = face.headEulerAngleX ?? 0.0;
    if (yaw.abs() > _maxYawDegrees || pitch.abs() > _maxPitchDegrees) {
      _setAligned(false);
      _setStatus('Look straight at the camera', _CaptureState.warning);
      return;
    }
    _setAligned(true);

    // 5) Sample capture (throttled so samples are slightly different)
    final now = DateTime.now();
    if (now.difference(_lastCapture) < _sampleGap) return;

    _setStatus(
      'Hold still… ${_capturedEmbeddings.length}/$_requiredSamples',
      _CaptureState.good,
    );

    final sample = await _faceRecognition.extractSample(
      image,
      face,
      inputImage.metadata!.rotation,
      cam.description.lensDirection,
    );
    if (!mounted || _finalizing) return;
    final embedding = sample.embedding;

    // Anti-spoof gate (skipped when the model isn't installed: score == null)
    final live = sample.liveScore;
    if (live != null && live < _minLiveScore) {
      _lastCapture = DateTime.now();
      if (++_spoofStrikes >= _maxSpoofStrikes) {
        _resetCapture();
        _showNotice(
          'Live face not verified. Use your real face in good light.',
          _CaptureState.error,
        );
      } else {
        _setStatus('Live face not verified', _CaptureState.warning);
      }
      return;
    }

    if (_capturedEmbeddings.isNotEmpty) {
      final sim = _cosine(embedding, _meanOf(_capturedEmbeddings));
      if (sim < _consistencyThreshold) {
        _lastCapture = DateTime.now();
        if (++_rejects >= _maxRejects) {
          // First samples were probably bad — start fresh instead of stalling.
          _capturedEmbeddings.clear();
          _rejects = 0;
          if (mounted) setState(() {});
          _setStatus('Restarting — hold steady', _CaptureState.warning);
        } else {
          _setStatus('Hold steady', _CaptureState.warning);
        }
        return;
      }
    }

    _rejects = 0;
    _capturedEmbeddings.add(embedding);
    _lastCapture = DateTime.now();
    HapticFeedback.selectionClick();
    if (mounted) setState(() {});
    _setStatus(
      'Hold still… ${_capturedEmbeddings.length}/$_requiredSamples',
      _CaptureState.good,
    );

    if (_capturedEmbeddings.length >= _requiredSamples && !_finalizing) {
      await _finalizeEnrollment();
    }
  }

  List<List<double>> _trimOutliers(List<List<double>> samples, int keep) {
    if (samples.length <= keep) return samples;
    final mean = _meanOf(samples);
    final scored = samples.map((s) => MapEntry(s, _cosine(s, mean))).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return scored.take(keep).map((e) => e.key).toList();
  }

  Future<void> _finalizeEnrollment() async {
    if (_finalizing) return;
    _finalizing = true;

    await _stopStream();
    _setStatus('Finishing up…', _CaptureState.good, force: true);

    try {
      final trimmed = _trimOutliers(_capturedEmbeddings, _keepCount);
      final avg = _meanOf(trimmed);
      final norm = sqrt(avg.fold(0.0, (s, x) => s + x * x));
      final normalized = norm > 0 ? avg.map((x) => x / norm).toList() : avg;

      final res = await _api.registerFace(
        embedding: normalized,
        livenessPassed: true,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        HapticFeedback.mediumImpact();
        await _showSuccessDialog();
        if (!mounted) return;
        Navigator.pop(context, FaceEnrollmentResult.success);
        return;
      }

      if (res['reason'] == 'ALREADY_ENROLLED') {
        final enrolledAt = res['data']?['enrolledAt']?.toString();
        await _showAlreadyEnrolledDialog(enrolledAt);
        if (!mounted) return;
        Navigator.pop(context, FaceEnrollmentResult.alreadyEnrolled);
        return;
      }

      _setStatus(
        (res['message'] ?? 'Enrollment failed').toString(),
        _CaptureState.error,
      );
      _resetCapture();
      _finalizing = false;
      await _startStream();
    } catch (e) {
      if (!mounted) return;
      _setStatus('Enrollment error — please retry', _CaptureState.error);
      _resetCapture();
      _finalizing = false;
      await _startStream();
    }
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------
  String _formatEnrolledAt(String? enrolledAt) {
    if (enrolledAt == null) return 'a previous session';
    final parsed = DateTime.tryParse(enrolledAt);
    if (parsed == null) return enrolledAt;
    final local = parsed.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final m = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} · $h:$m $ampm';
  }

  Future<void> _showInfoDialog({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String message,
    required String buttonLabel,
    Widget? extra,
    String? footnote,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _D.surface,
        surfaceTintColor: _D.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_D.radiusLg),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _D.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: _D.textSecondary,
              ),
            ),
            if (extra != null) ...[const SizedBox(height: 12), extra],
            if (footnote != null) ...[
              const SizedBox(height: 14),
              Text(
                footnote,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: _D.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: _D.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_D.radiusSm),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAlreadyEnrolledDialog(String? enrolledAt) {
    return _showInfoDialog(
      icon: Icons.verified_user_rounded,
      iconBg: _D.primarySoft,
      iconColor: _D.primary,
      title: 'Face Already Registered',
      message: 'Your face was enrolled on:',
      extra: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _D.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _D.border),
        ),
        child: Text(
          _formatEnrolledAt(enrolledAt),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _D.textPrimary,
          ),
        ),
      ),
      footnote: 'If you need to re-enroll, please contact HR.',
      buttonLabel: 'Got it',
    );
  }

  Future<void> _showSuccessDialog() {
    return _showInfoDialog(
      icon: Icons.check_rounded,
      iconBg: _D.primaryLight,
      iconColor: _D.primary,
      title: 'Face Enrolled',
      message:
      'Your face has been registered successfully. You can now use face recognition to check in.',
      buttonLabel: 'Continue',
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _camera?.dispose();
    _faceRecognition.dispose();
    _liveness.reset();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  Color _stateColor(_CaptureState s) {
    switch (s) {
      case _CaptureState.good:
        return _D.primary;
      case _CaptureState.warning:
        return _D.warning;
      case _CaptureState.error:
        return _D.danger;
      case _CaptureState.idle:
        return _D.textMuted;
    }
  }

  Color _stateSoft(_CaptureState s) {
    switch (s) {
      case _CaptureState.good:
        return _D.primarySoft;
      case _CaptureState.warning:
        return _D.warningSoft;
      case _CaptureState.error:
        return _D.dangerSoft;
      case _CaptureState.idle:
        return _D.surface;
    }
  }

  IconData _stateIcon(_CaptureState s) {
    switch (s) {
      case _CaptureState.good:
        return Icons.check_circle_rounded;
      case _CaptureState.warning:
        return Icons.info_rounded;
      case _CaptureState.error:
        return Icons.error_rounded;
      case _CaptureState.idle:
        return Icons.face_retouching_natural;
    }
  }

  double get _progress =>
      (_capturedEmbeddings.length / _requiredSamples).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _D.bg,
      appBar: AppBar(
        backgroundColor: _D.bg,
        surfaceTintColor: _D.bg,
        elevation: 0,
        centerTitle: false,
        foregroundColor: _D.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: const Text(
          'Register Face',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: _D.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _fatalError ? _buildFatalError() : _buildCameraArea(),
            ),
            if (!_fatalError) _buildBottomPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final subtitle = !_cameraReady
        ? 'Preparing camera…'
        : _livenessPassed
        ? 'Hold still while we capture your face'
        : 'Follow the prompt to confirm you are live';
    return Padding(
      padding: const EdgeInsets.fromLTRB(_D.lg, _D.sm, _D.lg, 0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: _D.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Face Verification Setup',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _D.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _D.textMuted,
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

  Widget _buildCameraArea() {
    return LayoutBuilder(
      builder: (context, c) {
        const ringPad = 14.0;
        // Oval is 4:5 (matches a portrait selfie frame, so little is cropped)
        final maxW = min(c.maxWidth * 0.78, (c.maxHeight - 16) / 1.25);
        final ovalW = max(maxW, 160.0);
        final ovalH = ovalW * 1.25;

        return Center(
          child: SizedBox(
            width: ovalW + ringPad * 2,
            height: ovalH + ringPad * 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Camera (cover-fit inside the oval)
                Container(
                  width: ovalW,
                  height: ovalH,
                  decoration: BoxDecoration(
                    color: _D.surface,
                    shape: BoxShape.circle,
                    boxShadow: _D.softShadow,
                  ),
                ),
                ClipOval(
                  child: SizedBox(
                    width: ovalW,
                    height: ovalH,
                    child: _buildPreview(),
                  ),
                ),
                // Progress ring
                Positioned.fill(
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _progress),
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      builder: (context, p, _) => AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) => CustomPaint(
                          painter: _RingPainter(
                            progress: p,
                            pulse: _pulseController.value,
                            aligned: _faceAligned,
                            color: _faceAligned
                                ? _D.primary
                                : _stateColor(_captureState),
                            inset: ringPad / 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreview() {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: _D.primary),
        ),
      );
    }
    final ps = cam.value.previewSize!; // landscape: width > height
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: ps.height,
        height: ps.width,
        child: CameraPreview(cam),
      ),
    );
  }

  Widget _buildFatalError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: _D.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam_off_rounded,
                color: _D.danger,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _D.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _fatalError = false;
                  _status = 'Preparing camera…';
                  _captureState = _CaptureState.idle;
                });
                _init();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _D.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_D.radiusSm),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    final color = _stateColor(_captureState);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status pill
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _stateSoft(_captureState),
              borderRadius: BorderRadius.circular(_D.radiusMd),
              border: Border.all(color: color.withOpacity(0.35)),
              boxShadow: _D.softShadow,
            ),
            child: Row(
              children: [
                Icon(_stateIcon(_captureState), color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _status,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _D.textPrimary,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Progress card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _D.surface,
              borderRadius: BorderRadius.circular(_D.radiusMd),
              border: Border.all(color: _D.border),
              boxShadow: _D.softShadow,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Capture progress',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _D.textSecondary,
                      ),
                    ),
                    Text(
                      '${(_progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _D.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _SampleDots(
                  total: _requiredSamples,
                  filled: _capturedEmbeddings.length,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tip
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.light_mode_rounded, size: 14, color: _D.textMuted),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Use good lighting and remove mask or cap',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: _D.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Progress ring painter (light theme). Separate from FaceOvalPainter so the
// punch-in screen keeps its current look.
// -----------------------------------------------------------------------------
class _RingPainter extends CustomPainter {
  final double progress; // 0..1
  final double pulse; // 0..1 looping
  final bool aligned;
  final Color color;
  final double inset;

  _RingPainter({
    required this.progress,
    required this.pulse,
    required this.aligned,
    required this.color,
    required this.inset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );

    // Soft breathing glow when the face is aligned
    if (aligned) {
      final amt = 0.5 + 0.5 * sin(pulse * 2 * pi);
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10 + 4 * amt
          ..color = color.withOpacity(0.10 + 0.10 * amt)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Track
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = aligned ? color.withOpacity(0.25) : _D.border,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5
          ..color = _D.primary,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
          old.pulse != pulse ||
          old.aligned != aligned ||
          old.color != color;
}

// -----------------------------------------------------------------------------
// Sample dots
// -----------------------------------------------------------------------------
class _SampleDots extends StatelessWidget {
  final int total;
  final int filled;

  const _SampleDots({required this.total, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isFilled = i < filled;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 6,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: isFilled ? _D.primary : _D.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}