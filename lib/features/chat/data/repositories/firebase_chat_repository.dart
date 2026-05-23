import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';

class FirebaseChatRepository implements ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Result<List<Conversation>>> getConversations(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('conversations')
          .where('participantIds', arrayContains: userId)
          .get();
      return Success(snapshot.docs
          .map((doc) => ConversationModel.fromJson(doc.data()).toEntity())
          .toList());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<ChatMessage>>> getMessages(String conversationId) async {
    try {
      final snapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .get();
      return Success(snapshot.docs
          .map((doc) => ChatMessageModel.fromJson(doc.data()).toEntity())
          .toList());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ChatMessage>> sendMessage(ChatMessage message) async {
    try {
      final model = ChatMessageModel.fromEntity(message);
      final docRef = _firestore
          .collection('conversations')
          .doc(message.conversationId)
          .collection('messages')
          .doc();
      
      final sentModel = model.copyWith(id: docRef.id);
      await docRef.set(sentModel.toJson());

      // Update conversation last message
      await _firestore.collection('conversations').doc(message.conversationId).update({
        'lastMessage': sentModel.toJson(),
      });

      return Success(sentModel.toEntity());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> markAsRead(String conversationId) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'unreadCount': 0,
      });
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Stream<ChatMessage> getMessageStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .where((snapshot) => snapshot.docs.isNotEmpty)
        .map((snapshot) => ChatMessageModel.fromJson(snapshot.docs.first.data()).toEntity());
  }
}
