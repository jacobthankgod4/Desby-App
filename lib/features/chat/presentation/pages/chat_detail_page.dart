import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../widgets/ai_tryon_widget.dart';
import '../../domain/entities/chat_message.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/error_state_widget.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  final String conversationId;
  final String? peerId; // NEW: Real Peer Identity
  final String? orderId; // NEW: Project Context

  const ChatDetailPage({
    super.key, 
    required this.conversationId,
    this.peerId,
    this.orderId,
  });

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImageUploadService _imageService = ImageUploadService();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Mark messages as read on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatRepositoryProvider).markAsRead(widget.conversationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.conversationId));
    final user = ref.watch(currentUserProvider);
    final currentUserId = user?.id ?? '';

    // Peer Profile Sync
    final peerProfile = widget.peerId != null ? ref.watch(userProfileProvider(widget.peerId!)) : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
          onPressed: () {
            final navState = ref.read(navigationProvider);
            if (navState.route == '/chat-detail') {
              ref.read(navigationProvider.notifier).state = const NavigationState('/chats');
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: peerProfile?.when(
          data: (profile) => Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.amber.withValues(alpha: 0.1),
                backgroundImage: profile?.profileImage != null ? NetworkImage(profile!.profileImage!) : null,
                child: profile?.profileImage == null ? const Icon(Icons.person, size: 18, color: AppColors.amber) : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile?.name.toUpperCase() ?? 'PROFESSIONAL', 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Theme.of(context).colorScheme.onSurface)),
                  const Text('ENCRYPTED CHANNEL', 
                    style: TextStyle(fontSize: 8, color: Color(0xFF00FF7F), fontWeight: FontWeight.w900, letterSpacing: 1)),
                ],
              ),
            ],
          ),
          loading: () => const Text('SYNCHRONIZING...', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
          error: (_, __) => const Text('PEER OFFLINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
        ) ?? const Text('SECURE CHAT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
        actions: [
          if (widget.orderId != null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.amber.withValues(alpha: 0.3))),
              child: Center(child: Text('ORDER #${widget.orderId!.substring(0, 5)}', style: const TextStyle(color: AppColors.amber, fontSize: 8, fontWeight: FontWeight.w900))),
            ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  reverse: true, 
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    return ChatMessageBubble(message: message, isMe: isMe);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
              error: (err, _) => const ErrorStateWidget(message: 'Dossier sync failed.'),
            ),
          ),
          if (_isUploading) const LinearProgressIndicator(color: AppColors.amber, backgroundColor: Colors.transparent, minHeight: 2),
          _buildMessageInput(),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white38, size: 22),
              onPressed: _sendImage,
            ),
            IconButton(
              icon: const Icon(Icons.auto_fix_high_rounded, color: AppColors.amber, size: 22),
              onPressed: _openAiTryOn,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white.withValues(alpha: 0.03) 
                    : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'COMMAND...',
                    hintStyle: TextStyle(color: Colors.white12, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 48, height: 48,
                decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, color: AppColors.darkNavy, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAiTryOn() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiTryOnWidget(
        onGenerated: (url) {
          _sendAiImage(url);
        },
      ),
    );
  }

  void _sendAiImage(String url) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final message = ChatMessage(
      id: '',
      conversationId: widget.conversationId,
      senderId: user.id,
      content: url,
      timestamp: DateTime.now(),
      type: ChatMessageType.image,
      orderId: widget.orderId,
    );
    await ref.read(chatRepositoryProvider).sendMessage(message);
    ref.invalidate(chatMessagesProvider(widget.conversationId));
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final message = ChatMessage(
      id: '', 
      conversationId: widget.conversationId,
      senderId: user.id,
      content: content,
      timestamp: DateTime.now(),
      type: ChatMessageType.text,
      orderId: widget.orderId,
    );

    _messageController.clear();
    await ref.read(chatRepositoryProvider).sendMessage(message);
    ref.invalidate(chatMessagesProvider(widget.conversationId));
  }

  void _sendImage() async {
    final image = await _imageService.pickImageFromGallery();
    if (image == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      final url = await _imageService.uploadImage(image, user.id, 'chats');
      if (url != null) {
        final message = ChatMessage(
          id: '',
          conversationId: widget.conversationId,
          senderId: user.id,
          content: url,
          timestamp: DateTime.now(),
          type: ChatMessageType.image,
          orderId: widget.orderId,
        );
        await ref.read(chatRepositoryProvider).sendMessage(message);
        ref.invalidate(chatMessagesProvider(widget.conversationId));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const ChatMessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMe ? AppColors.amber.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          border: Border.all(color: isMe ? AppColors.amber.withValues(alpha: 0.2) : Colors.white10),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.type == ChatMessageType.image)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(message.content, fit: BoxFit.cover),
              )
            else
              Text(
                message.content,
                style: TextStyle(color: isMe ? Colors.white : Colors.white70, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.w900),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all_rounded, size: 10, color: message.isRead ? const Color(0xFF00FF7F) : Colors.white10),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
