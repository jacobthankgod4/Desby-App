import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/luxury_glass_card.dart';

class InviteApprenticeModal extends StatelessWidget {
  const InviteApprenticeModal({super.key});

  @override
  Widget build(BuildContext context) {
    final String inviteCode = 'DESBY-ACAD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1921),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school_rounded, color: AppColors.amber, size: 24),
              SizedBox(width: 12),
              Text(
                'ACADEMY INVITATION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Onboard New Talent',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Generate a unique academy access code for your apprentice. They will gain immediate access to your curriculum and digital workspace.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          
          LuxuryGlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'UNIQUE ACCESS CODE',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  inviteCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied to clipboard')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('COPY CODE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Logic for sharing link
                          final link = 'https://desby.app/invite?code=$inviteCode';
                          Clipboard.setData(ClipboardData(text: link));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invite link copied')),
                          );
                        },
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('SHARE LINK'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amber,
                          foregroundColor: AppColors.darkNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white24, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Inviting an apprentice links them to your professional profile. Ensure they follow the Desby Academy guidelines.',
                  style: TextStyle(color: Colors.white24, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CLOSE SYSTEM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
