import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/app_config.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../checkout/presentation/providers/request_journey_feature.dart';
import '../../../../core/widgets/design_card_public.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../designs/domain/entities/design.dart';
import '../../../designs/presentation/providers/design_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class TailorProfilePage extends ConsumerWidget {
  final String tailorId;

  const TailorProfilePage({super.key, required this.tailorId});

  Future<void> _makeCall(BuildContext context, String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number listed'),
          backgroundColor: AppColors.amber,
        ),
      );
      return;
    }
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      final launched = await launchUrl(launchUri);
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: phoneNumber));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Number copied: $phoneNumber'),
              backgroundColor: AppColors.amber,
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: phoneNumber));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Number copied: $phoneNumber'),
            backgroundColor: AppColors.amber,
          ),
        );
      }
    }
  }

  Future<void> _getDirections(BuildContext context, String location) async {
    final query = Uri.encodeComponent(location);
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Map link copied'),
            backgroundColor: AppColors.amber,
          ),
        );
      }
    }
  }

  Future<void> _shareProfile(BuildContext context) async {
    final link = '${AppConfig.websiteUrl}/tailor/$tailorId';
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile link copied to clipboard'),
          backgroundColor: AppColors.amber,
        ),
      );
    }
  }

  Future<void> _startChat(BuildContext context, WidgetRef ref) async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    final repo = ref.read(chatRepositoryProvider);
    final result = await repo.createConversation([me.id, tailorId]);
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not load profile. Please try again.'),
          backgroundColor: context.colors.statusError,
        ),
      ),
      (conversation) => ref.pushShell('/chat-detail', {
        'conversationId': conversation.id,
        'peerId': tailorId,
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profileAsync = ref.watch(userProfileProvider(tailorId));
    final designsAsync = ref.watch(tailorDesignsProvider(tailorId));
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1000 ? 3 : (screenWidth > 600 ? 2 : 1);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text(
                'Tailor not found',
                style: TextStyle(color: colors.textPrimary),
              ),
            );
          }

          final List<String> services = profile.services ?? [];
          final fullName = profile.businessName?.isNotEmpty == true
              ? profile.businessName!
              : profile.name;
          final fullLocation = [
            profile.address,
            profile.lga,
            profile.state,
          ].whereType<String>().where((s) => s.isNotEmpty).join(', ');

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: colors.scaffoldBg,
                elevation: 0,
                toolbarHeight: 60,
                leading: const SizedBox.shrink(),
                title: shellTitle(context, 'TAILOR PROFILE'),
                actions: [
                  if (profile.isVerified)
                    const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Icon(
                        Icons.verified_rounded,
                        color: AppColors.amber,
                        size: 20,
                      ),
                    ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: _buildHeroCard(
                    context,
                    fullName,
                    fullLocation,
                    services.length,
                    designsAsync,
                    profile.profileImage,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      _actionButton(
                        context,
                        Icons.phone_rounded,
                        'Call',
                        () => _makeCall(context, profile.phone),
                      ),
                      _actionButton(
                        context,
                        Icons.near_me_rounded,
                        'Route',
                        () => _getDirections(
                          context,
                          fullLocation.isNotEmpty ? fullLocation : 'Nigeria',
                        ),
                      ),
                      _actionButton(
                        context,
                        Icons.chat_bubble_rounded,
                        'Chat',
                        () => _startChat(context, ref),
                      ),
                      _actionButton(
                        context,
                        Icons.ios_share_rounded,
                        'Share',
                        () => _shareProfile(context),
                      ),
                    ],
                  ),
                ),
              ),

              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                _sectionHeader(context, 'ABOUT'),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      profile.bio!,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                  ),
                ),
              ],

              if (services.isNotEmpty) ...[
                _sectionHeader(context, 'EXPERTISE'),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: services
                          .map(
                            (s) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accentSubtleFill,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: colors.accentSubtleBorder,
                                ),
                              ),
                              child: Text(
                                s.toUpperCase(),
                                style: TextStyle(
                                  color: colors.accentOnSubtleFill,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],

              if (profile.availableFabrics != null &&
                  profile.availableFabrics!.isNotEmpty) ...[
                _sectionHeader(context, 'FABRICS WE WORK WITH'),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.availableFabrics!
                          .map(
                            (f) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: colors.borderSubtle,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: colors.borderDefault),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],

              _sectionHeader(context, 'PORTFOLIO'),
              SliverToBoxAdapter(
                child: designsAsync.when(
                  data: (designs) => designs.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: colors.borderSubtle),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.checkroom_rounded,
                                  color: colors.accentOnSurface,
                                  size: 40,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'NO PUBLISHED PIECES YET',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.72,
                                ),
                            itemCount: designs.length,
                            itemBuilder: (context, index) {
                              final d = designs[index];
                              return DesignCardPublic(
                                design: d,
                                onTap: () => ref.pushShell('/design-details', {
                                  'design': d,
                                }),
                              );
                            },
                          ),
                        ),
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.amber),
                    ),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),

              if (services.isNotEmpty) ...[
                _sectionHeader(context, 'WHAT WE DO'),
                SliverToBoxAdapter(
                  child: designsAsync.when(
                    data: (designs) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: _servicesLayout(context, services, designs),
                    ),
                    // The curated photographs are bundled assets, so the cards
                    // render perfectly well without any live designs. Waiting on
                    // a network fetch here used to blank the whole section.
                    loading: () => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: _servicesLayout(context, services, const []),
                    ),
                    error: (_, _) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: _servicesLayout(context, services, const []),
                    ),
                  ),
                ),
              ],

              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (err, _) => Center(
          child: Text(
            'Fatal Sync Error: $err',
            style: TextStyle(color: context.colors.statusError),
          ),
        ),
      ),
      bottomSheet: _bottomAction(
        context,
        ref,
        (profileAsync.valueOrNull?.businessName?.isNotEmpty == true
                ? profileAsync.valueOrNull!.businessName
                : null) ??
            profileAsync.valueOrNull?.name ??
            'This Tailor',
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    String name,
    String location,
    int serviceCount,
    AsyncValue<List<Design>> designsAsync,
    String? avatarUrl,
  ) {
    final colors = context.colors;
    final productCount = designsAsync.valueOrNull?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        colors: [
          colors.surface,
          colors.surface,
          colors.accentSubtleFill,
        ],
        ),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: colors.accentSubtleFill,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: colors.accentOnSurface,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: colors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (productCount > 0 || serviceCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: colors.interactiveFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.interactiveBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (productCount > 0) ...[
                    _stat('$productCount', 'PIECES PUBLISHED', colors: colors),
                    if (serviceCount > 0) _divider(colors: colors),
                  ],
                  if (serviceCount > 0)
                    _stat('$serviceCount', 'SPECIALTIES', colors: colors),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.interactiveFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.interactiveBorder),
              ),
              child: Text(
                'NEW ON DESBY',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, {required DesbyThemeColors colors}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: colors.accentOnSurface,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            // 8.5pt was illegible; the wider letter-spacing made it worse.
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _divider({required DesbyThemeColors colors}) =>
      Container(width: 1, height: 26, color: colors.borderSubtle);

  Widget _actionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final colors = context.colors;
    return Expanded(
      child: Material(
        // A tap target, so it needs a ripple. GestureDetector gave no feedback
        // that the press registered at all.
        color: colors.interactiveFill,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.interactiveBorder),
            ),
            child: Column(
              children: [
                Icon(icon, color: colors.accentOnSurface, size: 22),
                const SizedBox(height: 7),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: colors.textSecondary,
                    // 9pt was below any readable floor on a phone.
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForService(String service) {
    final s = service.toLowerCase();
    if (s.contains('agbada') || s.contains('babariga'))
      return Icons.style_rounded;
    if (s.contains('suit') || s.contains('blazer') || s.contains('tuxedo'))
      return Icons.business_center_rounded;
    if (s.contains('gown') || s.contains('bridal') || s.contains('wedding'))
      return Icons.diamond_rounded;
    if (s.contains('kaftan') || s.contains('caftan') || s.contains('shirt'))
      return Icons.checkroom_rounded;
    if (s.contains('repair') || s.contains('alteration'))
      return Icons.build_rounded;
    if (s.contains('custom') || s.contains('bespoke'))
      return Icons.design_services_rounded;
    return Icons.auto_awesome_rounded;
  }

  String _descForService(String service) {
    final s = service.toLowerCase();
    if (s.contains('agbada') || s.contains('babariga')) {
      return 'Flowing three-piece grand boubous cut with precision embroidery and hand-finished detailing.';
    }
    if (s.contains('suit') || s.contains('blazer') || s.contains('tuxedo')) {
      return 'Structured canvassed suits tailored to your exact measurements \u2014 from business sharp to black-tie.';
    }
    if (s.contains('gown') || s.contains('bridal') || s.contains('wedding')) {
      return 'Occasion gowns with couture finishing, fitted across multiple sessions for a flawless silhouette.';
    }
    if (s.contains('kaftan') || s.contains('caftan') || s.contains('shirt')) {
      return 'Relaxed yet refined everyday pieces in premium cottons, linens and silks.';
    }
    if (s.contains('repair') || s.contains('alteration')) {
      return 'Expert restyling, resizing and repairs that restore garments to perfect fit.';
    }
    if (s.contains('ankara') ||
        s.contains('native') ||
        s.contains('traditional')) {
      return 'Contemporary native wear rooted in heritage fabrics and bold African prints.';
    }
    return 'Precision tailoring with premium finishing, made exactly to your measurements.';
  }

  Design? _findDesignForService(String service, List<Design> designs) {
    if (designs.isEmpty) return null;
    final s = service.toLowerCase();
    for (final d in designs) {
      final t = '${d.title} ${d.category}'.toLowerCase();
      if (s.contains('suit') && (t.contains('suit') || t.contains('executive')))
        return d;
      if (s.contains('agbada') ||
          s.contains('babariga') ||
          s.contains('traditional')) {
        if (t.contains('agbada') ||
            t.contains('babariga') ||
            t.contains('traditional') ||
            t.contains('senator'))
          return d;
      }
      if (s.contains('gown') || s.contains('bridal') || s.contains('wedding')) {
        if (t.contains('gown') || t.contains('bridal') || t.contains('aso oke'))
          return d;
      }
      if (s.contains('kaftan') || s.contains('shirt')) {
        if (t.contains('kaftan') || t.contains('shirt')) return d;
      }
      if (s.contains('ankara') || s.contains('native')) {
        if (t.contains('ankara') || t.contains('aso ebi')) return d;
      }
    }
    // Deliberately no "any design with an image" fallback. That is what made
    // every service card show the same photograph: dress making matched nothing,
    // fell back to the first design, and suits/bridal lost their own imagery.
    // A curated per-service photograph is a far better answer than an
    // unrelated picture of someone else's work.
    return null;
  }

  /// Curated bundled photograph for a service, used when the tailor has no
  /// live design photo for that service.
  String? _assetForService(String service) {
    final s = service.toLowerCase();
    if (s.contains('alter') || s.contains('repair') || s.contains('restyl')) {
      return 'assets/images/services/alterations.jpeg';
    }
    if (s.contains('bridal') || s.contains('wedding') || s.contains('gown')) {
      return 'assets/images/services/bridal.jpg';
    }
    if (s.contains('suit') || s.contains('tuxedo')) {
      return 'assets/images/services/suits.jpg';
    }
    if (s.contains('shirt')) return 'assets/images/services/shirts.webp';
    if (s.contains('corporate') ||
        s.contains('office') ||
        s.contains('blazer')) {
      return 'assets/images/services/corporate.jpg';
    }
    if (s.contains('dress') || s.contains('skirt') || s.contains('wrapper')) {
      return 'assets/images/services/dress_making.jpg';
    }
    if (s.contains('fabric') || s.contains('material')) {
      return 'assets/images/services/fabrics.jpeg';
    }
    if (s.contains('native') ||
        s.contains('ankara') ||
        s.contains('agbada') ||
        s.contains('traditional') ||
        s.contains('kaftan') ||
        s.contains('senator') ||
        s.contains('babariga')) {
      return 'assets/images/services/native_wear.webp';
    }
    return null;
  }

  /// Three service cards across on a phone, flowing rows on a wide screen.
  ///
  /// The brief asked for a 3-card grid on mobile. Equal thirds with the text
  /// beneath keeps each card legible instead of squeezing descriptions into a
  /// sliver the way a plain `Wrap` did.
  Widget _servicesLayout(
    BuildContext context,
    List<String> services,
    List<Design> designs,
  ) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    Widget card(String service) => _serviceCompactCard(
          context,
          service,
          _descForService(service),
          _findDesignForService(service, designs)?.imageUrls,
          fallbackAsset: _assetForService(service),
          compact: narrow,
        );

    if (!narrow) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: services.map(card).toList(),
      );
    }
    return Column(
      children: [
        for (var row = 0; row * 3 < services.length; row++) ...[
          if (row > 0) const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var col = 0; col < 3; col++) ...[
                  if (col > 0) const SizedBox(width: 8),
                  Expanded(
                    child: (row * 3 + col) < services.length
                        ? card(services[row * 3 + col])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _serviceCompactCard(
    BuildContext context,
    String title,
    String desc,
    List<String>? imageUrls, {
    String? fallbackAsset,
    bool compact = false,
  }) {
    final colors = context.colors;
    final matchedUrl = (imageUrls != null && imageUrls.isNotEmpty)
        ? imageUrls.first
        : null;
    final assetPath = fallbackAsset ?? _assetForService(title);
    final narrow = compact || MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: compact ? null : 210,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colors.surface,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: narrow ? 96 : 110,
            width: double.infinity,
            child: matchedUrl != null
                ? AppNetworkImage(
                    url: matchedUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    placeholderIcon: _iconForService(title),
                  )
                : assetPath != null
                ? Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('[SERVICE_ASSET] $assetPath failed: $error');
                      return _serviceFallbackImage(context);
                    },
                  )
                : _serviceFallbackImage(context),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    color: colors.textSecondary,
                    // 9.5pt descriptions were the worst offender: three lines of
                    // 9.5pt grey is not readable on a phone at arm's length.
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceFallbackImage(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.accentSubtleFill,
      alignment: Alignment.center,
      child: Icon(
        Icons.checkroom_rounded,
        color: colors.accentOnSurface,
        size: 28,
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final colors = context.colors;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 14),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.amber,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomAction(BuildContext context, WidgetRef ref, String tailorName) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: colors.scaffoldBg,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            // Scenario A: the client found a tailor but has NOT chosen a
            // design. There is nothing to check out yet, so the guided journey
            // opens by asking what they want made. The legacy chain opened on a
            // step that assumed a product had already been chosen.
            onPressed: () {
              if (RequestJourneyFeature.enabled) {
                ref.pushShell(requestJourneyRoute, tailorProfileJourneyArgs(
                  tailorId: tailorId,
                  tailorName: tailorName,
                ));
                return;
              }
              // Legacy chain, unchanged.
              ref.pushShell('/booking-cart', {
                'id': tailorId,
                'tailorId': tailorId,
                'name': tailorName,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: colors.scaffoldBg,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text(
              'BOOK APPOINTMENT',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
