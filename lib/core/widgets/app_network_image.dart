import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/colors.dart';

/// Normalises any stored image reference into an absolute, fetchable URL.
///
/// Accepts:
/// * full `https://` URLs (returned as-is after trimming),
/// * storage object paths such as `images/designs/x.jpg`,
/// * URLs missing the leading slash such as `/object/public/images/x.jpg`.
String resolveImageUrl(String? url) {
  if (url == null) return '';
  final trimmed = url.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  try {
    // `{project}/storage/v1`
    final storageBase = Supabase.instance.client.storage.url;
    if (trimmed.startsWith('/')) {
      return '$storageBase/object/public${trimmed.startsWith('/storage/')
          ? trimmed.replaceFirst('/storage', '')
          : trimmed}';
    }
    if (trimmed.startsWith('object/public/')) return '$storageBase/$trimmed';
    return '$storageBase/object/public/${trimmed.replaceFirst('/', '')}';
  } catch (_) {
    return trimmed;
  }
}

/// The app-wide network image.
///
/// Every remote image in Desby goes through this widget so that loading,
/// missing and failed images behave consistently:
///
/// * **loading** — a neutral skeleton (never a fake photo),
/// * **empty / missing URL** — a muted icon placeholder,
/// * **failed** — the same muted placeholder plus a `debugPrint` trace so a
///   broken image pipeline is visible in logs instead of failing silently.
///
/// This intentionally does *not* invent fallback imagery: it only distinguishes
/// "not loaded yet", "no image exists" and "image failed to load".
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final IconData placeholderIcon;
  final BorderRadius? borderRadius;
  final FilterQuality filterQuality;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.placeholderIcon = Icons.image_outlined,
    this.borderRadius,
    this.filterQuality = FilterQuality.high,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resolved = resolveImageUrl(url);

    final Widget placeholder = Center(
      child: Icon(placeholderIcon, color: colors.iconMuted, size: 32),
    );

    if (resolved.isEmpty) {
      return _sized(_filled(placeholder, colors), colors);
    }

    final image = Image.network(
      resolved,
      fit: fit,
      alignment: alignment,
      width: width,
      height: height,
      filterQuality: filterQuality,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _filled(const SizedBox.shrink(), colors);
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[AppNetworkImage] failed to load "$resolved": $error');
        return _filled(placeholder, colors);
      },
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _filled(Widget child, DesbyThemeColors colors) =>
      Container(width: width, height: height, color: colors.surface, child: child);

  Widget _sized(Widget child, DesbyThemeColors colors) =>
      SizedBox(width: width, height: height, child: child);
}
