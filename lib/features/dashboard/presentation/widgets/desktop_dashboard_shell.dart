import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:desby_app/core/storage/local_storage.dart';
import 'package:desby_app/core/storage/storage_keys.dart';
import 'package:desby_app/core/providers/navigation_provider.dart';
import 'package:desby_app/theme/colors.dart';
import '../../../../core/models/nav_item.dart';

/// Desktop Dashboard Shell - Desktop view with Desby OS Brand Colors
/// Main sidebar with ALL navigation items - always visible on desktop
class DesktopDashboardShell extends ConsumerStatefulWidget {
  final Widget child;
  final String pageTitle;
  final List<NavItem>? navItems; 
  final int selectedIndex;
  final Function(int, String)? onIndexChanged;
  final VoidCallback? onNotificationTap;
  final Widget? floatingActionButton;
  final Widget? headerAction;

  const DesktopDashboardShell({
    super.key,
    required this.child,
    required this.pageTitle,
    this.navItems,
    this.selectedIndex = 0,
    this.onIndexChanged,
    this.onNotificationTap,
    this.floatingActionButton,
    this.headerAction,
  });

  @override
  ConsumerState<DesktopDashboardShell> createState() => _DesktopDashboardShellState();
}

class _DesktopDashboardShellState extends ConsumerState<DesktopDashboardShell> {
  
  List<NavItem> _buildDefaultMenu() {
    final userType = localStorage.get(StorageKeys.userType, defaultValue: 'tailor');
    return _getNavItemsForUserType(userType);
  }
  
  List<NavItem> _getNavItemsForUserType(String userType) {
    switch (userType) {
      case 'tailor': return _tailorNavItems;
      case 'client': return _clientNavItems;
      case 'apprentice': return _apprenticeNavItems;
      case 'fabric_seller': return _fabricSellerNavItems;
      default: return _tailorNavItems;
    }
  }

  List<NavItem> get _tailorNavItems => const [
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

  List<NavItem> get _clientNavItems => const [
    NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
    NavItem(label: 'Orders', icon: Icons.shopping_bag_rounded, route: '/orders'),
    NavItem(label: 'Find Tailor', icon: Icons.search_rounded, route: '/tailor-discovery'),
    NavItem(label: 'Measurements', icon: Icons.straighten_rounded, route: '/measurements-input'),
    NavItem(label: 'Insights', icon: Icons.insights_rounded, route: '/insights'),
    NavItem(label: 'Settings', icon: Icons.settings_rounded, route: '/profile/settings'),
  ];

  List<NavItem> get _apprenticeNavItems => const [
    NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
    NavItem(label: 'Tasks', icon: Icons.assignment_rounded, route: '/tasks'),
    NavItem(label: 'Curriculum', icon: Icons.menu_book_rounded, route: '/curriculum'),
    NavItem(label: 'Progress', icon: Icons.trending_up_rounded, route: '/progress'),
    NavItem(label: 'Mentors', icon: Icons.person_rounded, route: '/mentors'),
    NavItem(label: 'Insights', icon: Icons.insights_rounded, route: '/insights'),
    NavItem(label: 'Settings', icon: Icons.settings_rounded, route: '/profile/settings'),
  ];

  List<NavItem> get _fabricSellerNavItems => const [
    NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
    NavItem(label: 'Orders', icon: Icons.shopping_cart_rounded, route: '/orders'),
    NavItem(label: 'Upload', icon: Icons.add_photo_alternate_rounded, route: '/fabric-upload'),
    NavItem(label: 'Inventory', icon: Icons.inventory_2_rounded, route: '/inventory'),
    NavItem(label: 'Insights', icon: Icons.insights_rounded, route: '/insights'),
    NavItem(label: 'Settings', icon: Icons.settings_rounded, route: '/profile/settings'),
  ];

  void _onMenuTap(BuildContext context, NavItem item, int index) {
    if (widget.onIndexChanged != null && item.route != null) {
      widget.onIndexChanged!(index, item.route!);
      return;
    }

    if (item.onTap != null) {
      item.onTap!();
      return;
    }
    
    if (item.route != null) {
      // Use navigationStackProvider for consistent shell context
      ref.read(navigationStackProvider.notifier).set(item.route!);
    }
  }

  Future<void> _onLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: const Text('LOGOUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
        content: const Text('Are you sure you want to terminate your session?', style: TextStyle(color: Colors.white38, fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('LOGOUT', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1000;
        if (!isDesktop) return widget.child;

        final menuItems = _buildDefaultMenu();
        
        return Scaffold(
          backgroundColor: AppColors.darkNavy,
          body: Row(
            children: [
              SizedBox(width: 280, child: _buildMainSidebar(context, menuItems)),
              Expanded(
                child: Column(
                  children: [
                    _buildTopHeader(context, user?.name ?? 'User'),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: AppColors.darkNavy, // Solid fallback background
                        child: widget.child,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: widget.floatingActionButton,
        );
      },
    );
  }

  Widget _buildTopHeader(BuildContext context, String userName) {
    final navState = ref.watch(navigationProvider);
    final currentRoute = navState.route;
    final bool isSubPage = currentRoute != '/main';
    final navStack = ref.read(navigationStackProvider.notifier);

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: AppColors.darkNavy, border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      child: Row(
        children: [
          if (isSubPage)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 20),
              onPressed: () {
                if (navStack.canPop) {
                  navStack.pop();
                } else {
                  navStack.set('/main');
                }
              },
            ),
          if (isSubPage) const SizedBox(width: 8),
          Text(widget.pageTitle.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const Spacer(),
          GestureDetector(
            onTap: () => navStack.push('/profile'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
              child: Row(
                children: [
                  CircleAvatar(radius: 12, backgroundColor: AppColors.amber, child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'U', style: const TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w900, fontSize: 10))),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white24, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(onPressed: widget.onNotificationTap ?? () => navStack.push('/notifications'), icon: const Icon(Icons.notifications_none_rounded, color: Colors.white38, size: 22)),
        ],
      ),
    );
  }

  Widget _buildMainSidebar(BuildContext context, List<NavItem> menuItems) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF0A1921), border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', height: 32, errorBuilder: (_, __, ___) => const Icon(Icons.design_services, color: AppColors.amber)),
                const SizedBox(width: 12),
                const Text('DESBY OS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(24, 12, 24, 12), child: Text('TERMINAL MENU', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2))),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isActive = index == widget.selectedIndex;
                return _buildMenuItem(context, item, isActive, index);
              },
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: _buildUpgradeCard(context)),
          _buildLogoutItem(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, NavItem item, bool isActive, int index) {
    return InkWell(
      onTap: () => _onMenuTap(context, item, index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.amber.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: isActive ? AppColors.amber : Colors.white24, size: 20),
            const SizedBox(width: 14),
            Text(item.label.toUpperCase(), style: TextStyle(color: isActive ? Colors.white : Colors.white60, fontSize: 11, fontWeight: isActive ? FontWeight.w900 : FontWeight.w600, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return ListTile(
      onTap: () => _onLogout(context),
      leading: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 20),
      title: const Text('TERMINATE', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
    );
  }

  Widget _buildUpgradeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.amber, size: 20),
          const SizedBox(width: 12),
          const Expanded(child: Text('UPGRADE SYSTEM', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1))),
          const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.amber, size: 10),
        ],
      ),
    );
  }
}
