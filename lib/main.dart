import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:desby_app/core/providers/theme_provider.dart';

import 'features/chat/presentation/pages/chat_detail_page.dart';
import 'features/payments/domain/platform_money_config.dart';
import 'core/constants/user_types.dart';
import 'core/storage/local_storage.dart';
import 'package:desby_app/core/storage/storage_keys.dart';
import 'theme/app_theme.dart';
import 'theme/colors.dart';

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
import 'features/apprenticeship/presentation/pages/apprentice_invite_accept_page.dart';
import 'features/clients/presentation/pages/client_onboarding_page.dart';
import 'features/clients/presentation/pages/invite_page.dart';

import 'features/dashboard/presentation/pages/main_page.dart';

import 'features/marketplace/presentation/pages/fabric_seller_onboarding_page.dart';

import 'features/orders/presentation/pages/booking_cart_page.dart';
import 'features/checkout/presentation/pages/request_journey_page.dart';
import 'features/orders/presentation/pages/delivery_setup_page.dart';
import 'features/orders/presentation/pages/price_estimation_page.dart';
import 'features/orders/presentation/pages/delivery_tracking_page.dart';
import 'features/payments/presentation/pages/checkout_page.dart';

import 'features/payments/presentation/pages/payment_callback_page.dart';
import 'features/profile/presentation/pages/profile_edit_page.dart';

import 'features/tailor/presentation/pages/tailor_onboarding_page.dart';
import 'features/tailor/presentation/pages/tailor_profile_page.dart';
import 'features/tailor/presentation/pages/tailor_availability_page.dart';
import 'features/tailor/domain/entities/shop_product.dart';
import 'features/tailor/presentation/pages/product_details_page.dart';
import 'features/admin/presentation/pages/admin_dashboard_page.dart';

const bool kIsInTest = bool.fromEnvironment(
  'FLUTTER_TEST',
  defaultValue: false,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Console-noise filter (E1): flutter_map aborts obsolete OSM tile requests
  // as tiles leave the viewport; package:http then throws
  // "Request aborted by `abortTrigger`" — benign by design, but it logged as
  // dozens of console errors per session. Drop exactly that case and keep
  // every other error on the default reporting path.
  bool isBenignTileAbort(Object error) =>
      error.toString().contains('abortTrigger');
  FlutterError.onError = (FlutterErrorDetails details) {
    if (isBenignTileAbort(details.exception)) return;
    FlutterError.presentError(details);
  };
  WidgetsBinding.instance.platformDispatcher.onError =
      (Object error, StackTrace stack) {
        if (isBenignTileAbort(error)) return true; // swallowed — handled
        return false; // default reporting
      };

  // Initialize Supabase BEFORE runApp — auth provider accesses it immediately
  try {
    await Environment.initialize();
    final supabaseUrl = Environment.current.supabaseUrl.trim();
    final anonKey = Environment.current.supabaseAnonKey.trim();
    if (supabaseUrl.isNotEmpty && anonKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: anonKey,
        debug: false,
      );
      debugPrint('[BOOT] Supabase initialized');
    }
  } catch (e) {
    debugPrint('[BOOT] Supabase init error: $e');
  }

  // Initialize localStorage BEFORE runApp so theme preference loads immediately
  try {
    await localStorage.initialize();
    debugPrint('[BOOT] Local storage initialized');
  } catch (e) {
    debugPrint('[BOOT] Local storage error: $e');
  }

  // Platform money rules (commission rate, deposit split). Loads the current
  // values from `platform_config` so the rate is defined once, server-side.
  // Falls back to the built-in defaults if unavailable -- never blocks boot.
  unawaited(PlatformMoneyConfig.load());

  runApp(const ProviderScope(child: DesbyApp()));
}

class DesbyApp extends ConsumerWidget {
  const DesbyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);

    // Only start realtime when authenticated
    final isAuth = authState.maybeMap(
      authenticated: (_) => true,
      orElse: () => false,
    );
    if (!kIsInTest && isAuth) {
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
        '/invite': (context) => const InvitePage(),
        '/invite-apprentice': (context) {
          final token =
              ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return ApprenticeInviteAcceptPage(inviteToken: token);
        },
        '/client-onboarding': (context) => const ClientOnboardingPage(),
        '/fabric-seller-onboarding': (context) =>
            const FabricSellerOnboardingPage(),
        '/splash': (context) => const SplashScreen(),
        '/verify-email': (context) {
          final email =
              ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return VerifyEmailPage(email: email);
        },
        '/main': (context) {
          return const MainPage();
        },
        '/payment-callback': (context) => const PaymentCallbackPage(),
        // Not listed in navigation on purpose: an admin link is a URL, not a
        // tab. The page re-checks is_admin() server-side and refuses non-admins.
        '/admin': (context) => const AdminDashboardPage(),
        '/checkout': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>? ??
              {};
          final orderId = args['orderId'] as String? ?? '';
          final rawOrderIds = args['orderIds'];
          return CheckoutPage(
            amount: (args['amount'] as num?)?.toDouble() ?? 0.0,
            orderId: orderId,
            orderIds:
                (rawOrderIds as List?)?.whereType<String>().toList() ??
                const [],
          );
        },
        '/chat-detail': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>? ??
              {};
          return ChatDetailPage(
            conversationId: args['conversationId'] ?? '',
            peerId: args['peerId'],
            orderId: args['orderId'],
          );
        },
        '/profile/edit': (context) {
          final argsUserId =
              ModalRoute.of(context)?.settings.arguments as String?;
          return _ProfileEditWrapper(userId: argsUserId);
        },
        '/tailor-profile': (context) {
          final id =
              ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return TailorProfilePage(tailorId: id);
        },
        '/tailor-availability': (context) => TailorAvailabilityPage(
          tailor:
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>? ??
              {},
        ),
        '/booking-cart': (context) => BookingCartPage(
          tailor:
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>? ??
              {},
        ),
        // The guided request journey. Additive route; '/booking-cart' stays.
        '/request-journey': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>? ??
                  {};
          return RequestJourneyPage(
            tailorId: args['tailorId'],
            tailorName: args['tailorName'],
            tailorAvatarUrl: args['tailorAvatarUrl'],
            designId: args['designId'],
            productId: args['productId'],
            productTitle: args['productTitle'],
            productCategory: args['productCategory'],
            productImageUrls:
                (args['productImageUrls'] as List?)?.whereType<String>().toList() ??
                    const <String>[],
            productPrice: (args['productPrice'] as num?)?.toDouble(),
            selectedSize: args['selectedSize'],
            selectedColour: args['selectedColour'],
            quantity: (args['quantity'] as num?)?.toInt() ?? 1,
          );
        },
        '/delivery-setup': (context) => DeliverySetupPage(
          tailor:
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>? ??
              {},
        ),
        '/price-estimation': (context) => PriceEstimationPage(
          tailor:
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>? ??
              {},
        ),
        '/delivery-tracking': (context) => DeliveryTrackingPage(
          shipmentId:
              ModalRoute.of(context)?.settings.arguments as String? ?? '',
        ),
        '/product-details': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final product = args as ShopProduct?;
          if (product == null)
            return const Scaffold(
              body: Center(child: Text('Product not found')),
            );
          return ProductDetailsPage(product: product);
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
    initial: (_) {
      // While auth state is resolving, show splash.
      // If Supabase session exists, the listener will resolve to authenticated.
      return const SplashScreen();
    },
    loading: (_) => const _PulseLoader(),
    unverified: (state) => VerifyEmailPage(email: state.email),
    authenticated: (auth) {
      // CRITICAL: Check onboarding flags BEFORE routing to MainPage.
      // Namespaced by user id so one account's completion can never send a
      // different account straight to the dashboard.
      final uid = auth.authResponse.user.id;
      final userType = localStorage.get(StorageKeys.userType, defaultValue: '');
      final tailorOnboarded = localStorage.get(
        StorageKeys.tailorOnboardedFor(uid),
        defaultValue: false,
      );
      final apprenticeOnboarded = localStorage.get(
        StorageKeys.apprenticeOnboardedFor(uid),
        defaultValue: false,
      );
      final clientOnboarded = localStorage.get(
        StorageKeys.clientOnboardedFor(uid),
        defaultValue: false,
      );
      final fabricSellerOnboarded = localStorage.get(
        StorageKeys.fabricSellerOnboardedFor(uid),
        defaultValue: false,
      );

      if (userType == UserType.tailor.value && tailorOnboarded != true) {
        return const TailorOnboardingPage();
      }
      if (userType == UserType.apprentice.value &&
          apprenticeOnboarded != true) {
        return const ApprenticeOnboardingPage();
      }
      if (userType == UserType.client.value && clientOnboarded != true) {
        return const ClientOnboardingPage();
      }
      if (userType == UserType.fabricSeller.value &&
          fabricSellerOnboarded != true) {
        return const FabricSellerOnboardingPage();
      }

      // Unknown user type: this used to fall straight through to the
      // dashboard, so a user whose type never reached localStorage skipped
      // onboarding entirely. Resolve from the live session instead, and only
      // reach the dashboard once every known role is confirmed complete.
      final resolved = userType.trim().isNotEmpty
          ? userType
          : (Supabase.instance.client.auth.currentUser?.userMetadata?[
                'user_type'
              ] ??
              '');
      if (resolved.isEmpty) {
        // No role anywhere — re-ask rather than dropping them on a dashboard
        // they were never set up for.
        return const OnboardingPage();
      }
      switch (resolved) {
        case UserType.tailor:
          return const TailorOnboardingPage();
        case UserType.apprentice:
          return const ApprenticeOnboardingPage();
        case UserType.client:
          return const ClientOnboardingPage();
        case UserType.fabricSeller:
          return const FabricSellerOnboardingPage();
        default:
          return const MainPage();
      }
    },
    unauthenticated: (_) {
      // CRITICAL: If Supabase session exists, check onboarding before routing
      bool hasSupabaseSession = false;
      try {
        hasSupabaseSession =
            Supabase.instance.client.auth.currentSession != null;
      } catch (_) {
        // Supabase not initialized — fall through to login
      }
      if (hasSupabaseSession) {
        // Same per-user namespacing as the authenticated branch above.
        final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
        final userType = localStorage.get(
          StorageKeys.userType,
          defaultValue: '',
        );
        final tailorOnboarded = localStorage.get(
          StorageKeys.tailorOnboardedFor(uid),
          defaultValue: false,
        );
        final apprenticeOnboarded = localStorage.get(
          StorageKeys.apprenticeOnboardedFor(uid),
          defaultValue: false,
        );
        final clientOnboarded = localStorage.get(
          StorageKeys.clientOnboardedFor(uid),
          defaultValue: false,
        );
        final fabricSellerOnboarded = localStorage.get(
          StorageKeys.fabricSellerOnboardedFor(uid),
          defaultValue: false,
        );

        if (userType == UserType.tailor.value && tailorOnboarded != true) {
          return const TailorOnboardingPage();
        }
        if (userType == UserType.apprentice.value &&
            apprenticeOnboarded != true) {
          return const ApprenticeOnboardingPage();
        }
        if (userType == UserType.client.value && clientOnboarded != true) {
          return const ClientOnboardingPage();
        }
        if (userType == UserType.fabricSeller.value &&
            fabricSellerOnboarded != true) {
          return const FabricSellerOnboardingPage();
        }
        return const MainPage();
      }
      // No session — show login page
      return const LoginPage();
    },
    error: (error) {
      // Auth errors (wrong password, etc.) — go to login instead of dead-end
      return const LoginPage();
    },
  );
}

class _PulseLoader extends StatefulWidget {
  const _PulseLoader();

  @override
  State<_PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<_PulseLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Image.asset('assets/images/logo.png', height: 100),
        ),
      ),
    );
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
