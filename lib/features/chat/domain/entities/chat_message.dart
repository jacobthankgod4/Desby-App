import 'package:equatable/equatable.dart';

enum ChatMessageType {
  text,
  image,
  file,
  location,
  measurementRequest, // NEW: Elite Master Tool
  designProposal      // NEW: Professional Proposal
}

class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final ChatMessageType type;
  final bool isRead;
  final String? orderId; // NEW: Project Context
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.orderId,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        content,
        timestamp,
        type,
        isRead,
        orderId,
        metadata,
      ];

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    DateTime? timestamp,
    ChatMessageType? type,
    bool? isRead,
    String? orderId,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      orderId: orderId ?? this.orderId,
      metadata: metadata ?? this.metadata,
    );
  }
}
