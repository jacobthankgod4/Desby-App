import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../designs/domain/entities/design.dart';
import '../../../designs/presentation/providers/design_provider.dart';
import 'shop_checkout_page.dart';

/// Resolves a [Design] by id before handing off to [ShopCheckoutPage].
///
/// Navigation persists only serialisable arguments, so a `Design` survives a
/// reload as its id alone. This re-fetches it so a refresh resumes the exact
/// checkout the user was on rather than dumping them back at the dashboard.
class ShopCheckoutLoader extends ConsumerStatefulWidget {
  const ShopCheckoutLoader({
    super.key,
    required this.designId,
    required this.quantity,
    required this.size,
    required this.colorValue,
  });

  final String designId;
  final int quantity;
  final String? size;
  final int colorValue;

  @override
  ConsumerState<ShopCheckoutLoader> createState() => _ShopCheckoutLoaderState();
}

class _ShopCheckoutLoaderState extends ConsumerState<ShopCheckoutLoader> {
  late Future<Design> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<Design> _fetch() async {
    final result =
        await ref.read(designRepositoryProvider).getDesignById(widget.designId);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (design) => design,
    );
  }

  void _retry() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Design>(
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
              message: 'This checkout could not be restored.',
              onRetry: _retry,
            ),
          );
        }
        return ShopCheckoutPage(
          design: snapshot.data!,
          quantity: widget.quantity,
          size: widget.size,
          colorValue: widget.colorValue,
        );
      },
    );
  }
}

/// Shown when checkout is entered with neither a design nor a recoverable id.
class MissingCheckoutState extends ConsumerWidget {
  const MissingCheckoutState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ErrorStateWidget(
        message: 'No item selected. Pick something from the shop to start a checkout.',
        onRetry: () => ref.read(navigationStackProvider.notifier).pop(),
      ),
    );
  }
}