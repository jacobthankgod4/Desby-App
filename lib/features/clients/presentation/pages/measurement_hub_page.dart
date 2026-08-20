import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/network/korra_client.dart';
import '../../../../core/services/body_measurement_service.dart';

class MeasurementHubPage extends ConsumerStatefulWidget {
  const MeasurementHubPage({super.key});

  @override
  ConsumerState<MeasurementHubPage> createState() => _MeasurementHubPageState();
}

class _MeasurementHubPageState extends ConsumerState<MeasurementHubPage> {
  final BodyMeasurementService _service = BodyMeasurementService();
  List<KorraMeasurementSummary> _korraScans = [];
  bool _isLoadingScans = false;
  bool _isKorraAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadKorraData();
  }

  Future<void> _loadKorraData() async {
    setState(() => _isLoadingScans = true);
    try {
      _isKorraAvailable = await _service.isAvailable;
      if (_isKorraAvailable) {
        _korraScans = await _service.listMeasurements();
      }
    } catch (e) {
      debugPrint('[MEASUREMENT_HUB] Failed to load Korra data: $e');
    }
    if (mounted) setState(() => _isLoadingScans = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = user != null
        ? ref.watch(userProfileProvider(user.id))
        : null;

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body:
          profileAsync?.when(
            data: (profile) => _buildModernContent(context, ref, profile),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.amber),
            ),
            error: (err, _) => Center(
              child: Text(
                'Dossier Sync Error: $err',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ) ??
          const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildModernContent(
    BuildContext context,
    WidgetRef ref,
    dynamic profile,
  ) {
    if (profile == null) return _buildNoProfileState(context, ref);

    final bool isVerified = profile.isMeasurementsVerified;
    final int metricCount = profile.personalMeasurements?.length ?? 0;
    final double readiness = (metricCount / 20).clamp(0.0, 1.0);
    final int korraScanCount = _korraScans.length;

    return RefreshIndicator(
      onRefresh: _loadKorraData,
      color: AppColors.amber,
      backgroundColor: AppColors.darkNavy,
      child: CustomScrollView(
        slivers: [
          // 1. SLEEK HUD HEADER
          SliverToBoxAdapter(
            child: Container(
              height: 220,
              padding: const EdgeInsets.fromLTRB(32, 60, 32, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.darkNavy,
                    AppColors.darkNavy.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'BODY MEASUREMENTS',
                        style: TextStyle(
                          color: AppColors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Capture your\nfit dimensions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildReadinessPill(
                        readiness,
                        isVerified,
                        korraScanCount,
                      ),
                    ],
                  ),
                  _buildCircularReadiness(readiness),
                ],
              ),
            ),
          ),

          // 2. KORRA STATUS BANNER
          if (_isLoadingScans)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: LinearProgressIndicator(color: AppColors.amber),
              ),
            ),

          // 3. MODERN BENTO GRID
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildListDelegate([
                _VisualBentoCard(
                  title: 'REMOTE BODY\nSCAN',
                  subtitle: _isKorraAvailable
                      ? '$korraScanCount scans on file'
                      : 'Connect to Korra AI',
                  imagePath: 'assets/images/onboarding screens4.png',
                  icon: Icons.biotech_rounded,
                  color: _isKorraAvailable ? Colors.blueAccent : Colors.white24,
                  isFullWidth: false,
                  onTap: () async {
                    ref.read(navigationStackProvider.notifier).push('/ai-body-scan');
                    _loadKorraData(); // Refresh after scan
                  },
                ),
                _VisualBentoCard(
                  title: 'VISIT A\nTAILOR',
                  subtitle: 'Professional session',
                  imagePath:
                      'assets/images/african-tailor-taking-measurements-client-255059921.webp',
                  icon: Icons.architecture_rounded,
                  color: AppColors.amber,
                  isFullWidth: false,
                  onTap: () => ref.pushShell('/tailor-discovery'),
                ),
              ]),
            ),
          ),

          // 4. SECONDARY ACTIONS (WIDE BENTO)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _VisualBentoCard(
                  title: '3D VIRTUAL FIT',
                  subtitle: 'See how clothes fit on your digital twin',
                  imagePath:
                      'assets/images/two-african-dressmaker-woman-designed-new-red-dress-mannequin-tailor-office-black-seamstress-girls_627829-4465.avif',
                  icon: Icons.accessibility_new_rounded,
                  color: Colors.purpleAccent,
                  isFullWidth: true,
                  onTap: () =>
                      ref.pushShell('/measurements-input'),
                ),
                const SizedBox(height: 16),
                _VisualBentoCard(
                  title: 'MANUAL ENTRY',
                  subtitle: 'Enter your measurements yourself',
                  imagePath: 'assets/images/onboarding image3.png',
                  icon: Icons.edit_note_rounded,
                  color: Colors.white24,
                  isFullWidth: true,
                  onTap: () =>
                      ref.pushShell('/measurements-profile'),
                ),
              ]),
            ),
          ),

          // 5. QUICK ESTIMATE CARD
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildQuickEstimateCard(context),
              ]),
            ),
          ),

          // 6. FIT ARCHETYPE SECTION
          _buildSectionHeader('FITTING STYLE'),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildModernArchetypeCard(
                    'SLIM FIT',
                    'Contoured to body',
                    Icons.bolt_rounded,
                  ),
                  _buildModernArchetypeCard(
                    'STANDARD',
                    'Classic fit',
                    Icons.business_center_rounded,
                  ),
                  _buildModernArchetypeCard(
                    'RELAXED',
                    'Comfortable volume',
                    Icons.auto_awesome_mosaic_rounded,
                  ),
                ],
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }

  Widget _buildReadinessPill(
    double progress,
    bool isVerified,
    int korraScanCount,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isVerified
                ? const Color(0xFF00FF7F).withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isVerified
                  ? const Color(0xFF00FF7F).withValues(alpha: 0.3)
                  : Colors.white10,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isVerified ? Icons.verified_rounded : Icons.sync_rounded,
                color: isVerified ? const Color(0xFF00FF7F) : Colors.white38,
                size: 12,
              ),
              const SizedBox(width: 8),
              Text(
                isVerified ? 'VERIFIED' : '${(progress * 100).toInt()}% SYNCED',
                style: TextStyle(
                  color: isVerified ? const Color(0xFF00FF7F) : Colors.white60,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        if (korraScanCount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.biotech_rounded,
                  color: AppColors.amber,
                  size: 12,
                ),
                const SizedBox(width: 6),
                Text(
                  '$korraScanCount AI SCANS',
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickEstimateCard(BuildContext context) {
    return GestureDetector(
      onTap: () => ref.pushShell('/ai-body-scan'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purpleAccent.withValues(alpha: 0.1),
              Colors.blueAccent.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.height_rounded,
                color: Colors.purpleAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'QUICK ESTIMATE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get measurements from height only — no photos needed',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularReadiness(double progress) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.amber),
          ),
        ),
        Text(
          '${(progress * 100).toInt()}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.amber,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildModernArchetypeCard(String title, String desc, IconData icon) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.amber.withValues(alpha: 0.5), size: 20),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
          Text(
            desc,
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProfileState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_sync_rounded, size: 64, color: Colors.white10),
          const SizedBox(height: 24),
          const Text(
            'SYNCING DOSSIER...',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () {
              final user = ref.read(currentUserProvider);
              if (user != null) ref.invalidate(userProfileProvider(user.id));
            },
            child: const Text(
              'RETRY',
              style: TextStyle(
                color: AppColors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualBentoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final IconData icon;
  final Color color;
  final bool isFullWidth;
  final VoidCallback onTap;

  const _VisualBentoCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.icon,
    required this.color,
    required this.isFullWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: isFullWidth ? 140 : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.black),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.9),
                        Colors.black.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: Icon(
                  Icons.north_east_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
