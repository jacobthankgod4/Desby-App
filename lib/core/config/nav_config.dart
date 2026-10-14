import 'package:flutter/material.dart';

/// Centralized navigation configuration for all user types.
/// Single source of truth for desktop sidebar, mobile bottom nav, and drawer.
class NavConfig {
  NavConfig._();

  // ---------------------------------------------------------------------------
  // DESKTOP SIDEBAR ITEMS (full list, ordered by importance)
  // ---------------------------------------------------------------------------

  static List<NavItem> getDesktopItems(String userType) {
    switch (userType) {
      case 'tailor':
        return _tailorDesktop;
      case 'client':
        return _clientDesktop;
      case 'apprentice':
        return _apprenticeDesktop;
      case 'fabric_seller':
        return _fabricSellerDesktop;
      default:
        return _tailorDesktop;
    }
  }

  // ---------------------------------------------------------------------------
  // MOBILE BOTTOM NAV (top 5 most important items)
  // ---------------------------------------------------------------------------

  static List<NavItem> getMobileItems(String userType) {
    switch (userType) {
      case 'tailor':
        return _tailorMobile;
      case 'client':
        return _clientMobile;
      case 'apprentice':
        return _apprenticeMobile;
      case 'fabric_seller':
        return _fabricSellerMobile;
      default:
        return _clientMobile;
    }
  }

  // ---------------------------------------------------------------------------
  // MOBILE DRAWER ITEMS (items NOT in bottom nav, ordered by importance)
  // ---------------------------------------------------------------------------

  static List<NavItem> getDrawerItems(String userType) {
    switch (userType) {
      case 'tailor':
        return _tailorDrawer;
      case 'client':
        return _clientDrawer;
      case 'apprentice':
        return _apprenticeDrawer;
      case 'fabric_seller':
        return _fabricSellerDrawer;
      default:
        return _clientDrawer;
    }
  }

  // Get mobile routes as a simple list (for index mapping)
  static List<String> getMobileRoutes(String userType) {
    return getMobileItems(userType).map((item) => item.route).toList();
  }

  // Get index of a route in the desktop nav items (-1 if not found)
  static int getDesktopIndex(String userType, String route) {
    final items = getDesktopItems(userType);
    for (int i = 0; i < items.length; i++) {
      if (items[i].route == route) return i;
      // Match sub-routes (e.g., /order-detail matches /orders)
      if (items[i].route != '/main' && route.startsWith(items[i].route))
        return i;
    }
    return -1;
  }

  // Get index of a route in the mobile nav items (-1 if not found)
  static int getMobileIndex(String userType, String route) {
    final routes = getMobileRoutes(userType);
    final index = routes.indexOf(route);
    return index;
  }

  // ---------------------------------------------------------------------------
  // TAILOR
  // ---------------------------------------------------------------------------

  static const _tailorDesktop = [
    NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
    NavItem(label: 'Orders', icon: Icons.description_rounded, route: '/orders'),
    NavItem(label: 'Clients', icon: Icons.people_rounded, route: '/clients'),
    NavItem(
      label: 'Add Client',
      icon: Icons.person_add_rounded,
      route: '/unified-add-client',
    ),
    NavItem(
      label: 'Virtual Try-On',
      icon: Icons.checkroom_rounded,
      route: '/virtual-tryon',
    ),
    NavItem(label: 'Academy', icon: Icons.school_rounded, route: '/academy'),
    NavItem(
      label: 'Fabric Marketplace',
      icon: Icons.shopping_bag_rounded,
      route: '/marketplace',
    ),
    NavItem(
      label: 'My Shop',
      icon: Icons.storefront_rounded,
      route: '/virtual-atelier',
    ),
    NavItem(
      label: 'Pricing',
      icon: Icons.attach_money_rounded,
      route: '/pricing-setup',
    ),
    NavItem(
      label: 'Insights',
      icon: Icons.insights_rounded,
      route: '/insights',
    ),
    NavItem(label: 'Messages', icon: Icons.forum_rounded, route: '/chats'),
    NavItem(
      label: 'Ask Zoe',
      icon: Icons.auto_awesome_rounded,
      route: '/zoe-chat',
    ),
    NavItem(
      label: 'Settings',
      icon: Icons.settings_rounded,
      route: '/profile/settings',
    ),
  ];

  static const _tailorMobile = [
    NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
    NavItem(label: 'Clients', icon: Icons.people_rounded, route: '/clients'),
    NavItem(
      label: 'Orders',
      icon: Icons.shopping_bag_rounded,
      route: '/orders',
    ),
    NavItem(label: 'Messages', icon: Icons.forum_rounded, route: '/chats'),
    NavItem(label: 'Profile', icon: Icons.person_rounded, route: '/profile'),
  ];

  static const _tailorDrawer = [
    NavItem(
      label: 'Add Client',
      icon: Icons.person_add_rounded,
      route: '/unified-add-client',
    ),
    NavItem(
      label: 'Virtual Try-On',
      icon: Icons.checkroom_rounded,
      route: '/virtual-tryon',
    ),
    NavItem(label: 'Academy', icon: Icons.school_rounded, route: '/academy'),
    NavItem(
      label: 'Fabric Marketplace',
      icon: Icons.shopping_bag_rounded,
      route: '/marketplace',
    ),
    NavItem(
      label: 'My Shop',
      icon: Icons.storefront_rounded,
      route: '/virtual-atelier',
    ),
    NavItem(
      label: 'Pricing',
      icon: Icons.attach_money_rounded,
      route: '/pricing-setup',
    ),
    NavItem(
      label: 'Insights',
      icon: Icons.insights_rounded,
      route: '/insights',
    ),
    NavItem(
      label: 'Ask Zoe',
      icon: Icons.auto_awesome_rounded,
      route: '/zoe-chat',
    ),
    NavItem(
      label: 'Settings',
      icon: Icons.settings_rounded,
      route: '/profile/settings',
    ),
    NavItem(
      label: 'Notifications',
      icon: Icons.notifications_none_rounded,
      route: '/notifications',
    ),
  ];

  // ---------------------------------------------------------------------------
  // CLIENT
  // ---------------------------------------------------------------------------

  static const _clientDesktop = [
    NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
    NavItem(
      label: 'Orders',
      icon: Icons.shopping_bag_rounded,
      route: '/orders',
    ),
    NavItem(
      label: 'Find Tailor',
      icon: Icons.search_rounded,
      route: '/tailor-discovery',
    ),
    NavItem(
      label: 'Style Preferences',
      icon: Icons.edit_note_rounded,
      route: '/measurements-input',
    ),
    NavItem(
      label: 'My Measurements',
      icon: Icons.straighten_rounded,
      route: '/measurements-profile',
    ),
    NavItem(label: 'Shop', icon: Icons.storefront_rounded, route: '/designs'),
    NavItem(
      label: 'Favourites',
      icon: Icons.favorite_border_rounded,
      route: '/saved-designs',
    ),
    // 'Favorites' (/favorites) was removed from the nav as a duplicate of
    // 'Favourites' above. The route and FavoritesPage are intentionally left
    // wired up: marketplace_header.dart still navigates to /favorites directly,
    // and any saved deep link still resolves.
    NavItem(
      label: 'Design Upload',
      icon: Icons.add_photo_alternate_rounded,
      route: '/design-upload',
    ),
    NavItem(
      label: 'Virtual Try-On',
      icon: Icons.checkroom_rounded,
      route: '/virtual-tryon',
    ),
    // 'AI Body Scan' (/ai-body-scan) was removed from the nav and merged into
    // 'My Measurements' (/measurements-profile), which now hosts the scan entry
    // and the saved list. The route stays registered for deep links.
    NavItem(
      label: 'Referrals',
      icon: Icons.card_giftcard_rounded,
      route: '/referrals',
    ),
    NavItem(label: 'Messages', icon: Icons.forum_rounded, route: '/chats'),
    NavItem(
      label: 'Ask Zoe',
      icon: Icons.auto_awesome_rounded,
      route: '/zoe-chat',
    ),
    NavItem(
      label: 'Insights',
      icon: Icons.insights_rounded,
      route: '/insights',
    ),
    NavItem(
      label: 'Settings',
      icon: Icons.settings_rounded,
      route: '/profile/settings',
    ),
    NavItem(
      label: 'Notifications',
      icon: Icons.notifications_none_rounded,
      route: '/notifications',
    ),
  ];

  static const _clientMobile = [
    NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
    NavItem(
      label: 'Orders',
      icon: Icons.shopping_bag_rounded,
      route: '/orders',
    ),
    NavItem(
      label: 'Find Tailor',
      icon: Icons.search_rounded,
      route: '/tailor-discovery',
    ),
    NavItem(
      label: 'Alerts',
      icon: Icons.notifications_none_rounded,
      route: '/notifications',
    ),
    NavItem(label: 'Profile', icon: Icons.person_rounded, route: '/profile'),
  ];

  static const _clientDrawer = [
    NavItem(
      label: 'My Measurements',
      icon: Icons.straighten_rounded,
      route: '/measurements-profile',
    ),
    // 'AI Body Scan' (/ai-body-scan) was removed from the nav and merged into
    // 'My Measurements' (/measurements-profile), which now hosts the scan entry
    // and the saved list. The route stays registered for deep links.
    NavItem(
      label: 'Virtual Try-On',
      icon: Icons.checkroom_rounded,
      route: '/virtual-tryon',
    ),
    NavItem(label: 'Shop', icon: Icons.storefront_rounded, route: '/designs'),
    NavItem(
      label: 'Favourites',
      icon: Icons.favorite_border_rounded,
      route: '/saved-designs',
    ),
    // 'Favorites' (/favorites) was removed from the nav as a duplicate of
    // 'Favourites' above. The route and FavoritesPage are intentionally left
    // wired up: marketplace_header.dart still navigates to /favorites directly,
    // and any saved deep link still resolves.
    NavItem(
      label: 'Design Upload',
      icon: Icons.add_photo_alternate_rounded,
      route: '/design-upload',
    ),
    NavItem(
      label: 'Style Preferences',
      icon: Icons.edit_note_rounded,
      route: '/measurements-input',
    ),
    NavItem(
      label: 'Referrals',
      icon: Icons.card_giftcard_rounded,
      route: '/referrals',
    ),
    NavItem(
      label: 'Insights',
      icon: Icons.insights_rounded,
      route: '/insights',
    ),
    NavItem(
      label: 'Ask Zoe',
      icon: Icons.auto_awesome_rounded,
      route: '/zoe-chat',
    ),
    NavItem(
      label: 'Settings',
      icon: Icons.settings_rounded,
      route: '/profile/settings',
    ),
    NavItem(
      label: 'Notifications',
      icon: Icons.notifications_none_rounded,
      route: '/notifications',
    ),
  ];

  // ---------------------------------------------------------------------------
  // APPRENTICE
  // ---------------------------------------------------------------------------

  static const _apprenticeDesktop = [
    NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
    NavItem(label: 'Tasks', icon: Icons.assignment_rounded, route: '/tasks'),
    NavItem(
      label: 'Curriculum',
      icon: Icons.menu_book_rounded,
      route: '/curriculum',
    ),
    NavItem(
      label: 'Progress',
      icon: Icons.trending_up_rounded,
      route: '/progress',
    ),
    NavItem(label: 'Mentors', icon: Icons.person_rounded, route: '/mentors'),
    NavItem(
      label: 'Masterclass',
      icon: Icons.play_circle_outline_rounded,
      route: '/masterclass',
    ),
    NavItem(
      label: 'Portfolio',
      icon: Icons.photo_library_rounded,
      route: '/portfolio',
    ),
    NavItem(
      label: 'Badges',
      icon: Icons.emoji_events_rounded,
      route: '/badges',
    ),
    NavItem(
      label: 'Certificates',
      icon: Icons.workspace_premium_rounded,
      route: '/certificates',
    ),
    NavItem(
      label: 'Showcase',
      icon: Icons.star_border_rounded,
      route: '/showcase',
    ),
    NavItem(label: 'Messages', icon: Icons.forum_rounded, route: '/chats'),
    NavItem(
      label: 'Ask Zoe',
      icon: Icons.auto_awesome_rounded,
      route: '/zoe-chat',
    ),
    NavItem(
      label: 'Settings',
      icon: Icons.settings_rounded,
      route: '/profile/settings',
    ),
  ];

  static const _apprenticeMobile = [
    NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
    NavItem(label: 'Tasks', icon: Icons.assignment_rounded, route: '/tasks'),
    NavItem(
      label: 'Learn',
      icon: Icons.menu_book_rounded,
      route: '/curriculum',
    ),
    NavItem(label: 'Messages', icon: Icons.forum_rounded, route: '/chats'),
    NavItem(label: 'Profile', icon: Icons.person_rounded, route: '/profile'),
  ];

  static const _apprenticeDrawer = [
    NavItem(
      label: 'Progress',
      icon: Icons.trending_up_rounded,
      route: '/progress',
    ),
    NavItem(label: 'Mentors', icon: Icons.person_rounded, route: '/mentors'),
    NavItem(
      label: 'Masterclass',
      icon: Icons.play_circle_outline_rounded,
      route: '/masterclass',
    ),
    NavItem(
      label: 'Portfolio',
      icon: Icons.photo_library_rounded,
      route: '/portfolio',
    ),
    NavItem(
      label: 'Badges',
      icon: Icons.emoji_events_rounded,
      route: '/badges',
    ),
    NavItem(
      label: 'Certificates',
      icon: Icons.workspace_premium_rounded,
      route: '/certificates',
    ),
    NavItem(
      label: 'Showcase',
      icon: Icons.star_border_rounded,
      route: '/showcase',
    ),
    NavItem(
      label: 'Ask Zoe',
      icon: Icons.auto_awesome_rounded,
      route: '/zoe-chat',
    ),
    NavItem(
      label: 'Settings',
      icon: Icons.settings_rounded,
      route: '/profile/settings',
    ),
    NavItem(
      label: 'Notifications',
      icon: Icons.notifications_none_rounded,
      route: '/notifications',
    ),
  ];

  // ---------------------------------------------------------------------------
  // FABRIC SELLER
  // ---------------------------------------------------------------------------

  static const _fabricSellerDesktop = [
    NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
    NavItem(
      label: 'Orders',
      icon: Icons.shopping_cart_rounded,
      route: '/orders',
    ),
    NavItem(
      label: 'Marketplace',
      icon: Icons.storefront_rounded,
      route: '/marketplace',
    ),
    NavItem(
      label: 'Upload',
      icon: Icons.add_photo_alternate_rounded,
      route: '/fabric-upload',
    ),
    NavItem(
      label: 'Inventory',
      icon: Icons.inventory_2_rounded,
      route: '/inventory',
    ),
    NavItem(
      label: 'AI Pricing',
      icon: Icons.auto_awesome_rounded,
      route: '/ai-pricing',
    ),
    NavItem(
      label: 'Storefront',
      icon: Icons.storefront_rounded,
      route: '/storefront',
    ),
    NavItem(
      label: 'Seller Portfolio',
      icon: Icons.photo_library_rounded,
      route: '/seller-portfolio',
    ),
    NavItem(
      label: 'Low Stock',
      icon: Icons.warning_amber_rounded,
      route: '/low-stock',
    ),
    NavItem(
      label: 'Wallet',
      icon: Icons.account_balance_wallet_rounded,
      route: '/merchant-wallet',
    ),
    NavItem(label: 'Messages', icon: Icons.forum_rounded, route: '/chats'),
    NavItem(
      label: 'Ask Zoe',
      icon: Icons.auto_awesome_rounded,
      route: '/zoe-chat',
    ),
    NavItem(
      label: 'Settings',
      icon: Icons.settings_rounded,
      route: '/profile/settings',
    ),
  ];

  static const _fabricSellerMobile = [
    NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/main'),
    NavItem(
      label: 'Orders',
      icon: Icons.shopping_bag_rounded,
      route: '/orders',
    ),
    NavItem(
      label: 'Market',
      icon: Icons.storefront_rounded,
      route: '/marketplace',
    ),
    NavItem(label: 'Messages', icon: Icons.forum_rounded, route: '/chats'),
    NavItem(label: 'Profile', icon: Icons.person_rounded, route: '/profile'),
  ];

  static const _fabricSellerDrawer = [
    NavItem(
      label: 'Upload',
      icon: Icons.add_photo_alternate_rounded,
      route: '/fabric-upload',
    ),
    NavItem(
      label: 'Inventory',
      icon: Icons.inventory_2_rounded,
      route: '/inventory',
    ),
    NavItem(
      label: 'AI Pricing',
      icon: Icons.auto_awesome_rounded,
      route: '/ai-pricing',
    ),
    NavItem(
      label: 'Storefront',
      icon: Icons.storefront_rounded,
      route: '/storefront',
    ),
    NavItem(
      label: 'Seller Portfolio',
      icon: Icons.photo_library_rounded,
      route: '/seller-portfolio',
    ),
    NavItem(
      label: 'Low Stock',
      icon: Icons.warning_amber_rounded,
      route: '/low-stock',
    ),
    NavItem(
      label: 'Wallet',
      icon: Icons.account_balance_wallet_rounded,
      route: '/merchant-wallet',
    ),
    NavItem(
      label: 'Ask Zoe',
      icon: Icons.auto_awesome_rounded,
      route: '/zoe-chat',
    ),
    NavItem(
      label: 'Settings',
      icon: Icons.settings_rounded,
      route: '/profile/settings',
    ),
    NavItem(
      label: 'Notifications',
      icon: Icons.notifications_none_rounded,
      route: '/notifications',
    ),
  ];
}

/// Lightweight nav item model (avoids circular dependency with core/models/nav_item.dart).
class NavItem {
  final String label;
  final IconData icon;
  final String route;

  const NavItem({required this.label, required this.icon, required this.route});
}
