import 'package:dio/dio.dart';
import '../../domain/repositories/uber_auth_repository.dart';

class UberAuthRepositoryImpl implements UberAuthRepository {
  final Dio _dio;
  final String _clientId;
  final String _clientSecret;
  
  String? _cachedToken;
  DateTime? _expiry;

  UberAuthRepositoryImpl({
    required Dio dio,
    required String clientId,
    required String clientSecret,
  }) : _dio = dio, _clientId = clientId, _clientSecret = clientSecret;

  @override
  Future<String> getAccessToken() async {
    if (_cachedToken != null && _expiry != null && _expiry!.isAfter(DateTime.now())) {
      return _cachedToken!;
    }
    await refreshTokens();
    return _cachedToken!;
  }

  @override
  Future<void> refreshTokens() async {
    try {
      final response = await _dio.post(
        'https://auth.uber.com/oauth/v2/token',
        data: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'grant_type': 'client_credentials',
          'scope': 'eats.deliveries',
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      _cachedToken = response.data['access_token'];
      final int expiresIn = response.data['expires_in']; // seconds
      _expiry = DateTime.now().add(Duration(seconds: expiresIn - 60)); // 1 min buffer
    } catch (e) {
      throw Exception('Uber Auth failed: $e');
    }
  }
}
