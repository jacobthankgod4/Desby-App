import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/features/dashboard/presentation/widgets/desktop_dashboard_shell.dart';
import 'package:desby_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:desby_app/core/config/nav_config.dart';
import 'package:desby_app/core/providers/layout_provider.dart';

class DesktopShellWrapper extends ConsumerWidget {
  final Widget child;
  final String title;
  final int selectedIndex;
  final Widget? headerAction;

  const DesktopShellWrapper({
    super.key,
    required this.child,
    required this.title,
    this.selectedIndex = -1,
    this.headerAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = ref.watch(isDesktopProvider);

    if (!isDesktop) {
      return child;
    }

    final user = ref.watch(currentUserProvider);
    final userType = user?.userType ?? 'tailor';
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    return DesktopDashboardShell(
      pageTitle: title,
      selectedIndex: selectedIndex != -1
          ? selectedIndex
          : NavConfig.getDesktopIndex(userType, currentRoute),
      headerAction: headerAction,
      child: child,
    );
  }
}
