import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/conversation.dart';
import 'chat_message_model.dart';

part 'conversation_model.freezed.dart';
part 'conversation_model.g.dart';

@freezed
class ConversationModel with _$ConversationModel {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ConversationModel({
    required String id,
    required List<String> participantIds,
    ChatMessageModel? lastMessage,
    @Default(0) int unreadCount,
    String? orderId,
    Map<String, dynamic>? metadata,
  }) = _ConversationModel;

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);

  factory ConversationModel.fromEntity(Conversation entity) {
    return ConversationModel(
      id: entity.id,
      participantIds: entity.participantIds,
      lastMessage: entity.lastMessage != null 
        ? ChatMessageModel.fromEntity(entity.lastMessage!) 
        : null,
      unreadCount: entity.unreadCount,
      orderId: entity.orderId,
      metadata: entity.metadata,
    );
  }
}

extension ConversationModelX on ConversationModel {
  Conversation toEntity() => Conversation(
        id: id,
        participantIds: participantIds,
        lastMessage: lastMessage?.toEntity(),
        unreadCount: unreadCount,
        orderId: orderId,
        metadata: metadata,
      );
}
