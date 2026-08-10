import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/chat_message.dart';

part 'chat_message_model.freezed.dart';
part 'chat_message_model.g.dart';

@freezed
class ChatMessageModel with _$ChatMessageModel {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ChatMessageModel({
    required String id,
    required String conversationId,
    required String senderId,
    required String content,
    required DateTime timestamp,
    required String type,
    @Default(false) bool isRead,
    String? orderId,
    Map<String, dynamic>? metadata,
  }) = _ChatMessageModel;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);

  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      conversationId: entity.conversationId,
      senderId: entity.senderId,
      content: entity.content,
      timestamp: entity.timestamp,
      type: entity.type.name,
      isRead: entity.isRead,
      orderId: entity.orderId,
      metadata: entity.metadata,
    );
  }
}

extension ChatMessageModelX on ChatMessageModel {
  ChatMessage toEntity() => ChatMessage(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        content: content,
        timestamp: timestamp,
        type: ChatMessageType.values.byName(type),
        isRead: isRead,
        orderId: orderId,
        metadata: metadata,
      );
}
