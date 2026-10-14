import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/referral_repository.dart';
import '../../../../core/widgets/shell_app_bar.dart';

final referralRepoProvider = Provider((ref) => ReferralRepository());

final referralStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {'total': 0, 'used': 0};
  return ref.read(referralRepoProvider).getStats(user.id);
});

class ReferralsPage extends ConsumerStatefulWidget {
  const ReferralsPage({super.key});

  @override
  ConsumerState<ReferralsPage> createState() => _ReferralsPageState();
}

class _ReferralsPageState extends ConsumerState<ReferralsPage> {
  String? _referralCode;
  bool _isApplying = false;
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCode();
  }

  Future<void> _loadCode() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final code = await ref.read(referralRepoProvider).generateCode(user.id);
    if (!mounted) return;
    setState(() => _referralCode = code);
  }

  Future<void> _applyCode() async {
    if (_codeController.text.isEmpty) return;
    if (!mounted) return;
    setState(() => _isApplying = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final success = await ref
        .read(referralRepoProvider)
        .applyReferral(_codeController.text.toUpperCase(), user.id);

    if (!mounted) return;
    setState(() => _isApplying = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Referral applied! Both you and your friend get 30 extra days.'
              : 'Invalid or already used referral code',
        ),
        backgroundColor: success ? AppColors.successGreen : Colors.redAccent,
      ),
    );
    if (success) ref.invalidate(referralStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statsAsync = ref.watch(referralStatsProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'INVITE FRIENDS',
        foregroundColor: colors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Hero
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.amber.withValues(alpha: 0.15),
                  AppColors.darkNavy.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('🎁', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'Give 30 days, get 30 days',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share your referral code with friends. When they sign up, you both get 30 extra days of Pro.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Your code
          Text(
            'YOUR CODE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _referralCode ?? '...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: AppColors.amber,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_referralCode != null) {
                      Clipboard.setData(ClipboardData(text: _referralCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy, color: AppColors.amber),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats
          statsAsync.when(
            data: (stats) => Row(
              children: [
                _StatCard(
                  label: 'Shared',
                  value: '${stats['total']}',
                  colors: colors,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Joined',
                  value: '${stats['used']}',
                  colors: colors,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Days Earned',
                  value: '${(stats['used'] ?? 0) * 30}',
                  colors: colors,
                ),
              ],
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 32),

          // Apply code
          Text(
            'HAVE A CODE?',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter referral code',
                    hintStyle: TextStyle(color: colors.textHint),
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.borderDefault),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.borderDefault),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isApplying ? null : _applyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: colors.textOnAmber,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isApplying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'APPLY',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final dynamic colors;
  const _StatCard({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderDefault),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.amber,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
