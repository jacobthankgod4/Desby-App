import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';

class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Result<Conversation>> createConversation(List<String> participantIds) async {
    try {
      // Sort IDs to ensure consistent conversation ID generation if needed
      // but Supabase uses primary key, so we'll just check if one exists
      final existing = await _supabase
          .from('conversations')
          .select()
          .contains('participant_ids', participantIds);
      
      if ((existing as List).isNotEmpty) {
        return Success(ConversationModel.fromJson(existing.first).toEntity());
      }

      final id = 'CONV_${DateTime.now().millisecondsSinceEpoch}';
      final response = await _supabase.from('conversations').insert({
        'id': id,
        'participant_ids': participantIds,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      return Success(ConversationModel.fromJson(response).toEntity());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Conversation>>> getConversations(String userId) async {
    try {
      final response = await _supabase
          .from('conversations')
          .select()
          .contains('participant_ids', [userId]);
      return Success((response as List)
          .map((data) => ConversationModel.fromJson(data).toEntity())
          .toList());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<ChatMessage>>> getMessages(String conversationId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('timestamp', ascending: false);
      return Success((response as List)
          .map((data) => ChatMessageModel.fromJson(data).toEntity())
          .toList());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ChatMessage>> sendMessage(ChatMessage message) async {
    try {
      final model = ChatMessageModel.fromEntity(message);
      final response = await _supabase
          .from('messages')
          .insert(model.toJson())
          .select()
          .single();
      
      final sentModel = ChatMessageModel.fromJson(response);

      // Update conversation last message
      await _supabase.from('conversations').update({
        'last_message': sentModel.toJson(),
      }).eq('id', message.conversationId);

      return Success(sentModel.toEntity());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> markAsRead(String conversationId) async {
    try {
      await _supabase.from('conversations').update({
        'unread_count': 0,
      }).eq('id', conversationId);
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Stream<ChatMessage> getMessageStream(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('timestamp', ascending: false)
        .limit(1)
        .where((event) => event.isNotEmpty)
        .map((event) => ChatMessageModel.fromJson(event.first).toEntity());
  }
}
