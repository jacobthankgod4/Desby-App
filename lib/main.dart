import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:desby_app/core/providers/theme_provider.dart';

import 'package:desby_app/core/widgets/desktop_shell_wrapper.dart';
import 'features/chat/presentation/pages/chat_detail_page.dart';
import 'features/chat/presentation/pages/chat_list_page.dart';
import 'core/constants/user_types.dart';
import 'core/storage/local_storage.dart';
import 'package:desby_app/core/storage/storage_keys.dart';
import 'package:desby_app/core/providers/navigation_provider.dart';
import 'theme/app_theme.dart';

import 'config/environment.dart';
import 'core/network/realtime_provider.dart';

import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/auth/presentation/pages/onboarding_page.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'features/auth/presentation/pages/verify_email_page.dart';

import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/state/auth_state.dart' as local_auth;

import 'features/apprenticeship/presentation/pages/apprentice_onboarding_page.dart';
import 'features/clients/presentation/pages/client_list_page.dart';
import 'features/clients/presentation/pages/client_detail_page.dart';
import 'features/clients/presentation/pages/client_onboarding_page.dart';
import 'features/clients/presentation/pages/unified_add_client_page.dart';
import 'features/clients/presentation/pages/measurement_hub_page.dart';
import 'features/clients/presentation/pages/measurement_profile_page.dart';

import 'features/dashboard/presentation/pages/main_page.dart';
import 'features/dashboard/presentation/pages/fabric_seller_dashboard.dart';

import 'features/designs/presentation/pages/measurement_input_page.dart';
import 'features/designs/presentation/pages/design_gallery_page.dart';
import 'features/designs/presentation/pages/ai_body_scan_page.dart';

import 'features/marketplace/presentation/pages/fabric_seller_onboarding_page.dart';
import 'features/marketplace/presentation/pages/fabric_catalog_page.dart';
import 'features/marketplace/presentation/pages/fabric_upload_page.dart';
import 'features/marketplace/presentation/pages/fabric_detail_page.dart';

import 'features/orders/presentation/pages/order_list_page.dart';
import 'features/orders/presentation/pages/order_detail_page.dart';
import 'features/orders/presentation/pages/order_create_page.dart';
import 'features/orders/presentation/pages/booking_cart_page.dart';
import 'features/orders/presentation/pages/delivery_setup_page.dart';
import 'features/orders/presentation/pages/price_estimation_page.dart';
import 'features/orders/presentation/pages/delivery_tracking_page.dart';

import 'features/payments/presentation/pages/subscription_plans_page.dart';
import 'features/payments/presentation/pages/checkout_page.dart';
import 'features/profile/presentation/pages/profile_view_page.dart';
import 'features/profile/presentation/pages/profile_edit_page.dart';
import 'features/profile/presentation/pages/settings_page.dart';

import 'features/notifications/presentation/pages/notification_center_page.dart';
import 'features/analytics/presentation/pages/insights_dashboard.dart';
import 'features/analytics/presentation/pages/reports_page.dart';
import 'features/analytics/presentation/pages/ai_insights_page.dart';

import 'features/marketplace/presentation/pages/merchant_wallet_page.dart';

import 'features/tailor/presentation/pages/tailor_onboarding_page.dart';
import 'features/tailor/presentation/pages/tailor_profile_page.dart';
import 'features/tailor/presentation/pages/tailor_availability_page.dart';
import 'features/tailor/domain/entities/shop_product.dart';
import 'features/tailor/presentation/pages/virtual_atelier_page.dart';
import 'features/tailor/presentation/pages/pricing_setup_page.dart';
import 'features/tailor/presentation/pages/tailor_discovery_page.dart';
import 'features/tailor/presentation/pages/product_details_page.dart';
import 'features/tailor/presentation/pages/shop_setup_page.dart';

const bool kIsInTest = bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('--- DESBY OS BOOT SEQUENCE START ---');

  try {
    debugPrint('[BOOT] Initializing local storage...');
    await localStorage.initialize();
    debugPrint('[BOOT] Local storage initialized');
  } catch (e) {
    debugPrint('[BOOT] Local storage initialization error: $e');
  }

  try {
    await Environment.initialize();
    debugPrint('[BOOT] Environment initialized');
  } catch (e) {
    debugPrint('[BOOT] Environment initialization error: $e');
  }

  try {
    debugPrint('[BOOT] Initializing Supabase...');
    final supabaseUrl = Environment.current.supabaseUrl.trim();
    final anonKey = Environment.current.supabaseAnonKey.trim();
    
    if (supabaseUrl.isEmpty || anonKey.isEmpty) {
      debugPrint('[BOOT] ❌ CRITICAL: Supabase credentials are empty!');
    } else {
      // Forensic masking for security while providing diagnostic proof
      final maskedKey = "${anonKey.substring(0, 5)}...${anonKey.substring(anonKey.length - 5)}";
      debugPrint('[BOOT] Supabase Target: $supabaseUrl');
      debugPrint('[BOOT] Supabase Key: $maskedKey');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: anonKey,
      debug: true,
    );
    debugPrint('[BOOT] Supabase successfully initialized');
  } catch (e) {
    debugPrint('[BOOT] Supabase initialization error: $e');
  }

  runApp(
    const ProviderScope(
      child: DesbyApp(),
    ),
  );

  debugPrint('--- DESBY OS BOOT SEQUENCE COMPLETE ---');
}

class DesbyApp extends ConsumerWidget {
  const DesbyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);

    // Avoid starting realtime connection during widget tests.
    if (!kIsInTest) {
      ref.watch(realtimeServiceProvider);
    }

    return MaterialApp(
      title: 'Desby OS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/onboarding': (context) => const OnboardingPage(),
        '/tailor-onboarding': (context) => const TailorOnboardingPage(),
        '/apprentice-onboarding': (context) => const ApprenticeOnboardingPage(),
        '/client-onboarding': (context) => const ClientOnboardingPage(),
        '/fabric-seller-onboarding': (context) => const FabricSellerOnboardingPage(),
        '/splash': (context) => const SplashScreen(),
        '/verify-email': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return VerifyEmailPage(email: email);
        },
        '/main': (context) {
          // Reset navigation provider to /main when entering from home
          // This ensures deep links or direct navigation to /main reflect the correct internal state
          return Consumer(
            builder: (context, ref, child) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ref.read(navigationProvider).route != '/main') {
                   ref.read(navigationProvider.notifier).state = const NavigationState('/main');
                }
              });
              return const MainPage();
            },
          );
        },
        '/tailor-discovery': (context) => DesktopShellWrapper(title: 'Find Designer', child: TailorDiscoveryPage()),
        '/clients': (context) => DesktopShellWrapper(title: 'Client Database', child: ClientListPage()),
        '/client-detail': (context) => DesktopShellWrapper(
              title: 'Client Profile',
              child: ClientDetailPage(
                clientId: ModalRoute.of(context)?.settings.arguments as String? ?? '',
              ),
            ),
        '/orders': (context) => DesktopShellWrapper(title: 'Garment Pipeline', child: OrderListPage()),
        '/unified-add-client': (context) => DesktopShellWrapper(title: 'Add Client', child: UnifiedAddClientPage()),
        '/fabric-upload': (context) => DesktopShellWrapper(title: 'Upload Fabric', child: FabricUploadPage()),
        '/fabric-seller-dashboard': (context) => DesktopShellWrapper(title: 'Seller Dashboard', child: FabricSellerDashboard()),
        '/subscription-plans': (context) => DesktopShellWrapper(title: 'System Upgrade', child: SubscriptionPlansPage()),
        '/order-detail': (context) => DesktopShellWrapper(
              title: 'Manifest Details',
              child: OrderDetailPage(
                orderId: ModalRoute.of(context)?.settings.arguments as String? ?? '',
              ),
            ),
        '/order-create': (context) => DesktopShellWrapper(title: 'New Manifest', child: OrderCreatePage()),
        '/measurements-hub': (context) => DesktopShellWrapper(title: 'Bespoke Station', child: MeasurementHubPage()),
        '/measurements-input': (context) => DesktopShellWrapper(title: 'Fitting Station', child: MeasurementInputPage()),
        '/measurements-profile': (context) => DesktopShellWrapper(title: 'Digital Dossier', child: MeasurementProfilePage()),
        '/ai-body-scan': (context) => DesktopShellWrapper(title: 'Neural Scan', child: AiBodyScanPage()),
        '/designs': (context) => DesktopShellWrapper(title: 'Visual Vault', child: DesignGalleryPage()),
        '/marketplace': (context) => DesktopShellWrapper(title: 'Textile Market', child: FabricCatalogPage()),
        '/checkout': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          return DesktopShellWrapper(
            title: 'Secure Checkout',
            child: CheckoutPage(
              amount: (args['amount'] as num?)?.toDouble() ?? 0.0,
              orderId: args['orderId'] ?? 'MKT_${DateTime.now().millisecondsSinceEpoch}',
            ),
          );
        },
        '/profile': (context) {
          final argsUserId = ModalRoute.of(context)?.settings.arguments as String?;
          return DesktopShellWrapper(
            title: 'My Dossier',
            child: _ProfileWrapper(userId: argsUserId),
          );
        },
        '/profile/settings': (context) => DesktopShellWrapper(title: 'System Settings', child: SettingsPage()),
        '/insights': (context) => DesktopShellWrapper(title: 'Business Intel', child: InsightsDashboard()),
        '/notifications': (context) => DesktopShellWrapper(title: 'Comm Center', child: NotificationCenterPage()),
        '/shop-setup': (context) => DesktopShellWrapper(title: 'Atelier Config', child: ShopSetupPage()),
        '/virtual-atelier': (context) => DesktopShellWrapper(title: 'Virtual Atelier', child: VirtualAtelierPage()),
        '/pricing-setup': (context) => DesktopShellWrapper(title: 'Pricing Model', child: PricingSetupPage()),
        '/chats': (context) => DesktopShellWrapper(title: 'Encrypted Comms', child: ChatListPage()),
        '/chat-detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          return ChatDetailPage(
            conversationId: args['conversationId'] ?? '',
            peerId: args['peerId'],
            orderId: args['orderId'],
          );
        },
        '/profile/edit': (context) {
          final argsUserId = ModalRoute.of(context)?.settings.arguments as String?;
          return _ProfileEditWrapper(userId: argsUserId);
        },
        '/tailor-profile': (context) {
          final id = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return TailorProfilePage(tailorId: id);
        },
        '/tailor-availability': (context) => TailorAvailabilityPage(
              tailor: ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {},
            ),
        '/booking-cart': (context) => BookingCartPage(
              tailor: ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {},
            ),
        '/delivery-setup': (context) => DeliverySetupPage(
              tailor: ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {},
            ),
        '/price-estimation': (context) => PriceEstimationPage(
              tailor: ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {},
            ),
        '/delivery-tracking': (context) => DeliveryTrackingPage(
              fezOrderNo: ModalRoute.of(context)?.settings.arguments as String? ?? '',
            ),
        '/product-details': (context) {
          final product = ModalRoute.of(context)?.settings.arguments as ShopProduct;
          return ProductDetailsPage(product: product);
        },
        '/reports': (context) => DesktopShellWrapper(title: 'Data Reports', child: ReportsPage()),
        '/ai-insights': (context) => DesktopShellWrapper(title: 'AI Intel', child: AIInsightsPage()),
        '/merchant-wallet': (context) => DesktopShellWrapper(title: 'Merchant Wallet', child: const MerchantWalletPage()),
        '/fabric-details': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          return DesktopShellWrapper(
            title: 'Textile Analysis',
            child: FabricDetailPage(
              fabricId: args['fabricId'] ?? '',
            ),
          );
        },
      },
      home: _buildHome(authState),
    );
  }
}

Widget _buildHome(local_auth.AuthState authState) {
  if (kIsInTest) {
    return const LoginPage();
  }

  return authState.map(
    initial: (_) => const SplashScreen(),
    loading: (_) => const _PulseLoader(),
    unverified: (state) => VerifyEmailPage(email: state.email),
    authenticated: (auth) {
      final userType = localStorage.get(StorageKeys.userType, defaultValue: '');
      final tailorOnboarded = localStorage.get(StorageKeys.tailorOnboardingComplete, defaultValue: false);
      final apprenticeOnboarded = localStorage.get(StorageKeys.apprenticeOnboardingComplete, defaultValue: false);
      final clientOnboarded = localStorage.get(StorageKeys.clientOnboardingComplete, defaultValue: false);
      final fabricSellerOnboarded = localStorage.get(StorageKeys.fabricSellerOnboardingComplete, defaultValue: false);

      if (userType == UserType.tailor.value && tailorOnboarded != true) {
        return const TailorOnboardingPage();
      }
      if (userType == UserType.apprentice.value && apprenticeOnboarded != true) {
        return const ApprenticeOnboardingPage();
      }
      if (userType == UserType.client.value && clientOnboarded != true) {
        return const ClientOnboardingPage();
      }
      if (userType == UserType.fabricSeller.value && fabricSellerOnboarded != true) {
        return const FabricSellerOnboardingPage();
      }

      return const MainPage();
    },
    unauthenticated: (_) {
      final hasOnboarded = localStorage.get(StorageKeys.appFirstLaunch, defaultValue: false);
      if (!hasOnboarded) {
        return const OnboardingPage();
      }
      return const LoginPage();
    },
    error: (error) => Scaffold(
      backgroundColor: const Color(0xFF0A1921),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Authentication Error', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              error.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                localStorage.delete(StorageKeys.currentUser);
                localStorage.delete(StorageKeys.accessToken);
              },
              child: const Text('Return to Login'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PulseLoader extends StatefulWidget {
  const _PulseLoader();

  @override
  State<_PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<_PulseLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1921),
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Image.asset('assets/images/logo.png', height: 100),
        ),
      ),
    );
  }
}

class _ProfileWrapper extends ConsumerWidget {
  final String? userId;
  const _ProfileWrapper({this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = userId ?? ref.watch(currentUserProvider)?.id ?? '';
    if (currentUserId.isEmpty) return const LoginPage();
    return ProfileViewPage(userId: currentUserId);
  }
}

class _ProfileEditWrapper extends ConsumerWidget {
  final String? userId;
  const _ProfileEditWrapper({this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = userId ?? ref.watch(currentUserProvider)?.id ?? '';
    if (currentUserId.isEmpty) return const LoginPage();
    return ProfileEditPage(userId: currentUserId);
  }
}
