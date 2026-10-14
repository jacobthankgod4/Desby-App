import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:desby_app/core/storage/local_storage.dart';
import 'package:desby_app/core/storage/storage_keys.dart';
import 'package:desby_app/core/providers/navigation_provider.dart';
import 'package:desby_app/core/providers/layout_provider.dart';
import 'package:desby_app/core/providers/theme_provider.dart';
import 'package:desby_app/theme/colors.dart';
import '../../../../core/config/nav_config.dart';
import '../../../../core/services/background_scan_service.dart';
import '../../../../core/widgets/shell_scope.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../marketplace/presentation/providers/merchant_provider.dart';

class DesktopDashboardShell extends ConsumerStatefulWidget {
  final Widget child;
  final String pageTitle;
  final List<NavItem>? navItems;
  final int selectedIndex;
  final Function(int, String)? onIndexChanged;
  final VoidCallback? onNotificationTap;
  final Widget? floatingActionButton;
  final Widget? headerAction;
  final Widget? drawer;

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
    this.drawer,
  });

  @override
  ConsumerState<DesktopDashboardShell> createState() =>
      _DesktopDashboardShellState();
}

class _DesktopDashboardShellState extends ConsumerState<DesktopDashboardShell> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  bool _isSidebarCollapsed = false;

  static const double _sidebarExpandedWidth = 280;
  static const double _sidebarCollapsedWidth = 72;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<NavItem> _buildDefaultMenu() {
    final userType = localStorage.get(
      StorageKeys.userType,
      defaultValue: 'tailor',
    );
    return NavConfig.getDesktopItems(userType);
  }

  void _onMenuTap(BuildContext context, NavItem item, int index) {
    if (widget.onIndexChanged != null) {
      widget.onIndexChanged!(index, item.route);
      return;
    }

    ref.read(navigationStackProvider.notifier).set(item.route);
  }

  Future<void> _onLogout(BuildContext context) async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.dialogBg,
        title: Text(
          'Log Out',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: colors.textMuted, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Log Out', style: TextStyle(color: colors.statusError)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted)
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1000;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(isDesktopProvider.notifier).state = isDesktop;
        });
        final menuItems = _buildDefaultMenu();
        final navStack = ref.read(navigationStackProvider.notifier);

        // Mobile-specific data
        final navState = ref.watch(navigationProvider);
        final currentRoute = navState.route;
        final userType = localStorage.get(
          StorageKeys.userType,
          defaultValue: 'tailor',
        );
        final mobileItems = NavConfig.getMobileItems(userType);
        final currentIndex = NavConfig.getMobileIndex(userType, currentRoute);

        // Desktop: Row[Sidebar, Column[TopHeader, Expanded[widget.child]]]
        // Mobile: Column[Expanded[widget.child]] (Scaffold AppBar + BottomNav handle chrome)
        // widget.child stays at Column > Expanded > widget.child in both paths for state preservation.
        return Scaffold(
          backgroundColor: colors.scaffoldBg,
          appBar: isDesktop
              ? null
              : AppBar(
                  title: Text(
                    widget.pageTitle.toUpperCase(),
                    style: TextStyle(
                      color: colors.appBarText,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                  // Inside the shell a sub-page keeps a back control so pages
                  // never need to render their own leading/title; at the root
                  // of the stack the menu (drawer) is the entry point.
                  leading: Builder(
                    builder: (ctx) {
                      // Route-based, not depth-based: the desktop header below
                      // already treats anything other than /main as a sub-page.
                      // Keying off stack depth made this control flip between a
                      // drawer toggle and a back button depending on how the page
                      // was entered (first tap vs. reload vs. deep link).
                      final currentRoute = ref.watch(navigationProvider).route;
                      final canPop = currentRoute != '/main';
                      if (canPop) {
                        return IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.amber,
                            size: 18,
                          ),
                          onPressed: () {
                            if (navStack.canPop) {
                              navStack.pop();
                            } else {
                              navStack.set('/main');
                            }
                          },
                        );
                      }
                      return IconButton(
                        icon: Icon(
                          Icons.menu_rounded,
                          color: colors.appBarText,
                        ),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      );
                    },
                  ),
                  elevation: 0,
                  backgroundColor: colors.appBarBg,
                ),
          drawer: !isDesktop ? widget.drawer : null,
          body: Column(
            children: [
              // Background scan progress banner (full width)
              Consumer(
                builder: (context, ref, _) {
                  final scanTask = ref.watch(backgroundScanProvider);
                  if (scanTask == null ||
                      scanTask.status == BackgroundScanStatus.idle ||
                      scanTask.status == BackgroundScanStatus.completed ||
                      scanTask.status == BackgroundScanStatus.failed) {
                    return const SizedBox.shrink();
                  }
                  final isProcessing =
                      scanTask.status == BackgroundScanStatus.extracting ||
                      scanTask.status == BackgroundScanStatus.polling;
                  return Material(
                    color: AppColors.amber.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          if (isProcessing)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.amber,
                              ),
                            )
                          else
                            Icon(
                              scanTask.status == BackgroundScanStatus.completed
                                  ? Icons.check_circle_rounded
                                  : Icons.error_rounded,
                              size: 16,
                              color:
                                  scanTask.status ==
                                      BackgroundScanStatus.completed
                                  ? AppColors.successGreen
                                  : Colors.red,
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isProcessing
                                  ? 'AI Body Scan processing — you can continue browsing'
                                  : scanTask.status ==
                                        BackgroundScanStatus.completed
                                  ? 'Scan complete — ${scanTask.measurements?.length ?? 0} measurements ready'
                                  : 'Scan failed — ${scanTask.error ?? "Unknown error"}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          if (scanTask.status == BackgroundScanStatus.completed)
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(navigationStackProvider.notifier)
                                    .set('/ai-body-scan');
                              },
                              child: const Text(
                                'VIEW RESULTS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          if (scanTask.status ==
                                  BackgroundScanStatus.completed ||
                              scanTask.status == BackgroundScanStatus.failed)
                            IconButton(
                              icon: const Icon(Icons.close, size: 14),
                              onPressed: () => ref
                                  .read(backgroundScanProvider.notifier)
                                  .clearTask(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Expanded(
                child: Row(
                  children: [
                    if (isDesktop)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        width: _isSidebarCollapsed
                            ? _sidebarCollapsedWidth
                            : _sidebarExpandedWidth,
                        child: _buildMainSidebar(context, menuItems),
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          if (isDesktop)
                            _buildTopHeader(
                              context,
                              user?.name ?? 'User',
                              isDesktop: true,
                            ),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: colors.scaffoldBg,
                              child: ShellScope(child: widget.child),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: !isDesktop
              ? BottomNavigationBar(
                  currentIndex: currentIndex >= 0 ? currentIndex : 0,
                  onTap: (index) {
                    if (index >= 0 && index < mobileItems.length) {
                      navStack.set(mobileItems[index].route);
                    }
                  },
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: colors.navSelected,
                  unselectedItemColor: colors.navUnselected,
                  backgroundColor: colors.bottomNavBg,
                  items: mobileItems
                      .map(
                        (item) => BottomNavigationBarItem(
                          icon: Icon(item.icon),
                          activeIcon: Icon(item.icon),
                          label: item.label.toUpperCase(),
                        ),
                      )
                      .toList(),
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                )
              : null,
          floatingActionButton: widget.floatingActionButton,
        );
      },
    );
  }

  Widget _buildTopHeader(
    BuildContext context,
    String userName, {
    bool isDesktop = true,
  }) {
    final colors = context.colors;
    final navState = ref.watch(navigationProvider);
    final currentRoute = navState.route;
    final bool isSubPage = currentRoute != '/main';
    final navStack = ref.read(navigationStackProvider.notifier);
    final headerUser = ref.watch(currentUserProvider);
    final headerUserType = localStorage.get(
      StorageKeys.userType,
      defaultValue: 'tailor',
    );

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colors.appBarBg,
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        children: [
          if (!isDesktop && !isSubPage)
            Builder(
              builder: (ctx) => IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  color: colors.iconPrimary,
                  size: 22,
                ),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          if (isSubPage)
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.amber,
                size: 20,
              ),
              onPressed: () {
                if (navStack.canPop) {
                  navStack.pop();
                } else {
                  navStack.set('/main');
                }
              },
            ),
          if (isSubPage || !isDesktop) const SizedBox(width: 8),
          Text(
            widget.pageTitle.toUpperCase(),
            style: TextStyle(
              color: colors.appBarText,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 24),

          // Search bar — only on dashboard
          if (isDesktop && !isSubPage)
            Expanded(
              child: _SearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                isFocused: _isSearchFocused,
                onFocusChanged: (focused) =>
                    setState(() => _isSearchFocused = focused),
              ),
            ),

          const Spacer(),

          // Wallet balance (tailors & fabric sellers)
          if (headerUserType == 'tailor' || headerUserType == 'fabric_seller')
            _WalletBalanceChip(
              userId: headerUser?.id ?? '',
              onTap: () => navStack.push('/merchant-wallet'),
            ),
          if (headerUserType == 'tailor' || headerUserType == 'fabric_seller')
            const SizedBox(width: 12),

          // Saved designs (wishlist) with badge
          IconButton(
            onPressed: () => navStack.push('/saved-designs'),
            icon: Icon(
              Icons.favorite_border_rounded,
              color: colors.iconSecondary,
              size: 22,
            ),
            tooltip: 'Saved designs',
          ),
          const SizedBox(width: 8),

          // Notification bell with badge
          _NotificationBell(
            onTap:
                widget.onNotificationTap ??
                () => navStack.push('/notifications'),
          ),
          const SizedBox(width: 8),

          // Theme toggle
          Builder(
            builder: (ctx) {
              final themeMode = ref.watch(themeModeProvider);
              final isLight = themeMode == ThemeMode.light;
              return IconButton(
                onPressed: () =>
                    ref.read(themeModeProvider.notifier).toggleTheme(),
                icon: Icon(
                  isLight ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isLight ? colors.iconSecondary : AppColors.amber,
                  size: 20,
                ),
                tooltip: isLight
                    ? 'Switch to dark mode'
                    : 'Switch to light mode',
              );
            },
          ),
          const SizedBox(width: 8),

          // User avatar
          GestureDetector(
            onTap: () => navStack.push('/profile'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                children: [
                  UserAvatar(
                    imageUrl: headerUser?.profileImage,
                    name: userName,
                    radius: 12,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colors.iconMuted,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSidebar(BuildContext context, List<NavItem> menuItems) {
    final colors = context.colors;
    final isCollapsed = _isSidebarCollapsed;

    return Container(
      decoration: BoxDecoration(
        color: colors.sidebarBg,
        border: Border(right: BorderSide(color: colors.sidebarBorder)),
      ),
      child: Column(
        children: [
          // Logo + collapse toggle
          AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(isCollapsed ? 12 : 24),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => setState(
                    () => _isSidebarCollapsed = !_isSidebarCollapsed,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(isCollapsed ? 8 : 6),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isCollapsed
                            ? Icons.chevron_right_rounded
                            : Icons.chevron_left_rounded,
                        color: colors.iconSecondary,
                        size: 18,
                        key: ValueKey(isCollapsed),
                      ),
                    ),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Image.asset(
                    'assets/images/logo.png',
                    height: 28,
                    errorBuilder: (_, _, _) =>
                        Icon(Icons.design_services, color: AppColors.amber),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'DESBY OS',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isCollapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                'MENU',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          if (!isCollapsed) const SizedBox(height: 4),
          Expanded(
            child: isCollapsed
                ? _buildCollapsedMenu(menuItems)
                : _buildExpandedMenu(menuItems),
          ),
          if (!isCollapsed) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildUpgradeCard(context),
            ),
            _buildLogoutItem(context),
          ] else ...[
            const SizedBox(height: 8),
            IconButton(
              onPressed: () => _onLogout(context),
              icon: Icon(
                Icons.power_settings_new_rounded,
                color: colors.statusError,
                size: 20,
              ),
              tooltip: 'Log Out',
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCollapsedMenu(List<NavItem> menuItems) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        final isActive = index == widget.selectedIndex;
        return Tooltip(
          message: item.label,
          preferBelow: false,
          waitDuration: const Duration(milliseconds: 400),
          child: _SidebarMenuItem(
            item: item,
            isActive: isActive,
            isCollapsed: true,
            onTap: () => _onMenuTap(context, item, index),
          ),
        );
      },
    );
  }

  Widget _buildExpandedMenu(List<NavItem> menuItems) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        final isActive = index == widget.selectedIndex;
        return _SidebarMenuItem(
          item: item,
          isActive: isActive,
          isCollapsed: false,
          onTap: () => _onMenuTap(context, item, index),
        );
      },
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      onTap: () => _onLogout(context),
      leading: Icon(
        Icons.power_settings_new_rounded,
        color: colors.statusError,
        size: 20,
      ),
      title: Text(
        'LOG OUT',
        style: TextStyle(
          color: colors.statusError,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildUpgradeCard(BuildContext context) {
    return const _UpgradeCard();
  }
}

class _SidebarMenuItem extends StatefulWidget {
  final NavItem item;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarMenuItem({
    required this.item,
    required this.isActive,
    this.isCollapsed = false,
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
    final isCollapsed = widget.isCollapsed;
    final colors = context.colors;

    if (isCollapsed) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? colors.navItemActiveBg
                  : isHovered
                  ? colors.navItemHoverBg
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(color: colors.navItemActiveBorder)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.item.icon,
                  color: isActive
                      ? AppColors.amber
                      : isHovered
                      ? colors.iconSecondary
                      : colors.iconMuted,
                  size: 22,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 64,
                  child: Text(
                    widget.item.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isActive
                          ? colors.textPrimary
                          : isHovered
                          ? colors.textSecondary
                          : colors.textMuted,
                      fontSize: 8,
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                ? colors.navItemActiveBg
                : isHovered
                ? colors.navItemHoverBg
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(color: colors.navItemActiveBorder)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.item.icon,
                color: isActive
                    ? AppColors.amber
                    : isHovered
                    ? colors.iconSecondary
                    : colors.iconMuted,
                size: 20,
              ),
              const SizedBox(width: 14),
              Text(
                widget.item.label.toUpperCase(),
                style: TextStyle(
                  color: isActive
                      ? colors.textPrimary
                      : isHovered
                      ? colors.textSecondary
                      : colors.textMuted,
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

class _WalletBalanceChip extends ConsumerWidget {
  final String userId;
  final VoidCallback onTap;

  const _WalletBalanceChip({required this.userId, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final balanceAsync = ref.watch(walletBalanceProvider(userId));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
        ),
        child: balanceAsync.when(
          data: (data) {
            final balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.amber,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '\u20A6${balance.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            );
          },
          loading: () => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.amber,
                size: 16,
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.amber,
                ),
              ),
            ],
          ),
          error: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.amber,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '\u20A60',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
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
    final colors = context.colors;
    return Focus(
      onFocusChange: onFocusChanged,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: TextStyle(color: colors.textPrimary, fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Search orders, clients...',
          hintStyle: TextStyle(color: colors.textMuted, fontSize: 12),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isFocused ? AppColors.amber : colors.iconMuted,
            size: 18,
          ),
          filled: true,
          fillColor: isFocused ? colors.surfaceElevated : colors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.amber.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends ConsumerStatefulWidget {
  final VoidCallback onTap;
  const _NotificationBell({required this.onTap});

  @override
  ConsumerState<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<_NotificationBell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final badgeCount =
        notificationsAsync.whenOrNull(data: (n) => n.length) ?? 0;
    final colors = context.colors;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered ? colors.surfaceHover : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: _isHovered ? colors.iconSecondary : colors.iconMuted,
                size: 22,
              ),
              if (badgeCount > 0)
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
                      '$badgeCount',
                      style: TextStyle(
                        color: colors.textPrimary,
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

class _UpgradeCard extends ConsumerStatefulWidget {
  const _UpgradeCard();

  @override
  ConsumerState<_UpgradeCard> createState() => _UpgradeCardState();
}

class _UpgradeCardState extends ConsumerState<_UpgradeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          ref.read(navigationStackProvider.notifier).set('/subscription-plans');
        },
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
                Icons.workspace_premium_rounded,
                color: _isHovered ? AppColors.amber : colors.iconSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'UPGRADE PLAN',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: _isHovered ? AppColors.amber : colors.iconMuted,
                size: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
