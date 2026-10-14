import 'package:flutter/material.dart';

import '../../../../theme/colors.dart';

/// A soft-UI ("neomorphic") quick-action tile, shared by every role dashboard.
///
/// Why one shared widget: the four dashboards previously each grew their own
/// card, and only the tailor dashboard had a quick-action grid at all. Four
/// private `_OpTile`-alike implementations meant four sets of shadows, hover
/// easing and press feedback that drifted apart. This is the single tile, and
/// every role uses it.
///
/// Neomorphism: the surface matches the page background and is separated purely
/// by a light-from-above / dark-from-below shadow pair. That only reads as
/// relief when the fill and the page are the same colour, so the tile uses
/// `scaffoldBg` rather than `surface` (which is plain white and would just be a
/// flat card with shadows). A hairline border is kept at low opacity so the tile
/// still has an edge in high-contrast situations where soft shadows wash out.
///
/// Motion, in three independent layers so they compose rather than fight:
///   * entrance — staggered rise + fade, driven by [index]
///   * hover    — lift, deeper shadow, faint amber bloom
///   * press    — inset shadow + squeeze, the tactile "pushed into the page" cue
///
/// All three collapse to a static tile when `MediaQuery.disableAnimations` is
/// set, and the entrance never re-runs on rebuild.
class QuickActionTile extends StatefulWidget {
  const QuickActionTile({
    super.key,
    required this.label,
    required this.onTap,
    this.asset,
    this.icon,
    this.index = 0,
  }) : assert(
          asset != null || icon != null,
          'Provide asset or icon — a tile with neither renders as an empty box.',
        );

  /// Path to the illustration, when one exists for this action.
  final String? asset;

  /// Fallback glyph. Used until artwork is supplied for this action, so a new
  /// tile is never blocked on an image.
  final IconData? icon;

  final String label;
  final VoidCallback onTap;

  /// Position in the grid, used to stagger the entrance.
  final int index;

  @override
  State<QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<QuickActionTile>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  bool _imageFailed = false;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  /// Ease-out-cubic, matching the motion curve used elsewhere in the app.
  late final Animation<double> _ease = CurvedAnimation(
    parent: _entrance,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    if (_animationsDisabled) {
      // No animation available: the controller is never started and the build
      // below skips the AnimatedBuilder entirely, so the tile renders final.
    } else {
      // Stagger, but cap it so a long grid does not take seconds to appear.
      final delay = Duration(milliseconds: (widget.index.clamp(0, 8)) * 55);
      Future<void>.delayed(delay, () {
        if (mounted && !_entrance.isCompleted) _entrance.forward();
      });
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  bool get _animationsDisabled => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// Neumorphic shadow pair for the current interaction state.
  List<BoxShadow> _shadows(BuildContext context, {required bool inset}) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    // Neumorphism needs one shadow darker than the fill and one lighter. In
    // dark mode "lighter than the fill" is a white glow, not a white shadow.
    final depth = _hovered && !inset ? 1.0 : 0.0;

    final light = dark
        ? Colors.white.withValues(alpha: inset ? 0.0 : 0.045)
        : Colors.white.withValues(alpha: inset ? 0.0 : 0.95);
    final shade = dark
        ? Colors.black.withValues(alpha: inset ? 0.45 : 0.55)
        : const Color(0xFF94A3B8).withValues(alpha: inset ? 0.28 : 0.22 + 0.10 * depth);

    if (inset) {
      return <BoxShadow>[
        BoxShadow(
          color: shade,
          offset: const Offset(3, 3),
          blurRadius: 8,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: light,
          offset: const Offset(-3, -3),
          blurRadius: 8,
          spreadRadius: -2,
        ),
      ];
    }

    return <BoxShadow>[
      BoxShadow(
        color: shade,
        offset: Offset(5 + 3 * depth, 5 + 3 * depth),
        blurRadius: 14 + 8 * depth,
        spreadRadius: -4,
      ),
      BoxShadow(
        color: light,
        offset: Offset(-5 - 2 * depth, -5 - 2 * depth),
        blurRadius: 14 + 6 * depth,
        spreadRadius: -4,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(18);

    // Pressed inverts the shadow direction: light appears to come from below,
    // which is what makes a soft-UI control feel physically depressed.
    final inset = _pressed;

    Widget tile = AnimatedContainer(
      duration: _animationsDisabled
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        // Same colour as the page: relief comes from the shadows alone.
        color: dark ? colors.surfaceElevated : colors.scaffoldBg,
        borderRadius: radius,
        boxShadow: _shadows(context, inset: inset),
        border: Border.all(
          color: _hovered
              ? AppColors.amber.withValues(alpha: dark ? 0.34 : 0.42)
              : colors.borderSubtle.withValues(alpha: dark ? 0.6 : 0.9),
          width: _hovered ? 1.2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: _artwork(context)),
            const SizedBox(height: 8),
            AnimatedDefaultTextStyle(
              duration: _animationsDisabled
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              style: TextStyle(
                color: _hovered ? colors.textPrimary : colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
              child: Text(
                widget.label.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    // Press squeeze + hover lift.
    tile = AnimatedScale(
      scale: _animationsDisabled ? 1.0 : (_pressed ? 0.965 : (_hovered ? 1.015 : 1.0)),
      duration: _animationsDisabled ? Duration.zero : const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _animationsDisabled || !_hovered || _pressed
            ? Offset.zero
            : const Offset(0, -0.018),
        duration: _animationsDisabled ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: tile,
      ),
    );

    if (_animationsDisabled) return _withSemantics(tile);

    // Entrance: rise + fade + a small settle scale.
    return AnimatedBuilder(
      animation: _ease,
      builder: (context, child) {
        final t = _ease.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - t)),
            child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
          ),
        );
      },
      child: _withSemantics(tile),
    );
  }

  /// Illustration when supplied and loadable, otherwise the glyph badge.
  ///
  /// `errorBuilder` is not enough on its own: a missing asset resolves to an
  /// error the image widget reports asynchronously, so the icon is chosen from
  /// local state instead and the tile degrades to an icon without flashing.
  Widget _artwork(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    if (widget.asset != null && !_imageFailed) {
      return Image.asset(
        widget.asset!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stack) {
          // Flip state after the frame so it is not a setState during build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_imageFailed) setState(() => _imageFailed = true);
          });
          return const SizedBox.shrink();
        },
      );
    }

    // Icon fallback: a recessed well, mirroring the tile's own relief.
    return Container(
      constraints: const BoxConstraints(minWidth: 54, minHeight: 54),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark
            ? Colors.black.withValues(alpha: 0.22)
            : AppColors.amber.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.amber.withValues(alpha: dark ? 0.30 : 0.38),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: 0.45)
                : const Color(0xFF94A3B8).withValues(alpha: 0.22),
            offset: const Offset(2, 2),
            blurRadius: 6,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: dark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.9),
            offset: const Offset(-2, -2),
            blurRadius: 6,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Icon(
        widget.icon ?? Icons.circle_outlined,
        color: AppColors.amber,
        size: 26,
      ),
    );
  }

  Widget _withSemantics(Widget child) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (mounted && !_animationsDisabled) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (mounted && !_animationsDisabled) {
          setState(() {
            _hovered = false;
            _pressed = false;
          });
        }
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (mounted && !_animationsDisabled) setState(() => _pressed = true);
        },
        onTapUp: (_) {
          if (mounted && !_animationsDisabled) setState(() => _pressed = false);
        },
        onTapCancel: () {
          if (mounted && !_animationsDisabled) setState(() => _pressed = false);
        },
        onTap: widget.onTap,
        child: Semantics(
          button: true,
          label: widget.label,
          child: child,
        ),
      ),
    );
  }
}

/// Shared header for a quick-action grid, so the four dashboards stop
/// copy-pasting their own heading block.
class QuickActionsHeading extends StatelessWidget {
  const QuickActionsHeading({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      'QUICK ACTIONS',
      style: TextStyle(
        color: colors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }
}