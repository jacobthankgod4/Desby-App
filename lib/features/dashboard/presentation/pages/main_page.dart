import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tailor_dashboard.dart';
import 'apprentice_dashboard.dart';
import 'client_dashboard.dart';
import 'fabric_seller_dashboard.dart';
import '../widgets/desktop_dashboard_shell.dart';
import '../../../../features/clients/presentation/pages/client_list_page.dart';
import '../../../../features/orders/presentation/pages/order_list_page.dart';
import '../../../../features/marketplace/presentation/pages/fabric_catalog_page.dart';
import '../../../../features/apprenticeship/presentation/pages/apprentice_management_page.dart';
import '../../../../features/apprenticeship/presentation/pages/apprentice_learning_page.dart';
import '../../../../features/chat/presentation/pages/chat_list_page.dart';
import '../../../../features/profile/presentation/pages/profile_view_page.dart';
import '../../../../features/profile/presentation/pages/settings_page.dart';
import '../../../../features/profile/presentation/providers/profile_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/profile/domain/entities/user_profile.dart';
import '../../../../features/notifications/presentation/pages/notification_center_page.dart';
import '../../../../features/analytics/presentation/pages/insights_dashboard.dart';
import '../../../../theme/colors.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userType = user?.userType ?? 'tailor';
    final userId = user?.id ?? '';

    final List<Widget> pages = _getPages(userType, userId);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1000;
        if (isDesktop) {
          // Desktop: Wrap with DesktopDashboardShell for consistent main menu + header
          return DesktopDashboardShell(
            pageTitle: 'DESBY OS',
            selectedIndex: _currentIndex,
            child: pages[_currentIndex],
          );
        }
        
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
          body: pages[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.amber,
            unselectedItemColor: Colors.white.withValues(alpha: 0.3),
            backgroundColor: AppColors.darkNavy,
            items: _getNavItems(userType),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 9),
          ),
          floatingActionButton: _getFAB(userType, context),
        );
      },
    );
  }

  Widget? _getFAB(String type, BuildContext context) {
    if (type != 'tailor') return null;

    switch (_currentIndex) {
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
          onPressed: () => Navigator.pushNamed(context, '/apprentice-onboarding'),
          label: const Text('Enroll Apprentice', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
          icon: const Icon(Icons.school_rounded, size: 20),
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.darkNavy,
        );
      default:
        return null;
    }
  }

  List<Widget> _getPages(String type, String userId) {
    switch (type) {
      case 'tailor':
        return [
          const TailorDashboard(),
          const ClientListPage(),
          const OrderListPage(),
          const ApprenticeManagementPage(),
          const ChatListPage(),
        ];
      case 'apprentice':
        return [
          const ApprenticeDashboard(),
          const ApprenticeLearningPage(),
          const OrderListPage(),
          const ChatListPage(),
          ProfileViewPage(userId: userId),
        ];
      case 'client':
        return [
          const ClientDashboard(),
          const OrderListPage(),
          const FabricCatalogPage(),
          const ChatListPage(),
          ProfileViewPage(userId: userId),
        ];
      case 'fabric_seller':
        return [
          const FabricSellerDashboard(),
          const FabricCatalogPage(),
          const ChatListPage(),
          ProfileViewPage(userId: userId),
        ];
      default:
        return [const TailorDashboard()];
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
              _QuickActionItem(icon: Icons.person_add_rounded, label: 'Add New Client', onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/unified-add-client'); }),
              _QuickActionItem(icon: Icons.add_shopping_cart_rounded, label: 'Quick Order (Existing)', onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/order-create'); }),
              _QuickActionItem(icon: Icons.school_rounded, label: 'Invite Apprentice', onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/apprentice-onboarding'); }),
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
            return _buildOnboardingAlert(context, userType);
          }
          return _checkProfileCompleteness(context, profile, userType);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
        error: (e, st) => _buildOnboardingAlert(context, userType),
      );
    } else {
      onboardingWidget = _buildOnboardingAlert(context, userType);
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
                  _buildDrawerItem(Icons.grid_view_rounded, 'Dashboard Home', '/main'),
                  _buildDrawerItem(Icons.person_outline_rounded, 'My Profile', '/profile', arguments: user?.id),
                  if (userType == 'tailor')
                    _buildDrawerItem(Icons.bar_chart_rounded, 'Business Insights', '/insights'),
                  _buildDrawerItem(Icons.settings_suggest_rounded, 'System Settings', '/profile/settings'),
                  _buildDrawerItem(Icons.notifications_none_rounded, 'Notification Center', '/notifications'),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white10),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(color: Color(0xFF0A1921)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.amber,
            child: Text(user?.name?[0].toUpperCase() ?? 'U', style: const TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w900, fontSize: 28)),
          ),
          const SizedBox(height: 20),
          Text(user?.name ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5)),
          Text(user?.email ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
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

  Widget _buildOnboardingAlert(BuildContext context, String type) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/$type-onboarding');
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

  Widget _checkProfileCompleteness(BuildContext context, UserProfile profile, String userType) {
    final bool isComplete = (userType == 'tailor') 
        ? (profile.services != null && profile.services!.isNotEmpty) ||
          (profile.availableFabrics != null && profile.availableFabrics!.isNotEmpty)
        : profile.name.isNotEmpty && profile.name != 'New User';

    if (isComplete) {
      return _buildUpgradeCard(context);
    } else {
      return _buildOnboardingAlert(context, userType);
    }
  }

  Widget _buildUpgradeCard(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/subscription-plans');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.amber.withValues(alpha: 0.2), Colors.purple.withValues(alpha: 0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('UPGRADE PLAN', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                  Text('Unlock premium features', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.amber, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, String route, {Object? arguments, Color color = Colors.white70}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.2)),
      onTap: () {
        Navigator.pop(context);
        final currentRoute = ModalRoute.of(context)?.settings.name;
        if (currentRoute != route) {
          Navigator.pushNamed(context, route, arguments: arguments);
        }
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
