import 'package:flutter/material.dart';

/// Marks the subtree hosted inside the Desby app shell
/// (`DesktopDashboardShell`).
///
/// The shell renders the page title, back/menu navigation and global header
/// actions for every route it hosts. Pages mounted inside the shell must NOT
/// render their own title or leading navigation — that is what caused
/// duplicate headings (e.g. "My Shop" appearing twice).
///
/// The same page widget can also be pushed as a standalone `Navigator` route
/// (see `lib/main.dart` routes table), where no shell header exists. In that
/// context the page has to render its own title and back button.
///
/// Use [ShellScope.isInside] to branch, or [shellAppBar] which handles the
/// branching for the common case.
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required Widget child, this.inShell = true})
    : super(child: child);

  /// Whether the subtree is hosted by the app shell.
  final bool inShell;

  /// Returns true when the nearest shell ancestor is present.
  ///
  /// Falls back to `inShell` semantics: pages rendered through
  /// `MainPage`/`DesktopDashboardShell` return true, standalone routes false.
  static bool isInside(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ShellScope>();
    return scope?.inShell ?? false;
  }

  @override
  bool updateShouldNotify(ShellScope oldWidget) =>
      oldWidget.inShell != inShell;
}
