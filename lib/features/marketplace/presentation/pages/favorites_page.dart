import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('Please login')));

    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Items')),
      body: ListView(
        children: [
          const ListTile(title: Text('Fabric Favorites', style: TextStyle(fontWeight: FontWeight.bold))),
          StreamBuilder(
            stream: supabase.from('favorites').stream(primaryKey: ['id']).eq('user_id', user.id),
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];
              return Column(
                children: data.map((fav) => ListTile(title: Text('Fabric ID: ${fav['fabric_id']}'))).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
