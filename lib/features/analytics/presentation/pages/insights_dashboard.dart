import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/analytics_service_impl.dart';

class InsightsDashboard extends ConsumerStatefulWidget {
  const InsightsDashboard({super.key});

  @override
  ConsumerState<InsightsDashboard> createState() => _InsightsDashboardState();
}

class _InsightsDashboardState extends ConsumerState<InsightsDashboard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _chartController;
  late AnimationController _pulseController;

  bool _isLoading = true;
  bool _isRefreshing = false;

  Map<String, dynamic> _insights = {};
  List<Map<String, dynamic>> _monthlyRevenue = [];
  Map<String, int> _categoryDistribution = {};

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _chartController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final service = AnalyticsServiceImpl();
      final results = await Future.wait([
        service.getBusinessInsights(user.id),
        service.getMonthlyRevenue(user.id),
        service.getOrderCategoryDistribution(user.id),
      ]);
      if (!mounted) return;
      setState(() {
        _insights = results[0] as Map<String, dynamic>;
        _monthlyRevenue = results[1] as List<Map<String, dynamic>>;
        _categoryDistribution = results[2] as Map<String, int>;
        _isLoading = false;
      });
      _fadeController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _chartController.forward(from: 0);
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadData();
    if (mounted) setState(() => _isRefreshing = false);
  }

  String _formatCompactCurrency(double value) {
    if (value >= 1000000) {
      return '₦${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '₦${(value / 1000).toStringAsFixed(1)}k';
    }
    return '₦${value.toStringAsFixed(0)}';
  }

  String _formatFullCurrency(double value) {
    final text = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      if (remaining > 1 && (remaining - 1) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return '₦$buffer';
  }

  double get _completionRate {
    final total = (_insights['totalOrders'] as num?)?.toDouble() ?? 0;
    final completed = (_insights['completedOrders'] as num?)?.toDouble() ?? 0;
    if (total == 0) return 0;
    return (completed / total) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.amber,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'BUSINESS INTELLIGENCE',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.amber,
            ),
            onPressed: () => ref.pushShell('/ai-insights'),
          ),
          IconButton(
            icon: const Icon(Icons.description_outlined, color: Colors.white38),
            onPressed: () => ref.pushShell('/reports'),
          ),
        ],
      ),
      body: _isLoading && !_isRefreshing
          ? _buildShimmerLoading()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.amber,
      backgroundColor: AppColors.deepBlue,
      child: FadeTransition(
        opacity: _fadeController,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 28),
              _buildQuickStatPills(),
              const SizedBox(height: 32),
              _buildKeyMetricsGrid(),
              const SizedBox(height: 32),
              _buildRevenueChartSection(),
              const SizedBox(height: 32),
              _buildOrderCategoriesSection(),
              const SizedBox(height: 32),
              _buildQuickActionsSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BUSINESS INTELLIGENCE',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Real-time analytics for your bespoke empire.',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatPills() {
    final totalOrders = (_insights['totalOrders'] as num?)?.toInt() ?? 0;
    final totalClients = (_insights['totalClients'] as num?)?.toInt() ?? 0;
    final totalRevenue = (_insights['totalRevenue'] as num?)?.toDouble() ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatPill(
            icon: Icons.shopping_bag_outlined,
            value: '$totalOrders',
            label: 'Orders',
            color: AppColors.amber,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatPill(
            icon: Icons.people_outline_rounded,
            value: '$totalClients',
            label: 'Clients',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatPill(
            icon: Icons.account_balance_wallet_outlined,
            value: _formatCompactCurrency(totalRevenue),
            label: 'Revenue',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsGrid() {
    final totalRevenue = (_insights['totalRevenue'] as num?)?.toDouble() ?? 0;
    final totalOrders = (_insights['totalOrders'] as num?)?.toInt() ?? 0;
    final totalClients = (_insights['totalClients'] as num?)?.toInt() ?? 0;
    final completionRate = _completionRate;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.35,
      children: [
        _buildMetricCard(
          icon: Icons.payments_rounded,
          value: _formatFullCurrency(totalRevenue),
          label: 'Total Revenue',
          trendPercent: 12.5,
          isUp: true,
          accentColor: AppColors.success,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.success.withValues(alpha: 0.12),
              AppColors.success.withValues(alpha: 0.03),
            ],
          ),
        ),
        _buildMetricCard(
          icon: Icons.shopping_cart_rounded,
          value: '$totalOrders',
          label: 'Total Orders',
          trendPercent: 8.3,
          isUp: true,
          accentColor: AppColors.amber,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.amber.withValues(alpha: 0.12),
              AppColors.amber.withValues(alpha: 0.03),
            ],
          ),
        ),
        _buildMetricCard(
          icon: Icons.group_rounded,
          value: '$totalClients',
          label: 'Active Clients',
          trendPercent: 5.7,
          isUp: true,
          accentColor: AppColors.info,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.info.withValues(alpha: 0.12),
              AppColors.info.withValues(alpha: 0.03),
            ],
          ),
        ),
        _buildMetricCard(
          icon: Icons.check_circle_rounded,
          value: '${completionRate.toStringAsFixed(0)}%',
          label: 'Completion Rate',
          trendPercent: 3.2,
          isUp: true,
          accentColor: const Color(0xFF9C27B0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF9C27B0).withValues(alpha: 0.12),
              const Color(0xFF9C27B0).withValues(alpha: 0.03),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required double trendPercent,
    required bool isUp,
    required Color accentColor,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isUp
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUp
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 10,
                      color: isUp ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${trendPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isUp ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.38),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChartSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.amber,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'MONTHLY REVENUE',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              if (_monthlyRevenue.isNotEmpty)
                Text(
                  _formatCompactCurrency(
                    _monthlyRevenue.last['revenue'] as double? ?? 0,
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (_monthlyRevenue.isEmpty)
            _buildEmptyChartState()
          else
            SizedBox(
              height: 200,
              child: AnimatedBuilder(
                animation: _chartController,
                builder: (context, _) => CustomPaint(
                  size: const Size(double.infinity, 200),
                  painter: _RevenueChartPainter(
                    monthlyRevenue: _monthlyRevenue,
                    animation: _chartController.value,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyChartState() {
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 12),
            Text(
              'No revenue data yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start completing orders to see trends',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.15),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCategoriesSection() {
    final totalItems = _categoryDistribution.values.fold<int>(
      0,
      (sum, v) => sum + v,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('GARMENT DISTRIBUTION'),
          const SizedBox(height: 24),
          if (_categoryDistribution.isEmpty)
            _buildEmptyDistributionState()
          else
            AnimatedBuilder(
              animation: _chartController,
              builder: (context, _) => CustomPaint(
                size: Size(
                  double.infinity,
                  (_categoryDistribution.length * 56.0) + 8,
                ),
                painter: _BarChartPainter(
                  distribution: _categoryDistribution,
                  totalItems: totalItems,
                  animation: _chartController.value,
                  barColor: AppColors.amber,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyDistributionState() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 12),
            Text(
              'No category data yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add garments to see distribution',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.15),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('QUICK ACTIONS'),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.auto_awesome_rounded,
                label: 'AI Insights',
                route: '/ai-insights',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.assessment_rounded,
                label: 'Reports',
                route: '/reports',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_rounded,
                label: 'New Order',
                route: '/order-create',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String route,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.setShell(route);
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final glow = _pulseController.value * 0.04;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.06 + glow),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.amber.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.amber, size: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.amber,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.amber,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBlock(height: 36, width: 260, radius: 12),
          const SizedBox(height: 8),
          _shimmerBlock(height: 16, width: 200, radius: 8),
          const SizedBox(height: 28),
          Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                  child: _shimmerBlock(height: 68, radius: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.35,
            children: List.generate(4, (_) => _shimmerBlock(radius: 22)),
          ),
          const SizedBox(height: 32),
          _shimmerBlock(height: 260, radius: 28),
          const SizedBox(height: 32),
          _shimmerBlock(height: 220, radius: 28),
          const SizedBox(height: 32),
          _shimmerBlock(height: 140, radius: 18),
        ],
      ),
    );
  }

  Widget _shimmerBlock({double? height, double? width, double radius = 14}) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final opacity = 0.04 + (_pulseController.value * 0.03);
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      },
    );
  }
}

class _RevenueChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> monthlyRevenue;
  final double animation;

  _RevenueChartPainter({required this.monthlyRevenue, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    if (monthlyRevenue.isEmpty) return;

    final revenues = monthlyRevenue
        .map((e) => (e['revenue'] as num?)?.toDouble() ?? 0)
        .toList();
    final maxRevenue = revenues.reduce(max);
    if (maxRevenue == 0) return;

    const padding = EdgeInsets.fromLTRB(52, 20, 20, 36);
    final chartWidth = size.width - padding.left - padding.right;
    final chartHeight = size.height - padding.top - padding.bottom;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    final labelStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.35),
      fontSize: 9,
      fontWeight: FontWeight.w700,
    );

    const gridSteps = 4;
    for (int i = 0; i <= gridSteps; i++) {
      final y = padding.top + (chartHeight / gridSteps) * i;
      canvas.drawLine(
        Offset(padding.left, y),
        Offset(size.width - padding.right, y),
        gridPaint,
      );
      final rev = maxRevenue - (maxRevenue / gridSteps) * i;
      final formatted = _formatCompact(rev);
      final tp = TextPainter(
        text: TextSpan(text: formatted, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padding.left - tp.width - 8, y - tp.height / 2));
    }

    final count = revenues.length;
    final stepWidth = chartWidth / (count > 1 ? count - 1 : 1);

    final points = <Offset>[];
    for (int i = 0; i < count; i++) {
      final x = padding.left + stepWidth * i;
      final normalized = revenues[i] / maxRevenue;
      final y =
          padding.top + chartHeight - (normalized * chartHeight * animation);
      points.add(Offset(x, y));
    }

    if (points.length >= 2) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, padding.top + chartHeight);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final cx = (prev.dx + curr.dx) / 2;
        fillPath.cubicTo(cx, prev.dy, cx, curr.dy, curr.dx, curr.dy);
      }
      fillPath.lineTo(points.last.dx, padding.top + chartHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.amber.withValues(alpha: 0.2),
            AppColors.amber.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, padding.top, size.width, chartHeight));
      canvas.drawPath(fillPath, fillPaint);

      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final cx = (prev.dx + curr.dx) / 2;
        linePath.cubicTo(cx, prev.dy, cx, curr.dy, curr.dx, curr.dy);
      }

      final linePaint = Paint()
        ..color = AppColors.amber
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(linePath, linePaint);

      final dotGlowPaint = Paint()
        ..color = AppColors.amber.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      final dotPaint = Paint()
        ..color = AppColors.amber
        ..style = PaintingStyle.fill;

      for (final point in points) {
        canvas.drawCircle(point, 6, dotGlowPaint);
        canvas.drawCircle(point, 3, dotPaint);
      }
    }

    for (int i = 0; i < count; i++) {
      final monthKey = monthlyRevenue[i]['month'] as String? ?? '';
      final label = _shortMonth(monthKey);
      final x = padding.left + stepWidth * i;
      final tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(x - tp.width / 2, padding.top + chartHeight + 10),
      );
    }
  }

  String _formatCompact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
  }

  String _shortMonth(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length < 2) return '';
    final m = int.tryParse(parts[1]) ?? 1;
    const labels = [
      '',
      'J',
      'F',
      'M',
      'A',
      'M',
      'J',
      'J',
      'A',
      'S',
      'O',
      'N',
      'D',
    ];
    return labels[m.clamp(1, 12)];
  }

  @override
  bool shouldRepaint(covariant _RevenueChartPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.monthlyRevenue.length != monthlyRevenue.length;
  }
}

class _BarChartPainter extends CustomPainter {
  final Map<String, int> distribution;
  final int totalItems;
  final double animation;
  final Color barColor;

  _BarChartPainter({
    required this.distribution,
    required this.totalItems,
    required this.animation,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (distribution.isEmpty || totalItems == 0) return;

    final entries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxValue = entries.first.value;
    const barHeight = 24.0;
    const barGap = 32.0;
    const leftLabelWidth = 95.0;
    const rightLabelWidth = 56.0;
    final barMaxWidth = size.width - leftLabelWidth - rightLabelWidth - 16;

    final labelStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.65),
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    final valueStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w800,
    );
    final percentStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.4),
      fontSize: 9,
      fontWeight: FontWeight.w700,
    );

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final y = i * (barHeight + barGap);
      final fraction = entry.value / maxValue;
      final animatedWidth = barMaxWidth * fraction * animation;
      final percentage = (entry.value / totalItems) * 100;

      final nameTp = TextPainter(
        text: TextSpan(text: entry.key, style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '..',
      )..layout(maxWidth: leftLabelWidth - 8);
      nameTp.paint(canvas, Offset(0, y + barHeight / 2 - nameTp.height / 2));

      final barRect = RRect.fromLTRBR(
        leftLabelWidth,
        y,
        leftLabelWidth + animatedWidth,
        y + barHeight,
        const Radius.circular(6),
      );

      final glowPaint = Paint()
        ..color = barColor.withValues(alpha: 0.06)
        ..style = PaintingStyle.fill;
      final glowRect = RRect.fromLTRBR(
        leftLabelWidth,
        y - 2,
        leftLabelWidth + animatedWidth + 4,
        y + barHeight + 2,
        const Radius.circular(8),
      );
      canvas.drawRRect(glowRect, glowPaint);

      final barFillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            barColor.withValues(alpha: 0.8),
            barColor.withValues(alpha: 0.3),
          ],
        ).createShader(Rect.fromLTWH(leftLabelWidth, y, barMaxWidth, barHeight))
        ..style = PaintingStyle.fill;
      canvas.drawRRect(barRect, barFillPaint);

      if (animation > 0.4) {
        final countTp = TextPainter(
          text: TextSpan(text: '${entry.value}', style: valueStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        countTp.paint(
          canvas,
          Offset(
            leftLabelWidth + animatedWidth + 10,
            y + barHeight / 2 - countTp.height / 2,
          ),
        );

        final percentTp = TextPainter(
          text: TextSpan(
            text: '${percentage.toStringAsFixed(0)}%',
            style: percentStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        percentTp.paint(
          canvas,
          Offset(
            size.width - rightLabelWidth,
            y + barHeight / 2 - percentTp.height / 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.distribution.length != distribution.length;
  }
}
