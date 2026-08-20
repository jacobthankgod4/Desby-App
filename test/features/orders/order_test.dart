import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:desby_app/core/error/failures.dart';
import 'package:desby_app/features/orders/domain/entities/order.dart';
import 'package:desby_app/features/orders/domain/repositories/order_repository.dart';
import 'package:desby_app/features/orders/domain/usecases/order_usecases.dart';

@GenerateMocks([OrderRepository])
import 'order_test.mocks.dart';

void main() {
  late GetOrdersUsecase getOrders;
  late GetOrderByIdUsecase getOrderById;
  late CreateOrderUsecase createOrder;
  late MockOrderRepository mockRepository;

  setUp(() {
    mockRepository = MockOrderRepository();
    getOrders = GetOrdersUsecase(mockRepository);
    getOrderById = GetOrderByIdUsecase(mockRepository);
    createOrder = CreateOrderUsecase(mockRepository);
    provideDummy<Result<List<OrderEntity>>>(Failure(ServerFailure(message: 'dummy')));
    provideDummy<Result<OrderEntity>>(Failure(ServerFailure(message: 'dummy')));
  });

  final tOrder = OrderEntity(
    id: 'ord_1',
    clientId: 'client_1',
    tailorId: 'tailor_1',
    clientName: 'Test Client',
    items: [],
    status: OrderStatus.pending,
    totalAmount: 5000.0,
    dueDate: DateTime(2024, 12, 31),
    createdAt: DateTime(2024),
  );

  group('GetOrdersUsecase', () {
    test('should return list of orders on success', () async {
      when(mockRepository.getOrders(tailorId: anyNamed('tailorId')))
          .thenAnswer((_) async => Success([tOrder]));

      final result = await getOrders(tailorId: 'tailor1');

      expect(result, isA<Success>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (orders) => expect(orders.length, 1),
      );
    });

    test('should return Failure on error', () async {
      when(mockRepository.getOrders(tailorId: anyNamed('tailorId')))
          .thenAnswer((_) async => Failure(NetworkFailure(message: 'No connection')));

      final result = await getOrders(tailorId: 'tailor1');

      expect(result, isA<Failure>());
    });
  });

  group('GetOrderByIdUsecase', () {
    test('should return order by id', () async {
      when(mockRepository.getOrderById('ord_1'))
          .thenAnswer((_) async => Success(tOrder));

      final result = await getOrderById('ord_1');

      expect(result, isA<Success>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (order) => expect(order.id, 'ord_1'),
      );
    });
  });

  group('CreateOrderUsecase', () {
    test('should create order successfully', () async {
      when(mockRepository.createOrder(any))
          .thenAnswer((_) async => Success(tOrder));

      final result = await createOrder(tOrder);

      expect(result, isA<Success>());
      verify(mockRepository.createOrder(tOrder)).called(1);
    });
  });
}
