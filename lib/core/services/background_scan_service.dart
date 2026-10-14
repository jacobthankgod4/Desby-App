import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/korra_client.dart';
import 'body_measurement_service.dart';
import '../providers/body_measurement_provider.dart';

enum BackgroundScanStatus {
  idle,
  uploading,
  extracting,
  polling,
  completed,
  failed,
}

class BackgroundScanTask {
  final String taskId;
  final BackgroundScanStatus status;
  final Map<String, double>? measurements;
  final String? accuracyDescription;
  final String? error;
  final String gender;
  final double heightCm;
  final DateTime startedAt;
  final DateTime? completedAt;

  const BackgroundScanTask({
    required this.taskId,
    required this.status,
    this.measurements,
    this.accuracyDescription,
    this.error,
    required this.gender,
    required this.heightCm,
    required this.startedAt,
    this.completedAt,
  });

  BackgroundScanTask copyWith({
    BackgroundScanStatus? status,
    Map<String, double>? measurements,
    String? accuracyDescription,
    String? error,
    DateTime? completedAt,
  }) {
    return BackgroundScanTask(
      taskId: taskId,
      status: status ?? this.status,
      measurements: measurements ?? this.measurements,
      accuracyDescription: accuracyDescription ?? this.accuracyDescription,
      error: error ?? this.error,
      gender: gender,
      heightCm: heightCm,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class BackgroundScanNotifier extends StateNotifier<BackgroundScanTask?> {
  Completer<BackgroundScanTask?>? _completion;

  /// Resolves when the current scan settles (completed or failed).
  ///
  /// The page used to depend purely on a `ref.listen` for the transition to
  /// results. That listener is registered once and competes with other
  /// consumers of this shared provider, so a completed scan could be announced
  /// globally (the green banner) while the page that started it stayed on
  /// "Processing in background…" forever. Awaiting the outcome removes the
  /// race entirely.
  Future<BackgroundScanTask?> waitForCompletion() {
    final s = state;
    if (s != null &&
        (s.status == BackgroundScanStatus.completed ||
            s.status == BackgroundScanStatus.failed)) {
      return Future<BackgroundScanTask?>.value(s);
    }
    _completion ??= Completer<BackgroundScanTask?>();
    return _completion!.future;
  }

  void _settle() {
    final s = state;
    if (s == null) return;
    if (s.status != BackgroundScanStatus.completed &&
        s.status != BackgroundScanStatus.failed) {
      return;
    }
    final c = _completion;
    _completion = null;
    if (c != null && !c.isCompleted) c.complete(s);
  }
  final BodyMeasurementService _service;
  final KorraClient _korra;
  Timer? _pollTimer;

  BackgroundScanNotifier(this._service, this._korra) : super(null);

  /// Start a background scan. Images are sent to Korra and processing
  /// continues even if the user navigates away.
  Future<void> startScan({
    required Uint8List frontImageBytes,
    required Uint8List sideImageBytes,
    required double heightCm,
    required String gender,
  }) async {
    if (state?.status == BackgroundScanStatus.polling ||
        state?.status == BackgroundScanStatus.extracting) {
      debugPrint('[BG-SCAN] Scan already in progress — skipping');
      return;
    }

    final taskId = 'scan_${DateTime.now().millisecondsSinceEpoch}';
    state = BackgroundScanTask(
      taskId: taskId,
      status: BackgroundScanStatus.uploading,
      gender: gender,
      heightCm: heightCm,
      startedAt: DateTime.now(),
    );
    debugPrint('[BG-SCAN] ═══ Scan started: $taskId ═══');

    try {
      // Ensure API key is set
      await _service.listMeasurements(); // triggers _ensureApiKey

      state = state!.copyWith(status: BackgroundScanStatus.extracting);
      debugPrint('[BG-SCAN] Sending photos to Korra...');

      final result = await _korra.extractMeasurements(
        frontImageBytes: frontImageBytes,
        sideImageBytes: sideImageBytes,
        heightCm: heightCm,
        gender: gender,
      );

      debugPrint(
        '[BG-SCAN] Korra responded — success: ${result.success}, measurements: ${result.measurements?.length}, error: ${result.error}',
      );

      if (result.success && result.measurements != null) {
        // Compute accuracy description from accuracyMode
        String accDesc;
        switch (result.accuracyMode) {
          case 'dual':
            accDesc = 'Professional accuracy (±1-3cm)';
            break;
          case 'single':
            accDesc = 'Good accuracy (±3-5cm)';
            break;
          case 'estimate':
            accDesc = 'Estimated (±5-8cm)';
            break;
          default:
            accDesc = result.accuracy;
        }
        state = state!.copyWith(
          status: BackgroundScanStatus.completed,
          measurements: result.measurements,
          accuracyDescription: accDesc,
          completedAt: DateTime.now(),
        );
        debugPrint(
          '[BG-SCAN] ✅ Scan completed — ${result.measurements!.length} measurements',
        );
        _settle();
      } else {
        state = state!.copyWith(
          status: BackgroundScanStatus.failed,
          error: result.error ?? 'Extraction failed',
          completedAt: DateTime.now(),
        );
        debugPrint('[BG-SCAN] ❌ Scan failed: ${result.error}');
      _settle();
      }
    } catch (e, stack) {
      debugPrint('[BG-SCAN] EXCEPTION: $e');
      debugPrint('[BG-SCAN] STACK: $stack');
      _settle();
      state = state!.copyWith(
        status: BackgroundScanStatus.failed,
        error: e.toString(),
        completedAt: DateTime.now(),
      );
    }
  }

  /// Clear the current task (after user views results or dismisses error)
  void clearTask() {
    debugPrint('[BG-SCAN] clearTask');
    _pollTimer?.cancel();
    state = null;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final backgroundScanProvider =
    StateNotifierProvider<BackgroundScanNotifier, BackgroundScanTask?>((ref) {
      final service = ref.watch(bodyMeasurementServiceProvider);
      final korra = KorraClient();
      return BackgroundScanNotifier(service, korra);
    });
