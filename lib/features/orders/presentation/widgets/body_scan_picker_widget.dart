import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/korra_client.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/services/body_measurement_service.dart';
import '../../../../theme/colors.dart';

/// A card that lets users pick from existing body scans or start a new one.
///
/// Behaviours:
/// - 0 scans → shows "Start Body Scan" CTA
/// - 1 scan → auto-selects it, shows summary with option to rescan
/// - multiple scans → radio list to select, plus "Start New Scan"
///
/// Returns selected measurements via [onMeasurementsSelected].
class BodyScanPickerWidget extends ConsumerStatefulWidget {
  /// Called when measurements are selected (from existing or new scan).
  final void Function(Map<String, double> measurements) onMeasurementsSelected;

  /// Called when user navigates to start a new scan.
  final VoidCallback? onStartNewScan;

  const BodyScanPickerWidget({
    super.key,
    required this.onMeasurementsSelected,
    this.onStartNewScan,
  });

  @override
  ConsumerState<BodyScanPickerWidget> createState() =>
      _BodyScanPickerWidgetState();
}

class _BodyScanPickerWidgetState extends ConsumerState<BodyScanPickerWidget> {
  List<KorraMeasurementSummary> _scans = [];
  bool _isLoading = true;
  String? _error;
  KorraMeasurementSummary? _selectedScan;
  Map<String, double>? _selectedMeasurements;

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = BodyMeasurementService();
      final scans = await service.listMeasurements();
      if (!mounted) return;
      setState(() {
        _scans = scans;
        _isLoading = false;
      });
      // Auto-select if exactly 1 scan
      if (scans.length == 1) {
        _selectScan(scans.first);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load scans';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectScan(KorraMeasurementSummary scan) async {
    setState(() {
      _selectedScan = scan;
      _selectedMeasurements = null;
    });
    try {
      final service = BodyMeasurementService();
      final detail = await service.getMeasurement(scan.id);
      if (detail != null && detail.measurements != null && mounted) {
        setState(() => _selectedMeasurements = detail.measurements);
        widget.onMeasurementsSelected(detail.measurements!);
      }
    } catch (e) {
      debugPrint('[SCAN-PICKER] Failed to load scan detail: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          if (_isLoading)
            _buildLoading()
          else if (_error != null)
            _buildError()
          else if (_scans.isEmpty)
            _buildEmptyState()
          else ...[
            if (_scans.length > 1) _buildScanList(),
            if (_selectedScan != null && _selectedMeasurements != null)
              _buildSelectedSummary(),
            const SizedBox(height: 12),
            _buildRescanButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.accessibility_new_rounded,
          color: AppColors.amber,
          size: 18,
        ),
        const SizedBox(width: 10),
        const Text(
          'BODY MEASUREMENTS',
          style: TextStyle(
            color: AppColors.amber,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        if (_selectedMeasurements != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.098),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 12),
                SizedBox(width: 4),
                Text(
                  'ATTACHED',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLoading() {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Loading your scans...',
          style: TextStyle(color: context.colors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Text(
      _error!,
      style: TextStyle(color: context.colors.statusError, fontSize: 12),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Icon(
          Icons.photo_camera_back_rounded,
          color: context.colors.textMuted,
          size: 32,
        ),
        const SizedBox(height: 12),
        Text(
          'No body scans yet',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Start a body scan to attach accurate measurements to your order.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        _buildStartScanButton(),
      ],
    );
  }

  Widget _buildScanList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select a scan (${_scans.length} available)',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ..._scans.map((scan) {
          final isSelected = _selectedScan?.id == scan.id;
          final date = scan.createdAt;
          final dateStr = date != null
              ? '${date.day}/${date.month}/${date.year}'
              : 'Unknown date';
          return GestureDetector(
            onTap: () => _selectScan(scan),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.amber.withValues(alpha: 0.098)
                    : context.colors.surfaceHover,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.amber.withValues(alpha: 0.5)
                      : context.colors.borderSubtle,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.amber.withValues(alpha: 0.15)
                          : context.colors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      scan.gender == 'female' ? Icons.female : Icons.male,
                      color: isSelected
                          ? AppColors.amber
                          : context.colors.textMuted,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${scan.gender ?? "Unknown"} • ${scan.heightCm?.toInt() ?? "?"}cm',
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${scan.measurementCount ?? "?"} measurements • $dateStr',
                          style: TextStyle(
                            color: context.colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.amber,
                      size: 20,
                    )
                  else
                    Icon(
                      Icons.radio_button_unchecked,
                      color: context.colors.textMuted,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSelectedSummary() {
    final entries = _selectedMeasurements!.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          '${_selectedMeasurements!.length} measurements attached',
          style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: entries
              .take(6)
              .map(
                (e) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${e.key}: ${e.value.toStringAsFixed(1)}cm',
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        if (entries.length > 6)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '+${entries.length - 6} more',
              style: TextStyle(color: context.colors.textMuted, fontSize: 10),
            ),
          ),
      ],
    );
  }

  Widget _buildStartScanButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.selectionClick();
          if (widget.onStartNewScan != null) {
            widget.onStartNewScan!();
          } else {
            ref.read(navigationStackProvider.notifier).push('/ai-body-scan');
          }
        },
        icon: const Icon(Icons.camera_alt_rounded, size: 18),
        label: const Text(
          'START BODY SCAN',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            fontSize: 12,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.darkNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildRescanButton() {
    return TextButton.icon(
      onPressed: () {
        HapticFeedback.selectionClick();
        if (widget.onStartNewScan != null) {
          widget.onStartNewScan!();
        } else {
          ref.read(navigationStackProvider.notifier).push('/ai-body-scan');
        }
      },
      icon: Icon(
        Icons.refresh_rounded,
        size: 16,
        color: context.colors.textMuted,
      ),
      label: Text(
        _scans.isEmpty ? 'Start Body Scan' : 'Start a new scan',
        style: TextStyle(color: context.colors.textMuted, fontSize: 12),
      ),
    );
  }
}
