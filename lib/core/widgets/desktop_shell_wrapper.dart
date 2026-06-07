import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/presentation/widgets/desktop_dashboard_shell.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// DesktopShellWrapper - Automatically applies the DesktopDashboardShell 
/// if the platform is desktop (width > 1000). Otherwise, returns the child.
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1000;
        
        if (!isDesktop) {
          return child;
        }

        final user = ref.watch(currentUserProvider);
        final userType = user?.userType ?? 'tailor';

        return DesktopDashboardShell(
          pageTitle: title,
          selectedIndex: selectedIndex,
          headerAction: headerAction,
          child: child,
        );
      },
    );
  }
}
