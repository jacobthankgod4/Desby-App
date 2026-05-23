import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../providers/logistics_provider.dart';

class DeliveryTrackingPage extends ConsumerStatefulWidget {
  final String fezOrderNo;
  const DeliveryTrackingPage({super.key, required this.fezOrderNo});

  @override
  ConsumerState<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends ConsumerState<DeliveryTrackingPage> {
  @override
  Widget build(BuildContext context) {
    final trackingAsync = ref.watch(trackDeliveryProvider(widget.fezOrderNo));

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text('REAL-TIME TRACKING', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: trackingAsync.when(
        data: (data) => _buildTrackingContent(data),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
        error: (err, _) => Center(child: Text('Tracking data offline: $err', style: const TextStyle(color: Colors.white38))),
      ),
    );
  }

  Widget _buildTrackingContent(Map<String, dynamic> data) {
    final order = data['order'] as Map<String, dynamic>;
    final history = data['history'] as List<dynamic>;
    final status = order['orderStatus']?.toString().toUpperCase() ?? 'IN TRANSIT';

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
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
            ),
            child: Stack(
              children: [
                Center(child: Icon(Icons.map_rounded, color: AppColors.amber.withValues(alpha: 0.05), size: 120)),
                Positioned(
                  bottom: 24, left: 24, right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(backgroundColor: AppColors.amber, radius: 4, ),
                        const SizedBox(width: 12),
                        Text('Rider Status:'.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900)),
                        const Spacer(),
                        Text(status, style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 11)),
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
              _buildInfoTile('WAYBILL', order['orderNo'] ?? 'N/A'),
              _buildInfoTile('EST. ARRIVAL', '20-30 MINS'), // Mock for now
            ],
          ),
          const SizedBox(height: 32),

          // 3. TIMELINE (MOUTH-WATERING)
          const Text('DELIVERY TIMELINE', style: TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 24),
          ...history.map((h) => _buildTimelineItem(h)),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(value.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      ],
    );
  }

  Widget _buildTimelineItem(dynamic h) {
    final status = h['orderStatus']?.toString().toUpperCase() ?? 'UPDATED';
    final desc = h['statusDescription'] ?? 'Processing through network hub.';
    final date = h['statusCreationDate']?.toString().split(' ').last ?? 'NOW';

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  color: AppColors.amber, 
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.amber.withValues(alpha: 0.3), blurRadius: 10)
                  ]
                ),
              ),
              Container(width: 1.5, height: 60, color: Colors.white12),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                      Text(date, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
