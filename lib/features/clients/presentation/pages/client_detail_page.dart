import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/client_provider.dart';
import '../widgets/mannequin_status.dart';
import '../widgets/client_order_history.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../domain/entities/client.dart';

class ClientDetailPage extends ConsumerWidget {
  final String clientId;
  const ClientDetailPage({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientDetailProvider(clientId));
    final ordersAsync = ref.watch(clientOrdersProvider(clientId));

    return Scaffold(
      backgroundColor: const Color(0xFF0A1921),
      appBar: AppBar(
        title: const Text('CLIENT DOSSIER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white38),
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
              _buildIdentityHeader(client),
              const SizedBox(height: 32),
              
              MannequinStatus(
                gender: client.gender,
                measurements: client.measurements,
              ),
              
              const SizedBox(height: 32),
              _buildLogisticsSection(client),
              
              const SizedBox(height: 32),
              _buildMeasurementLedger(client),
              
              const SizedBox(height: 32),
              ordersAsync.when(
                data: (orders) => ClientOrderHistory(orders: orders),
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (e, _) => const Text('History Sync Error', style: TextStyle(color: Colors.red, fontSize: 10)),
              ),
              
              const SizedBox(height: 60),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
        error: (err, _) => const ErrorStateWidget(message: 'Failed to sync profile.'),
      ),
    );
  }

  Widget _buildIdentityHeader(Client client) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.3), width: 2),
            image: client.profileImage != null
                ? DecorationImage(image: NetworkImage(client.profileImage!), fit: BoxFit.cover)
                : null,
          ),
          child: client.profileImage == null
              ? Center(child: Text(client.name[0].toUpperCase(), style: const TextStyle(fontSize: 32, color: AppColors.amber, fontWeight: FontWeight.w900)))
              : null,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                client.name.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      client.gender.toUpperCase(),
                      style: const TextStyle(color: AppColors.amber, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.verified_user_rounded, color: Colors.blueAccent, size: 14),
                  const SizedBox(width: 4),
                  const Text('VIP CLIENT', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogisticsSection(Client client) {
    return LuxuryGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LOGISTICS & CORRESPONDENCE', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.location_on_outlined, 'PRIMARY ADDRESS', client.address),
          _buildInfoRow(Icons.phone_outlined, 'DIRECT LINE', client.phone),
          _buildInfoRow(Icons.email_outlined, 'ENCRYPTED EMAIL', client.email),
        ],
      ),
    );
  }

  Widget _buildMeasurementLedger(Client client) {
    final Map<String, String> metrics = client.measurements ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('PRECISION MEASUREMENT RECORD', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
            GestureDetector(
              onTap: () {},
              child: const Text('VIEW ALL', style: TextStyle(color: AppColors.amber, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
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
            return _buildMetricTile(key, value);
          },
        ),
        if (metrics.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('NO MEASUREMENTS RECORDED', style: TextStyle(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? 'N/A' : '$value IN',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
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
                Text(label, style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
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
