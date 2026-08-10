import 'package:flutter/material.dart';

/// Responsive utilities for Tailor Finder pages
/// Provides responsive breakpoints, adaptive layouts, and accessibility helpers

/// Breakpoint constants - aligned with Material Design guidelines
class TailorFinderBreakpoints {
  TailorFinderBreakpoints._();

  // ATOMIC FIX: Low thresholds to account for sidebar + padding
  static const double mobile = 300.0;
  static const double tablet = 500.0;  
  static const double desktop = 700.0;
  static const double wide = 1000.0;
}

/// Responsive responsive wrapper
class TailorFinderResponsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  final Widget? wide;
  final bool forceDesktop; // NEW: Override for large screens

  const TailorFinderResponsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.wide,
    this.forceDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    if (forceDesktop) return desktop;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        if (width >= TailorFinderBreakpoints.wide && wide != null) {
          return wide!;
        } else if (width >= TailorFinderBreakpoints.desktop) {
          return desktop;
        } else if (width >= TailorFinderBreakpoints.tablet && tablet != null) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Adaptive layout helpers
class TailorFinderLayout {
  TailorFinderLayout._();

  // Map aspect ratios (mobile vs desktop)
  static const double mobileMapAspect = 0.55; // 55% height for map on mobile - reduced for more sheet space
  static const double desktopMapWidth = 0.55; // 55% width for map on desktop
  
  // Panel widths (fraction of total width)
  static const double desktopPanelMin = 280.0;
  static const double desktopPanelMax = 400.0;
  
  // Paddings
  static const double mobilePadding = 16.0;
  static const double desktopPadding = 24.0;
  
// Bottom sheet sizes (fraction of screen height)
  // FIX #2: Reduced max from 0.85 to 0.78 to prevent bottom overflow (3.4px):
  // accounts for: mobile nav bar (80px+34px) + CTA button (100px+34px) + safe area
  static const double sheetMin = 0.15;
  static const double sheetMedium = 0.35;
  static const double sheetMax = 0.78;
  
// Mobile-specific adjustments
  static const double mobileSheetInitial = 0.35;
  static const double mobileSheetMin = 0.20;
  // FIX: Reduced from 0.85 to 0.75 to prevent bottom overflow
  // Must leave space for: nav bar (~80px) + CTA button (~60px) + safe area (~34px) ≈ 174px
  // On a typical 844px phone: 174/844 ≈ 0.206, so use 0.75 for max (leaving ~21% free)
  static const double mobileSheetMax = 0.75;
  
  // Safe area padding for bottom elements (calculated dynamically in widget)
  static const double navBarHeight = 80.0;
  static const double ctaButtonHeight = 60.0;
  static const double bottomPadding = 20.0;
}

/// Loading shimmer for Tailor Finder
class TailorFinderShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const TailorFinderShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  State<TailorFinderShimmer> createState() => _TailorFinderShimmerState();
}

class _TailorFinderShimmerState extends State<TailorFinderShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Tailor list shimmer loading placeholder
class TailorListShimmer extends StatelessWidget {
  final int itemCount;

  const TailorListShimmer({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const TailorFinderShimmer(width: 56, height: 56, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TailorFinderShimmer(
                      width: double.infinity,
                      height: 16,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 8),
                    const TailorFinderShimmer(
                      width: 120,
                      height: 12,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Map loading placeholder
class MapShimmer extends StatelessWidget {
  final double aspectRatio;

  const MapShimmer({super.key, this.aspectRatio = 1.5});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

/// Semantic labels for accessibility (WCAG AA compliant)
class TailorFinderSemantics {
  TailorFinderSemantics._();

  // Tailor card labels
  static const String tailorCardLabel = 'Tailor profile card';
  static const String ratingLabel = 'Rating out of 5 stars';
  static const String reviewsLabel = 'reviews';
  static const String distanceLabel = 'distance from you';
  static const String availableLabel = 'Currently available';
  static const String unavailableLabel = 'Currently unavailable';
  static const String priceLabel = 'Starting price';
  static const String serviceLabel = 'Service type';

  // Action labels
  static const String bookButtonLabel = 'Book consultation with';
  static const String saveButtonLabel = 'Save quote for later';
  static const String scheduleLabel = 'Schedule appointment';
  static const String viewProfileLabel = 'View full profile of';

  // Navigation labels
  static const String mapLabel = 'Interactive map showing tailor locations';
  static const String filterLabel = 'Filter results';
  static const String searchLabel = 'Search for tailors';

  // Sheet labels
  static const String serviceSelectionLabel = 'Service type selection';
  static const String quoteLabel = 'Price quote details';
}

/// Contrast-safe colors (WCAG AA compliant - 4.5:1 ratio)
class TailorFinderContrast {
  TailorFinderContrast._();

  // Primary text (dark on light) - meets 4.5:1
  static const Color textPrimary = Color(0xFF1A1A1A); // #1A1A1A passes
  
  // Secondary text - meets 4.5:1  
  static const Color textSecondary = Color(0xFF4A4A4A);
  
  // Button text - meets 4.5:1
  static const Color buttonText = Color(0xFF0A0A0A);
  
  // Disabled text - below threshold is OK (3:1 minimum)
  static const Color disabled = Color(0xFF9E9E9E);
  
  // Required asterisk for forms
  static const Color required = Color(0xFFD32F2F);
}
