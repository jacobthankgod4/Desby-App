import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tailor_dashboard.dart';
import 'apprentice_dashboard.dart';
import 'client_dashboard.dart';
import 'fabric_seller_dashboard.dart';
import '../widgets/desktop_dashboard_shell.dart';
import '../../../../features/orders/presentation/pages/order_list_page.dart';
import '../../../../features/orders/presentation/pages/order_detail_page.dart';
import '../../../../features/orders/presentation/pages/order_create_page.dart';
import '../../../../features/orders/presentation/pages/booking_cart_page.dart';
import '../../../../features/orders/presentation/pages/delivery_setup_page.dart';
import '../../../../features/orders/presentation/pages/price_estimation_page.dart';
import '../../../../features/orders/presentation/pages/delivery_tracking_page.dart';
import '../../../../features/marketplace/presentation/pages/fabric_catalog_page.dart';
import '../../../../features/marketplace/presentation/pages/fabric_upload_page.dart';
import '../../../../features/marketplace/presentation/pages/fabric_detail_page.dart';
import '../../../../features/marketplace/presentation/pages/merchant_wallet_page.dart';
import '../../../../features/tailor/presentation/pages/virtual_atelier_page.dart';
import '../../../../features/tailor/presentation/pages/shop_setup_page.dart';
import '../../../../features/tailor/presentation/pages/pricing_setup_page.dart';
import '../../../../features/tailor/presentation/pages/tailor_discovery_page.dart';
import '../../../../features/tailor/presentation/pages/tailor_profile_page.dart';
import '../../../../features/tailor/presentation/pages/tailor_availability_page.dart';
import '../../../../features/tailor/presentation/pages/product_details_page.dart';
import '../../../../features/clients/presentation/pages/client_list_page.dart';
import '../../../../features/clients/presentation/pages/client_detail_page.dart';
import '../../../../features/clients/presentation/pages/unified_add_client_page.dart';
import '../../../../features/clients/presentation/pages/measurement_hub_page.dart';
import '../../../../features/clients/presentation/pages/measurement_profile_page.dart';
import '../../../../features/designs/presentation/pages/measurement_input_page.dart';
import '../../../../features/designs/presentation/pages/ai_body_scan_page.dart';
import '../../../../features/designs/presentation/pages/design_gallery_page.dart';
import '../../../../features/apprenticeship/presentation/pages/apprentice_learning_page.dart';
import '../../../../features/profile/presentation/pages/profile_view_page.dart';
import '../../../../features/profile/presentation/pages/profile_edit_page.dart';
import '../../../../features/profile/presentation/pages/settings_page.dart';
import '../../../../features/profile/presentation/providers/profile_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/profile/domain/entities/user_profile.dart';
import '../../../../features/notifications/presentation/pages/notification_center_page.dart';
import '../../../../features/analytics/presentation/pages/insights_dashboard.dart';
import '../../../../features/analytics/presentation/pages/reports_page.dart';
import '../../../../features/analytics/presentation/pages/ai_insights_page.dart';
import '../../../../features/marketplace/presentation/pages/seller_inventory_page.dart';
import '../../../../features/payments/presentation/pages/checkout_page.dart';
import 'package:desby_app/features/chat/presentation/pages/chat_list_page.dart';
import 'package:desby_app/features/chat/presentation/pages/chat_detail_page.dart';
import 'package:desby_app/core/models/nav_item.dart';
import 'package:desby_app/core/providers/navigation_provider.dart';
import 'package:desby_app/core/providers/theme_provider.dart';
import 'package:desby_app/theme/colors.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userType = user?.userType ?? 'tailor';
    final userId = user?.id ?? '';
    final navState = ref.watch(navigationProvider);
    final selectedRoute = navState.route;
    final navArguments = navState.arguments;
    final navStack = ref.read(navigationStackProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1000;
        
        final child = _getPageForRoute(selectedRoute, userId, userType, navArguments);

        if (isDesktop) {
          // Desktop: Persistent sidebar with dynamic content switching
          return DesktopDashboardShell(
            pageTitle: getPageTitle(selectedRoute),
            selectedIndex: _getSelectedIndexForRoute(userType, selectedRoute),
            onIndexChanged: (index, route) {
              navStack.set(route);
            },
            child: child,
          );
        }
        
        final currentIndex = _getMobileIndexForRoute(userType, selectedRoute);

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.darkNavy,
          appBar: AppBar(
            title: Text(_getAppBarTitle(userType),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            elevation: 0,
            backgroundColor: AppColors.darkNavy,
          ),
          drawer: _buildDrawer(context, user),
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              final route = _getRouteForMobileIndex(userType, index);
              navStack.set(route);
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.amber,
            unselectedItemColor: Colors.white.withValues(alpha: 0.3),
            backgroundColor: AppColors.darkNavy,
            items: _getNavItems(userType),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 9),
          ),
          floatingActionButton: _getFAB(userType, context, currentIndex),
        );
      },
    );
  }

  int _getMobileIndexForRoute(String userType, String route) {
    final routes = _getMobileRoutes(userType);
    final index = routes.indexOf(route);
    return index != -1 ? index : 0;
  }

  String _getRouteForMobileIndex(String userType, int index) {
    final routes = _getMobileRoutes(userType);
    if (index >= 0 && index < routes.length) return routes[index];
    return '/main';
  }

  List<String> _getMobileRoutes(String userType) {
    switch (userType) {
      case 'tailor':
        return ['/main', '/clients', '/orders', '/academy', '/chats'];
      default:
        return ['/main', '/orders', '/marketplace', '/chats', '/profile'];
    }
  }

  int _getSelectedIndexForRoute(String userType, String route) {
    final items = _getDesktopNavItems(userType);
    for (int i = 0; i < items.length; i++) {
      if (route == items[i].route || (route.startsWith(items[i].route!) && items[i].route != '/main')) {
        return i;
      }
    }
    return -1;
  }

  List<NavItem> _getDesktopNavItems(String userType) {
    switch (userType) {
      case 'tailor':
        return [
          NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
          NavItem(label: 'Orders', icon: Icons.description_rounded, route: '/orders'),
          NavItem(label: 'Clients', icon: Icons.people_rounded, route: '/clients'),
          NavItem(label: 'Add Client', icon: Icons.person_add_rounded, route: '/unified-add-client'),
          NavItem(label: 'New Order', icon: Icons.add_circle_rounded, route: '/order-create'),
          NavItem(label: 'Marketplace', icon: Icons.shopping_bag_rounded, route: '/marketplace'),
          NavItem(label: 'My Shop', icon: Icons.storefront_rounded, route: '/virtual-atelier'),
          NavItem(label: 'Pricing', icon: Icons.attach_money_rounded, route: '/pricing-setup'),
          NavItem(label: 'Insights', icon: Icons.insights_rounded, route: '/insights'),
          NavItem(label: 'Settings', icon: Icons.settings_rounded, route: '/profile/settings'),
        ];
      case 'client':
        return [
          NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
          NavItem(label: 'Orders', icon: Icons.shopping_bag_rounded, route: '/orders'),
          NavItem(label: 'Find Tailor', icon: Icons.search_rounded, route: '/tailor-discovery'),
          NavItem(label: 'Fitting Hub', icon: Icons.straighten_rounded, route: '/measurements-hub'),
          NavItem(label: 'Insights', icon: Icons.insights_rounded, route: '/insights'),
          NavItem(label: 'Settings', icon: Icons.settings_rounded, route: '/profile/settings'),
        ];
      case 'apprentice':
        return [
          NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
          NavItem(label: 'Tasks', icon: Icons.assignment_rounded, route: '/tasks'),
          NavItem(label: 'Curriculum', icon: Icons.menu_book_rounded, route: '/curriculum'),
          NavItem(label: 'Progress', icon: Icons.trending_up_rounded, route: '/progress'),
          NavItem(label: 'Insights', icon: Icons.insights_rounded, route: '/insights'),
          NavItem(label: 'Settings', icon: Icons.settings_rounded, route: '/profile/settings'),
        ];
      case 'fabric_seller':
        return [
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

  Widget _getPageForRoute(String route, String userId, String userType, [Map<String, dynamic>? arguments]) {
    switch (route) {
      case '/main':
        if (userType == 'tailor') return const TailorDashboard();
        if (userType == 'client') return const ClientDashboard();
        if (userType == 'apprentice') return const ApprenticeDashboard();
        if (userType == 'fabric_seller') return const FabricSellerDashboard();
        return const TailorDashboard();
      case '/orders': return const OrderListPage();
      case '/order-detail':
        return OrderDetailPage(orderId: arguments?['orderId'] ?? '');
      case '/clients': return const ClientListPage();
      case '/client-detail':
        return ClientDetailPage(clientId: arguments?['clientId'] ?? '');
      case '/unified-add-client': return const UnifiedAddClientPage();
      case '/order-create': return const OrderCreatePage();
      case '/marketplace': return const FabricCatalogPage();
      case '/fabric-details':
        return FabricDetailPage(fabricId: arguments?['fabricId'] ?? '');
      case '/shop-setup': return const ShopSetupPage();
      case '/virtual-atelier': return const VirtualAtelierPage();
      case '/pricing-setup': return const PricingSetupPage();
      case '/insights': return const InsightsDashboard();
      case '/profile/settings': return const SettingsPage();
      case '/profile': return ProfileViewPage(userId: userId);
      case '/profile/edit': return ProfileEditPage(userId: userId);
      case '/notifications': return const NotificationCenterPage();
      case '/tailor-discovery': return const TailorDiscoveryPage();
      case '/measurements-hub': return const MeasurementHubPage();
      case '/measurements-input': return const MeasurementInputPage();
      case '/measurements-profile': return const MeasurementProfilePage();
      case '/tasks': return const OrderListPage(); // Placeholder for Apprentice Tasks
      case '/curriculum': return const ApprenticeLearningPage();
      case '/progress': return const InsightsDashboard(); // Placeholder
      case '/mentors': return const TailorDiscoveryPage(); // Placeholder
      case '/fabric-upload': return const FabricUploadPage();
      case '/inventory': return const SellerInventoryPage();
      case '/chats': return const ChatListPage();
      case '/chat-detail':
        return ChatDetailPage(
          conversationId: arguments?['conversationId'] ?? '',
          peerId: arguments?['peerId'],
          orderId: arguments?['orderId'],
        );
      case '/tailor-profile':
        return TailorProfilePage(tailorId: arguments?['tailorId'] ?? '');
      case '/tailor-availability':
        return TailorAvailabilityPage(tailor: arguments ?? {});
      case '/booking-cart':
        return BookingCartPage(tailor: arguments ?? {});
      case '/delivery-setup':
        return DeliverySetupPage(tailor: arguments ?? {});
      case '/price-estimation':
        return PriceEstimationPage(tailor: arguments ?? {});
      case '/delivery-tracking':
        return DeliveryTrackingPage(fezOrderNo: arguments?['fezOrderNo'] ?? '');
      case '/product-details':
        return ProductDetailsPage(product: arguments?['product']);
      case '/checkout':
        return CheckoutPage(
          amount: arguments?['amount'] ?? 0.0,
          orderId: arguments?['orderId'] ?? '',
        );
      case '/reports': return const ReportsPage();
      case '/ai-insights': return const AIInsightsPage();
      case '/merchant-wallet': return const MerchantWalletPage();
      case '/ai-body-scan': return const AiBodyScanPage();
      case '/designs': return const DesignGalleryPage();
      default: return const TailorDashboard();
    }
  }

  Widget? _getFAB(String type, BuildContext context, int currentIndex) {
    if (type != 'tailor') return null;

    switch (currentIndex) {
      case 0:
        return FloatingActionButton(
          heroTag: 'main_add_fab',
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.darkNavy,
          onPressed: () => _showQuickActions(context),
          child: const Icon(Icons.add_rounded),
        );
      case 3:
        return FloatingActionButton.extended(
          heroTag: 'enroll_fab',
          onPressed: () => ref.pushShell('/apprentice-onboarding'),
          label: const Text('Enroll Apprentice', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
          icon: const Icon(Icons.school_rounded, size: 20),
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.darkNavy,
        );
      default:
        return null;
    }
  }

  List<BottomNavigationBarItem> _getNavItems(String type) {
    switch (type) {
      case 'tailor':
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), activeIcon: Icon(Icons.grid_view_rounded), label: 'OS'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), activeIcon: Icon(Icons.people_alt_rounded), label: 'CLIENTS'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_rounded), activeIcon: Icon(Icons.shopping_bag_rounded), label: 'ORDERS'),
          BottomNavigationBarItem(icon: Icon(Icons.school_rounded), activeIcon: Icon(Icons.school_rounded), label: 'ACADEMY'),
          BottomNavigationBarItem(icon: Icon(Icons.forum_rounded), activeIcon: Icon(Icons.forum_rounded), label: 'CHATS'),
        ];
      default:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'OS'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_rounded), label: 'ORDERS'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'MARKET'),
          BottomNavigationBarItem(icon: Icon(Icons.forum_rounded), label: 'CHATS'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'PROFILE'),
        ];
    }
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkNavy,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('RAPID ACTIONS', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 32),
              _QuickActionItem(icon: Icons.person_add_rounded, label: 'Add New Client', onTap: () { Navigator.pop(context); ref.pushShell('/unified-add-client'); }),
              _QuickActionItem(icon: Icons.add_shopping_cart_rounded, label: 'Quick Order (Existing)', onTap: () { Navigator.pop(context); ref.pushShell('/order-create'); }),
              _QuickActionItem(icon: Icons.school_rounded, label: 'Invite Apprentice', onTap: () { Navigator.pop(context); ref.pushShell('/apprentice-onboarding'); }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, dynamic user) {
    final userId = user?.id ?? '';
    final userType = user?.userType ?? 'tailor';

    final profileAsync = userId.isNotEmpty ? ref.watch(userProfileProvider(userId)) : null;
    
    Widget onboardingWidget;
    if (profileAsync != null) {
      onboardingWidget = profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return _buildOnboardingAlert(context, ref, userType);
          }
          return _checkProfileCompleteness(context, ref, profile, userType);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
        error: (e, st) => _buildOnboardingAlert(context, ref, userType),
      );
    } else {
      onboardingWidget = _buildOnboardingAlert(context, ref, userType);
    }

    return Drawer(
      backgroundColor: AppColors.darkNavy,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDrawerHeader(user),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: onboardingWidget,
                  ),
                  _buildDrawerItem(ref, Icons.grid_view_rounded, 'Dashboard Home', '/main'),
                  _buildDrawerItem(ref, Icons.person_outline_rounded, 'My Profile', '/profile', arguments: {'userId': user?.id}),
                  if (userType == 'tailor')
                    _buildDrawerItem(ref, Icons.bar_chart_rounded, 'Business Insights', '/insights'),
                  _buildDrawerItem(ref, Icons.settings_suggest_rounded, 'System Settings', '/profile/settings'),
                  _buildDrawerItem(ref, Icons.notifications_none_rounded, 'Notification Center', '/notifications'),
                ],
              ),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
            title: const Text('Terminate Session', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.2)),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(dynamic user) {
    final themeMode = ref.watch(themeModeProvider);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: AppColors.amber,
                child: Text(user?.name?[0].toUpperCase() ?? 'U', style: const TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w900, fontSize: 28)),
              ),
              IconButton(
                icon: Icon(
                  themeMode == ThemeMode.light ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: AppColors.amber,
                ),
                onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(user?.name ?? 'User', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5)),
          Text(user?.email ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(user?.userType?.toUpperCase() ?? 'ACCESS', style: const TextStyle(color: AppColors.amber, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingAlert(BuildContext context, WidgetRef ref, String type) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ref.pushShell('/$type-onboarding');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.amber,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.darkNavy),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACTION REQUIRED', style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                  Text('Complete Mandatory Onboarding', style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.darkNavy, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _checkProfileCompleteness(BuildContext context, WidgetRef ref, UserProfile profile, String userType) {
    final bool isComplete = (userType == 'tailor') 
        ? (profile.services != null && profile.services!.isNotEmpty) ||
          (profile.availableFabrics != null && profile.availableFabrics!.isNotEmpty)
        : profile.name.isNotEmpty && profile.name != 'New User';

    if (isComplete) {
      return _buildUpgradeCard(context, ref);
    } else {
      return _buildOnboardingAlert(context, ref, userType);
    }
  }

  Widget _buildUpgradeCard(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ref.pushShell('/subscription-plans');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 0),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward_rounded, color: AppColors.amber, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('UPGRADE PLAN', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                  Text('Unlock premium features', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.amber, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(WidgetRef ref, IconData icon, String title, String route, {Object? arguments, Color? color}) {
    final itemColor = color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: itemColor, size: 22),
      title: Text(title, style: TextStyle(color: itemColor, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.2)),
      onTap: () {
        Navigator.pop(context);
        ref.pushShell(route, arguments as Map<String, dynamic>?);
      },
    );
  }

  String _getAppBarTitle(String type) {
    return 'DESBY OS';
  }
}

class _QuickActionItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionItem({required this.icon, required this.label, required this.onTap});

  @override
  State<_QuickActionItem> createState() => _QuickActionItemState();
}

class _QuickActionItemState extends State<_QuickActionItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.05), 
            child: Icon(widget.icon, color: AppColors.amber, size: 20),
          ),
          title: Text(widget.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ),
    );
  }
}
