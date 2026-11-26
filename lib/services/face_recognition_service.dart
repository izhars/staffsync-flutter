import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// One captured frame: identity embedding + (optional) anti-spoof score.
class FaceSample {
  final List<double> embedding;

  /// Probability that the face is a real, live face (0..1).
  /// null when the anti-spoof model isn't available or failed to run.
  final double? liveScore;

  const FaceSample(this.embedding, this.liveScore);
}

class FaceRecognitionService {
  static Interpreter? _cachedInterpreter;
  static Interpreter? _cachedSpoofInterpreter;
  static bool _staticLoaded = false;

  Interpreter get _interpreter => _cachedInterpreter!;
  Interpreter? get _spoofInterpreter => _cachedSpoofInterpreter;

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: true, // needed to detect a face swap mid-enrollment
      minFaceSize: 0.15,
    ),
  );

  static const int _inputSize = 112;
  bool get isLoaded => _staticLoaded;

  // --- Anti-spoof (Silent-Face MiniFASNet) ---------------------------------
  // Put the converted model at this asset path and list it in pubspec.yaml.
  static const String _spoofAsset = 'assets/models/anti_spoof.tflite';
  static const int _spoofSize = 80;
  // 2.7 for MiniFASNetV2, 4.0 for MiniFASNetV1SE.
  static const double _spoofCropScale = 2.7;
  // Output classes are [other, real, spoof] (or [spoof, real]) -> index 1.
  static const int _spoofRealIndex = 1;

  bool get antiSpoofAvailable => _cachedSpoofInterpreter != null;

  Future<void> loadModel() async {
    if (_staticLoaded && _cachedInterpreter != null) return;
    _cachedInterpreter = await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');
    _staticLoaded = true;

    final inTensor = _cachedInterpreter!.getInputTensor(0);
    final outTensor = _cachedInterpreter!.getOutputTensor(0);
    print('MODEL INPUT: shape=${inTensor.shape} type=${inTensor.type}');
    print('MODEL OUTPUT: shape=${outTensor.shape} type=${outTensor.type}');

    await _loadSpoofModel();
  }

  Future<void> _loadSpoofModel() async {
    if (_cachedSpoofInterpreter != null) return;
    try {
      _cachedSpoofInterpreter = await Interpreter.fromAsset(_spoofAsset);
      final i = _cachedSpoofInterpreter!.getInputTensor(0);
      final o = _cachedSpoofInterpreter!.getOutputTensor(0);
      print('SPOOF INPUT: shape=${i.shape} type=${i.type}');
      print('SPOOF OUTPUT: shape=${o.shape} type=${o.type}');
    } catch (e) {
      _cachedSpoofInterpreter = null;
      print('WARNING: anti-spoof model not loaded ($e). Spoof check is OFF.');
    }
  }

  /// Detect a face from a camera image.
  Future<Face?> detectFace(InputImage inputImage) async {
    final faces = await _detector.processImage(inputImage);
    if (faces.isEmpty) return null;

    faces.sort((a, b) =>
        (b.boundingBox.width * b.boundingBox.height)
            .compareTo(a.boundingBox.width * a.boundingBox.height));
    return faces.first;
  }

  /// Embedding only (used by punch-in).
  Future<List<double>> extractEmbedding(
      CameraImage cameraImage,
      Face face,
      InputImageRotation rotation,
      CameraLensDirection lensDirection,
      ) async {
    final frame = _convertCameraImage(cameraImage, rotation, lensDirection);
    return _embeddingFrom(frame, face, lensDirection);
  }

  /// Embedding + anti-spoof score from a single frame conversion.
  Future<FaceSample> extractSample(
      CameraImage cameraImage,
      Face face,
      InputImageRotation rotation,
      CameraLensDirection lensDirection,
      ) async {
    final frame = _convertCameraImage(cameraImage, rotation, lensDirection);
    final embedding = _embeddingFrom(frame, face, lensDirection);
    final score = _realScore(frame, face);
    return FaceSample(embedding, score);
  }

  List<double> _embeddingFrom(
      img.Image imgImage,
      Face face,
      CameraLensDirection lensDirection,
      ) {
    final box = face.boundingBox;
    final padding = (box.width * 0.15).toInt();
    final cropRect = _clampRect(
      box.left.toInt() - padding,
      box.top.toInt() - padding,
      box.right.toInt() + padding,
      box.bottom.toInt() + padding,
      imgImage.width,
      imgImage.height,
    );

    final cw = cropRect[2] - cropRect[0];
    final ch = cropRect[3] - cropRect[1];
    if (cw <= 0 || ch <= 0) throw StateError('Invalid face crop region');

    var cropped = img.copyCrop(
      imgImage,
      x: cropRect[0],
      y: cropRect[1],
      width: cw,
      height: ch,
    );

    // Mirror only the crop (cosmetic/consistency), doesn't affect matching
    // since it's applied identically on enroll and verify.
    if (lensDirection == CameraLensDirection.front) {
      cropped = img.flipHorizontal(cropped);
    }

    final resized = img.copyResize(cropped, width: _inputSize, height: _inputSize);
    final input = _imageToFloat32(resized).reshape([1, _inputSize, _inputSize, 3]);

    final output = List.filled(192, 0.0).reshape([1, 192]);
    _interpreter.run(input, output);

    final raw = List<double>.from(output[0]);
    return _l2Normalize(raw);
  }

  /// Quick liveness check from ML Kit's eye-open probability.
  bool isLikelyLive(Face face) {
    final leftOpen = face.leftEyeOpenProbability ?? 1.0;
    final rightOpen = face.rightEyeOpenProbability ?? 1.0;
    return leftOpen > 0.15 && rightOpen > 0.15;
  }

  // ───────────────────────── anti-spoof ─────────────────────────

  /// Returns P(real face) from the MiniFASNet model, or null if unavailable.
  double? _realScore(img.Image frame, Face face) {
    final interp = _spoofInterpreter;
    if (interp == null) return null;

    try {
      // Square crop around the face WITH context (the model looks at the
      // surroundings: screen bezels, paper edges, moire, etc.).
      final box = face.boundingBox;
      var side = max(box.width, box.height) * _spoofCropScale;
      side = min(side, min(frame.width, frame.height).toDouble());

      final left = (box.center.dx - side / 2)
          .clamp(0.0, frame.width - side)
          .round();
      final top = (box.center.dy - side / 2)
          .clamp(0.0, frame.height - side)
          .round();
      final s = side.round();

      final crop = img.copyCrop(frame, x: left, y: top, width: s, height: s);
      final resized =
      img.copyResize(crop, width: _spoofSize, height: _spoofSize);

      // Silent-Face uses BGR, raw 0..255 (no normalisation).
      final bytes = resized.getBytes(order: img.ChannelOrder.bgr);
      final hw = _spoofSize * _spoofSize;
      final shape = interp.getInputTensor(0).shape;
      final nchw = shape.length == 4 && shape[1] == 3;

      final buf = Float32List(hw * 3);
      if (nchw) {
        for (int c = 0; c < 3; c++) {
          for (int i = 0; i < hw; i++) {
            buf[c * hw + i] = bytes[i * 3 + c].toDouble();
          }
        }
      } else {
        for (int i = 0; i < buf.length; i++) {
          buf[i] = bytes[i].toDouble();
        }
      }
      final input = nchw
          ? buf.reshape([1, 3, _spoofSize, _spoofSize])
          : buf.reshape([1, _spoofSize, _spoofSize, 3]);

      final n = interp.getOutputTensor(0).shape.last;
      final out = List.filled(n, 0.0).reshape([1, n]);
      interp.run(input, out);

      final raw = List<double>.from(out[0]);
      final sum = raw.fold<double>(0, (a, b) => a + b);
      final isProb =
          raw.every((v) => v >= 0 && v <= 1) && (sum - 1).abs() < 0.01;
      final probs = isProb ? raw : _softmax(raw);
      final real = probs[_spoofRealIndex.clamp(0, n - 1)];

      if (kDebugMode) print('SPOOF real-score=${real.toStringAsFixed(3)}');
      return real;
    } catch (e) {
      print('Anti-spoof failed: $e');
      return null;
    }
  }

  List<double> _softmax(List<double> v) {
    final m = v.reduce(max);
    final exps = v.map((x) => exp(x - m)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((x) => x / sum).toList();
  }

  // ─────────────────────────── helpers ───────────────────────────

  List<int> _clampRect(int l, int t, int r, int b, int w, int h) {
    final left = l.clamp(0, w - 1);
    final top = t.clamp(0, h - 1);
    final right = r.clamp(left + 1, w);
    final bottom = b.clamp(top + 1, h);
    return [left, top, right, bottom];
  }

  List<double> _l2Normalize(List<double> v) {
    double sum = 0;
    for (final x in v) sum += x * x;
    final n = sqrt(sum);
    if (n == 0) return v;
    return v.map((x) => x / n).toList();
  }

  img.Image _convertCameraImage(
      CameraImage image,
      InputImageRotation rotation,
      CameraLensDirection lensDirection,
      ) {
    img.Image out;
    if (image.format.group == ImageFormatGroup.bgra8888) {
      out = _convertBGRA(image);
    } else if (image.format.group == ImageFormatGroup.nv21) {
      out = _convertNV21(image);
    } else {
      out = _convertYUV420(image);
    }

    final deg = _rotationToDegrees(rotation);
    if (deg == 90) {
      out = img.copyRotate(out, angle: 90);
    } else if (deg == 180) {
      out = img.copyRotate(out, angle: 180);
    } else if (deg == 270) {
      out = img.copyRotate(out, angle: 270);
    }

    // NOTE: no mirroring here anymore — box coords match this image.
    return out;
  }

  img.Image _convertBGRA(CameraImage image) {
    final plane = image.planes[0];
    final bytes = plane.bytes;
    final out = img.Image(width: image.width, height: image.height);
    int i = 0;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final b = bytes[i++];
        final g = bytes[i++];
        final r = bytes[i++];
        i++; // alpha
        out.setPixelRgb(x, y, r, g, b);
      }
    }
    return out;
  }

  /// NV21: single plane, Y first (width*height bytes), then interleaved
  /// V,U pairs for every 2x2 block. This is what CameraController delivers
  /// on Android when imageFormatGroup is ImageFormatGroup.nv21.
  img.Image _convertNV21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yRowStride = image.planes[0].bytesPerRow;
    final bytes = image.planes[0].bytes;
    final frameSize = yRowStride * height;
    final out = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yRowStride + x;
        final uvIndex = frameSize + (y ~/ 2) * yRowStride + (x ~/ 2) * 2;

        if (yIndex >= bytes.length || uvIndex + 1 >= bytes.length) continue;

        final yVal = bytes[yIndex];
        final vVal = bytes[uvIndex];
        final uVal = bytes[uvIndex + 1];

        final r = (yVal + 1.402 * (vVal - 128)).round();
        final g =
        (yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128)).round();
        final b = (yVal + 1.772 * (uVal - 128)).round();

        out.setPixelRgb(
          x,
          y,
          r.clamp(0, 255),
          g.clamp(0, 255),
          b.clamp(0, 255),
        );
      }
    }
    return out;
  }

  img.Image _convertYUV420(CameraImage image) {
    final planeY = image.planes[0];
    final planeU = image.planes[1];
    final planeV = image.planes[2];

    final uvRowStride = planeU.bytesPerRow;
    final uvPixelStride = planeU.bytesPerPixel ?? 1;

    final out = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
        final yIndex = y * planeY.bytesPerRow + x;

        final yVal = planeY.bytes[yIndex];
        final uVal = planeU.bytes[uvIndex];
        final vVal = planeV.bytes[uvIndex];

        final r = (yVal + 1.402 * (vVal - 128)).round();
        final g =
        (yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128)).round();
        final b = (yVal + 1.772 * (uVal - 128)).round();

        out.setPixelRgb(
          x,
          y,
          r.clamp(0, 255),
          g.clamp(0, 255),
          b.clamp(0, 255),
        );
      }
    }
    return out;
  }

  int _rotationToDegrees(InputImageRotation r) {
    switch (r) {
      case InputImageRotation.rotation90deg:
        return 90;
      case InputImageRotation.rotation180deg:
        return 180;
      case InputImageRotation.rotation270deg:
        return 270;
      case InputImageRotation.rotation0deg:
      default:
        return 0;
    }
  }

  Float32List _imageToFloat32(img.Image image) {
    final bytes = image.getBytes(order: img.ChannelOrder.rgb);
    final buffer = Float32List(image.width * image.height * 3);
    int i = 0;
    for (final b in bytes) {
      buffer[i++] = (b - 127.5) / 127.5;
    }
    return buffer;
  }

  void dispose() {
    _detector.close();
    // Keep static model interpreters cached in memory across screens for instant reuse
  }
}