import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'zoe_ai_provider.dart';

/// AI Provider Cluster with automatic rotation and fallback.
///
/// When a provider returns 429 (rate limited), the cluster automatically
/// tries the next available provider. Providers cool down after 429s
/// and rejoin the rotation automatically.
class ZoeAICluster {
  final List<ZoeAIProvider> _providers;

  /// Index of the last successfully used provider (for preference).
  int _lastUsedIndex = -1;

  ZoeAICluster(this._providers) {
    // Sort by priority (lower number = higher priority)
    _providers.sort((a, b) => a.priority.compareTo(b.priority));
    debugPrint(
      '[ZOE-CLUSTER] Initialized with ${_providers.length} providers: ${_providers.map((p) => p.name).join(', ')}',
    );
  }

  /// Get the number of available (non-rate-limited) providers.
  int get availableCount => _providers.where((p) => !p.isRateLimited).length;

  /// Get status of all providers.
  List<Map<String, dynamic>> get status => _providers
      .map(
        (p) => {
          'name': p.name,
          'model': p.model,
          'rateLimited': p.isRateLimited,
          'priority': p.priority,
        },
      )
      .toList();

  /// Send a chat completion request using the best available provider.
  ///
  /// Tries providers in priority order, skipping rate-limited ones.
  /// If all providers are rate-limited, returns a fallback message.
  Future<String> complete({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    // Try each provider in order
    for (int attempt = 0; attempt < _providers.length; attempt++) {
      // Pick next available provider
      final provider = _getNextProvider();
      if (provider == null) {
        // All providers are rate-limited
        debugPrint('[ZOE-CLUSTER] All providers rate-limited');
        return _getFallbackMessage();
      }

      try {
        debugPrint('[ZOE-CLUSTER] Trying: ${provider.name}');
        final result = await provider.complete(
          systemPrompt: systemPrompt,
          messages: messages,
          temperature: temperature,
          maxTokens: maxTokens,
        );
        _lastUsedIndex = _providers.indexOf(provider);
        return result;
      } on DioException catch (e) {
        if (e.response?.statusCode == 429) {
          // Rate limited — mark and try next
          provider.markRateLimited();
          debugPrint(
            '[ZOE-CLUSTER] ${provider.name} rate-limited, trying next...',
          );
          continue;
        }
        // Other Dio error — log and try next
        debugPrint('[ZOE-CLUSTER] ${provider.name} error: ${e.message}');
        continue;
      } catch (e) {
        // Unknown error — log and try next
        debugPrint('[ZOE-CLUSTER] ${provider.name} unexpected error: $e');
        continue;
      }
    }

    // All providers failed
    return _getFallbackMessage();
  }

  /// Get the next available provider, preferring the last used one.
  ZoeAIProvider? _getNextProvider() {
    // If last used provider is still available, prefer it
    if (_lastUsedIndex >= 0 && _lastUsedIndex < _providers.length) {
      final lastUsed = _providers[_lastUsedIndex];
      if (!lastUsed.isRateLimited) return lastUsed;
    }

    // Otherwise, find first available provider
    for (final provider in _providers) {
      if (!provider.isRateLimited) return provider;
    }

    return null;
  }

  /// Fallback message when all providers are exhausted.
  String _getFallbackMessage() {
    final cooldowns = _providers
        .where((p) => p.isRateLimited)
        .map((p) => p.name)
        .join(', ');
    return 'I\'m currently experiencing high demand across all my AI engines ($cooldowns are cooling down). Please try again in a moment — I\'ll be right back!';
  }
}
