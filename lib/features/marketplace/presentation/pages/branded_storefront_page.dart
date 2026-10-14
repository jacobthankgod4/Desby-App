import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../theme/colors.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class BrandedStorefrontPage extends ConsumerStatefulWidget {
  const BrandedStorefrontPage({super.key});

  @override
  ConsumerState<BrandedStorefrontPage> createState() =>
      _BrandedStorefrontPageState();
}

class _BrandedStorefrontPageState extends ConsumerState<BrandedStorefrontPage> {
  String? _bannerUrl;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  void _loadImages() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final profileAsync = ref.read(userProfileProvider(user.id));
    final profile = profileAsync.valueOrNull;
    if (profile?.metadata != null) {
      _bannerUrl = profile!.metadata!['storefront_banner'];
      _logoUrl = profile.metadata!['storefront_logo'];
    }
  }

  Future<void> _pickImage({required bool isBanner}) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: isBanner ? 1200 : 400,
      imageQuality: 85,
    );
    if (file == null) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final path =
          'storefront/${user.id}/${isBanner ? "banner" : "logo"}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await file.readAsBytes();
      await Supabase.instance.client.storage
          .from('profiles')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = Supabase.instance.client.storage
          .from('profiles')
          .getPublicUrl(path);

      setState(() {
        if (isBanner) {
          _bannerUrl = url;
        } else {
          _logoUrl = url;
        }
      });

      // Save to profile metadata
      final profileAsync = ref.read(userProfileProvider(user.id));
      final profile = profileAsync.valueOrNull;
      if (profile != null) {
        final updatedMeta = Map<String, dynamic>.from(profile.metadata ?? {});
        if (isBanner) {
          updatedMeta['storefront_banner'] = url;
        } else {
          updatedMeta['storefront_logo'] = url;
        }
        final updated = profile.copyWith(metadata: updatedMeta);
        await ref.read(updateProfileUsecaseProvider)(updated);
        ref.invalidate(userProfileProvider(user.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'MY STOREFRONT',
        foregroundColor: colors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Customize how your shop looks to buyers in the marketplace.',
            style: TextStyle(
              fontSize: 13,
              color: colors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Banner
          Text(
            'BANNER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickImage(isBanner: true),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? colors.surface : colors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                image: _bannerUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_bannerUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _bannerUrl == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_camera_outlined,
                          size: 32,
                          color: colors.textHint,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to upload banner',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                        Text(
                          '1200 x 400 recommended',
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textHint,
                          ),
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Change',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Logo
          Text(
            'LOGO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickImage(isBanner: false),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? colors.surface : colors.surfaceAlt,
                shape: BoxShape.circle,
                image: _logoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_logoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _logoUrl == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 24,
                          color: colors.textHint,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Logo',
                          style: TextStyle(
                            fontSize: 9,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 12,
                          color: colors.textOnAmber,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),

          // Preview
          Text(
            'PREVIEW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? colors.surface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Column(
              children: [
                if (_bannerUrl != null)
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      image: DecorationImage(
                        image: NetworkImage(_bannerUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: colors.borderDefault,
                        backgroundImage: _logoUrl != null
                            ? NetworkImage(_logoUrl!)
                            : null,
                        child: _logoUrl == null
                            ? Icon(Icons.store, color: colors.textHint)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Shop Name',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Verified Seller',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.amber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
