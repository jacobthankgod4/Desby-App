import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desby_app/theme/colors.dart';
import '../../../../core/services/whatsapp_service.dart';
import '../../domain/entities/client.dart';
import '../providers/client_provider.dart';

class InviteShareCard extends ConsumerStatefulWidget {
  final Client client;
  final VoidCallback? onInviteSent;

  const InviteShareCard({super.key, required this.client, this.onInviteSent});

  @override
  ConsumerState<InviteShareCard> createState() => _InviteShareCardState();
}

class _InviteShareCardState extends ConsumerState<InviteShareCard> {
  bool _isCopying = false;

  Color _statusColor(InviteStatus status) {
    switch (status) {
      case InviteStatus.pending:
        return Colors.amber;
      case InviteStatus.accepted:
        return AppColors.successGreen;
      case InviteStatus.expired:
        return AppColors.error;
      case InviteStatus.none:
        return context.colors.textMuted;
    }
  }

  String _statusLabel(InviteStatus status) {
    switch (status) {
      case InviteStatus.pending:
        return 'PENDING';
      case InviteStatus.accepted:
        return 'ACCEPTED';
      case InviteStatus.expired:
        return 'EXPIRED';
      case InviteStatus.none:
        return 'NOT SENT';
    }
  }

  IconData _statusIcon(InviteStatus status) {
    switch (status) {
      case InviteStatus.pending:
        return Icons.schedule_rounded;
      case InviteStatus.accepted:
        return Icons.check_circle_rounded;
      case InviteStatus.expired:
        return Icons.error_outline_rounded;
      case InviteStatus.none:
        return Icons.mail_outline_rounded;
    }
  }

  Future<void> _handleWhatsAppShare() async {
    if (widget.client.phone.isEmpty || widget.client.inviteUrl == null) return;

    final success = await WhatsAppService.sendInviteLink(
      phoneNumber: widget.client.phone,
      clientName: widget.client.name,
      inviteUrl: widget.client.inviteUrl!,
    );

    if (success && mounted) {
      final updatedClient = widget.client.copyWith(
        inviteStatus: InviteStatus.pending,
        inviteSentAt: DateTime.now(),
      );
      final result = await ref.read(updateClientUsecaseProvider)(updatedClient);
      result.fold(
        (failure) => debugPrint('Failed to update client: $failure'),
        (_) => ref.invalidate(clientsProvider),
      );

      // Create in-app notification for the client
      _createInviteNotification();

      widget.onInviteSent?.call();
    }
  }

  Future<void> _createInviteNotification() async {
    try {
      final tailorUser = Supabase.instance.client.auth.currentUser;
      if (tailorUser == null) return;

      // Find the client's user account by phone number
      final clientUser = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('phone', widget.client.phone)
          .maybeSingle();

      if (clientUser == null) return; // Client hasn't signed up yet

      final tailorName = tailorUser.userMetadata?['full_name'] as String? ?? 'Your tailor';

      await Supabase.instance.client.from('notifications').insert({
        'user_id': clientUser['id'],
        'type': 'clientInvite',
        'title': 'You have been invited!',
        'body': '$tailorName has invited you to complete your profile and measurements.',
        'data': {
          'invite_token': widget.client.inviteToken,
          'tailor_id': tailorUser.id,
          'tailor_name': tailorName,
        },
        'is_read': false,
      });
    } catch (e) {
      debugPrint('[INVITE] Failed to create notification: $e');
    }
  }

  Future<void> _handleCopyLink() async {
    if (widget.client.inviteUrl == null) return;

    setState(() => _isCopying = true);
    await WhatsAppService.copyLink(widget.client.inviteUrl!);
    if (mounted) {
      setState(() => _isCopying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard'),
          backgroundColor: AppColors.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final client = widget.client;
    final hasPhone = client.phone.isNotEmpty;
    final hasInvite = client.hasInvite;
    final status = client.inviteStatus;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.share_rounded,
                  color: AppColors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INVITE CLIENT',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Send measurements link to ${client.name}',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasInvite)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _statusColor(status).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(status),
                        color: _statusColor(status),
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _statusLabel(status),
                        style: TextStyle(
                          color: _statusColor(status),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (!hasInvite) ...[
            const SizedBox(height: 20),
            Text(
              'No invite sent yet. Share a link so the client can fill in their measurements.',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
          ],
          if (hasInvite && client.inviteUrl != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(Icons.link_rounded, color: colors.textMuted, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      client.inviteUrl!,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                        fontFamily: 'Monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'WHATSAPP',
                  icon: Icons.chat_rounded,
                  color: const Color(0xFF25D366),
                  enabled: hasPhone && hasInvite,
                  onTap: _handleWhatsAppShare,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: _isCopying ? 'COPIED!' : 'COPY LINK',
                  icon: _isCopying ? Icons.check_rounded : Icons.copy_rounded,
                  color: AppColors.amber,
                  enabled: hasInvite,
                  onTap: _handleCopyLink,
                ),
              ),
            ],
          ),
          if (!hasPhone)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.amber,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add a phone number to share via WhatsApp',
                      style: TextStyle(color: Colors.amber, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.15) : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled ? color.withValues(alpha: 0.3) : colors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: enabled ? color : colors.borderSubtle, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: enabled ? color : colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
