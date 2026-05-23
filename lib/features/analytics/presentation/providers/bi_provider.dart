import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/bi_service.dart';
import '../../data/repositories/bi_service_impl.dart';
import '../../domain/entities/recommendation.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final biServiceProvider = Provider<BIService>((ref) {
  return BIServiceImpl();
});

final recommendationsProvider = FutureProvider<List<Recommendation>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final service = ref.watch(biServiceProvider);
  return await service.getRecommendations(user.id);
});

final revenueForecastProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  
  final service = ref.watch(biServiceProvider);
  return await service.getRevenueForecast(user.id);
});
