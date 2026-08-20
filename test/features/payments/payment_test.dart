import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:desby_app/core/error/failures.dart';
import 'package:desby_app/features/payments/domain/models/plan_registry.dart';
import 'package:desby_app/features/payments/domain/repositories/subscription_repository.dart';
import 'package:desby_app/features/payments/domain/usecases/get_available_plans_usecase.dart';

@GenerateMocks([SubscriptionRepository])
import 'payment_test.mocks.dart';

void main() {
  late GetAvailablePlansUsecase getPlans;
  late MockSubscriptionRepository mockRepo;

  setUp(() {
    mockRepo = MockSubscriptionRepository();
    getPlans = GetAvailablePlansUsecase(mockRepo);
    provideDummy<Result<List<SubscriptionPlan>>>(Failure(ServerFailure(message: 'dummy')));
  });

  final tPlans = [
    SubscriptionPlan(
      id: 'plan_1',
      name: 'Basic',
      price: '5,000',
      amount: 5000,
      features: ['Feature 1'],
      userType: 'tailor',
    ),
    SubscriptionPlan(
      id: 'plan_2',
      name: 'Pro',
      price: '15,000',
      amount: 15000,
      features: ['Feature 1', 'Feature 2'],
      isElite: true,
      userType: 'tailor',
    ),
  ];

  group('GetAvailablePlansUsecase', () {
    test('should return list of plans on success', () async {
      when(mockRepo.getPlans('tailor'))
          .thenAnswer((_) async => Success(tPlans));

      final result = await getPlans('tailor');

      expect(result, isA<Success>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (plans) => expect(plans.length, 2),
      );
    });

    test('should return Failure on error', () async {
      when(mockRepo.getPlans('tailor'))
          .thenAnswer((_) async => Failure(ServerFailure(message: 'DB error')));

      final result = await getPlans('tailor');

      expect(result, isA<Failure>());
    });
  });
}
