import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MarketplaceCartPage extends ConsumerWidget {
  const MarketplaceCartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('Please login')));

    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: StreamBuilder(
        stream: supabase.from('carts').stream(primaryKey: ['user_id']).eq('user_id', user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final cartData = snapshot.data;
          if (cartData == null || cartData.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }
          final items = cartData.first['items'] as List<dynamic>;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item['fabricName'] ?? 'Unknown Fabric'),
                subtitle: Text('${item['quantity']} yards'),
              );
            },
          );
        },
      ),
    );
  }
}
