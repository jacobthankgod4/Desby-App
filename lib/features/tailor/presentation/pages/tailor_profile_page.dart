import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/shop_provider.dart';

class TailorProfilePage extends ConsumerWidget {
  final String tailorId;
  final Map<String, dynamic>? initialData;

  const TailorProfilePage({
    super.key, 
    required this.tailorId, 
    this.initialData,
  });

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _getDirections(String location) async {
    final query = Uri.encodeComponent(location);
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(tailorId));
    final productsAsync = ref.watch(shopProductsProvider(tailorId));

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Tailor not found', style: TextStyle(color: Colors.white)));
          }

          final List<String> services = profile.services ?? [];
          
          return CustomScrollView(
            slivers: [
              // 1. ATELIER HEADER
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.darkNavy,
                elevation: 0,
                toolbarHeight: 60,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text('TAILOR PROFILE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.8)),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(10),
                  child: Container(height: 10, color: AppColors.amber),
                ),
              ),

              // 2. HERO CARD
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildProfileHeroCard(profile.name, profile.address, 4.9), // Rating placeholder
                ),
              ),

              // 3. ACTION RIBBON
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLargeSquareShortcut(Icons.phone_rounded, 'Call', () => _makeCall(profile.phone ?? '+234 800 000 0000')),
                      _buildLargeSquareShortcut(Icons.near_me_rounded, 'Route', () => _getDirections(profile.address ?? 'Nigeria')),
                      _buildLargeSquareShortcut(Icons.chat_bubble_rounded, 'Chat', () {}),
                      _buildLargeSquareShortcut(Icons.ios_share_rounded, 'Share', () {}),
                    ],
                  ),
                ),
              ),

              // 4. VIRTUAL ATELIER SHOP
              _buildSectionHeader('TAILOR SHOP'),
              SliverToBoxAdapter(
                child: productsAsync.when(
                  data: (products) => products.isEmpty 
                    ? const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('SHOP EMPTY', style: TextStyle(color: Colors.white12, fontWeight: FontWeight.w900)))
                    : SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: products.length,
                          itemBuilder: (context, index) => _buildShopProductCard(context, products[index], ref),
                        ),
                      ),
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
                  error: (err, _) => Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text('SYNC ERROR: $err', style: const TextStyle(color: Colors.redAccent, fontSize: 10))),
                ),
              ),

              // 5. MASTERED SERVICES
              _buildSectionHeader('SERVICES'),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: services.isEmpty
                    ? const Text('CRAFT DETAILS', style: TextStyle(color: Colors.white12, fontWeight: FontWeight.w900))
                    : Column(
                        children: services.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildServiceItem(Icons.auto_awesome_rounded, s, 'Professionally executed precision tailoring for this category.'),
                        )).toList(),
                      ),
                ),
              ),

              // 6. QUICK LINKS
              _buildSectionHeader('RESOURCES'),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: Colors.white.withValues(alpha: 0.03),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGlassLink('AVAILABLE FABRICS', () {}),
                        const SizedBox(height: 12),
                        _buildGlassLink('MEASUREMENT STATION', () => ref.pushShell('/measurements-input')),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
        error: (err, _) => Center(child: Text('Fatal Sync Error: $err', style: const TextStyle(color: Colors.redAccent))),
      ),
      bottomSheet: _buildBottomAction(context, ref),
    );
  }

  Widget _buildProfileHeroCard(String name, String? location, double rating) {
    return Container(
      height: 270,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF141414), Color(0xFF282828), Color(0xFF6B4A12)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PROFILE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.2)),
          const SizedBox(height: 12),
          Text(
            name.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, height: 1.0, letterSpacing: -1),
          ),
          const SizedBox(height: 8),
          Text(location ?? 'LAGOS, NIGERIA', style: const TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RATING: $rating', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.4), width: 4),
                  color: Colors.white10,
                ),
                child: Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.amber, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeSquareShortcut(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.amber,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.darkNavy, size: 24),
              const SizedBox(height: 8),
              Text(label.toUpperCase(), style: const TextStyle(color: AppColors.darkNavy, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopProductCard(BuildContext context, dynamic product, WidgetRef ref) {
    final String name = product.name;
    final String price = '₦${product.price.toInt()}';
    final String? image = product.imageUrls.isNotEmpty ? product.imageUrls.first : null;

    return GestureDetector(
      onTap: () => ref.pushShell('/product-details', {'product': product}),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: image != null 
                  ? ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.network(image, fit: BoxFit.cover))
                  : Center(child: Icon(Icons.checkroom_rounded, color: AppColors.amber.withValues(alpha: 0.1), size: 60)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5), maxLines: 1),
                  Text(price, style: const TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String title, String desc) {
    return Row(
      children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.amber, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              Text(desc, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassLink(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.darkNavy,
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () => ref.pushShell('/booking-cart', {'tailorId': tailorId}),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('BOOK APPOINTMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.0)),
          ),
        ),
      ),
    );
  }
}
