import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bi_provider.dart';
import '../../domain/entities/recommendation.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/error_state_widget.dart';

class AIInsightsPage extends ConsumerWidget {
  const AIInsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final forecastAsync = ref.watch(revenueForecastProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Business Insights'),
        backgroundColor: AppColors.darkNavy,
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          _buildForecastHero(forecastAsync),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Personalized Recommendations',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          recommendationsAsync.when(
            data: (recs) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _RecommendationCard(recommendation: recs[index]),
                childCount: recs.length,
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (err, _) => const SliverToBoxAdapter(child: ErrorStateWidget(message: 'Could not load recommendations.')),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildForecastHero(AsyncValue<Map<String, dynamic>> forecastAsync) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: AppColors.darkNavy,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: forecastAsync.when(
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Next Month Forecast',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${data['forecast_next_month']}',
                style: const TextStyle(color: AppColors.amber, fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white54, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Growth driven by: ${data['growth_factors'].join(', ')}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
          error: (err, _) => ErrorStateWidget(message: 'Could not load forecast.', icon: Icons.auto_awesome),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;

  const _RecommendationCard({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _getTypeIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recommendation.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(recommendation.confidenceScore * 100).toInt()}% match',
                  style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation.description,
            style: TextStyle(color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Take Action', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16, color: AppColors.darkNavy),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getTypeIcon() {
    IconData iconData;
    Color color;
    switch (recommendation.type) {
      case RecommendationType.design:
        iconData = Icons.palette_outlined;
        color = Colors.purple;
        break;
      case RecommendationType.fabric:
        iconData = Icons.layers_outlined;
        color = Colors.blue;
        break;
      case RecommendationType.pricing:
        iconData = Icons.monetization_on_outlined;
        color = Colors.green;
        break;
      case RecommendationType.marketing:
        iconData = Icons.campaign_outlined;
        color = Colors.orange;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(iconData, color: color, size: 20),
    );
  }
}
