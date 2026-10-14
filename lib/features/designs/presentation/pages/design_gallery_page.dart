import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../theme/colors.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/layout_provider.dart';
import '../../domain/entities/design.dart';
import '../providers/design_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/shell_scope.dart';

class DesignGalleryPage extends ConsumerStatefulWidget {
  const DesignGalleryPage({super.key});

  @override
  ConsumerState<DesignGalleryPage> createState() => _DesignGalleryPageState();
}

class _DesignGalleryPageState extends ConsumerState<DesignGalleryPage> {
  String _selectedCategory = 'ALL';
  String _searchQuery = '';

  static const List<String> _categories = [
    'ALL',
    'AGBADA',
    'DRESS',
    'GOWN',
    'ANKARA',
    'ASO EBI',
    'SUITS',
    'KAFTAN',
    'SENATOR',
    'BABARIGA',
    'JEAN',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDesktop = ref.watch(isDesktopProvider);
    final category = _selectedCategory == 'ALL' ? null : _selectedCategory;
    final designsAsync = ref.watch(designListProvider(category));

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: (isDesktop || ShellScope.isInside(context))
          ? null
          : AppBar(
              title: Text(
                'DESIGN PORTFOLIO',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.amber,
                  size: 18,
                ),
                onPressed: () => ref.popShell(),
              ),
            ),
      body: Column(
        children: [
          if (!isDesktop) _buildSearchBar(),
          _buildCategoryTabs(),
          Expanded(
            child: designsAsync.when(
              data: (designs) {
                final filtered = _applySearch(designs);
                if (filtered.isEmpty) return _buildEmptyState();
                return _buildDesignGrid(filtered, isDesktop);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.amber),
              ),
              error: (_, _) => _buildEmptyState(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ref.pushShell('/design-upload'),
        backgroundColor: AppColors.amber,
        foregroundColor: AppColors.darkNavy,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text(
          'UPLOAD',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ),
    );
  }

  List<Design> _applySearch(List<Design> designs) {
    if (_searchQuery.isEmpty) return designs;
    final q = _searchQuery.toLowerCase();
    return designs
        .where(
          (d) =>
              d.title.toLowerCase().contains(q) ||
              d.category.toLowerCase().contains(q) ||
              d.tailorName.toLowerCase().contains(q),
        )
        .toList();
  }

  Widget _buildSearchBar() {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(color: colors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search designs, fabrics, styles...',
          hintStyle: TextStyle(color: colors.textMuted),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colors.textMuted,
            size: 20,
          ),
          filled: true,
          fillColor: colors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          final colors = context.colors;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.amber : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? null : Border.all(color: colors.divider),
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? AppColors.darkNavy : colors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesignGrid(List<Design> designs, bool isDesktop) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 1400;
    final crossAxisCount = isWide
        ? 5
        : width >= 1100
            ? 4
            : width >= 820
                ? 3
                : width >= 560
                    ? 2
                    : 1;

    return GridView.builder(
      padding: EdgeInsets.all(isDesktop ? 24 : 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: isWide ? 14 : 16,
        crossAxisSpacing: isWide ? 14 : 16,
        childAspectRatio: isWide ? 0.74 : 0.72,
      ),
      itemCount: designs.length,
      itemBuilder: (context, index) => _DesignCard(
        design: designs[index],
        onTap: () => _onDesignTap(designs[index]),
        onBook: () => _onBookDesign(designs[index]),
        onLike: () => _onLikeDesign(designs[index]),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.palette_outlined, color: colors.textMuted, size: 64),
          const SizedBox(height: 16),
          Text(
            'No designs found',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Designs will appear here once tailors upload them.',
            style: TextStyle(color: colors.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _onDesignTap(Design design) {
    ref.pushShell('/design-details', {'design': design, 'origin': 'shop'});
  }

  void _onBookDesign(Design design) {
    ref.pushShell('/booking-cart', {
      'id': design.tailorId,
      'tailorId': design.tailorId,
      'name': design.tailorName,
      'designId': design.id,
      'designTitle': design.title,
      'designPrice': design.price,
    });
  }

  void _onLikeDesign(Design design) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(designRepositoryProvider).toggleLike(design.id, user.id);
    ref.invalidate(likedDesignIdsProvider);
  }
}

class _DesignCard extends ConsumerWidget {
  final Design design;
  final VoidCallback onTap;
  final VoidCallback onBook;
  final VoidCallback onLike;

  const _DesignCard({
    required this.design,
    required this.onTap,
    required this.onBook,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            design.imageUrls.isNotEmpty
                ? AppNetworkImage(
                    url: design.imageUrls.first,
                    fit: BoxFit.cover,
                  )
                : _buildPlaceholder(context),
            // Contrast treatment so overlay text stays readable on any image
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66000000),
                    Color(0x1A000000),
                    Color(0xE6000000),
                  ],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
            // Category chip — top left
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  design.category.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.darkNavy,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            // Likes — top right
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onLike,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: colors.statusError.withValues(alpha: 0.9),
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${design.likesCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Metadata rail — bottom
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    design.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 6),
                      ],
                    ),
                  ),
                  if (design.description != null &&
                      design.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      design.description!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 10,
                        height: 1.3,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 6),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '₦${_formatPrice(design.price)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.amber,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 6),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          onPressed: onBook,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.darkNavy,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'GET THIS MADE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.surface,
      child: Center(
        child: Icon(Icons.checkroom_rounded, color: colors.textMuted, size: 48),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return NumberFormat('#,##0').format(price.toInt());
    }
    return price.toInt().toString();
  }
}
