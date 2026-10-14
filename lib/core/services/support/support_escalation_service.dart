import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../../config/environment.dart';

/// Result of a support escalation attempt.
class SupportEscalationResult {
  final bool success;
  final String ticketId;
  final String? error;

  const SupportEscalationResult({
    required this.success,
    required this.ticketId,
    this.error,
  });
}

/// Sends support escalation emails via Supabase Edge Function → Brevo API.
///
/// Flow:
/// 1. Generates a ticket reference (DESBY-XXXXX)
/// 2. Calls the send-support-email edge function
/// 3. Edge function sends formatted email to support@desby.app
/// 4. Returns ticket reference for the user
class SupportEscalationService {
  static const _uuid = Uuid();

  /// Escalate a support request to the support team.
  ///
  /// [userMessage] is the user's specific request that triggered escalation.
  /// [conversation] is the recent chat history for context.
  /// Returns a [SupportEscalationResult] with the ticket reference.
  Future<SupportEscalationResult> escalate({
    required String userMessage,
    required String userId,
    required String userName,
    required String userEmail,
    required String userType,
    required List<Map<String, String>> conversation,
  }) async {
    // Generate ticket reference: DESBY-XXXXX (8 char hex)
    final ticketId = 'DESBY-${_uuid.v4().substring(0, 8).toUpperCase()}';

    debugPrint(
      '[SUPPORT] Escalating ticket $ticketId for $userName ($userType)',
    );

    try {
      final env = Environment.current;
      final supabaseUrl = env.supabaseUrl;
      final supabaseKey = env.supabaseAnonKey;

      if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
        return SupportEscalationResult(
          success: false,
          ticketId: ticketId,
          error: 'Supabase not configured',
        );
      }

      final edgeFunctionUrl = '$supabaseUrl/functions/v1/send-support-email';

      // Call the edge function
      final response = await http.post(
        Uri.parse(edgeFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseKey',
          'apikey': supabaseKey,
        },
        body: jsonEncode({
          'ticketId': ticketId,
          'userId': userId,
          'userName': userName,
          'userEmail': userEmail,
          'userType': userType,
          'subject': _extractSubject(userMessage),
          'message': userMessage,
          'conversation': conversation,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          debugPrint('[SUPPORT] Ticket $ticketId sent successfully');
          return SupportEscalationResult(success: true, ticketId: ticketId);
        } else {
          debugPrint('[SUPPORT] Edge function error: ${data['message']}');
          return SupportEscalationResult(
            success: false,
            ticketId: ticketId,
            error: data['message'] ?? 'Unknown error',
          );
        }
      } else {
        debugPrint(
          '[SUPPORT] HTTP error: ${response.statusCode} ${response.body}',
        );
        return SupportEscalationResult(
          success: false,
          ticketId: ticketId,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      debugPrint('[SUPPORT] Exception: $e');
      return SupportEscalationResult(
        success: false,
        ticketId: ticketId,
        error: e.toString(),
      );
    }
  }

  /// Extract a short subject line from the user's message.
  String _extractSubject(String message) {
    final cleaned = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= 60) return cleaned;
    return '${cleaned.substring(0, 57)}...';
  }
}
