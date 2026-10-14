import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import 'app_network_image.dart';

/// Circular user avatar that renders the uploaded profile photo when one
/// exists and falls back to the user's initial when no photo is available or
/// the stored URL is broken.
///
/// This is the single rendering path for avatars in navigation chrome (side
/// menu, header) so the upload → persist → render flow behaves the same
/// everywhere.
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.name,
    required this.radius,
    this.backgroundColor,
  });

  String get _initial {
    final trimmed = (name ?? '').trim();
    return trimmed.isEmpty ? 'U' : trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final url = resolveImageUrl(imageUrl);
    final hasImage = url.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.amber,
      // Clip the network image to the circle and drop to the initial letter
      // if the URL is invalid/missing instead of showing a broken image.
      child: hasImage
          ? ClipOval(
              child: SizedBox.expand(
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _initialText(colors),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return _initialText(colors);
                  },
                ),
              ),
            )
          : _initialText(colors),
    );
  }

  Widget _initialText(DesbyThemeColors colors) {
    return Center(
      child: Text(
        _initial,
        style: TextStyle(
          color: colors.textOnAmber,
          fontWeight: FontWeight.w900,
          fontSize: (radius * 0.8).clamp(8, 40),
        ),
      ),
    );
  }
}
