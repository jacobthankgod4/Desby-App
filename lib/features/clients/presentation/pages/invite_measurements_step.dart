import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/theme/colors.dart';

import '../../../designs/presentation/pages/ai_body_scan_page.dart';
import '../../../orders/presentation/widgets/body_scan_picker_widget.dart';
import '../providers/invite_provider.dart';

class InviteMeasurementsStep extends ConsumerStatefulWidget {
  const InviteMeasurementsStep({super.key});

  @override
  ConsumerState<InviteMeasurementsStep> createState() =>
      _InviteMeasurementsStepState();
}

class _InviteMeasurementsStepState
    extends ConsumerState<InviteMeasurementsStep> {
  Map<String, dynamic>? _scanResults;
  bool _scanComplete = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final inviteState = ref.watch(inviteNotifierProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'BODY MEASUREMENTS',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select an existing scan or use AI to capture new measurements.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 32),

          BodyScanPickerWidget(
            onMeasurementsSelected: (measurements) {
              final converted = <String, dynamic>{};
              measurements.forEach((key, value) {
                converted[key] = value;
              });
              setState(() {
                _scanResults = converted;
                _scanComplete = true;
              });
            },
            onStartNewScan: () => _launchNewScan(),
          ),
          const SizedBox(height: 24),

          if (_scanComplete && _scanResults != null) ...[
            _buildScanSummary(_scanResults!),
            const SizedBox(height: 24),
          ],

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
                      foregroundColor: colors.textSecondary,
                      side: BorderSide(color: colors.borderSubtle),
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
                    onPressed: _scanComplete && !inviteState.isLoading
                        ? _submit
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.darkNavy,
                      disabledBackgroundColor: colors.borderSubtle,
                      disabledForegroundColor: colors.textMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: inviteState.isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: colors.textOnAmber,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'CONTINUE',
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

  Widget _buildScanSummary(Map<String, dynamic> results) {
    final colors = context.colors;
    final entries =
        results.entries.where((e) => !e.key.startsWith('_')).toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.successGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.successGreen,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                '${entries.length} MEASUREMENTS CAPTURED',
                style: const TextStyle(
                  color: AppColors.successGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: entries.take(12).map((e) {
              final value = e.value is num
                  ? '${(e.value as num).toStringAsFixed(1)}"'
                  : '${e.value}"';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceHover,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${e.key}: $value',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
          if (entries.length > 12)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+ ${entries.length - 12} more measurements',
                style: TextStyle(color: colors.textMuted, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _launchNewScan() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AiBodyScanPage(
          onMeasurementsReady: (measurements, gender, heightCm) {
            final converted = <String, dynamic>{};
            measurements.forEach((key, value) {
              converted[key] = value;
            });
            converted['Height'] = heightCm;
            converted['_gender'] = gender;
            setState(() {
              _scanResults = converted;
              _scanComplete = true;
            });
          },
        ),
      ),
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Body scan complete!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_scanComplete || _scanResults == null) return;

    final token = ref.read(inviteNotifierProvider).client?.inviteToken ?? '';
    await ref
        .read(inviteNotifierProvider.notifier)
        .updateMeasurements(token, _scanResults!);
  }
}
