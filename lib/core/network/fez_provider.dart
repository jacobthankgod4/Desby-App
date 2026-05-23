import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_client.dart';
import 'fez_logistics_service.dart';

final fezLogisticsServiceProvider = Provider<FezLogisticsService>((ref) {
  final dio = ref.watch(dioProvider);
  return FezLogisticsService(dio);
});
