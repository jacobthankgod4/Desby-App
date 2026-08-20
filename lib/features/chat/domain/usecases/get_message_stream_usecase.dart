import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class GetMessageStreamUsecase {
  final ChatRepository repository;
  GetMessageStreamUsecase(this.repository);
  Stream<ChatMessage> call(String conversationId) =>
      repository.getMessageStream(conversationId);
}
