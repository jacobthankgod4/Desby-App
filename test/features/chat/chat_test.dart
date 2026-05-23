import 'package:flutter_test/flutter_test.dart';
import 'package:desby_app/features/chat/domain/entities/chat_message.dart';

void main() {
  group('ChatMessage Entity Tests', () {
    test('should identify sender correctly', () {
      final message = ChatMessage(
        id: '1',
        conversationId: 'c1',
        senderId: 'user_1',
        content: 'Hello',
        timestamp: DateTime.now(),
        type: ChatMessageType.text,
      );

      expect(message.senderId, 'user_1');
    });

    test('should support copyWith for marking as read', () {
      final message = ChatMessage(
        id: '1',
        conversationId: 'c1',
        senderId: 'user_1',
        content: 'Hello',
        timestamp: DateTime.now(),
        type: ChatMessageType.text,
        isRead: false,
      );

      final updated = message.copyWith(isRead: true);
      expect(updated.isRead, true);
    });
  });
}
