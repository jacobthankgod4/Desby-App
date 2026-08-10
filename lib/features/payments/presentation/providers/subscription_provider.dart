import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/supabase_subscription_repository.dart';
import '../../domain/models/plan_registry.dart';
import '../../domain/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SupabaseSubscriptionRepository();
});

final availablePlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final userType = user?.userType ?? 'tailor';
  
  final repository = ref.read(subscriptionRepositoryProvider);
  
  var result = await repository.getPlans(userType);
  
  return result.fold(
    (failure) => throw failure.message,
    (plans) async {
      // Automatic data refresh if needed
      if (plans.isEmpty) {
        final repo = repository as SupabaseSubscriptionRepository;
        await repo.seedPlans();
        final freshResult = await repo.getPlans(userType);
        return freshResult.fold((f) => throw f.message, (p) => p);
      }
      return plans;
    },
  );
});
