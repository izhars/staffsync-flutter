// screens/face/face_capture_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../services/face_recognition_service.dart';
import 'liveness_tracker.dart';

/// Visual state driving color + icon for the status pill.
enum _CaptureState { idle, good, warning, error }

/// Mirrors DashboardDesign so all face screens match the dashboard.
/// TODO: move DashboardDesign (+ this ring painter) into a shared file and
/// import it here and in face_enrollment_screen.dart.
class _D {
  static const double sm = 8;
  static const double lg = 24;
  static const double radiusSm = 12;
  static const double radiusMd = 18;

  static const Color bg = Color(0xFFF6F7FB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFEAECEF);
  static const Color primary = Color(0xFF0F766E);
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

class FaceCaptureScreen extends StatefulWidget {
  /// Heading shown in the app bar (e.g. "Punch In", "Verify Face").
  final String title;

  /// Subtitle shown under the heading.
  final String subtitle;

  /// Minimum face-to-frame ratio for a valid capture.
  final double minFaceRatio;

  /// How many samples to average before popping.
  final int requiredSamples;

  const FaceCaptureScreen({
    super.key,
    this.title = 'Position your face',
    this.subtitle = 'Keep your face inside the frame',
    this.minFaceRatio = 0.20,
    this.requiredSamples = 3,
  });

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _camera;
  final FaceRecognitionService _recognition = FaceRecognitionService();
  final LivenessTracker _liveness = LivenessTracker();

  // Frame pipeline state
  bool _processing = false; // one frame at a time
  bool _streaming = false;
  bool _finishing = false;
  bool _disposed = false;
  bool _livenessPassed = false; // liveness is checked ONCE
  int _missStreak = 0;
  int _rejects = 0;
  int _spoofStrikes = 0;
  int? _trackingId;
  DateTime _noticeUntil = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastCapture = DateTime.fromMillisecondsSinceEpoch(0);

  // UI state
  bool _faceAligned = false;
  bool _cameraReady = false;
  bool _fatalError = false;
  String _status = 'Position your face inside the oval';
  _CaptureState _captureState = _CaptureState.idle;

  final List<List<double>> _captured = [];

  // --- Tuning ---------------------------------------------------------------
  static const double _consistencyThreshold = 0.5;
  static const int _maxRejects = 4;
  static const Duration _frameGap = Duration(milliseconds: 50);
  static const Duration _sampleGap = Duration(milliseconds: 150);

  static const double _maxFaceRatio = 1.0;
  static const double _maxCenterOffsetX = 0.24;
  static const double _maxCenterOffsetY = 0.24;
  static const double _maxYawDegrees = 20.0;
  static const double _maxPitchDegrees = 20.0;

  // Anti-spoof
  static const double _minLiveScore = 0.5; // keep in sync with enrollment
  static const int _maxSpoofStrikes = 4;
  static const int _maxLostFrames = 6;

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
    _init();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  void _showNotice(String text, _CaptureState state) {
    _setStatus(text, state, force: true);
    _noticeUntil = DateTime.now().add(const Duration(milliseconds: 1800));
  }

  void _setStatus(String text, _CaptureState state, {bool force = false}) {
    if (!mounted || _disposed) return;
    if (!force && DateTime.now().isBefore(_noticeUntil)) return;
    if (_status == text && _captureState == state) return;
    setState(() {
      _status = text;
      _captureState = state;
    });
  }

  void _setAligned(bool v) {
    if (!mounted || _disposed || _faceAligned == v) return;
    setState(() => _faceAligned = v);
  }

  void _resetCapture() {
    _captured.clear();
    _livenessPassed = false;
    _rejects = 0;
    _spoofStrikes = 0;
    _trackingId = null;
    _liveness.start();
    if (mounted && !_disposed) setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Init: model load and camera discovery run in parallel
  // ---------------------------------------------------------------------------
  Future<void> _init() async {
    try {
      final modelFuture = _recognition.loadModel();
      final camerasFuture = availableCameras();

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
      if (_disposed) return;

      _liveness.start();
      await _startStream();
      if (mounted) {
        setState(() => _cameraReady = true);
        _setStatus('Position your face inside the oval', _CaptureState.idle);
      }
    } catch (e) {
      _setStatus('Camera error — please retry', _CaptureState.error);
      if (mounted) setState(() => _fatalError = true);
    }
  }

  Future<void> _startStream() async {
    if (_camera == null || _streaming || _disposed) return;
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

  List<double> _averageAndNormalize(List<List<double>> samples) {
    final avg = _meanOf(samples);
    final norm = sqrt(avg.fold(0.0, (s, x) => s + x * x));
    if (norm > 0) {
      for (int i = 0; i < avg.length; i++) {
        avg[i] /= norm;
      }
    }
    return avg;
  }

  // ---------------------------------------------------------------------------
  // Frame pipeline
  // ---------------------------------------------------------------------------
  Future<void> _onFrame(CameraImage image) async {
    if (_processing || _finishing || _disposed || !mounted) return;
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

    final Face? face = await _recognition.detectFace(inputImage);
    if (_disposed || !mounted || _finishing) return;

    if (face == null) {
      _missStreak++;
      // Face left the frame after liveness: require liveness again.
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
    if (min(box.width, box.height) < minFrameDim * widget.minFaceRatio) {
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

    // 3) Liveness — once. Before the pose gate (turn challenges need a turn).
    if (!_livenessPassed) {
      _setAligned(true);
      if (_liveness.expired) _liveness.start();
      if (!_liveness.feed(face)) {
        _setStatus(_liveness.prompt, _CaptureState.warning);
        return;
      }
      _livenessPassed = true;
      _trackingId = face.trackingId;
      HapticFeedback.selectionClick();
    }

    // 4) Same face throughout?
    if (_trackingId != null &&
        face.trackingId != null &&
        face.trackingId != _trackingId) {
      _resetCapture();
      _showNotice('Face changed — please start again', _CaptureState.warning);
      return;
    }

    // 5) Pose gate (sample capture only)
    final yaw = face.headEulerAngleY ?? 0.0;
    final pitch = face.headEulerAngleX ?? 0.0;
    if (yaw.abs() > _maxYawDegrees || pitch.abs() > _maxPitchDegrees) {
      _setAligned(false);
      _setStatus('Look straight at the camera', _CaptureState.warning);
      return;
    }
    _setAligned(true);

    // 6) Sample capture (throttled)
    if (DateTime.now().difference(_lastCapture) < _sampleGap) return;

    _setStatus(
      'Hold still… ${_captured.length}/${widget.requiredSamples}',
      _CaptureState.good,
    );

    final sample = await _recognition.extractSample(
      image,
      face,
      inputImage.metadata!.rotation,
      cam.description.lensDirection,
    );
    if (_disposed || !mounted || _finishing) return;
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

    // Consistency between samples
    if (_captured.isNotEmpty) {
      final sim = _cosine(embedding, _meanOf(_captured));
      if (sim < _consistencyThreshold) {
        _lastCapture = DateTime.now();
        if (++_rejects >= _maxRejects) {
          _captured.clear();
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
    _captured.add(embedding);
    _lastCapture = DateTime.now();
    HapticFeedback.selectionClick();
    if (mounted) setState(() {});
    _setStatus(
      'Hold still… ${_captured.length}/${widget.requiredSamples}',
      _CaptureState.good,
    );

    if (_captured.length >= widget.requiredSamples && !_finishing) {
      _finishing = true;
      final avg = _averageAndNormalize(_captured);
      _setStatus('Verifying…', _CaptureState.good, force: true);
      // Defer teardown outside the stream callback (Android crash).
      scheduleMicrotask(() => _finishCapture(avg));
    }
  }

  Future<void> _finishCapture(List<double> embedding) async {
    await _stopStream();
    if (_disposed || !mounted) return;
    Navigator.pop(context, embedding);
  }

  @override
  void dispose() {
    _disposed = true;
    _streaming = false;
    _liveness.reset();
    _pulseController.dispose();
    _camera?.dispose();
    _recognition.dispose();
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
      (_captured.length / widget.requiredSamples).clamp(0.0, 1.0);

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
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: _D.textPrimary),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
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
    final subtitle = _cameraReady ? widget.subtitle : 'Preparing camera…';
    return Padding(
      padding: const EdgeInsets.fromLTRB(_D.lg, _D.sm, _D.lg, 0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: _D.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13.5,
                color: _D.textSecondary,
                fontWeight: FontWeight.w500,
              ),
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
    final ps = cam.value.previewSize!;
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
          Row(
            children: List.generate(widget.requiredSamples, (i) {
              final filled = i < _captured.length;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  height: 6,
                  margin: EdgeInsets.only(
                    right: i == widget.requiredSamples - 1 ? 0 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: filled ? _D.primary : _D.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
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
// Progress ring painter (light theme)
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

    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = aligned ? color.withOpacity(0.25) : _D.border,
    );

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