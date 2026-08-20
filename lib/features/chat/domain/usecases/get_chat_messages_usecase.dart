import '../../../../core/error/failures.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class GetChatMessagesUsecase {
  final ChatRepository repository;
  GetChatMessagesUsecase(this.repository);
  Future<Result<List<ChatMessage>>> call(String conversationId) =>
      repository.getMessages(conversationId);
}
