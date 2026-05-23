import '../entities/recommendation.dart';

abstract class BIService {
  Future<List<Recommendation>> getRecommendations(String userId);
  Future<Map<String, dynamic>> getRevenueForecast(String userId);
  Future<double> getChurnProbability(String userId, String clientId);
}
