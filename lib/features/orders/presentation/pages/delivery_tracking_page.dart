import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../providers/logistics_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class DeliveryTrackingPage extends ConsumerStatefulWidget {
  final String shipmentId;
  const DeliveryTrackingPage({super.key, required this.shipmentId});

  @override
  ConsumerState<DeliveryTrackingPage> createState() =>
      _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends ConsumerState<DeliveryTrackingPage> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasWaybill = widget.shipmentId.trim().isNotEmpty;
    final trackingAsync = hasWaybill
        ? ref.watch(trackDeliveryProvider(widget.shipmentId))
        : null;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(context, title: 'REAL-TIME TRACKING'),
      body: !hasWaybill
          ? Center(
              child: Text(
                'Tracking not available',
                style: TextStyle(color: colors.textMuted),
              ),
            )
          : trackingAsync!.when(
              data: (data) => _buildTrackingContent(data),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.amber),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Tracking not available. Pull down to retry.',
                  style: TextStyle(color: colors.textMuted),
                ),
              ),
            ),
    );
  }

  Widget _buildTrackingContent(Map<String, dynamic> data) {
    final colors = context.colors;
    final rawOrder = data['order'];
    final order = rawOrder is Map
        ? Map<String, dynamic>.from(rawOrder)
        : <String, dynamic>{};
    final rawNestedData = data['data'];
    final nestedData = rawNestedData is Map
        ? Map<String, dynamic>.from(rawNestedData)
        : <String, dynamic>{};
    final rawHistory =
        data['history'] ?? nestedData['history'] ?? nestedData['timeline'];
    final history = rawHistory is List ? rawHistory : <dynamic>[];
    final statusValue =
        data['status'] ??
        data['orderStatus'] ??
        order['orderStatus'] ??
        nestedData['orderStatus'] ??
        nestedData['status'];
    final status =
        statusValue?.toString().toUpperCase() ?? 'TRACKING NOT AVAILABLE';
    final etaValue =
        data['deliveryEta'] ??
        order['deliveryEta'] ??
        data['expectedArrival'] ??
        order['expectedArrival'] ??
        nestedData['deliveryEta'] ??
        nestedData['expectedArrival'];
    final eta = etaValue?.toString() ?? 'Not available';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. NEURAL MAP PLACEHOLDER
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.map_rounded,
                    color: AppColors.amber.withValues(alpha: 0.05),
                    size: 120,
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: colors.overlayHeavy,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.amber,
                          radius: 4,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Rider Status:',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          status,
                          style: TextStyle(
                            color: AppColors.amber,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 2. LOGISTICS SUMMARY
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoTile('Tracking Number', order['orderNo'] ?? 'N/A'),
              _buildInfoTile('Estimated Arrival', eta),
            ],
          ),
          const SizedBox(height: 32),

          // 3. TIMELINE (MOUTH-WATERING)
          const Text(
            'Delivery Updates',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ...history.map((h) => _buildTimelineItem(h)),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.toUpperCase(),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(dynamic h) {
    final colors = context.colors;
    final event = h is Map ? Map<String, dynamic>.from(h) : <String, dynamic>{};
    final status = event['orderStatus']?.toString().toUpperCase() ?? 'UPDATED';
    final desc = event['statusDescription'] ?? 'Being processed';
    final date =
        event['statusCreationDate']?.toString().split(' ').last ?? 'NOW';

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amber.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              Container(width: 1.5, height: 60, color: colors.divider),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        status,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        date,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
