import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import 'shell_scope.dart';

/// Builds the `appBar` for a page hosted either inside the Desby app shell or
/// as a standalone `Navigator` route.
///
/// Behaviour:
/// * **Inside the shell** the shell header already renders the page title and
///   the back/menu control, so this returns an `AppBar` without a title or
///   leading widget — or `null` when the page has nothing else to put in a bar
///   (actions/bottom), which also reclaims the vertical space the duplicate
///   header used to occupy.
/// * **Standalone** (named routes pushed outside the shell) it renders the
///   normal title + back button so the page remains usable on its own.
///
/// Usage:
/// ```dart
/// return Scaffold(
///   appBar: shellAppBar(context, title: 'My Shop', actions: [...]),
///   body: ...,
/// );
/// ```
PreferredSizeWidget? shellAppBar(
  BuildContext context, {
  String? title,
  Widget? titleWidget,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
  bool implyBackWhenStandalone = true,
  Color? backgroundColor,
  double elevation = 0,
  bool centerTitle = true,
  Color? foregroundColor,
  IconThemeData? iconTheme,
}) {
  final inShell = ShellScope.isInside(context);
  final hasOwnContent =
      titleWidget != null ||
      (actions != null && actions.isNotEmpty) ||
      bottom != null;

  // Inside the shell with nothing to contribute: the shell header owns the
  // chrome entirely — do not render an empty bar.
  if (inShell && !hasOwnContent) return null;

  final colors = context.colors;
  Widget? resolvedTitle;
  if (titleWidget != null) {
    // Custom contextual headers (avatars, breadcrumbs) stay visible in both
    // contexts — they are content, not a duplicate page title.
    resolvedTitle = titleWidget;
  } else if (!inShell && title != null) {
    resolvedTitle = Text(
      title,
      style: TextStyle(
        color: colors.appBarText,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }
  return AppBar(
    title: resolvedTitle,
    backgroundColor: backgroundColor ?? Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: elevation,
    centerTitle: centerTitle,
    automaticallyImplyLeading: false,
    leading: inShell
        ? null
        : (implyBackWhenStandalone
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.amber,
                    size: 20,
                  ),
                  onPressed: () {
                    final nav = Navigator.of(context);
                    if (nav.canPop()) {
                      nav.pop();
                    }
                  },
                )
              : null),
    actions: actions,
    bottom: bottom,
    foregroundColor: foregroundColor,
    iconTheme: iconTheme,
  );
}

/// Title widget helper for custom headers: renders nothing inside the shell.
Widget? shellTitle(BuildContext context, String title) {
  if (ShellScope.isInside(context)) return null;
  final colors = context.colors;
  return Text(
    title,
    style: TextStyle(
      color: colors.appBarText,
      fontSize: 12,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.5,
    ),
  );
}

/// Back control for custom sliver/inline bars: `null` inside the shell (the
/// shell header already owns the back/menu control), amber arrow otherwise.
Widget? shellLeading(BuildContext context, {VoidCallback? onBack}) {
  if (ShellScope.isInside(context)) return null;
  return IconButton(
    icon: const Icon(
      Icons.arrow_back_ios_new_rounded,
      color: AppColors.amber,
      size: 18,
    ),
    onPressed:
        onBack ??
        () {
          final nav = Navigator.of(context);
          if (nav.canPop()) nav.pop();
        },
  );
}
