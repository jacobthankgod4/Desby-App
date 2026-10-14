import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/body_measurement_service.dart';

final bodyMeasurementServiceProvider = Provider<BodyMeasurementService>((ref) {
  return BodyMeasurementService();
});
