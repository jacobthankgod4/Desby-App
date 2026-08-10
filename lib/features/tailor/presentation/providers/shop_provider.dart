import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/shop_product.dart';
import '../../domain/repositories/shop_repository.dart';
import '../../data/repositories/supabase_shop_repository.dart';

/// Shop repository provider
final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return SupabaseShopRepository();
});

/// Shop products provider for current tailor
final shopProductsProvider = FutureProvider.family<List<ShopProduct>, String>((ref, tailorId) async {
  final repository = ref.read(shopRepositoryProvider);
  final result = await repository.getProducts(tailorId);
  
  return result.fold(
    (failure) => <ShopProduct>[],
    (data) => data,
  );
});

/// Current shop products provider
final currentShopProductsProvider = FutureProvider<List<ShopProduct>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final tailorId = currentUser?.id ?? '';
  
  if (tailorId.isEmpty) return [];
  
  return ref.watch(shopProductsProvider(tailorId).future);
});

/// Add product usecase
class AddProductUseCase {
  final ShopRepository _repository;
  
  AddProductUseCase(this._repository);
  
  Future<Result<ShopProduct>> call(ShopProduct product) {
    return _repository.createProduct(product);
  }
}

final addProductUseCaseProvider = Provider<AddProductUseCase>((ref) {
  final repository = ref.read(shopRepositoryProvider);
  return AddProductUseCase(repository);
});

/// Update product usecase
class UpdateProductUseCase {
  final ShopRepository _repository;
  
  UpdateProductUseCase(this._repository);
  
  Future<Result<ShopProduct>> call(ShopProduct product) {
    return _repository.updateProduct(product);
  }
}

final updateProductUseCaseProvider = Provider<UpdateProductUseCase>((ref) {
  final repository = ref.read(shopRepositoryProvider);
  return UpdateProductUseCase(repository);
});

/// Delete product usecase
class DeleteProductUseCase {
  final ShopRepository _repository;
  
  DeleteProductUseCase(this._repository);
  
  Future<Result<void>> call(String productId) {
    return _repository.deleteProduct(productId);
  }
}

final deleteProductUseCaseProvider = Provider<DeleteProductUseCase>((ref) {
  final repository = ref.read(shopRepositoryProvider);
  return DeleteProductUseCase(repository);
});

/// Toggle product visibility usecase
class ToggleProductVisibilityUseCase {
  final ShopRepository _repository;
  
  ToggleProductVisibilityUseCase(this._repository);
  
  Future<Result<ShopProduct>> call(String productId, bool isVisible) {
    return _repository.toggleProductVisibility(productId, isVisible);
  }
}

final toggleProductVisibilityUseCaseProvider = Provider<ToggleProductVisibilityUseCase>((ref) {
  final repository = ref.read(shopRepositoryProvider);
  return ToggleProductVisibilityUseCase(repository);
});

/// Shop notifier for managing shop state
class ShopNotifier extends StateNotifier<AsyncValue<List<ShopProduct>>> {
  final ShopRepository _repository;
  final String _tailorId;
  
  ShopNotifier(this._repository, this._tailorId) : super(const AsyncValue.loading()) {
    loadProducts();
  }
  
  Future<void> loadProducts() async {
    if (_tailorId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    final result = await _repository.getProducts(_tailorId);
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (data) => state = AsyncValue.data(data),
    );
  }
  
  Future<bool> addProduct(ShopProduct product) async {
    final result = await _repository.createProduct(product);
    return result.fold(
      (failure) => false,
      (data) {
        loadProducts();
        return true;
      },
    );
  }
  
  Future<bool> updateProduct(ShopProduct product) async {
    final result = await _repository.updateProduct(product);
    return result.fold(
      (failure) => false,
      (data) {
        loadProducts();
        return true;
      },
    );
  }
  
  Future<bool> deleteProduct(String productId) async {
    final result = await _repository.deleteProduct(productId);
    return result.fold(
      (failure) => false,
      (data) {
        loadProducts();
        return true;
      },
    );
  }
  
  Future<bool> toggleVisibility(String productId, bool isVisible) async {
    final result = await _repository.toggleProductVisibility(productId, isVisible);
    return result.fold(
      (failure) => false,
      (data) {
        loadProducts();
        return true;
      },
    );
  }
}

final shopNotifierProvider = StateNotifierProvider<ShopNotifier, AsyncValue<List<ShopProduct>>>((ref) {
  final repository = ref.read(shopRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  final tailorId = currentUser?.id ?? '';
  
  return ShopNotifier(repository, tailorId);
});

/// Product form state for adding/editing products
class ProductFormState {
  final String name;
  final String description;
  final double price;
  final String category;
  final bool isLoading;
  final String? error;
  
  const ProductFormState({
    this.name = '',
    this.description = '',
    this.price = 0.0,
    this.category = 'Custom',
    this.isLoading = false,
    this.error,
  });
  
  ProductFormState copyWith({
    String? name,
    String? description,
    double? price,
    String? category,
    bool? isLoading,
    String? error,
  }) {
    return ProductFormState(
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
  
  bool get isValid => name.isNotEmpty && price > 0;
}

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  ProductFormNotifier() : super(const ProductFormState());
  
  void setName(String name) {
    state = state.copyWith(name: name);
  }
  
  void setDescription(String description) {
    state = state.copyWith(description: description);
  }
  
  void setPrice(double price) {
    state = state.copyWith(price: price);
  }
  
  void setCategory(String category) {
    state = state.copyWith(category: category);
  }
  
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }
  
  void setError(String? error) {
    state = state.copyWith(error: error);
  }
  
  void reset() {
    state = const ProductFormState();
  }
}

final productFormProvider = StateNotifierProvider<ProductFormNotifier, ProductFormState>((ref) {
  return ProductFormNotifier();
});
