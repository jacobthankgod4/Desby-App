import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
import '../../domain/usecases/get_chat_messages_usecase.dart';
import '../../domain/usecases/get_message_stream_usecase.dart';
import '../../data/repositories/supabase_chat_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return SupabaseChatRepository();
});

final getConversationsUsecaseProvider = Provider<GetConversationsUsecase>((ref) {
  return GetConversationsUsecase(ref.watch(chatRepositoryProvider));
});

final getChatMessagesUsecaseProvider = Provider<GetChatMessagesUsecase>((ref) {
  return GetChatMessagesUsecase(ref.watch(chatRepositoryProvider));
});

final getMessageStreamUsecaseProvider = Provider<GetMessageStreamUsecase>((ref) {
  return GetMessageStreamUsecase(ref.watch(chatRepositoryProvider));
});

final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final usecase = ref.watch(getConversationsUsecaseProvider);
  final result = await usecase(user.id);
  return result.fold(
    (failure) => throw failure,
    (conversations) => conversations,
  );
});

final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>((ref, conversationId) async {
  final usecase = ref.watch(getChatMessagesUsecaseProvider);
  final result = await usecase(conversationId);
  return result.fold(
    (failure) => throw failure,
    (messages) => messages,
  );
});

final chatMessageStreamProvider = StreamProvider.family<ChatMessage, String>((ref, conversationId) {
  final usecase = ref.watch(getMessageStreamUsecaseProvider);
  return usecase(conversationId);
});
