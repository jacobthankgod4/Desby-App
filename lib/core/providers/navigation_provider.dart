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
}

/// Navigation Provider - Manages the current active route within the Main OS Shell
/// Allows any component to trigger a screen switch without breaking the shell context.
final navigationProvider = StateProvider<NavigationState>((ref) => const NavigationState('/main'));

extension NavigationStateExtension on StateController<NavigationState> {
  set route(String value) => state = NavigationState(value);
}

/// Helper to get the display title for a given route
String getPageTitle(String route) {
  if (route.startsWith('/chat-detail')) return 'Encrypted Channel';
  if (route.startsWith('/client-detail')) return 'Client Profile';
  if (route.startsWith('/order-detail')) return 'Manifest Details';
  if (route.startsWith('/fabric-details')) return 'Textile Analysis';

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
    default: return 'Desby OS';
  }
}
