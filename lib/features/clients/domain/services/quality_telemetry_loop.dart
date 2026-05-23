
/// Captures confidence and user correction signals for calibration.
/// Part of Step 4.1: Quality Telemetry Loop.
class QualityTelemetryLoop {
  final List<Map<String, dynamic>> _events = [];

  void recordFocusEvent({
    required String measurementKey,
    required String profileId,
    required double qualityScore,
    required bool usedFallback,
    required int interactionLatencyMs,
  }) {
    final event = {
      'timestamp': DateTime.now().toIso8601String(),
      'measurementKey': measurementKey,
      'profileId': profileId,
      'qualityScore': qualityScore,
      'usedFallback': usedFallback,
      'latencyMs': interactionLatencyMs,
    };
    
    _events.add(event);
    // In a real app, this would be synced to a backend or Firebase Analytics.
    print('📊 [TELEMETRY] $event');
  }

  List<Map<String, dynamic>> getEvents() => List.unmodifiable(_events);
}
