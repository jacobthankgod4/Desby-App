import '../../../../core/error/failures.dart';
import '../models/plan_registry.dart';
import '../repositories/subscription_repository.dart';

class GetAvailablePlansUsecase {
  final SubscriptionRepository repository;
  GetAvailablePlansUsecase(this.repository);
  Future<Result<List<SubscriptionPlan>>> call(String userType) =>
      repository.getPlans(userType);
}
