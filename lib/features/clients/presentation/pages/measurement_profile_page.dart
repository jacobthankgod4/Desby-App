import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/theme/colors.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/layout_provider.dart';
import '../../../../core/services/body_measurement_service.dart';
import '../../../../core/network/korra_client.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class MeasurementProfilePage extends ConsumerStatefulWidget {
  const MeasurementProfilePage({super.key});

  @override
  ConsumerState<MeasurementProfilePage> createState() =>
      _MeasurementProfilePageState();
}

class _MeasurementProfilePageState
    extends ConsumerState<MeasurementProfilePage> {
  final BodyMeasurementService _service = BodyMeasurementService();
  List<KorraMeasurementSummary> _scans = [];
  bool _loading = true;
  KorraMeasurementSummary? _latestScan;
  Map<String, double>? _latestMeasurements;

  static const Map<String, String> _labels = {
    'neck': 'Neck',
    'shoulder': 'Shoulder',
    'chest': 'Chest',
    'waist': 'Waist',
    'hip': 'Hip',
    'inseam': 'Inseam',
    'outseam': 'Outseam',
    'thigh': 'Thigh',
    'bicep': 'Bicep',
    'wrist': 'Wrist',
    'bust': 'Bust',
    'underbust': 'Underbust',
    'arm_length': 'Arm Length',
    'torso': 'Torso',
    'shoulder_width': 'Shoulder Width',
    'back_width': 'Back Width',
  };

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    setState(() => _loading = true);
    try {
      _scans = await _service.listMeasurements();
      if (_scans.isNotEmpty) {
        _latestScan = _scans.first;
        final detail = await _service.getMeasurement(_latestScan!.id);
        if (detail != null && detail.measurements != null) {
          _latestMeasurements = detail.measurements;
        }
      }
    } catch (e) {
      debugPrint('[MEASUREMENTS] Failed to load scans: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDesktop = ref.watch(isDesktopProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: colors.scaffoldBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 60,
            // Inside the shell the header already owns the back control, and
            // `shellLeading` returns null there. Without this, AppBar adds its
            // own implied back arrow on top and the page renders two.
            automaticallyImplyLeading: false,
            leading: shellLeading(context),
            title: shellTitle(context, 'MY MEASUREMENTS'),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: colors.textSecondary,
                  size: 20,
                ),
                onPressed: _loadScans,
              ),
            ],
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.amber),
              ),
            )
          else if (_latestMeasurements == null || _latestScan == null)
            SliverFillRemaining(child: _buildEmptyState(isDesktop))
          else
            SliverToBoxAdapter(child: _buildResults(isDesktop)),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  /// Scan entry for the merged measurements + AI Body Scan page.
  ///
  /// The saved measurements list lives below this. The standalone
  /// `/ai-body-scan` route stays registered for deep links, so this only
  /// provides the entry point from the merged page.
  Widget _buildEmptyState(bool isDesktop) {
    final colors = context.colors;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amber.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.2),
                ),
              ),
              child: const Icon(
                Icons.accessibility_new_rounded,
                color: AppColors.amber,
                size: 44,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'NO BODY SCANS YET',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete your first AI body scan to see accurate measurements here. The scan takes less than 2 minutes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () => ref.pushShell('/ai-body-scan'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      color: context.colors.textOnAmber,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'START BODY SCAN',
                      style: TextStyle(
                        color: context.colors.textOnAmber,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(bool isDesktop) {
    final colors = context.colors;
    final scan = _latestScan!;
    final measurements = _latestMeasurements!;
    final entries = measurements.entries.toList();

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: isDesktop ? 900 : 600),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40 : 20,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScanInfoCard(scan),
            const SizedBox(height: 28),

            _buildQuickStats(scan),
            const SizedBox(height: 28),

            GestureDetector(
              onTap: () => ref.pushShell('/ai-body-scan'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.3),
                  ),
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.amber,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'NEW BODY SCAN',
                      style: TextStyle(
                        color: AppColors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            Row(
              children: [
                Text(
                  'MEASUREMENTS',
                  style: TextStyle(
                    color: AppColors.amber.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(height: 1, color: colors.surfaceHover),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (isDesktop)
              _buildDesktopGrid(entries)
            else
              _buildMobileList(entries),

            const SizedBox(height: 32),

            if (_scans.length > 1) ...[
              Row(
                children: [
                  Text(
                    'SCAN HISTORY',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(height: 1, color: colors.surfaceHover),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._scans.skip(1).take(5).map((s) => _buildHistoryItem(s)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScanInfoCard(KorraMeasurementSummary scan) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              scan.gender == 'female'
                  ? Icons.female_rounded
                  : Icons.male_rounded,
              color: AppColors.amber,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LATEST BODY SCAN',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${scan.gender != null ? (scan.gender == 'female' ? 'Female' : 'Male') : 'Unknown'}  •  ${scan.heightCm?.toInt() ?? "?"} cm  •  ${scan.measurementCount ?? "?"} measurements',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                if (scan.createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Scanned ${scan.createdAt!.day}/${scan.createdAt!.month}/${scan.createdAt!.year}',
                    style: TextStyle(color: colors.textMuted, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'ACCURATE',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(KorraMeasurementSummary scan) {
    final colors = context.colors;
    final stats = [
      ('${scan.measurementCount ?? 0}', 'Measurements'),
      ('${scan.heightCm?.toInt() ?? 0} cm', 'Height'),
      (scan.accuracyMode ?? 'dual', 'Mode'),
    ];
    return Row(
      children: stats
          .map(
            (s) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.surfaceHover),
                ),
                child: Column(
                  children: [
                    Text(
                      s.$1,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.$2,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDesktopGrid(List<MapEntry<String, double>> entries) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.8,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) => _buildMeasurementTile(entries[index]),
    );
  }

  Widget _buildMobileList(List<MapEntry<String, double>> entries) {
    return Column(
      children: entries
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildMeasurementTile(e),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMeasurementTile(MapEntry<String, double> entry) {
    final colors = context.colors;
    final label = _labels[entry.key] ?? entry.key.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.amber,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Text(
            '${entry.value.toStringAsFixed(1)} cm',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(KorraMeasurementSummary scan) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              scan.gender == 'female'
                  ? Icons.female_rounded
                  : Icons.male_rounded,
              color: AppColors.amber,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${scan.gender != null ? (scan.gender == 'female' ? 'Female' : 'Male') : 'Unknown'}  •  ${scan.heightCm?.toInt() ?? "?"} cm',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${scan.measurementCount ?? "?"} measurements  •  ${scan.accuracyMode ?? "dual"}',
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (scan.createdAt != null)
            Text(
              '${scan.createdAt!.day}/${scan.createdAt!.month}/${scan.createdAt!.year}',
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
        ],
      ),
    );
  }
}
