import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';

final lowStockProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    final supabase = Supabase.instance.client;

    // Get fabrics with low stock (<= 5 yards)
    final response = await supabase
        .from('fabrics')
        .select('id, name, stock_quantity, image_urls, category')
        .eq('seller_id', user.id)
        .eq('is_visible', true)
        .lte('stock_quantity', 5)
        .order('stock_quantity');

    return (response as List)
        .map(
          (f) => {
            'id': f['id'],
            'name': f['name'],
            'stock': (f['stock_quantity'] as num?)?.toDouble() ?? 0,
            'image': (f['image_urls'] as List?)?.first,
            'category': f['category'] ?? '',
          },
        )
        .toList();
  } catch (e) {
    return [];
  }
});

class LowStockAlertsPage extends ConsumerWidget {
  const LowStockAlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final alertsAsync = ref.watch(lowStockProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'LOW STOCK ALERTS',
        foregroundColor: colors.textPrimary,
      ),
      body: alertsAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppColors.successGreen,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All stocked up!',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No fabrics with low stock',
                    style: TextStyle(color: colors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orangeAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${alerts.length} fabric${alerts.length == 1 ? '' : 's'} running low',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: alerts.length,
                  itemBuilder: (_, i) => _AlertCard(item: alerts[i]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load alerts')),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _AlertCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stock = item['stock'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? colors.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stock <= 2
              ? Colors.redAccent.withValues(alpha: 0.3)
              : Colors.orangeAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: colors.borderDefault,
              image: item['image'] != null
                  ? DecorationImage(
                      image: NetworkImage(item['image']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: item['image'] == null
                ? Icon(
                    Icons.inventory_2_outlined,
                    size: 20,
                    color: colors.textHint,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['category'] ?? '',
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
              ],
            ),
          ),
          // Stock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: stock <= 2
                  ? Colors.redAccent.withValues(alpha: 0.15)
                  : Colors.orangeAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${stock.toInt()} left',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: stock <= 2 ? Colors.redAccent : Colors.orangeAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
