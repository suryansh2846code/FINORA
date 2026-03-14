class FreshnessResult {
  final bool isFresh;
  final double confidence;

  FreshnessResult({required this.isFresh, required this.confidence});

  @override
  String toString() {
    return 'FreshnessResult(isFresh: $isFresh, confidence: $confidence)';
  }
}
