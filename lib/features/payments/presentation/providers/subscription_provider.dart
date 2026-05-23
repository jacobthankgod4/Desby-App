import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/firebase_subscription_repository.dart';
import '../../domain/models/plan_registry.dart';
import '../../domain/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return FirebaseSubscriptionRepository();
});

final availablePlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final userType = user?.userType ?? 'tailor';
  
  final repository = ref.read(subscriptionRepositoryProvider);
  
  // PRODUCTION FETCH
  var result = await repository.getPlans(userType);
  
  return result.fold(
    (failure) => throw failure.message,
    (plans) async {
      // DATA UPGRADE LOGIC: If existing data is "old" (fewer than 8 features), refresh it once
      if (plans.isNotEmpty && plans.any((p) => p.features.length < 8)) {
        final repo = repository as FirebaseSubscriptionRepository;
        await repo.seedPlans();
        final freshResult = await repo.getPlans(userType);
        return freshResult.fold((f) => throw f.message, (p) => p);
      }
      return plans;
    },
  );
});
