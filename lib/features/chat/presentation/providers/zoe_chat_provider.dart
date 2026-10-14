import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/ai/zoe_ai_provider.dart';
import '../../../../core/services/ai/zoe_ai_cluster.dart';
import '../../../../core/services/ai/zoe_chat_service.dart';
import '../../../../core/services/ai/cloudflare_image_service.dart';
import '../../../../core/services/support/support_escalation_service.dart';
import '../../../../config/environment.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import '../../../clients/presentation/providers/client_provider.dart';

// AI Provider Cluster — initialized from .env keys
final zoeClusterProvider = Provider<ZoeAICluster>((ref) {
  final env = Environment.current;

  final providers = [
    ZoeAIProvider(
      name: 'Gemini',
      baseUrl: env.zoeGeminiBaseUrl,
      apiKey: env.zoeGeminiApiKey,
      model: env.zoeGeminiModel,
      priority: 1,
    ),
    ZoeAIProvider(
      name: 'Groq',
      baseUrl: env.zoeGroqBaseUrl,
      apiKey: env.zoeGroqApiKey,
      model: env.zoeGroqModel,
      priority: 2,
    ),
    ZoeAIProvider(
      name: 'Mistral',
      baseUrl: env.zoeMistralBaseUrl,
      apiKey: env.zoeMistralApiKey,
      model: env.zoeMistralModel,
      priority: 3,
    ),
    ZoeAIProvider(
      name: 'DeepSeek',
      baseUrl: env.zoeDeepSeekBaseUrl,
      apiKey: env.zoeDeepSeekApiKey,
      model: env.zoeDeepSeekModel,
      priority: 4,
    ),
  ];

  return ZoeAICluster(providers);
});

// Support escalation service (singleton)
final supportEscalationServiceProvider = Provider<SupportEscalationService>((
  ref,
) {
  return SupportEscalationService();
});

// Cloudflare image generation service
final cloudflareImageServiceProvider = Provider<CloudflareImageService>((ref) {
  return CloudflareImageService();
});

// Zoe chat service provider (uses cluster + image service)
final zoeChatServiceProvider = Provider<ZoeChatService>((ref) {
  final cluster = ref.watch(zoeClusterProvider);
  final imageService = ref.watch(cloudflareImageServiceProvider);
  return ZoeChatService(cluster, imageService: imageService);
});

// Zoe conversation state
class ZoeChatState {
  final List<ZoeMessage> messages;
  final bool isLoading;
  final String? error;
  final bool showEscalateButton;
  final bool isEscalating;
  final String? lastTicketId;
  final bool escalationSuccess;

  const ZoeChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.showEscalateButton = false,
    this.isEscalating = false,
    this.lastTicketId,
    this.escalationSuccess = false,
  });

  ZoeChatState copyWith({
    List<ZoeMessage>? messages,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? showEscalateButton,
    bool? isEscalating,
    String? lastTicketId,
    bool? escalationSuccess,
  }) {
    return ZoeChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      showEscalateButton: showEscalateButton ?? this.showEscalateButton,
      isEscalating: isEscalating ?? this.isEscalating,
      lastTicketId: lastTicketId ?? this.lastTicketId,
      escalationSuccess: escalationSuccess ?? this.escalationSuccess,
    );
  }
}

// Zoe chat notifier
class ZoeChatNotifier extends StateNotifier<ZoeChatState> {
  final ZoeChatService _service;
  final SupportEscalationService _escalationService;
  final String _userType;
  final String _userName;
  final String _userId;
  final String _userEmail;
  final Ref? _ref;

  ZoeChatNotifier(
    this._service,
    this._escalationService,
    this._userType,
    this._userName,
    this._userId,
    this._userEmail, [
    this._ref,
  ]) : super(const ZoeChatState()) {
    // Load persisted messages on init
    _service.loadMessages(_userId);
    if (_service.history.isNotEmpty) {
      state = state.copyWith(messages: _service.history);
    }
  }

  /// Build live context from real platform data
  Future<Map<String, dynamic>> _buildLiveContext() async {
    final ctx = <String, dynamic>{
      'userName': _userName,
      'userId': _userId,
      'userType': _userType,
    };

    if (_ref == null) return ctx;

    try {
      final ref = _ref;

      // Fetch dashboard stats — await the future, not just read the AsyncValue
      try {
        final stats = await ref.read(dashboardStatsProvider(_userId).future);
        ctx['totalOrders'] = stats.totalOrders;
        ctx['pendingOrders'] = stats.pendingOrders;
        ctx['completedOrders'] = stats.completedOrders;
        ctx['totalRevenue'] = stats.totalRevenue;
        ctx['totalClients'] = stats.totalClients;
        ctx['urgentDeadlines'] = stats.urgentDeadlines;
        ctx['totalApprentices'] = stats.totalApprentices;
        ctx['growthPercentage'] = stats.growthPercentage;
      } catch (e) {
        debugPrint('[ZOE] Failed to fetch dashboard stats: $e');
      }

      // Fetch recent orders
      try {
        final orders = await ref.read(ordersProvider(null).future);
        if (orders.isNotEmpty) {
          ctx['recentOrders'] = orders
              .take(5)
              .map(
                (o) => {
                  'garment': o.items.isNotEmpty
                      ? o.items.first.garmentType
                      : 'Unknown',
                  'status': o.status.name,
                  'amount': o.totalAmount,
                  'client': o.clientName,
                  'fabric': o.fabricType ?? 'Not specified',
                  'color': o.fabricColor ?? 'Not specified',
                },
              )
              .toList();
        }
      } catch (e) {
        debugPrint('[ZOE] Failed to fetch orders: $e');
      }

      // Fetch clients (tailor only)
      if (_userType == 'tailor') {
        try {
          final clients = await ref.read(clientsProvider((tailorId: _userId, query: null)).future);
          ctx['totalClientCount'] = clients.length;
          ctx['recentClients'] = clients
              .take(5)
              .map(
                (c) => {
                  'name': c.name,
                  'hasMeasurements': c.hasMeasurements,
                  'gender': c.gender,
                },
              )
              .toList();
        } catch (e) {
          debugPrint('[ZOE] Failed to fetch clients: $e');
        }
      }

      // Fetch user profile for pricing
      try {
        final profile = await ref.read(userProfileProvider(_userId).future);
        if (profile != null) {
          if (profile.hasPricing) {
            ctx['pricing'] = {
              'baseStitchingPrice': profile.baseStitchingPrice,
              'materialCost': profile.materialCost,
              'startingPrice': profile.startingPrice,
            };
          }
          if (profile.businessName != null) {
            ctx['businessName'] = profile.businessName;
          }
        }
      } catch (e) {
        debugPrint('[ZOE] Failed to fetch profile: $e');
      }
    } catch (e) {
      debugPrint('[ZOE] Failed to build live context: $e');
    }

    return ctx;
  }

  Future<void> sendMessage(String content, {String? imageUrl}) async {
    if (state.isLoading) return;
    if (content.trim().isEmpty && imageUrl == null) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      showEscalateButton: false,
    );

    try {
      // Check if this is an escalation request
      final isEscalation = _service.isEscalationRequest(content);

      // Build live context from real platform data
      final liveContext = await _buildLiveContext();
      liveContext['isEscalationRequest'] = isEscalation;

      await _service.sendMessage(
        content,
        userType: _userType,
        context: liveContext,
        imageUrl: imageUrl,
      );

      state = state.copyWith(
        messages: _service.history,
        isLoading: false,
        showEscalateButton: isEscalation,
      );
    } catch (e) {
      state = state.copyWith(
        messages: _service.history,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> escalateToSupport() async {
    if (state.isEscalating) return;

    state = state.copyWith(isEscalating: true, clearError: true);

    try {
      final result = await _escalationService.escalate(
        userMessage: _service.getLastUserMessage(),
        userId: _userId,
        userName: _userName,
        userEmail: _userEmail,
        userType: _userType,
        conversation: _service.getConversationForSupport(),
      );

      if (result.success) {
        // Add Zoe's confirmation message to history
        await _service.sendMessage(
          '[SILENT] The user has been escalated to support. Their ticket reference is ${result.ticketId}. Tell them their ticket has been created and our team will reach out within 24 hours. Be warm and reassuring.',
          userType: _userType,
          context: {'ticketId': result.ticketId},
        );

        state = state.copyWith(
          messages: _service.history,
          isEscalating: false,
          showEscalateButton: false,
          lastTicketId: result.ticketId,
          escalationSuccess: true,
        );
      } else {
        state = state.copyWith(
          isEscalating: false,
          error: 'Failed to create support ticket: ${result.error}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isEscalating: false,
        error: 'Escalation failed: $e',
      );
    }
  }

  void clearChat() {
    _service.clearHistory();
    state = const ZoeChatState();
  }

  void dismissEscalationBanner() {
    state = state.copyWith(escalationSuccess: false, lastTicketId: null);
  }
}

// Provider that auto-detects user type from auth
final zoeChatProvider = StateNotifierProvider<ZoeChatNotifier, ZoeChatState>((
  ref,
) {
  final service = ref.watch(zoeChatServiceProvider);
  final escalationService = ref.watch(supportEscalationServiceProvider);
  final user = ref.watch(currentUserProvider);
  final profileAsync = ref.watch(userProfileProvider(user?.id ?? ''));

  final userType = user?.userType ?? 'client';
  final userName = profileAsync.valueOrNull?.name ?? user?.name ?? 'there';
  final userId = user?.id ?? '';
  final userEmail = user?.email ?? '';

  return ZoeChatNotifier(
    service,
    escalationService,
    userType,
    userName,
    userId,
    userEmail,
    ref,
  );
});

// Quick action suggestions per user type
final zoeQuickActionsProvider = Provider<List<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  final userType = user?.userType ?? 'client';

  switch (userType) {
    case 'tailor':
      return [
        'How much should I charge for an agbada?',
        'Show me how to sew a senator collar',
        'Help me pattern-draft an ankara gown',
        'Tips for growing my tailoring business',
        'Talk to a human agent',
      ];
    case 'client':
      return [
        'What should I wear to a traditional wedding?',
        'Help me understand my body measurements',
        'Suggest outfit ideas for my budget',
        'What fabric is best for hot weather?',
        'Talk to a human agent',
      ];
    case 'apprentice':
      return [
        'Explain how to take chest measurements',
        'How do I hem a garment properly?',
        'What pattern drafting tools do I need?',
        'Help me understand fabric grain',
        'Talk to a human agent',
      ];
    case 'fabric_seller':
      return [
        'Write a product description for my fabric',
        'What price should I set for premium lace?',
        'How do I attract more tailors to my shop?',
        'What fabrics are trending this season?',
        'Talk to a human agent',
      ];
    default:
      return [
        'Help me with my outfit choice',
        'Tell me about African fabrics',
        'How does the AI body scan work?',
        'Find a tailor near me',
        'Talk to a human agent',
      ];
  }
});
