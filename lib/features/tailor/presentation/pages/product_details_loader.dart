import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/error_state_widget.dart';
import '../../domain/entities/shop_product.dart';
import '../providers/shop_provider.dart';
import 'product_details_page.dart';

/// Resolves a [ShopProduct] by id before rendering [ProductDetailsPage].
///
/// Navigation persists only serialisable arguments, so the product survives a
/// reload as its id alone. Re-fetching it here means a refresh lands back on
/// the same product instead of the "Product Not Available" placeholder.
class ProductDetailsLoader extends ConsumerStatefulWidget {
  const ProductDetailsLoader({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailsLoader> createState() => _ProductDetailsLoaderState();
}

class _ProductDetailsLoaderState extends ConsumerState<ProductDetailsLoader> {
  late Future<ShopProduct> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<ShopProduct> _fetch() async {
    final result =
        await ref.read(shopRepositoryProvider).getProduct(widget.productId);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (product) => product,
    );
  }

  void _retry() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShopProduct>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: ErrorStateWidget(
              message: 'This product could not be loaded.',
              onRetry: _retry,
            ),
          );
        }
        return ProductDetailsPage(product: snapshot.data!);
      },
    );
  }
}