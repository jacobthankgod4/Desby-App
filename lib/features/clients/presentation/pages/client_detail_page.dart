import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../providers/client_provider.dart';
import '../widgets/mannequin_status.dart';
import '../widgets/client_order_history.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../domain/entities/client.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class ClientDetailPage extends ConsumerWidget {
  final String clientId;
  const ClientDetailPage({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientDetailProvider(clientId));
    final ordersAsync = ref.watch(clientOrdersProvider(clientId));

    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'CLIENT DOSSIER',
        actions: [
          IconButton(
            icon: Icon(Icons.edit_note_rounded, color: colors.textMuted),
            onPressed: () {},
          ),
        ],
      ),
      body: clientAsync.when(
        data: (client) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildIdentityHeader(client, context),
              const SizedBox(height: 32),

              MannequinStatus(
                gender: client.gender,
                measurements: client.measurements,
              ),

              const SizedBox(height: 32),
              _buildLogisticsSection(client, context),

              const SizedBox(height: 32),
              _buildMeasurementLedger(context, client),

              const SizedBox(height: 32),
              ordersAsync.when(
                data: (orders) => ClientOrderHistory(orders: orders),
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (e, _) => const Text(
                  'History Sync Error',
                  style: TextStyle(color: Colors.red, fontSize: 10),
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (err, _) =>
            const ErrorStateWidget(message: 'Failed to sync profile.'),
      ),
    );
  }

  Widget _buildIdentityHeader(Client client, BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.amber.withValues(alpha: 0.3),
              width: 2,
            ),
            image: client.profileImage != null
                ? DecorationImage(
                    image: NetworkImage(client.profileImage!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: client.profileImage == null
              ? Center(
                  child: Text(
                    client.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      color: AppColors.amber,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                client.name.toUpperCase(),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      client.gender.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.amber,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.info,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'VIP CLIENT',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogisticsSection(Client client, BuildContext context) {
    final colors = context.colors;
    return LuxuryGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LOGISTICS & CORRESPONDENCE',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            Icons.location_on_outlined,
            'PRIMARY ADDRESS',
            client.address,
            context,
          ),
          _buildInfoRow(
            Icons.phone_outlined,
            'DIRECT LINE',
            client.phone,
            context,
          ),
          _buildInfoRow(
            Icons.email_outlined,
            'ENCRYPTED EMAIL',
            client.email,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementLedger(BuildContext context, Client client) {
    final colors = context.colors;
    final Map<String, String> metrics = client.measurements ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PRECISION MEASUREMENT RECORD',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            GestureDetector(
              onTap: () {
                final nav = ProviderScope.containerOf(
                  context,
                ).read(navigationStackProvider.notifier);
                nav.set('/orders');
              },
              child: const Text(
                'VIEW ALL',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: metrics.length > 4 ? 4 : metrics.length,
          itemBuilder: (context, index) {
            final key = metrics.keys.elementAt(index);
            final value = metrics.values.elementAt(index);
            return _buildMetricTile(context, key, value);
          },
        ),
        if (metrics.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'NO MEASUREMENTS RECORDED',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMetricTile(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? 'N/A' : '$value IN',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'Monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    BuildContext context,
  ) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.amber, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
