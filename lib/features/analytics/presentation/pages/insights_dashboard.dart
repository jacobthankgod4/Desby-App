import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'reports_page.dart';
import 'ai_insights_page.dart';

class InsightsDashboard extends ConsumerWidget {
  const InsightsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text('BUSINESS INTELLIGENCE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.amber),
            onPressed: () => Navigator.pushNamed(context, '/ai-insights'),
          ),
          IconButton(
            icon: const Icon(Icons.description_outlined, color: Colors.white38),
            onPressed: () => Navigator.pushNamed(context, '/reports'),
          ),
        ],
      ),
      body: metricsAsync.when(
        data: (metrics) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildMetricsGrid(metrics),
              const SizedBox(height: 48),
              _buildRevenueChart(),
              const SizedBox(height: 48),
              _buildTopServices(),
              const SizedBox(height: 60),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
        error: (err, _) => const ErrorStateWidget(message: 'Dossier sync failed.'),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PERFORMANCE ARCHITECTURE',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        const Text(
          'Real-time predictive forecasting for your bespoke empire.',
          style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(List<dynamic> metrics) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(metric.label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    metric.label.contains('Revenue') ? '₦${(metric.value * 1000).toInt()}' : '${metric.value.toInt()}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const Spacer(),
                  Icon(
                    metric.trend == 'up' ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    size: 14,
                    color: metric.trend == 'up' ? const Color(0xFF00FF7F) : Colors.redAccent,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REVENUE FORECASTING',
            style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(60, 'MON'),
                _buildBar(90, 'TUE'),
                _buildBar(70, 'WED'),
                _buildBar(120, 'THU'),
                _buildBar(150, 'FRI'),
                _buildBar(130, 'SAT'),
                _buildBar(80, 'SUN'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 12,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.amber,
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(color: AppColors.amber.withValues(alpha: 0.2), blurRadius: 15)
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildTopServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ELITE SPECIALTIES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.amber, letterSpacing: 1.5)),
        const SizedBox(height: 24),
        _buildServiceItem('SAVILE ROW SUITS', 0.85),
        _buildServiceItem('TRADITIONAL MASTERPIECES', 0.65),
        _buildServiceItem('BRIDAL CORSETRY', 0.45),
      ],
    );
  }

  Widget _buildServiceItem(String name, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900)),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.amber),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
