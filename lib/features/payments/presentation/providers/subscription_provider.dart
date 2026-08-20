import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/supabase_subscription_repository.dart';
import '../../domain/models/plan_registry.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/usecases/get_available_plans_usecase.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SupabaseSubscriptionRepository();
});

final getAvailablePlansUsecaseProvider = Provider<GetAvailablePlansUsecase>((ref) {
  return GetAvailablePlansUsecase(ref.watch(subscriptionRepositoryProvider));
});

final availablePlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final userType = user?.userType ?? 'tailor';
  final usecase = ref.watch(getAvailablePlansUsecaseProvider);
  var result = await usecase(userType);
  return result.fold(
    (failure) => throw failure.message,
    (plans) async {
      if (plans.isEmpty) {
        final repo = ref.read(subscriptionRepositoryProvider) as SupabaseSubscriptionRepository;
        await repo.seedPlans();
        final freshResult = await usecase(userType);
        return freshResult.fold((f) => throw f.message, (p) => p);
      }
      return plans;
    },
  );
});
