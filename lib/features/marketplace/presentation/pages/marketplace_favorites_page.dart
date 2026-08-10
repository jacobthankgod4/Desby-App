import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MarketplaceFavoritesPage extends ConsumerWidget {
  const MarketplaceFavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('Please login')));

    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Favorites')),
      body: StreamBuilder(
        stream: supabase.from('favorites').stream(primaryKey: ['id']).eq('user_id', user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final favorites = snapshot.data ?? [];
          if (favorites.isEmpty) {
            return const Center(child: Text('No favorites yet'));
          }
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final fav = favorites[index];
              return ListTile(
                title: Text('Fabric ID: ${fav['fabric_id']}'),
              );
            },
          );
        },
      ),
    );
  }
}
