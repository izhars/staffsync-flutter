class FaceMatchResult {
  final bool matched;
  final double similarity;
  final double threshold;
  final bool livenessPassed;
  final List<double> embedding;

  FaceMatchResult({
    required this.matched,
    required this.similarity,
    required this.threshold,
    required this.livenessPassed,
    required this.embedding,
  });
}

class LivenessChallenge {
  final String instruction;   // "Blink your eyes"
  final LivenessStep step;

  LivenessChallenge({required this.instruction, required this.step});
}

enum LivenessStep { blink, turnLeft, turnRight, done }