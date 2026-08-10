import '../../../../core/error/failures.dart';
import '../entities/chat_message.dart';
import '../entities/conversation.dart';

abstract class ChatRepository {
  Future<Result<Conversation>> createConversation(List<String> participantIds);
  Future<Result<List<Conversation>>> getConversations(String userId);
  Future<Result<List<ChatMessage>>> getMessages(String conversationId);
  Future<Result<ChatMessage>> sendMessage(ChatMessage message);
  Future<Result<void>> markAsRead(String conversationId);
  Stream<ChatMessage> getMessageStream(String conversationId);
}
