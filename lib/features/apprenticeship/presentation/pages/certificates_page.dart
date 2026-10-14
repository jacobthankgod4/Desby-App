import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/certificate.dart';
import '../providers/certificate_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class CertificatesPage extends ConsumerWidget {
  const CertificatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final certsAsync = ref.watch(certificatesProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'MY CERTIFICATES',
        foregroundColor: colors.textPrimary,
      ),
      body: certsAsync.when(
        data: (certs) {
          if (certs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 64,
                    color: colors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No certificates yet',
                    style: TextStyle(color: colors.textHint, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete a skill level to earn your certificate',
                    style: TextStyle(color: colors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: certs.length,
            itemBuilder: (_, i) => _CertificateCard(cert: certs[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Could not load certificates')),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final Certificate cert;
  const _CertificateCard({required this.cert});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'CERTIFICATE OF COMPLETION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: const Color(0xFFFFD700),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This is to certify that',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            cert.apprenticeName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'has successfully completed the',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            cert.level.toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.amber,
              letterSpacing: 1,
            ),
          ),
          Text(
            'training level',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: colors.borderDefault),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MENTOR',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cert.tailorName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'DATE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cert.completedAt.day}/${cert.completedAt.month}/${cert.completedAt.year}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            cert.certificateNumber,
            style: TextStyle(
              fontSize: 10,
              color: colors.textHint,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
