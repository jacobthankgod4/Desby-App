import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:desby_app/core/storage/local_storage.dart';
import 'package:desby_app/core/storage/storage_keys.dart';
import 'package:desby_app/theme/colors.dart';

/// Desktop Dashboard Shell - Desktop view with Desby OS Brand Colors
/// Main sidebar with ALL navigation items - always visible on desktop
class DesktopDashboardShell extends ConsumerStatefulWidget {
  final Widget child;
  final String pageTitle;
  final List<NavItem>? navItems; // Optional - uses default if not provided
  final int selectedIndex;
  final VoidCallback? onNotificationTap;
  final Widget? floatingActionButton;
  final Widget? headerAction;

  const DesktopDashboardShell({
    super.key,
    required this.child,
    required this.pageTitle,
    this.navItems,
    this.selectedIndex = 0,
    this.onNotificationTap,
    this.floatingActionButton,
    this.headerAction,
  });

  @override
  ConsumerState<DesktopDashboardShell> createState() => _DesktopDashboardShellState();
}

class _DesktopDashboardShellState extends ConsumerState<DesktopDashboardShell> {
  int _selectedIndex = 0;

/// Map menu labels to routes - FIXED for desktop to use correct routes
  static final Map<String, String> _menuRoutes = {
    'Dashboard': '/dashboard',
    'Orders': '/orders',
    'Clients': '/clients',
    'My Profile': '/profile',
    'Business Insights': '/insights',
    'Marketplace': '/marketplace',
    'Notifications': '/notifications',
    'System Settings': '/profile/settings', // FIXED: was '/settings'
    'Upgrade Plan': '/subscription-plans',
  };

/// Build default menu items - user-type aware routing
  /// Modern approach: centralized config per user type
  List<NavItem> _buildDefaultMenu() {
    final userType = localStorage.get(StorageKeys.userType, defaultValue: 'tailor');
    return _getNavItemsForUserType(userType);
  }
  
  /// Centralized nav items per user type - modern DRY approach
  List<NavItem> _getNavItemsForUserType(String userType) {
    switch (userType) {
      case 'tailor':
        return _tailorNavItems;
      case 'client':
        return _clientNavItems;
      case 'apprentice':
        return _apprenticeNavItems;
      case 'fabric_seller':
        return _fabricSellerNavItems;
      default:
        return _tailorNavItems;
    }
  }

/// Tailor nav configuration - FIXED routes
  List<NavItem> get _tailorNavItems => [
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

/// Client nav configuration - FIXED routes
  List<NavItem> get _clientNavItems => [
    NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
    NavItem(label: 'Orders', icon: Icons.shopping_bag_rounded, route: '/orders'),
    NavItem(label: 'Find Tailor', icon: Icons.search_rounded, route: '/tailor-discovery'),
    NavItem(label: 'Measurements', icon: Icons.straighten_rounded, route: '/measurements-input'),
    NavItem(label: 'Favorites', icon: Icons.favorite_rounded, route: '/favorites'),
    NavItem(label: 'Insights', icon: Icons.insights_rounded, route: '/insights'),
    NavItem(label: 'Settings', icon: Icons.settings_rounded, route: '/profile/settings'),
  ];

  /// Apprentice nav configuration - FIXED routes
  List<NavItem> get _apprenticeNavItems => [
    NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
    NavItem(label: 'Tasks', icon: Icons.assignment_rounded, route: '/tasks'),
    NavItem(label: 'Curriculum', icon: Icons.menu_book_rounded, route: '/curriculum'),
    NavItem(label: 'Progress', icon: Icons.trending_up_rounded, route: '/progress'),
    NavItem(label: 'Mentors', icon: Icons.person_rounded, route: '/mentors'),
    NavItem(label: 'Insights', icon: Icons.insights_rounded, route: '/insights'),
    NavItem(label: 'Settings', icon: Icons.settings_rounded, route: '/profile/settings'),
  ];

  /// Fabric Seller nav configuration - FIXED routes
  List<NavItem> get _fabricSellerNavItems => [
    NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
    NavItem(label: 'Orders', icon: Icons.shopping_cart_rounded, route: '/orders'),
    NavItem(label: 'Upload', icon: Icons.add_photo_alternate_rounded, route: '/fabric-upload'),
    NavItem(label: 'Inventory', icon: Icons.inventory_2_rounded, route: '/inventory'),
    NavItem(label: 'Analytics', icon: Icons.analytics_rounded, route: '/insights'),
    NavItem(label: 'Messages', icon: Icons.chat_rounded, route: '/messages'),
    NavItem(label: 'Settings', icon: Icons.settings_rounded, route: '/profile/settings'),
  ];

void _onMenuTap(BuildContext context, NavItem item) {
    // First try onTap callback if provided
    if (item.onTap != null) {
      item.onTap!();
      return;
    }
    // Otherwise use route navigation
    if (item.route != null) {
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute != item.route) {
        // Use pushNamed to maintain navigation stack for back button stability
        Navigator.pushNamed(context, item.route!);
      }
    }
  }

  Future<void> _onLogout(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

if (confirmed == true && mounted) {
      // Call the logout method from auth provider
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

@override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1000;
        
        if (!isDesktop) {
          return widget.child;
        }

        // Desktop UI/UX - Menu sidebar always visible  
        final menuItems = _buildDefaultMenu();
        
        return Scaffold(
          backgroundColor: AppColors.darkNavy,
          body: Row(
            children: [
              // Main sidebar with ALL navigation items - always visible
              SizedBox(
                width: 320,
                child: _buildMainSidebar(context, menuItems),
              ),
              // Main content area
              Expanded(
                child: Column(
                  children: [
                    _buildTopHeader(context, user?.name ?? 'User'),
                    Expanded(
                      child: Container(
                        color: AppColors.darkNavy,
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
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 36),
      decoration: const BoxDecoration(
        color: AppColors.darkNavy,
        border: Border(
          bottom: BorderSide(color: AppColors.amber, width: 2),
        ),
      ),
      child: Row(
        children: [
          // Page title only (logo is in sidebar menu)
          const SizedBox(width: 0),
          
// Page label
          Text(
            widget.pageTitle.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          
          const Spacer(),
          
          // User profile button
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.amber,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.darkNavy,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.settings, color: AppColors.amber, size: 18),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Notification icon
GestureDetector(
            onTap: widget.onNotificationTap ?? () => Navigator.pushNamed(context, '/notifications'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.amber,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

/// Main sidebar with ALL navigation items - always visible
  Widget _buildMainSidebar(BuildContext context, List<NavItem> menuItems) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with logo only in sidebar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.design_services, color: AppColors.amber, size: 28);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'DESBY',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          
          // Main Menu section
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              'MAIN MENU',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          
// All menu items - always visible
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isActive = index == widget.selectedIndex;
                return _buildMenuItem(context, item, isActive);
              },
            ),
          ),
          
          // Upgrade Plan Card - same design as hamburger menu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildUpgradeCard(context),
          ),
          
          const SizedBox(height: 12),
          
          // Logout button
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildLogoutItem(context),
          ),
        ],
      ),
    );
  }

Widget _buildMenuItem(BuildContext context, NavItem item, bool isActive) {
    return GestureDetector(
      onTap: () => _onMenuTap(context, item),
      child: Container(
        height: 52,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.amber.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: AppColors.amber, width: 1) : null,
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: isActive ? AppColors.amber : Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 14),
            Text(
              item.label,
              style: TextStyle(
                color: isActive ? AppColors.amber : Colors.white70,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (isActive)
              const Icon(Icons.check, color: AppColors.amber, size: 18),
          ],
        ),
      ),
    );
  }

Widget _buildLogoutItem(BuildContext context) {
    return GestureDetector(
      onTap: () => _onLogout(context),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.logout,
              color: Colors.redAccent,
              size: 20,
            ),
            SizedBox(width: 14),
            Text(
              'Logout',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
);
  }

/// Upgrade Plan Card - same design as hamburger menu
  Widget _buildUpgradeCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/subscription-plans'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.amber.withValues(alpha: 0.2),
              Colors.purple.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.amber.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: AppColors.amber,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UPGRADE PLAN',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Unlock premium features',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.amber,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation item model
class NavItem {
  final String label;
  final IconData icon;
  final String? route;
  final VoidCallback? onTap;
  
  const NavItem({
    required this.label,
    required this.icon,
    this.route,
    this.onTap,
  });
}
