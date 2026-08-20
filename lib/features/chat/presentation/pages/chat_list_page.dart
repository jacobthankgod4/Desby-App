import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/error_state_widget.dart';

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: conversationsAsync.when(
        data: (conversations) => conversations.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 24),
                itemCount: conversations.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10, indent: 80),
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  final peerId = conversation.participantIds.firstWhere((id) => id != currentUserId);
                  return _ConversationTile(conversation: conversation, peerId: peerId);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
        error: (error, _) => const ErrorStateWidget(message: 'Dossier sync failed.'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_rounded, size: 80, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 24),
          const Text('SECURE CHANNEL EMPTY', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
        ],
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final dynamic conversation;
  final String peerId;

  const _ConversationTile({required this.conversation, required this.peerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peerProfile = ref.watch(userProfileProvider(peerId));

    return peerProfile.when(
      data: (profile) => ListTile(
        onTap: () {
          ref.pushShell(
            '/chat-detail',
            {
              'conversationId': conversation.id,
              'peerId': peerId,
              'orderId': conversation.orderId,
            },
          );
        },
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          backgroundImage: profile?.profileImage != null ? NetworkImage(profile!.profileImage!) : null,
          child: profile?.profileImage == null 
            ? Text(profile?.name[0].toUpperCase() ?? 'P', style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900)) 
            : null,
        ),
        title: Text(
          profile?.name.toUpperCase() ?? 'PROFESSIONAL',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
        ),
        subtitle: Text(
          conversation.lastMessage?.content ?? 'ENCRYPTED CHANNEL OPEN',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'SECURE', // Placeholder for calibrated timestamp
              style: TextStyle(fontSize: 8, color: Color(0xFF00FF7F), fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            if (conversation.unreadCount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${conversation.unreadCount}',
                  style: const TextStyle(color: AppColors.darkNavy, fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ],
        ),
      ),
      loading: () => const SizedBox(height: 80),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
