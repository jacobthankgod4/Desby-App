import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Single AI provider configuration and client.
///
/// Each provider uses the OpenAI-compatible chat completions format.
/// Just different base_url, api_key, and model.
class ZoeAIProvider {
  final String name;
  final String baseUrl;
  final String apiKey;
  final String model;
  final int priority;
  late final Dio _dio;

  /// Timestamp when this provider was last rate-limited (429).
  /// Used for cooldown logic — skip provider for 60s after 429.
  DateTime? _rateLimitedAt;

  /// How many consecutive 429s in a row (backs off cooldown).
  int _consecutive429s = 0;

  ZoeAIProvider({
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.priority,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: false,
          logPrint: (obj) => debugPrint('[ZOE-AI][$name] $obj'),
        ),
      );
    }
  }

  /// Whether this provider is currently in cooldown (rate-limited).
  bool get isRateLimited {
    if (_rateLimitedAt == null) return false;
    final cooldown = Duration(seconds: 30 * _consecutive429s.clamp(1, 4));
    return DateTime.now().difference(_rateLimitedAt!) < cooldown;
  }

  /// Mark this provider as rate-limited.
  void markRateLimited() {
    _rateLimitedAt = DateTime.now();
    _consecutive429s++;
    debugPrint(
      '[ZOE-AI][$name] Rate limited. Cooldown: ${30 * _consecutive429s.clamp(1, 4)}s',
    );
  }

  /// Mark this provider as working (reset consecutive count).
  void markWorking() {
    _consecutive429s = 0;
    _rateLimitedAt = null;
  }

  /// Send a chat completion request.
  ///
  /// Returns the assistant's reply text, or throws on error.
  Future<String> complete({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    final requestMessages = [
      {'role': 'system', 'content': systemPrompt},
      ...messages,
    ];

    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': model,
        'messages': requestMessages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final content = choices[0]['message']?['content'] as String?;
        if (content != null && content.isNotEmpty) {
          markWorking();
          return content;
        }
      }
      throw Exception('Empty response from $name');
    }

    throw Exception('HTTP ${response.statusCode} from $name');
  }

  @override
  String toString() => 'ZoeAIProvider($name, model=$model, priority=$priority)';
}
