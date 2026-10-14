
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_storage.dart';
import '../storage/storage_keys.dart';
import '../utils/url_sync.dart';

/// Navigation State - Holds the current route and optional arguments
class NavigationState {
  final String route;
  final Map<String, dynamic>? arguments;

  const NavigationState(this.route, [this.arguments]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationState &&
          runtimeType == other.runtimeType &&
          route == other.route &&
          arguments == other.arguments;

  @override
  int get hashCode => route.hashCode ^ arguments.hashCode;

  @override
  String toString() => 'NavigationState(route: $route, arguments: $arguments)';
}

/// Onboarding routes -> completion-flag storage keys.
const Map<String, String> _onboardingCompletionKeys = {
  '/tailor-onboarding': StorageKeys.tailorOnboardingComplete,
  '/apprentice-onboarding': StorageKeys.apprenticeOnboardingComplete,
  '/client-onboarding': StorageKeys.clientOnboardingComplete,
  '/fabric-seller-onboarding': StorageKeys.fabricSellerOnboardingComplete,
};

/// Routes that reconstruct their own state on load and so may be entered
/// directly from a URL.
///
/// `/request-journey` rebuilds from the `order_drafts` table and redirects when
/// there is nothing to resume, so a reload is safe there.
const Set<String> _pageManagedRoutes = {'/request-journey'};

/// Recursively projects [value] into something `jsonEncode` accepts.
///
/// Primitives pass through. Maps/lists are walked so argument bundles (e.g. the
/// `tailor` map on `/booking-cart`) survive intact. Anything else that exposes a
/// String `id` is stored as `{idKey: id}` by the caller; opaque values are
/// dropped rather than written as something unusable.
dynamic _jsonSafe(dynamic value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is Map) {
    return value.map((k, v) => MapEntry('$k', _jsonSafe(v)));
  }
  if (value is Iterable) {
    return value.map(_jsonSafe).toList();
  }
  return _unsupported;
}

/// Sentinel: marks an argument we cannot serialise.
const Object _unsupported = Object();

/// Persists a JSON-safe projection of [arguments].
///
/// Domain objects (Design, ShopProduct, …) are stored as `<key>Id` by
/// duck-typing on an `id` field; the receiving page re-fetches them. That is
/// what makes an argument-taking route restorable after a reload.
String? _encodeArgs(Map<String, dynamic>? arguments) {
  if (arguments == null || arguments.isEmpty) return null;
  final enc = <String, dynamic>{};
  arguments.forEach((key, value) {
    final safe = _jsonSafe(value);
    if (!identical(safe, _unsupported)) {
      enc[key] = safe;
      return;
    }
    try {
      final id = (value as dynamic).id;
      if (id is String) enc['${key}Id'] = id;
    } catch (_) {
      // Not identifiable — omit rather than persist something unusable.
    }
  });
  if (enc.isEmpty) return null;
  try {
    return jsonEncode(enc);
  } catch (_) {
    return null;
  }
}

String? encodeNavigationArgs(Map<String, dynamic>? arguments) =>
    _encodeArgs(arguments);

/// Reads back what [_encodeArgs] wrote. Returns null when nothing was stored.
Map<String, dynamic>? decodeNavigationArgs(String? raw) => _decodeArgs(raw);

/// Reads back what [_encodeArgs] wrote. Returns null when nothing was stored.
Map<String, dynamic>? _decodeArgs(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  } catch (_) {
    return null;
  }
}

/// Reads the initial navigation state from the browser URL hash, else from the
/// last persisted route (+ its arguments), else falls back to `/main`.
NavigationState _readInitialNavigation() {
  if (!kIsWeb) return const NavigationState('/main');
  try {
    final fragment = readUrlHash();
    if (fragment.isNotEmpty && fragment.length > 1) {
      // Supabase reports auth callback failures in the fragment, e.g.
      //   #error=access_denied&error_code=otp_expired
      // Treat that as "go to email verification" rather than a route, so the
      // user can request a fresh link instead of silently landing on a generic
      // page with a dead error in the URL.
      if (fragment.startsWith('error=') || fragment.contains('error_code=')) {
        return const NavigationState('/verify-email');
      }
      final route = fragment.substring(1); // Remove leading #
      if (route.startsWith('/') && route.length > 1) {
        final flagKey = _onboardingCompletionKeys[route];
        if (flagKey != null) {
          final completed = localStorage.get(flagKey, defaultValue: false);
          if (completed == true) return const NavigationState('/main');
        }
        // A pasted or reloaded URL bypasses localStorage entirely, so the same
        // rule has to apply here. Without this, reloading
        // #/request-journey landed on a page that could never rebuild its state.
        if (_pageManagedRoutes.contains(route)) return NavigationState(route);
        if (!_isRestorable(route)) {
          debugPrint('[NAV] ignoring non-restorable URL route $route');
          return const NavigationState('/main');
        }
        return NavigationState(route);
      }
    }
  } catch (e) {
    debugPrint('[NAV] Error reading initial route: $e');
  }
  try {
    final saved = localStorage.get(StorageKeys.lastRoute);
    if (saved != null && saved is String && saved.startsWith('/')) {
      final flagKey = _onboardingCompletionKeys[saved];
      if (flagKey != null) {
        final completed = localStorage.get(flagKey, defaultValue: false);
        if (completed == true) return const NavigationState('/main');
      }

      // Persisted arguments make an argument-taking route rebuildable: the
      // page re-fetches its entity by id, so a reload resumes where the user
      // left off instead of dumping them on the dashboard.
      final args = _decodeArgs(
        localStorage.get(StorageKeys.lastRouteArgs, defaultValue: null) as String?,
      );
      if (_isRestorable(saved) || args != null) {
        return NavigationState(saved, args);
      }
      debugPrint('[NAV] not restoring argument-dependent route $saved');
    }
  } catch (_) {}
  return const NavigationState('/main');
}

/// Routes that receive their content through navigation arguments.
///
/// Arguments are persisted alongside the route (see `_encodeArgs`), so these
/// are restorable whenever enough of their arguments came back to rebuild the
/// page. Entity arguments are stored as `<key>Id` and re-fetched by a loader
/// widget in `main_page`; primitive arguments (ids, strings, numbers) restore
/// directly. This set exists so a route with *no* recoverable arguments falls
/// back to `/main` instead of mounting an empty shell.
const Set<String> _argumentDependentRoutes = {
  '/booking-cart',
  '/price-estimation',
  '/delivery-setup',
  '/tailor-availability',
  '/request-journey',
  '/shop-checkout',
  '/product-details',
  '/chat-detail',
  '/client-detail',
  '/order-detail',
  '/tailor-profile',
  '/delivery-tracking',
  '/verify-email',
};

/// Mid-transaction screens: `/checkout` and `/payment-callback`.
///
/// These used to be blocked from restoring because a reload mid-payment could
/// act twice on the same order. That is now handled properly rather than by
/// refusing to restore: payment still requires an explicit tap, `PaymentSession`
/// blocks a second reference for an order that already has one in flight, and
/// the callback page is stateless (it only reads `tx_ref`/`status` off the URL).
/// So they restore like any other route.
const Set<String> _transactionalRoutes = {'/checkout', '/payment-callback'};

/// Whether a route is safe to return to after a reload.
bool _isRestorable(String route) {
  // Transactional routes rebuild from their own guards / the URL itself.
  if (_transactionalRoutes.contains(route)) return true;
  if (_argumentDependentRoutes.contains(route)) return false;
  return true;
}

/// Syncs the browser URL hash to match the current route.
/// [push] = true uses pushState (creates new history entry for forward nav).
/// [push] = false uses replaceState (for initial load, pop, and stack reset).
/// Uses absolute path (not relative '#route') because the Flutter web
/// index.html has <base href="/"> which causes the browser to resolve
/// relative '#route' against the base href root, not the actual page path.
void _syncBrowserUrl(String route, {bool push = true, Map<String, dynamic>? arguments}) {
  if (!kIsWeb) return;
  try {
    final currentHash = readUrlHash();
    final targetHash = '#$route';
    if (currentHash != targetHash) {
      final basePath = getUrlPath();
      if (push) {
        pushUrlHash('$basePath$targetHash');
      } else {
        replaceUrlHash('$basePath$targetHash');
      }
    }
  } catch (e) {
    debugPrint('[NAV] Error syncing browser URL: $e');
  }
  try {
    localStorage.save(StorageKeys.lastRoute, route);
    final encoded = _encodeArgs(arguments);
    if (encoded == null) {
      localStorage.delete(StorageKeys.lastRouteArgs);
    } else {
      localStorage.save(StorageKeys.lastRouteArgs, encoded);
    }
  } catch (_) {}
}

/// Navigation Stack Notifier - Manages a history of navigation states within the shell
class NavigationStackNotifier extends StateNotifier<List<NavigationState>> {
  NavigationStackNotifier() : super([_readInitialNavigation()]) {
    // Sync initial route to URL (replaceState — don't create duplicate entry)
    _syncBrowserUrl(state.first.route,
        push: false, arguments: state.first.arguments);
    // Listen for browser back/forward button clicks
    if (kIsWeb) {
      try {
        listenToPopState(_onPopState);
      } catch (e) {
        debugPrint('[NAV] Error adding popstate listener: $e');
      }
    }
  }

  /// Handles browser back/forward button — syncs internal stack with URL hash
  void _onPopState(dynamic event) {
    if (!mounted) return;
    try {
      final hash = readUrlHash();
      if (hash.isNotEmpty && hash.length > 1) {
        final route = hash.substring(1);
        final currentRoute = state.last.route;
        if (route != currentRoute) {
          // Determine if this is a back (pop) or forward navigation
          if (state.length > 1 && state[state.length - 2].route == route) {
            // Going back — pop the stack
            state = state.sublist(0, state.length - 1);
          } else {
            // Navigating to a different route — set it
            final newState = NavigationState(route);
            state = [newState];
          }
        }
      }
    } catch (e) {
      debugPrint('[NAV] Error handling popstate: $e');
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      try {
        // No unsubscribe needed on web; the listener is bound once per session.
      } catch (_) {}
    }
    super.dispose();
  }

  NavigationState get current => state.last;

  void push(String route, [Map<String, dynamic>? arguments]) {
    final newState = NavigationState(route, arguments);
    if (state.last == newState) return; // Prevent double pushing
    state = [...state, newState];
    _syncBrowserUrl(route, push: true, arguments: arguments);
  }

  /// Sets the route, clearing history if it's a root-level switch.
  /// Uses replaceState for root resets (no new history entry).
  /// Uses pushState for sub-page navigation (creates history entry).
  void set(String route, [Map<String, dynamic>? arguments]) {
    final newState = NavigationState(route, arguments);
    // Root-level routes: reset stack (replaceState — no new history entry)
    if (route == '/main' ||
        route == '/orders' ||
        route == '/clients' ||
        route == '/chats' ||
        route == '/marketplace' ||
        route == '/profile' ||
        route == '/tasks' ||
        route == '/curriculum' ||
        route == '/academy' ||
        route == '/progress' ||
        route == '/mentors' ||
        route == '/masterclass' ||
        route == '/portfolio' ||
        route == '/badges' ||
        route == '/certificates' ||
        route == '/showcase' ||
        route == '/fabric-upload' ||
        route == '/inventory' ||
        route == '/ai-pricing' ||
        route == '/storefront' ||
        route == '/low-stock' ||
        route == '/merchant-wallet' ||
        route == '/designs' ||
        route == '/saved-designs' ||
        route == '/virtual-tryon' ||
        route == '/ai-body-scan' ||
        route == '/measurements-input' ||
        route == '/measurements-profile' ||
        route == '/tailor-discovery' ||
        route == '/insights' ||
        route == '/profile/settings' ||
        route == '/virtual-atelier' ||
        route == '/pricing-setup' ||
        route == '/ai-insights' ||
        route == '/reports' ||
        route == '/zoe-chat' ||
        route == '/curriculum-setup' ||
        route == '/unified-add-client' ||
        route == '/unified-add-apprentice' ||
        route == '/notifications' ||
        route == '/favorites' ||
        route == '/measurements-hub' ||
        route == '/design-upload' ||
        route == '/referrals' ||
        route == '/seller-portfolio' ||
        route == '/subscription-plans' ||
        route == '/shop-setup' ||
        route == '/product-list' ||
        route == '/add-product' ||
        route == '/tailor-onboarding' ||
        route == '/client-onboarding' ||
        route == '/apprentice-onboarding' ||
        route == '/fabric-seller-onboarding') {
      state = [newState];
      _syncBrowserUrl(route, push: false, arguments: arguments);
    } else {
      // Sub-page navigation: push (creates history entry)
      push(route, arguments);
    }
  }

  void pop() {
    if (state.length > 1) {
      state = state.sublist(0, state.length - 1);
    } else {
      // Already at root, reset to main
      state = [const NavigationState('/main')];
    }
    _syncBrowserUrl(state.last.route,
        push: false, arguments: state.last.arguments);
  }

  bool get canPop => state.length > 1;
}

/// Navigation Provider - Manages the current active route stack within the Main OS Shell
final navigationStackProvider =
    StateNotifierProvider<NavigationStackNotifier, List<NavigationState>>((
      ref,
    ) {
      return NavigationStackNotifier();
    });

/// Legacy compatibility provider (returns only the current state)
final navigationProvider = Provider<NavigationState>((ref) {
  return ref.watch(navigationStackProvider).last;
});

/// Extension for easier navigation from widgets
extension NavigationRefExtension on WidgetRef {
  void pushShell(String route, [Map<String, dynamic>? arguments]) {
    read(navigationStackProvider.notifier).push(route, arguments);
  }

  void setShell(String route, [Map<String, dynamic>? arguments]) {
    read(navigationStackProvider.notifier).set(route, arguments);
  }

  void popShell() {
    read(navigationStackProvider.notifier).pop();
  }

  bool get canPopShell => read(navigationStackProvider.notifier).canPop;
}

/// Finishes a user-onboarding flow and returns to the dashboard.
///
/// When onboarding ran INSIDE the shell (pushed via `pushShell` from the
/// drawer's "ACTION REQUIRED" alert), the current shell route is an onboarding
/// route — so we reset the shell back to `/main` via [NavigationRefExtension.setShell].
/// This avoids mounting a NEW MainPage on top of the existing one, which re-reads
/// `navigationStackProvider.current` (still the onboarding route) and re-renders
/// onboarding — the previous infinite-loop bug. Resetting also re-syncs the browser
/// URL to `#/main`, clearing the stale `#/<type>-onboarding` hash on web.
///
/// When onboarding ran as a full-screen named route (register / login flow, or
/// invite acceptance), the shell isn't involved — replace the named route with
/// `/main` on the Navigator instead.
void completeOnboarding(BuildContext context, WidgetRef ref) {
  final isOnboardingRoute = ref
      .read(navigationStackProvider)
      .last
      .route
      .contains('onboarding');
  if (isOnboardingRoute) {
    ref.setShell('/main');
  } else {
    Navigator.of(context).pushReplacementNamed('/main');
  }
}

/// Helper to get the display title for a given route
String getPageTitle(String route) {
  if (route.startsWith('/chat-detail')) return 'Chat';
  if (route.startsWith('/client-detail')) return 'Client Profile';
  if (route.startsWith('/order-detail')) return 'Order Details';
  if (route.startsWith('/fabric-details')) return 'Fabric Details';
  if (route.startsWith('/tailor-profile')) return 'Designer Profile';
  // Must come before '/checkout': the prefix would otherwise swallow it.
  if (route.startsWith('/request-journey')) return 'New Request';
  if (route.startsWith('/booking-cart')) return 'Booking Cart';
  if (route.startsWith('/price-estimation')) return 'Price Estimate';
  if (route.startsWith('/delivery-setup')) return 'Logistics Setup';
  if (route.startsWith('/checkout')) return 'Secure Checkout';

  switch (route) {
    case '/main':
      return 'Dashboard';
    case '/orders':
      return 'Orders';
    case '/clients':
      return 'Clients';
    case '/unified-add-client':
      return 'Add Client';
    case '/marketplace':
      return 'Fabric Marketplace';
    case '/shop-setup':
      return 'My Shop';
    case '/product-list':
      return 'My Shop';
    case '/add-product':
      return 'Add Product';
    case '/pricing-setup':
      return 'Pricing';
    case '/insights':
      return 'Insights';
    case '/profile/settings':
      return 'Settings';
    case '/profile':
      return 'My Profile';
    case '/notifications':
      return 'Notifications';
    case '/tailor-discovery':
      return 'Find Tailors';
    case '/measurements-hub':
      // Merged into My Measurements.
      return 'My Measurements';
    case '/measurements-input':
      return 'Style Preferences';
    case '/measurements-profile':
      return 'Measurement Profile';
    case '/fabric-upload':
      return 'Upload Fabric';
    case '/curriculum':
      return 'Learning';
    case '/academy':
      return 'Academy';
    case '/tasks':
      return 'Tasks';
    case '/chats':
      return 'Messages';
    case '/reports':
      return 'Reports';
    case '/ai-insights':
      return 'AI Insights';
    case '/merchant-wallet':
      return 'Wallet';
    case '/ai-body-scan':
      return 'Body Scan';
    case '/designs':
      return 'Shop';
    case '/design-details':
      return 'Design Details';
    case '/saved-designs':
      return 'Saved Designs';
    case '/virtual-tryon':
      return 'Virtual Try-On';
    case '/subscription-plans':
      return 'Subscription';
    case '/invite':
      return 'Complete Profile';
    case '/profile/edit':
      return 'Edit Profile';
    case '/product-details':
      return 'Product Details';
    case '/measurement-explorer':
      return 'Measurement Explorer';
    case '/inventory':
      return 'My Inventory';
    case '/progress':
      return 'Progress';
    case '/mentors':
      return 'Mentors';
    case '/tailor-onboarding':
      return 'Tailor Setup';
    case '/client-onboarding':
      return 'Client Setup';
    case '/apprentice-onboarding':
      return 'Apprentice Setup';
    case '/fabric-seller-onboarding':
      return 'Seller Setup';
    case '/badges':
      return 'My Badges';
    case '/certificates':
      return 'Certificates';
    case '/portfolio':
      return 'My Portfolio';
    case '/showcase':
      return 'Showcase';
    case '/masterclass':
      return 'Masterclasses';
    case '/referrals':
      return 'Invite Friends';
    case '/ai-pricing':
      return 'AI Pricing';
    case '/storefront':
      return 'My Storefront';
    case '/low-stock':
      return 'Low Stock Alerts';
    case '/virtual-atelier':
      return 'My Shop';
    case '/curriculum-setup':
      return 'Curriculum';
    case '/unified-add-apprentice':
      return 'Add Apprentice';
    case '/zoe-chat':
      return 'Ask Zoe';
    default:
      return 'Desby OS';
  }
}
