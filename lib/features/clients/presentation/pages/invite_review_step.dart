import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/theme/colors.dart';

import '../providers/invite_provider.dart';

class InviteReviewStep extends ConsumerWidget {
  const InviteReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inviteState = ref.watch(inviteNotifierProvider);
    final client = inviteState.client;
    final orderDetails = inviteState.orderDetails;
    final measurements = client?.measurements;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'REVIEW & SUBMIT',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Verify all details before submitting.',
            style: TextStyle(color: context.colors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 32),

          _buildReviewCard('PROFILE', {
            'NAME': client?.name ?? '-',
            'PHONE': client?.phone ?? '-',
            'EMAIL': client?.email ?? '-',
            'GENDER': client?.gender ?? '-',
            'ADDRESS': client?.address ?? '-',
          }, context),
          const SizedBox(height: 16),

          if (orderDetails != null) _buildOrderCard(orderDetails, context),
          const SizedBox(height: 16),

          if (measurements != null && measurements.isNotEmpty)
            _buildMeasurementsCard(measurements, context),

          const SizedBox(height: 32),

          if (inviteState.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                inviteState.error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(inviteNotifierProvider.notifier)
                        .previousStep(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.textSecondary,
                      side: BorderSide(color: context.colors.borderSubtle),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'BACK',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: inviteState.isLoading
                        ? null
                        : () async {
                            final token = client?.inviteToken ?? '';
                            await ref
                                .read(inviteNotifierProvider.notifier)
                                .completeInvite(token);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: context.colors.borderSubtle,
                      disabledForegroundColor: context.colors.textMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: inviteState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'SUBMIT ORDER',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    String title,
    Map<String, String> data,
    BuildContext buildContext,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: buildContext.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: buildContext.colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.amber,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...data.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.key,
                    style: TextStyle(
                      color: buildContext.colors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      e.value.toUpperCase(),
                      style: TextStyle(
                        color: buildContext.colors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.end,
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

  Widget _buildOrderCard(
    Map<String, dynamic> orderDetails,
    BuildContext context,
  ) {
    final garmentType = orderDetails['garment_type'] as String? ?? '-';
    final dueDateStr = orderDetails['due_date'] as String?;
    final fabric = orderDetails['fabric_type'] as String? ?? '-';
    final color = orderDetails['fabric_color'] as String? ?? '-';
    final hasPhoto = orderDetails['material_photo_url'] != null;

    String dueDate = '-';
    if (dueDateStr != null) {
      final dt = DateTime.tryParse(dueDateStr);
      if (dt != null) {
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        dueDate = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ORDER',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              if (hasPhoto)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PHOTO ATTACHED',
                    style: TextStyle(
                      color: AppColors.successGreen,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOrderRow('GARMENT', garmentType, context),
          _buildOrderRow('DUE DATE', dueDate, context),
          _buildOrderRow('FABRIC', fabric, context),
          _buildOrderRow('COLOR', color, context),
        ],
      ),
    );
  }

  Widget _buildOrderRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          Flexible(
            child: Text(
              value.toUpperCase(),
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsCard(
    Map<String, String> measurements,
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MEASUREMENTS',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: measurements.entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surfaceHover,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${e.key}: ${e.value}"',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
