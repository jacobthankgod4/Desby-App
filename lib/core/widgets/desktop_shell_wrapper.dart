import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/features/dashboard/presentation/widgets/desktop_dashboard_shell.dart';
import 'package:desby_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:desby_app/core/models/nav_item.dart';

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
        final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

        return DesktopDashboardShell(
          pageTitle: title,
          selectedIndex: selectedIndex != -1 
              ? selectedIndex 
              : _getSelectedIndexForRoute(userType, currentRoute),
          headerAction: headerAction,
          child: child,
        );
      },
    );
  }

  int _getSelectedIndexForRoute(String userType, String route) {
    // This logic replicates MainPage's route selection but for standalone routes
    // wrapped in DesktopShellWrapper (e.g. for deep links or mobile navigation fallback)
    final items = _getDesktopNavItems(userType);
    for (int i = 0; i < items.length; i++) {
      if (route == items[i].route || (route.startsWith(items[i].route!) && items[i].route != '/main')) {
        return i;
      }
    }
    return 0;
  }

  List<NavItem> _getDesktopNavItems(String userType) {
    switch (userType) {
      case 'tailor':
        return const [
          NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
          NavItem(label: 'Orders', icon: Icons.description_rounded, route: '/orders'),
          NavItem(label: 'Clients', icon: Icons.people_rounded, route: '/clients'),
          NavItem(label: 'Add Client', icon: Icons.person_add_rounded, route: '/unified-add-client'),
          NavItem(label: 'New Order', icon: Icons.add_circle_rounded, route: '/order-create'),
          NavItem(label: 'Marketplace', icon: Icons.shopping_bag_rounded, route: '/marketplace'),
          NavItem(label: 'My Shop', icon: Icons.storefront_rounded, route: '/shop-setup'),
          NavItem(label: 'Pricing', icon: Icons.attach_money_rounded, route: '/pricing-setup'),
          NavItem(label: 'Insights', icon: Icons.insights_rounded, route: '/insights'),
          NavItem(label: 'Settings', icon: Icons.settings_rounded, route: '/profile/settings'),
        ];
      case 'client':
        return const [
          NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
          NavItem(label: 'Orders', icon: Icons.shopping_bag_rounded, route: '/orders'),
          NavItem(label: 'Find Tailor', icon: Icons.search_rounded, route: '/tailor-discovery'),
          NavItem(label: 'Fitting Hub', icon: Icons.straighten_rounded, route: '/measurements-hub'),
          NavItem(label: 'Insights', icon: Icons.insights_rounded, route: '/insights'),
          NavItem(label: 'Settings', icon: Icons.settings_rounded, route: '/profile/settings'),
        ];
      case 'apprentice':
        return const [
          NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
          NavItem(label: 'Tasks', icon: Icons.assignment_rounded, route: '/tasks'),
          NavItem(label: 'Curriculum', icon: Icons.menu_book_rounded, route: '/curriculum'),
          NavItem(label: 'Progress', icon: Icons.trending_up_rounded, route: '/progress'),
          NavItem(label: 'Insights', icon: Icons.insights_rounded, route: '/insights'),
          NavItem(label: 'Settings', icon: Icons.settings_rounded, route: '/profile/settings'),
        ];
      case 'fabric_seller':
        return const [
          NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
          NavItem(label: 'Orders', icon: Icons.shopping_cart_rounded, route: '/orders'),
          NavItem(label: 'Upload', icon: Icons.add_photo_alternate_rounded, route: '/fabric-upload'),
          NavItem(label: 'Inventory', icon: Icons.inventory_2_rounded, route: '/inventory'),
          NavItem(label: 'Insights', icon: Icons.insights_rounded, route: '/insights'),
          NavItem(label: 'Settings', icon: Icons.settings_rounded, route: '/profile/settings'),
        ];
      default: return [];
    }
  }
}
