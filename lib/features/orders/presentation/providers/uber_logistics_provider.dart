import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/uber_logistics_repository_impl.dart';
import '../../domain/repositories/uber_logistics_repository.dart';

final uberLogisticsRepositoryProvider = Provider<UberLogisticsRepository>((ref) {
  return UberLogisticsRepositoryImpl();
});
