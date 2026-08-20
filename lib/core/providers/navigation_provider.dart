import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Navigation Stack Notifier - Manages a history of navigation states within the shell
class NavigationStackNotifier extends StateNotifier<List<NavigationState>> {
  NavigationStackNotifier() : super([const NavigationState('/main')]);

  NavigationState get current => state.last;

  void push(String route, [Map<String, dynamic>? arguments]) {
    final newState = NavigationState(route, arguments);
    if (state.last == newState) return; // Prevent double pushing
    state = [...state, newState];
  }

  /// Sets the route, clearing history if it's a root-level switch
  void set(String route, [Map<String, dynamic>? arguments]) {
    final newState = NavigationState(route, arguments);
    // If it's a main tab switch, we usually want to clear history
    if (route == '/main' || route == '/orders' || route == '/clients' || 
        route == '/chats' || route == '/marketplace' || route == '/profile') {
      state = [newState];
    } else {
      push(route, arguments);
    }
  }

  void pop() {
    if (state.length > 1) {
      state = state.sublist(0, state.length - 1);
    } else {
      // Already at root, maybe reset to main
      state = [const NavigationState('/main')];
    }
  }

  bool get canPop => state.length > 1;
}

/// Navigation Provider - Manages the current active route stack within the Main OS Shell
final navigationStackProvider = StateNotifierProvider<NavigationStackNotifier, List<NavigationState>>((ref) {
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

/// Helper to get the display title for a given route
String getPageTitle(String route) {
  if (route.startsWith('/chat-detail')) return 'Encrypted Channel';
  if (route.startsWith('/client-detail')) return 'Client Profile';
  if (route.startsWith('/order-detail')) return 'Manifest Details';
  if (route.startsWith('/fabric-details')) return 'Textile Analysis';
  if (route.startsWith('/tailor-profile')) return 'Designer Profile';
  if (route.startsWith('/booking-cart')) return 'Booking Cart';
  if (route.startsWith('/price-estimation')) return 'Price Estimate';
  if (route.startsWith('/delivery-setup')) return 'Logistics Setup';
  if (route.startsWith('/checkout')) return 'Secure Checkout';

  switch (route) {
    case '/main': return 'Command Center';
    case '/orders': return 'Garment Pipeline';
    case '/clients': return 'Client Database';
    case '/unified-add-client': return 'Add Client';
    case '/order-create': return 'New Manifest';
    case '/marketplace': return 'Textile Market';
    case '/shop-setup': return 'Atelier Config';
    case '/pricing-setup': return 'Pricing Model';
    case '/insights': return 'Business Intel';
    case '/profile/settings': return 'System Settings';
    case '/profile': return 'My Dossier';
    case '/notifications': return 'Comm Center';
    case '/tailor-discovery': return 'Find Designer';
    case '/measurements-hub': return 'Fitting Hub';
    case '/measurements-input': return 'Fitting Station';
    case '/measurements-profile': return 'Digital Dossier';
    case '/fabric-upload': return 'Upload Fabric';
    case '/curriculum': return 'Academy Hub';
    case '/tasks': return 'Mission Control';
    case '/chats': return 'Encrypted Comms';
    case '/reports': return 'Data Reports';
    case '/ai-insights': return 'AI Intel';
    case '/merchant-wallet': return 'Merchant Wallet';
    case '/ai-body-scan': return 'Neural Scan';
    case '/designs': return 'Visual Vault';
    default: return 'Desby OS';
  }
}
