import '../../../../core/error/failures.dart';
import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

class GetConversationsUsecase {
  final ChatRepository repository;
  GetConversationsUsecase(this.repository);
  Future<Result<List<Conversation>>> call(String userId) =>
      repository.getConversations(userId);
}
