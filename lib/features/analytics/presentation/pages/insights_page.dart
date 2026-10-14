import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:html' as html;

import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/analytics_service_impl.dart';
import '../providers/bi_provider.dart';
import '../providers/analytics_provider.dart';
import '../../domain/entities/recommendation.dart';
import '../../../payments/presentation/widgets/subscription_gate.dart';
import '../../../payments/domain/models/plan_registry.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/shell_app_bar.dart';

/// Combined Insights page with tabs: Overview, AI Insights, Reports.
class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'INSIGHTS',
        foregroundColor: colors.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.amber,
          unselectedLabelColor: colors.textMuted,
          indicatorColor: AppColors.amber,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'OVERVIEW'),
            Tab(text: 'AI INSIGHTS'),
            Tab(text: 'REPORTS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _OverviewTab(),
          const _AiInsightsTab(),
          const _ReportsTab(),
        ],
      ),
    );
  }
}

// ── Overview Tab (Business Intelligence dashboard) ──

class _OverviewTab extends ConsumerStatefulWidget {
  const _OverviewTab();

  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab>
    with SingleTickerProviderStateMixin {
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
        _insights = results[0] is Map<String, dynamic>
            ? results[0] as Map<String, dynamic>
            : <String, dynamic>{};
        _monthlyRevenue = results[1] is List
            ? (results[1] as List)
                  .map(
                    (e) => e is Map<String, dynamic> ? e : <String, dynamic>{},
                  )
                  .toList()
            : <Map<String, dynamic>>[];
        _categoryDistribution = results[2] is Map
            ? Map<String, int>.from(
                (results[2] as Map).map(
                  (k, v) => MapEntry(k.toString(), (v as num).toInt()),
                ),
              )
            : <String, int>{};
        _isLoading = false;
      });
      _fadeController.forward(from: 0);
      _chartController.forward(from: 0);
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
    if (value >= 1000000) return '₦${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '₦${(value / 1000).toStringAsFixed(1)}k';
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
    final colors = context.colors;
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      );
    }
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.amber,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickStats(colors),
            const SizedBox(height: 20),
            _buildKeyMetricsGrid(colors),
            const SizedBox(height: 24),
            _buildRevenueChart(colors),
            const SizedBox(height: 24),
            if (_categoryDistribution.isNotEmpty) ...[
              _buildCategoryDistribution(colors),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(DesbyThemeColors colors) {
    final totalRevenue = (_insights['totalRevenue'] as num?)?.toDouble() ?? 0;
    final totalOrders = (_insights['totalOrders'] as num?)?.toInt() ?? 0;
    final totalClients = (_insights['totalClients'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        _buildStatPill(
          'Revenue',
          _formatCompactCurrency(totalRevenue),
          AppColors.amber,
        ),
        const SizedBox(width: 8),
        _buildStatPill('Orders', '$totalOrders', Colors.blueAccent),
        const SizedBox(width: 8),
        _buildStatPill('Clients', '$totalClients', Colors.greenAccent),
      ],
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsGrid(DesbyThemeColors colors) {
    final totalRevenue = (_insights['totalRevenue'] as num?)?.toDouble() ?? 0;
    final totalOrders = (_insights['totalOrders'] as num?)?.toInt() ?? 0;
    final activeClients = (_insights['totalClients'] as num?)?.toInt() ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildMetricCard(
          'Total Revenue',
          _formatFullCurrency(totalRevenue),
          Icons.attach_money_rounded,
          AppColors.amber,
          colors,
        ),
        _buildMetricCard(
          'Total Orders',
          '$totalOrders',
          Icons.description_rounded,
          Colors.blueAccent,
          colors,
        ),
        _buildMetricCard(
          'Active Clients',
          '$activeClients',
          Icons.people_rounded,
          Colors.greenAccent,
          colors,
        ),
        _buildMetricCard(
          'Completion',
          '${_completionRate.toStringAsFixed(0)}%',
          Icons.check_circle_rounded,
          Colors.orangeAccent,
          colors,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
    DesbyThemeColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(DesbyThemeColors colors) {
    if (_monthlyRevenue.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONTHLY REVENUE',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: AnimatedBuilder(
              animation: _chartController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(double.infinity, 160),
                  painter: _RevenueChartPainter(
                    data: _monthlyRevenue,
                    progress: _chartController.value,
                    lineColor: AppColors.amber,
                    fillColor: AppColors.amber.withValues(alpha: 0.1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution(DesbyThemeColors colors) {
    final total = _categoryDistribution.values.fold<int>(0, (a, b) => a + b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORDER CATEGORIES',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ..._categoryDistribution.entries.map((entry) {
            final pct = total > 0 ? (entry.value / total * 100) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        backgroundColor: colors.borderSubtle,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.amber,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${pct.toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── AI Insights Tab ──

class _AiInsightsTab extends ConsumerWidget {
  const _AiInsightsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final forecastAsync = ref.watch(revenueForecastProvider);
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildForecastHero(forecastAsync, colors),
          const SizedBox(height: 24),
          Text(
            'Personalized Recommendations',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          recommendationsAsync.when(
            data: (recs) => Column(
              children: recs
                  .map((r) => _RecommendationCard(recommendation: r))
                  .toList(),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.amber),
            ),
            error: (err, _) => const ErrorStateWidget(
              message: 'Could not load recommendations.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastHero(
    AsyncValue<Map<String, dynamic>> forecastAsync,
    DesbyThemeColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: forecastAsync.when(
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NEXT MONTH FORECAST',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '₦${data['forecasted_revenue'] ?? 0}',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${data['growth_percentage'] ?? 0}% projected growth',
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (e, _) =>
            const ErrorStateWidget(message: 'Could not load forecast.'),
      ),
    );
  }
}

// ── Reports Tab ──

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(
      revenueReportProvider((
        start: DateTime.now().subtract(const Duration(days: 90)),
        end: DateTime.now(),
      )),
    );

    return reportAsync.when(
      data: (report) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReportSummary(report),
          const SizedBox(height: 20),
          _buildGarmentBreakdown((report['garment_breakdown'] as List?) ?? []),
          const SizedBox(height: 20),
          _buildExportSection(context, report),
        ],
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      ),
      error: (err, _) =>
          const ErrorStateWidget(message: 'Could not generate report.'),
    );
  }

  Widget _buildReportSummary(Map<String, dynamic> report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Total Revenue (90 days)',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '\u20A6${report['total_revenue']}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGarmentBreakdown(List breakdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revenue by Category',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...breakdown.map(
          (item) => ListTile(
            title: Text(item['type']),
            trailing: Text(
              '\u20A6${item['amount']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportSection(
    BuildContext context,
    Map<String, dynamic> report,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportPDF(report),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDF'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportCSV(report),
                    icon: const Icon(Icons.table_chart),
                    label: const Text('CSV'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _exportPDF(Map<String, dynamic> report) {
    final totalRevenue = report['total_revenue'] ?? 0;
    final breakdown = (report['garment_breakdown'] as List?) ?? [];
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final breakdownRows = breakdown
        .map(
          (item) =>
              '<tr><td style="padding:8px;border-bottom:1px solid #eee;">${item['type']}</td>'
              '<td style="padding:8px;border-bottom:1px solid #eee;text-align:right;">₦${item['amount']}</td></tr>',
        )
        .join();

    final htmlContent =
        '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Desby Revenue Report - $dateStr</title>
  <style>
    body { font-family: Arial, sans-serif; padding: 40px; color: #333; }
    h1 { color: #0A1921; border-bottom: 3px solid #FFC107; padding-bottom: 10px; }
    .summary { background: #f8f9fa; padding: 20px; border-radius: 12px; margin: 20px 0; }
    .amount { font-size: 32px; font-weight: bold; color: #FFC107; }
    table { width: 100%; border-collapse: collapse; margin-top: 20px; }
    th { background: #0A1921; color: #FFC107; padding: 12px 8px; text-align: left; }
    .footer { margin-top: 40px; color: #999; font-size: 12px; text-align: center; }
  </style>
</head>
<body>
  <h1>Desby Revenue Report</h1>
  <p>Period: Last 90 days | Generated: ${now.day}/${now.month}/${now.year}</p>
  <div class="summary">
    <p style="margin:0;color:#666;">Total Revenue</p>
    <p class="amount">₦$totalRevenue</p>
  </div>
  <table>
    <thead><tr><th>Category</th><th style="text-align:right;">Revenue</th></tr></thead>
    <tbody>$breakdownRows</tbody>
  </table>
  <div class="footer">Generated by Desby OS - desby.app</div>
</body>
</html>''';

    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'desby_report_$dateStr.html')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _exportCSV(Map<String, dynamic> report) {
    final totalRevenue = report['total_revenue'] ?? 0;
    final breakdown = (report['garment_breakdown'] as List?) ?? [];
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final buffer = StringBuffer();
    buffer.writeln('Desby Revenue Report');
    buffer.writeln('Period,Last 90 days');
    buffer.writeln('Generated,$dateStr');
    buffer.writeln('');
    buffer.writeln('Total Revenue,₦$totalRevenue');
    buffer.writeln('');
    buffer.writeln('Category,Revenue');
    for (final item in breakdown) {
      buffer.writeln('${item['type']},₦${item['amount']}');
    }

    final bytes = utf8.encode(buffer.toString());
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'desby_report_$dateStr.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}

// ── Shared widgets ──

class _RecommendationCard extends ConsumerWidget {
  final Recommendation recommendation;
  const _RecommendationCard({required this.recommendation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    recommendation.type.name.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.amber,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${(recommendation.confidenceScore * 100).toStringAsFixed(0)}% confidence',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recommendation.title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              recommendation.description,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _takeAction(context, ref),
                child: const Text('Take Action'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _takeAction(BuildContext context, WidgetRef ref) {
    switch (recommendation.type) {
      case RecommendationType.design:
        ref.pushShell('/design-upload');
        break;
      case RecommendationType.fabric:
        ref.pushShell('/marketplace');
        break;
      case RecommendationType.pricing:
        ref.pushShell('/pricing-setup');
        break;
      case RecommendationType.marketing:
        ref.pushShell('/virtual-atelier');
        break;
    }
  }
}

// ── Chart painter ──

class _RevenueChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double progress;
  final Color lineColor;
  final Color fillColor;

  _RevenueChartPainter({
    required this.data,
    required this.progress,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final values = data
        .map((e) => (e['revenue'] as num?)?.toDouble() ?? 0)
        .toList();
    final maxVal = values.reduce(max);
    if (maxVal == 0) return;

    final path = Path();
    final fillPath = Path();
    final w = size.width;
    final h = size.height;
    final step = w / (values.length - 1).clamp(1, values.length);

    for (int i = 0; i < values.length; i++) {
      final x = i * step;
      final y = h - (values[i] / maxVal * h * 0.85);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, h);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * step;
        final prevY = h - (values[i - 1] / maxVal * h * 0.85);
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
        fillPath.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }

    fillPath.lineTo(w, h);
    fillPath.close();

    final animatedPath = _interpolatePath(fillPath, progress);

    canvas.drawPath(
      animatedPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fillColor, fillColor.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    canvas.drawPath(
      _interpolatePath(path, progress),
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Dots
    for (int i = 0; i < values.length; i++) {
      final x = i * step;
      final y = h - (values[i] / maxVal * h * 0.85);
      if (x / w <= progress) {
        canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = lineColor);
        canvas.drawCircle(
          Offset(x, y),
          2,
          Paint()..color = lineColor.withValues(alpha: 0.3),
        );
      }
    }

    // Month labels
    final months = [
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
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < data.length; i++) {
      final monthIdx = (data[i]['month'] as num?)?.toInt() ?? (i + 1);
      final label = months[(monthIdx - 1).clamp(0, 11)];
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(color: lineColor.withValues(alpha: 0.5), fontSize: 9),
      );
      textPainter.layout();
      final x = i * step - textPainter.width / 2;
      textPainter.paint(canvas, Offset(x, h - 2));
    }
  }

  Path _interpolatePath(Path source, double t) {
    final metrics = source.computeMetrics().toList();
    final result = Path();
    for (final metric in metrics) {
      result.addPath(metric.extractPath(0, metric.length * t), Offset.zero);
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _RevenueChartPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.data != data;
  }
}
