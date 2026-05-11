class PredictionResult {
  final int riskScore;
  final bool isScam;

  const PredictionResult({required this.riskScore, required this.isScam});

  factory PredictionResult.fromProbability(
    double probability, {
    double threshold = 0.5,
  }) {
    final normalized = probability.clamp(0.0, 1.0);
    final score = (normalized * 100).round().clamp(0, 100);
    return PredictionResult(riskScore: score, isScam: normalized >= threshold);
  }

  /// Safe result when model is unavailable or prediction fails.
  factory PredictionResult.safe() {
    return const PredictionResult(riskScore: 0, isScam: false);
  }
}
