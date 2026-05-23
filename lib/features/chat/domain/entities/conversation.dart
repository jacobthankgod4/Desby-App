import 'package:equatable/equatable.dart';
import 'chat_message.dart';

class Conversation extends Equatable {
  final String id;
  final List<String> participantIds;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final String? orderId; // NEW: Associate conversation with a bespoke project
  final Map<String, dynamic>? metadata;

  const Conversation({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    this.unreadCount = 0,
    this.orderId,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        participantIds,
        lastMessage,
        unreadCount,
        orderId,
        metadata,
      ];

  Conversation copyWith({
    String? id,
    List<String>? participantIds,
    ChatMessage? lastMessage,
    int? unreadCount,
    String? orderId,
    Map<String, dynamic>? metadata,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      orderId: orderId ?? this.orderId,
      metadata: metadata ?? this.metadata,
    );
  }
}
