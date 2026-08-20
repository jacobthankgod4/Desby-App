import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:desby_app/core/storage/local_storage.dart';
import 'package:desby_app/core/storage/storage_keys.dart';
import 'package:desby_app/core/providers/navigation_provider.dart';
import 'package:desby_app/theme/colors.dart';
import '../../../../core/models/nav_item.dart';

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
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

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
    final navState = ref.watch(navigationProvider);
    final currentRoute = navState.route;
    final bool isSubPage = currentRoute != '/main';
    final navStack = ref.read(navigationStackProvider.notifier);

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
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
          const SizedBox(width: 24),

          // Search bar
          Expanded(
            child: _SearchBar(
              controller: _searchController,
              focusNode: _searchFocusNode,
              isFocused: _isSearchFocused,
              onFocusChanged: (focused) => setState(() => _isSearchFocused = focused),
            ),
          ),

          const Spacer(),

          // Notification bell with badge
          _NotificationBell(
            onTap: widget.onNotificationTap ?? () => navStack.push('/notifications'),
          ),
          const SizedBox(width: 16),

          // User avatar
          GestureDetector(
            onTap: () => navStack.push('/profile'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.amber,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w900, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white24, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSidebar(BuildContext context, List<NavItem> menuItems) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1921),
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 32,
                  errorBuilder: (_, __, ___) => const Icon(Icons.design_services, color: AppColors.amber),
                ),
                const SizedBox(width: 12),
                const Text('DESBY OS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: Text('MENU', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildUpgradeCard(context),
          ),
          _buildLogoutItem(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, NavItem item, bool isActive, int index) {
    return _SidebarMenuItem(
      item: item,
      isActive: isActive,
      onTap: () => _onMenuTap(context, item, index),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return ListTile(
      onTap: () => _onLogout(context),
      leading: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 20),
      title: const Text('LOG OUT', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
    );
  }

  Widget _buildUpgradeCard(BuildContext context) {
    return _UpgradeCard();
  }
}

class _SidebarMenuItem extends StatefulWidget {
  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarMenuItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<_SidebarMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    final isHovered = _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.amber.withValues(alpha: 0.08)
                : isHovered
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(color: AppColors.amber.withValues(alpha: 0.15))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.item.icon,
                color: isActive
                    ? AppColors.amber
                    : isHovered
                        ? Colors.white70
                        : Colors.white24,
                size: 20,
              ),
              const SizedBox(width: 14),
              Text(
                widget.item.label.toUpperCase(),
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : isHovered
                          ? Colors.white70
                          : Colors.white60,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final ValueChanged<bool> onFocusChanged;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.onFocusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: onFocusChanged,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(maxWidth: 400),
        height: 40,
        decoration: BoxDecoration(
          color: isFocused
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFocused
                ? AppColors.amber.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Search orders, clients...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isFocused ? AppColors.amber : Colors.white24,
              size: 18,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatefulWidget {
  final VoidCallback onTap;
  const _NotificationBell({required this.onTap});

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  bool _isHovered = false;
  final int _badgeCount = 3; // TODO: Wire to real notification count

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: _isHovered ? Colors.white70 : Colors.white38,
                size: 22,
              ),
              if (_badgeCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpgradeCard extends StatefulWidget {
  @override
  State<_UpgradeCard> createState() => _UpgradeCardState();
}

class _UpgradeCardState extends State<_UpgradeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppColors.amber.withValues(alpha: 0.1)
              : AppColors.amber.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? AppColors.amber.withValues(alpha: 0.3)
                : AppColors.amber.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: _isHovered ? AppColors.amber : Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('UPGRADE PLAN', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1))),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: _isHovered ? AppColors.amber : Colors.white24,
              size: 10,
            ),
          ],
        ),
      ),
    );
  }
}
