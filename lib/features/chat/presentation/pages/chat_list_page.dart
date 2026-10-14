import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../../domain/entities/chat_message.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../apprenticeship/presentation/providers/apprenticeship_provider.dart';
import '../../../apprenticeship/domain/entities/apprenticeship.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/zoe_avatar.dart';

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id ?? '';
    final userType = ref.watch(currentUserProvider)?.userType ?? 'tailor';
    final isApprentice = userType == 'apprentice';

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: conversationsAsync.when(
        data: (conversations) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            if (isApprentice) ...[
              _buildMentorSection(context, ref, currentUserId),
              const SizedBox(height: 8),
            ],
            _buildZoeEntry(context, ref),
            if (conversations.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Text(
                  'CONVERSATIONS',
                  style: TextStyle(
                    color: colors.textHint,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              ...List.generate(conversations.length, (index) {
                final conversation = conversations[index];
                final peerId = conversation.participantIds.firstWhere(
                  (id) => id != currentUserId,
                  orElse: () => conversation.participantIds.first,
                );
                return Column(
                  children: [
                    _ConversationTile(
                      conversation: conversation,
                      peerId: peerId,
                    ),
                    if (index < conversations.length - 1)
                      Divider(color: colors.divider, indent: 80),
                  ],
                );
              }),
            ],
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (error, _) =>
            const ErrorStateWidget(message: 'Could not load messages.'),
      ),
    );
  }

  Widget _buildMentorSection(
    BuildContext context,
    WidgetRef ref,
    String apprenticeId,
  ) {
    final colors = context.colors;
    final apprenticeshipAsync = ref.watch(
      apprenticeApprenticeshipProvider(apprenticeId),
    );

    return apprenticeshipAsync.when(
      data: (apprenticeship) {
        if (apprenticeship == null) return const SizedBox();
        final tailorProfile = apprenticeship.tailorProfile;
        final tailorName = tailorProfile?.name ?? 'Your Tailor';
        final tailorAvatar = tailorProfile?.profileImage;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.amber.withValues(alpha: 0.12),
                AppColors.amber.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.25)),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: () => ref.pushShell('/mentors', {}),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.amber.withValues(alpha: 0.15),
                      backgroundImage: tailorAvatar != null
                          ? NetworkImage(tailorAvatar)
                          : null,
                      child: tailorAvatar == null
                          ? Text(
                              tailorName.isNotEmpty
                                  ? tailorName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: AppColors.amber,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                tailorName,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.successGreen.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'MENTOR',
                                  style: TextStyle(
                                    color: AppColors.successGreen,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            apprenticeship.status == ApprenticeshipStatus.active
                                ? 'Tap to view mentor profile'
                                : 'Academy enrollment: ${apprenticeship.status.name}',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: AppColors.amber.withValues(alpha: 0.7),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildZoeEntry(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.amber.withValues(alpha: 0.08),
            AppColors.amber.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => ref.pushShell('/zoe-chat', {}),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const ZoeAvatarSmall(size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ZOE',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'AI',
                              style: TextStyle(
                                color: AppColors.amber,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your personal AI fashion assistant',
                        style: TextStyle(color: colors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.amber.withValues(alpha: 0.7),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
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
    final colors = context.colors;
    final peerProfile = ref.watch(userProfileProvider(peerId));

    return peerProfile.when(
      data: (profile) => ListTile(
        onTap: () {
          ref.pushShell('/chat-detail', {
            'conversationId': conversation.id,
            'peerId': peerId,
            'orderId': conversation.orderId,
          });
        },
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: colors.surface,
          backgroundImage: profile?.profileImage != null
              ? NetworkImage(profile!.profileImage!)
              : null,
          child: profile?.profileImage == null
              ? Text(
                  (profile?.name ?? '').isNotEmpty
                      ? profile!.name[0].toUpperCase()
                      : 'P',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : null,
        ),
        title: Text(
          profile?.name ?? 'User',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
        subtitle: Text(
          _lastMessagePreview(conversation.lastMessage),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: colors.textMuted, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(conversation.lastMessage?.timestamp),
              style: TextStyle(
                fontSize: 9,
                color: colors.textMuted,
                fontWeight: FontWeight.w600,
              ),
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
                  style: TextStyle(
                    color: colors.textOnAmber,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      loading: () => const SizedBox(height: 80),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  String _lastMessagePreview(dynamic message) {
    if (message == null) return 'Start a conversation';
    if (message.type == ChatMessageType.image) return '[Photo]';
    final content = message.content;
    return content is String ? content : 'Start a conversation';
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
