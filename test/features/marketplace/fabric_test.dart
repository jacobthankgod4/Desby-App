import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:desby_app/core/error/failures.dart';
import 'package:desby_app/features/marketplace/domain/entities/fabric.dart';
import 'package:desby_app/features/marketplace/domain/repositories/fabric_repository.dart';
import 'package:desby_app/features/marketplace/domain/usecases/get_fabric_by_id_usecase.dart';
import 'package:desby_app/features/marketplace/domain/usecases/get_seller_inventory_usecase.dart';
import 'package:desby_app/features/marketplace/domain/usecases/delete_fabric_usecase.dart';

@GenerateMocks([FabricRepository])
import 'fabric_test.mocks.dart';

void main() {
  late GetFabricByIdUsecase getFabricById;
  late GetSellerInventoryUsecase getSellerInventory;
  late DeleteFabricUsecase deleteFabric;
  late MockFabricRepository mockRepo;

  setUp(() {
    mockRepo = MockFabricRepository();
    getFabricById = GetFabricByIdUsecase(mockRepo);
    getSellerInventory = GetSellerInventoryUsecase(mockRepo);
    deleteFabric = DeleteFabricUsecase(mockRepo);
    provideDummy<Result<Fabric>>(Failure(ServerFailure(message: 'dummy')));
    provideDummy<Result<List<Fabric>>>(Failure(ServerFailure(message: 'dummy')));
    provideDummy<Result<void>>(Failure(ServerFailure(message: 'dummy')));
  });

  final tFabric = Fabric(
    id: 'fab_1',
    name: 'Ankara Print',
    sellerId: 'seller_1',
    pricePerYard: 2500.0,
    category: 'Ankara',
    stockQuantity: 100,
    imageUrls: [],
    availableColors: ['Red', 'Blue'],
    isVisible: true,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  group('GetFabricByIdUsecase', () {
    test('should return Fabric on success', () async {
      when(mockRepo.getFabricById('fab_1'))
          .thenAnswer((_) async => Success(tFabric));

      final result = await getFabricById('fab_1');

      expect(result, isA<Success>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (fabric) => expect(fabric.name, 'Ankara Print'),
      );
    });

    test('should return Failure when fabric not found', () async {
      when(mockRepo.getFabricById('fab_1'))
          .thenAnswer((_) async => Failure(ServerFailure(message: 'Not found')));

      final result = await getFabricById('fab_1');

      expect(result, isA<Failure>());
    });
  });

  group('GetSellerInventoryUsecase', () {
    test('should return list of fabrics', () async {
      when(mockRepo.getSellerInventory('seller_1'))
          .thenAnswer((_) async => Success([tFabric]));

      final result = await getSellerInventory('seller_1');

      expect(result, isA<Success>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (fabrics) => expect(fabrics.length, 1),
      );
    });
  });

  group('DeleteFabricUsecase', () {
    test('should delete fabric successfully', () async {
      when(mockRepo.deleteFabric('fab_1'))
          .thenAnswer((_) async => const Success(null));

      final result = await deleteFabric('fab_1');

      expect(result, isA<Success>());
      verify(mockRepo.deleteFabric('fab_1')).called(1);
    });
  });
}
