import '../../../../core/error/failures.dart';
import '../models/plan_registry.dart';

abstract class SubscriptionRepository {
  Future<Result<List<SubscriptionPlan>>> getPlans(String userType);
}
