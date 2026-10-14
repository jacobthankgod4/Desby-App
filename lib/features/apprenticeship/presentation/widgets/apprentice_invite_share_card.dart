import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/whatsapp_service.dart';
import '../../../../theme/colors.dart';
import '../../domain/entities/apprenticeship.dart';
import '../../../clients/domain/entities/client.dart' show InviteStatus;

class ApprenticeInviteShareCard extends ConsumerStatefulWidget {
  final Apprenticeship apprenticeship;
  final VoidCallback? onInviteSent;

  const ApprenticeInviteShareCard({
    super.key,
    required this.apprenticeship,
    this.onInviteSent,
  });

  @override
  ConsumerState<ApprenticeInviteShareCard> createState() =>
      _ApprenticeInviteShareCardState();
}

class _ApprenticeInviteShareCardState
    extends ConsumerState<ApprenticeInviteShareCard> {
  bool _isCopying = false;

  Color _statusColor(DesbyThemeColors colors, InviteStatus status) {
    switch (status) {
      case InviteStatus.pending:
        return Colors.amber;
      case InviteStatus.accepted:
        return AppColors.successGreen;
      case InviteStatus.expired:
        return AppColors.error;
      case InviteStatus.none:
        return colors.textMuted;
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
    final phone = widget.apprenticeship.apprenticePhone ?? '';
    final url = widget.apprenticeship.inviteUrl;
    if (phone.isEmpty || url == null) return;

    await WhatsAppService.sendInviteLink(
      phoneNumber: phone,
      clientName: widget.apprenticeship.apprenticeName ?? 'Apprentice',
      inviteUrl: url,
    );
    widget.onInviteSent?.call();
  }

  Future<void> _handleCopyLink() async {
    final url = widget.apprenticeship.inviteUrl;
    if (url == null) return;

    setState(() => _isCopying = true);
    await WhatsAppService.copyLink(url);
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
    final apprenticeship = widget.apprenticeship;
    final phone = apprenticeship.apprenticePhone ?? '';
    final hasPhone = phone.isNotEmpty;
    final hasInvite = apprenticeship.hasInvite;
    final status = apprenticeship.inviteStatus;
    final name = apprenticeship.apprenticeName ?? 'Apprentice';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderSubtle),
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
                  Icons.school_rounded,
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
                      'INVITE APPRENTICE',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Send onboarding link to $name',
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
                    color: _statusColor(colors, status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _statusColor(colors, status).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(status),
                        color: _statusColor(colors, status),
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _statusLabel(status),
                        style: TextStyle(
                          color: _statusColor(colors, status),
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
              'No invite sent yet. Share a link so the apprentice can complete their onboarding.',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
          ],
          if (hasInvite && apprenticeship.inviteUrl != null) ...[
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
                   Icon(
                    Icons.link_rounded,
                    color: colors.textMuted,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      apprenticeship.inviteUrl!,
                      style: TextStyle(
                        color: colors.textMuted,
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
                  colors: colors,
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
                  colors: colors,
                  label: _isCopying ? 'Copied!' : 'Copy Link',
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
                  const Expanded(
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
    required DesbyThemeColors colors,
    required String label,
    required IconData icon,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.15)
              : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled
                ? color.withValues(alpha: 0.3)
                : colors.borderSubtle,
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
