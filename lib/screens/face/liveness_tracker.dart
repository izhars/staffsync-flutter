import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum LivenessChallenge { blink, turnLeft, turnRight }

class LivenessTracker {
  LivenessChallenge? _challenge;
  DateTime? _startedAt;
  bool _sawClosed = false;
  static const _window = Duration(seconds: 4);
  final _rand = Random();

  LivenessChallenge start() {
    _challenge = LivenessChallenge.values[_rand.nextInt(3)];
    _startedAt = DateTime.now();
    _sawClosed = false;
    return _challenge!;
  }

  LivenessChallenge? get current => _challenge;

  bool get expired =>
      _startedAt != null && DateTime.now().difference(_startedAt!) > _window;

  /// Feed a frame's Face. Returns true once the current challenge is satisfied.
  bool feed(Face face) {
    final c = _challenge;
    if (c == null || _startedAt == null) return false;
    if (expired) return false;

    switch (c) {
      case LivenessChallenge.blink:
        final closed = (face.leftEyeOpenProbability ?? 1) < 0.2 &&
            (face.rightEyeOpenProbability ?? 1) < 0.2;
        final open = (face.leftEyeOpenProbability ?? 0) > 0.7 &&
            (face.rightEyeOpenProbability ?? 0) > 0.7;
        if (closed) _sawClosed = true;
        return _sawClosed && open;
      case LivenessChallenge.turnLeft:
        return (face.headEulerAngleY ?? 0) > 12;
      case LivenessChallenge.turnRight:
        return (face.headEulerAngleY ?? 0) < -12;
    }
  }

  String get prompt {
    switch (_challenge) {
      case LivenessChallenge.blink:
        return 'Blink now';
      case LivenessChallenge.turnLeft:
        return 'Turn your head left';
      case LivenessChallenge.turnRight:
        return 'Turn your head right';
      case null:
        return '';
    }
  }

  void reset() {
    _challenge = null;
    _startedAt = null;
    _sawClosed = false;
  }
}