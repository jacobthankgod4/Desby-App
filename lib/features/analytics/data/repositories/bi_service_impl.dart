import '../../domain/entities/recommendation.dart';
import '../../domain/services/bi_service.dart';

class BIServiceImpl implements BIService {
  @override
  Future<List<Recommendation>> getRecommendations(String userId) async {
    return [
      const Recommendation(
        id: 'r1',
        title: 'Trending: Velvet Suit',
        description: 'Velvet suits are gaining popularity in your area. Consider adding a sample to your gallery.',
        type: RecommendationType.design,
        confidenceScore: 0.85,
      ),
      const Recommendation(
        id: 'r2',
        title: 'Optimize Pricing',
        description: 'Your pricing for alterations is 15% lower than the market average. Consider a slight increase.',
        type: RecommendationType.pricing,
        confidenceScore: 0.92,
      ),
      const Recommendation(
        id: 'r3',
        title: 'Re-engage Client',
        description: 'Client John Doe hasn\'t ordered in 6 months. Send a personalized follow-up.',
        type: RecommendationType.marketing,
        confidenceScore: 0.78,
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> getRevenueForecast(String userId) async {
    return {
      'forecast_next_month': 5200.0,
      'confidence_interval': [4800.0, 5600.0],
      'growth_factors': ['Wedding Season', 'New Portfolio Addition'],
    };
  }

  @override
  Future<double> getChurnProbability(String userId, String clientId) async {
    return 0.15; // 15% probability
  }
}
