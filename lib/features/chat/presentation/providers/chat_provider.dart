import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/repositories/supabase_chat_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Repository Provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return SupabaseChatRepository();
});

// Conversations List Provider
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final repository = ref.watch(chatRepositoryProvider);
  final result = await repository.getConversations(user.id);
  return result.fold(
    (failure) => throw failure,
    (conversations) => conversations,
  );
});

// Message List Provider
final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>((ref, conversationId) async {
  final repository = ref.watch(chatRepositoryProvider);
  final result = await repository.getMessages(conversationId);
  return result.fold(
    (failure) => throw failure,
    (messages) => messages,
  );
});

// Real-time Messages Stream Provider
final chatMessageStreamProvider = StreamProvider.family<ChatMessage, String>((ref, conversationId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getMessageStream(conversationId);
});
