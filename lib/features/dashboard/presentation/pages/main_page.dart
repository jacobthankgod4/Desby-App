import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tailor_dashboard.dart';
import 'apprentice_dashboard.dart';
import 'client_dashboard.dart';
import 'fabric_seller_dashboard.dart';
import '../widgets/desktop_dashboard_shell.dart';
import '../../../../features/orders/presentation/pages/order_list_page.dart';
import '../../../../features/orders/presentation/pages/order_detail_page.dart';
import '../../../../features/orders/presentation/pages/booking_cart_page.dart';
import '../../../../features/orders/presentation/pages/delivery_setup_page.dart';
import '../../../../features/orders/presentation/pages/price_estimation_page.dart';
import '../../../../features/orders/presentation/pages/delivery_tracking_page.dart';
import '../../../../features/marketplace/presentation/pages/fabric_catalog_page.dart';
import '../../../../features/marketplace/presentation/pages/fabric_upload_page.dart';
import '../../../../features/marketplace/presentation/pages/fabric_detail_page.dart';
import '../../../../features/marketplace/presentation/pages/merchant_wallet_page.dart';
import '../../../../features/tailor/presentation/pages/virtual_atelier_page.dart';
import '../../../../features/tailor/presentation/pages/product_list_page.dart';
import '../../../../features/tailor/presentation/pages/add_product_page.dart';
import '../../../../features/tailor/presentation/pages/shop_setup_page.dart';
import '../../../../features/tailor/presentation/pages/pricing_setup_page.dart';
import '../../../../features/tailor/presentation/pages/tailor_discovery_page.dart';
import '../../../../features/tailor/presentation/pages/tailor_profile_page.dart';
import '../../../../features/tailor/presentation/pages/product_details_page.dart';
import '../../../../features/tailor/presentation/pages/product_details_loader.dart';
import '../../../../features/clients/presentation/pages/client_list_page.dart';
import '../../../../features/clients/presentation/pages/client_detail_page.dart';
import '../../../../features/clients/presentation/pages/client_garment_architecture_page.dart';
import '../../../../features/clients/presentation/pages/unified_add_client_page.dart';
import '../../../../features/clients/presentation/pages/measurement_profile_page.dart';
import '../../../../features/designs/presentation/pages/measurement_input_page.dart';
import '../../../../features/designs/presentation/pages/ai_body_scan_page.dart';
import '../../../../features/designs/presentation/pages/measurement_explorer_page.dart';
import '../../../../features/designs/presentation/pages/design_gallery_page.dart';
import '../../../../features/designs/presentation/pages/design_upload_page.dart';
import '../../../../features/designs/presentation/pages/saved_designs_page.dart';
import '../../../../features/designs/presentation/pages/virtual_tryon_page.dart';
import '../../../../features/designs/presentation/pages/tailor_tryon_page.dart';
import '../../../../features/designs/presentation/pages/design_detail_page.dart';
import '../../../../features/apprenticeship/presentation/pages/apprentice_learning_page.dart';
import '../../../../features/apprenticeship/presentation/pages/apprentice_tasks_page.dart';
import '../../../../features/apprenticeship/presentation/pages/apprentice_management_page.dart';
import '../../../../features/apprenticeship/presentation/pages/apprentice_progress_page.dart';
import '../../../../features/apprenticeship/presentation/pages/apprentice_task_grading_page.dart';
import '../../../../features/apprenticeship/presentation/pages/apprentice_lesson_detail_page.dart';
import '../../../../features/apprenticeship/presentation/pages/apprentice_task_submission_page.dart';
import '../../../../features/apprenticeship/presentation/pages/apprentice_onboarding_page.dart';
import '../../../../features/apprenticeship/presentation/pages/unified_add_apprentice_page.dart';
import '../../../../features/apprenticeship/presentation/pages/apprentice_detail_page.dart';
import '../../../../features/apprenticeship/presentation/pages/curriculum_setup_page.dart';
import '../../../../features/apprenticeship/presentation/pages/academy_page.dart';
import '../../../../features/apprenticeship/presentation/pages/module_detail_page.dart';
import '../../../../features/apprenticeship/presentation/pages/module_create_page.dart';
import '../../../../features/apprenticeship/presentation/pages/lesson_create_page.dart';
import '../../../../features/apprenticeship/presentation/pages/mentors_page.dart';
import '../../../../features/tailor/presentation/pages/tailor_onboarding_page.dart';
import '../../../../features/clients/presentation/pages/client_onboarding_page.dart';
import '../../../../features/marketplace/presentation/pages/fabric_seller_onboarding_page.dart';
import '../../../../features/profile/presentation/pages/profile_view_page.dart';
import '../../../../features/profile/presentation/pages/profile_edit_page.dart';
import '../../../../features/profile/presentation/pages/settings_page.dart';
import '../../../../features/profile/presentation/providers/profile_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/profile/domain/entities/user_profile.dart';
import '../../../../features/notifications/presentation/pages/notification_center_page.dart';
import '../../../../features/analytics/presentation/pages/insights_dashboard.dart';
import '../../../../features/analytics/presentation/pages/insights_page.dart';
import '../../../../features/analytics/presentation/pages/reports_page.dart';
import '../../../../features/analytics/presentation/pages/ai_insights_page.dart';
import '../../../../features/marketplace/presentation/pages/seller_inventory_page.dart';
import '../../../../features/marketplace/presentation/pages/seller_orders_page.dart';
import '../../../../features/marketplace/presentation/pages/seller_portfolio_page.dart';
import '../../../../features/marketplace/presentation/pages/favorites_page.dart';
import '../../../../features/payments/presentation/pages/checkout_page.dart';
import 'package:desby_app/features/chat/presentation/pages/chat_list_page.dart';
import 'package:desby_app/features/chat/presentation/pages/chat_detail_page.dart';
import 'package:desby_app/core/providers/navigation_provider.dart';
import '../../../../features/tailor/domain/entities/shop_product.dart';
import 'package:desby_app/core/providers/theme_provider.dart';
import 'package:desby_app/theme/colors.dart';
import '../../../payments/presentation/pages/subscription_plans_page.dart';
import '../../../../features/apprenticeship/presentation/pages/badges_page.dart';
import '../../../../features/apprenticeship/presentation/pages/certificates_page.dart';
import '../../../../features/apprenticeship/presentation/pages/portfolio_page.dart';
import '../../../../features/apprenticeship/presentation/pages/showcase_page.dart';
import '../../../../features/apprenticeship/presentation/pages/masterclass_page.dart';
import '../../../../features/referrals/presentation/pages/referrals_page.dart';
import '../../../../features/marketplace/presentation/pages/ai_pricing_page.dart';
import '../../../../features/marketplace/presentation/pages/branded_storefront_page.dart';
import '../../../../features/marketplace/presentation/pages/low_stock_alerts_page.dart';
import '../../../../features/reviews/presentation/pages/review_submit_page.dart';
import '../../../../features/marketplace/presentation/pages/marketplace_cart_page.dart';
import '../../../../features/chat/presentation/pages/zoe_chat_page.dart';
import '../../../../core/config/nav_config.dart';
import '../../../../core/services/background_scan_service.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../checkout/presentation/pages/request_journey_page.dart';
import '../../../checkout/presentation/pages/shop_checkout_page.dart';
import '../../../checkout/presentation/pages/shop_checkout_loader.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  bool _previousScanCompleted = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userType = user?.userType ?? 'tailor';
    final userId = user?.id ?? '';
    final navState = ref.watch(navigationProvider);
    final selectedRoute = navState.route;
    final navArguments = navState.arguments;
    final navStack = ref.read(navigationStackProvider.notifier);

    // Listen for background scan completion
    ref.listen<BackgroundScanTask?>(backgroundScanProvider, (prev, next) {
      if (next == null) return;
      if (next.status == BackgroundScanStatus.completed &&
          _previousScanCompleted != true) {
        _previousScanCompleted = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Scan complete! ${next.measurements?.length ?? 0} measurements extracted.',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.successGreen,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'VIEW',
                textColor: Colors.white,
                onPressed: () {
                  ref
                      .read(navigationStackProvider.notifier)
                      .set('/ai-body-scan');
                },
              ),
            ),
          );
        }
      } else if (next.status == BackgroundScanStatus.failed &&
          _previousScanCompleted != true) {
        _previousScanCompleted = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Scan failed: ${next.error ?? "Unknown error"}',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
                onPressed: () {
                  ref
                      .read(navigationStackProvider.notifier)
                      .set('/ai-body-scan');
                },
              ),
            ),
          );
        }
      } else if (next.status == BackgroundScanStatus.idle) {
        _previousScanCompleted = false;
      }
    });

    final child = _getPageForRoute(
      selectedRoute,
      userId,
      userType,
      navArguments,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Intercept browser back button and route through custom navigation stack
        if (navStack.canPop) {
          navStack.pop();
        } else {
          navStack.set('/main');
        }
      },
      child: DesktopDashboardShell(
        pageTitle: getPageTitle(selectedRoute),
        selectedIndex: _getSelectedIndexForRoute(userType, selectedRoute),
        onIndexChanged: (index, route) {
          navStack.set(route);
        },
        drawer: _buildDrawer(context, user),
        child: child,
      ),
    );
  }

  int _getSelectedIndexForRoute(String userType, String route) {
    return NavConfig.getDesktopIndex(userType, route);
  }

  Widget _getPageForRoute(
    String route,
    String userId,
    String userType, [
    Map<String, dynamic>? arguments,
  ]) {
    switch (route) {
      case '/main':
        if (userType == 'tailor') return const TailorDashboard();
        if (userType == 'client') return const ClientDashboard();
        if (userType == 'apprentice') return const ApprenticeDashboard();
        if (userType == 'fabric_seller') return const FabricSellerDashboard();
        return const TailorDashboard();
      case '/orders':
        if (userType == 'fabric_seller') return const SellerOrdersPage();
        return const OrderListPage();
      case '/order-detail':
        return OrderDetailPage(orderId: arguments?['orderId'] ?? '');
      case '/clients':
        return const ClientListPage();
      case '/client-detail':
        return ClientDetailPage(clientId: arguments?['clientId'] ?? '');
      case '/client-garment-architecture':
        return const ClientGarmentArchitecturePage();
      case '/unified-add-client':
        return const UnifiedAddClientPage();
      case '/unified-add-apprentice':
        return const UnifiedAddApprenticePage();
      case '/marketplace':
        return const FabricCatalogPage();
      case '/fabric-details':
        return FabricDetailPage(fabricId: arguments?['fabricId'] ?? '');
      case '/shop-setup':
        return const ShopSetupPage();
      case '/product-list':
        return const ProductListPage();
      case '/add-product':
        return const AddProductPage();
      case '/virtual-atelier':
        return const VirtualAtelierPage();
      case '/pricing-setup':
        return const PricingSetupPage();
      case '/insights':
        return const InsightsPage();
      case '/academy':
        return const AcademyPage();
      case '/profile/settings':
        return const SettingsPage();
      case '/profile':
        return ProfileViewPage(userId: userId);
      case '/profile/edit':
        return ProfileEditPage(userId: arguments?['userId'] ?? userId);
      case '/notifications':
        return const NotificationCenterPage();
      case '/tailor-discovery':
        return const TailorDiscoveryPage();
      // '/measurements-hub' was retired and merged into My Measurements
      // (/measurements-profile). Kept as a redirect so old deep links resolve.
      case '/measurements-hub':
        return const MeasurementProfilePage();
      case '/measurements-input':
        return const MeasurementInputPage();
      case '/measurements-profile':
        return const MeasurementProfilePage();
      case '/tasks':
        if (userType == 'apprentice') return const ApprenticeTasksPage();
        return const ApprenticeManagementPage();
      case '/curriculum':
        return const ApprenticeLearningPage();
      case '/progress':
        return const ApprenticeProgressPage();
      case '/mentors':
        return const MentorsPage();
      case '/fabric-upload':
        return FabricUploadPage(fabric: arguments?['fabric']);
      case '/inventory':
        return const SellerInventoryPage();
      case '/chats':
        return const ChatListPage();
      case '/chat-detail':
        return ChatDetailPage(
          conversationId: arguments?['conversationId'] ?? '',
          peerId: arguments?['peerId'],
          orderId: arguments?['orderId'],
        );
      case '/tailor-profile':
        return TailorProfilePage(tailorId: arguments?['tailorId'] ?? '');
      // case '/tailor-availability':
      //   return TailorAvailabilityPage(tailor: arguments ?? {});
      case '/request-journey':
      // The guided request journey. Additive: '/booking-cart' below is
      // untouched and still reachable when the feature flag is off.
      return RequestJourneyPage(
        tailorId: arguments?['tailorId'],
        tailorName: arguments?['tailorName'],
        tailorAvatarUrl: arguments?['tailorAvatarUrl'],
        designId: arguments?['designId'],
        productId: arguments?['productId'],
        productTitle: arguments?['productTitle'],
        productCategory: arguments?['productCategory'],
        productImageUrls:
            (arguments?['productImageUrls'] as List?)?.whereType<String>().toList() ??
                const <String>[],
        productPrice: (arguments?['productPrice'] as num?)?.toDouble(),
        selectedSize: arguments?['selectedSize'],
        selectedColour: arguments?['selectedColour'],
        quantity: (arguments?['quantity'] as num?)?.toInt() ?? 1,
      );
    case '/booking-cart':
        return BookingCartPage(tailor: arguments ?? {});
      case '/delivery-setup':
        return DeliverySetupPage(tailor: arguments ?? {});
      case '/price-estimation':
        return PriceEstimationPage(tailor: arguments ?? {});
      case '/delivery-tracking':
        return DeliveryTrackingPage(shipmentId: arguments?['shipmentId'] ?? '');
      case '/product-details':
        final product = arguments?['product'] as ShopProduct?;
        if (product != null) {
          return ProductDetailsPage(product: product);
        }
        // Restored from persisted args after a reload — only the product id
        // came back, so re-fetch it instead of showing the placeholder.
        final productId = arguments?['productId'] as String?;
        if (productId != null && productId.isNotEmpty) {
          return ProductDetailsLoader(productId: productId);
        }
        // No product and no recoverable id — nothing to show.
        {
          final colors = context.colors;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.grey,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Product Not Available',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This product could not be loaded.',
                  style: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.setShell('/main'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.darkNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Go to Dashboard'),
                ),
              ],
            ),
          );
        }
      case '/checkout':
        final orderId = arguments?['orderId'] ?? '';
        final rawOrderIds = arguments?['orderIds'];
        return CheckoutPage(
          amount: arguments?['amount'] ?? 0.0,
          orderId: orderId,
          orderIds:
              (rawOrderIds as List?)?.whereType<String>().toList() ?? const [],
        );
      case '/reports':
        return const ReportsPage();
      case '/ai-insights':
        return const AIInsightsPage();
      case '/merchant-wallet':
        return const MerchantWalletPage();
      case '/seller-portfolio':
        return SellerPortfolioPage(sellerId: arguments?['sellerId'] ?? '');
      case '/favorites':
        return const FavoritesPage();
      case '/ai-body-scan':
        return const AiBodyScanPage();
      case '/measurement-explorer':
        return MeasurementExplorerPage(
          measurements:
              (arguments?['measurements'] as Map<String, double>?) ?? {},
          gender: arguments?['gender'] ?? 'male',
          heightCm: arguments?['heightCm'],
          scanLabel: arguments?['scanLabel'],
        );
      case '/designs':
        return const DesignGalleryPage();
      case '/design-upload':
        return const DesignUploadPage();
      case '/saved-designs':
        return const SavedDesignsPage();
      case '/virtual-tryon':
        return const VirtualTryOnPage();
      case '/tailor-tryon':
        return const TailorTryOnPage();
      case '/design-details':
        return DesignDetailPage(
          design: arguments?['design'],
          origin: arguments?['origin'],
        );
      case '/shop-checkout':
        final checkoutDesign = arguments?['design'];
        if (checkoutDesign != null) {
          return ShopCheckoutPage(
            design: checkoutDesign,
            quantity: arguments?['quantity'] ?? 1,
            size: arguments?['size'],
            colorValue: arguments?['colorValue'] ?? 0xFF1A1A2E,
          );
        }
        // Restored from persisted args after a reload — the Design object was
        // never serialisable, so only its id came back. Re-fetch it here.
        final checkoutDesignId = arguments?['designId'] as String?;
        if (checkoutDesignId == null || checkoutDesignId.isEmpty) {
          return const MissingCheckoutState();
        }
        return ShopCheckoutLoader(
          designId: checkoutDesignId,
          quantity: arguments?['quantity'] ?? 1,
          size: arguments?['size'],
          colorValue: arguments?['colorValue'] ?? 0xFF1A1A2E,
        );
      case '/subscription-plans':
        return const SubscriptionPlansPage();
      case '/tailor-onboarding':
        return const TailorOnboardingPage();
      case '/client-onboarding':
        return const ClientOnboardingPage();
      case '/apprentice-onboarding':
        return const ApprenticeOnboardingPage();
      case '/fabric-seller-onboarding':
        return const FabricSellerOnboardingPage();
      case '/apprentice-task-grading':
        return ApprenticeTaskGradingPage(task: arguments?['task']);
      case '/apprentice-lesson-detail':
        return ApprenticeLessonDetailPage(
          lessonId: arguments?['lessonId'] ?? '',
        );
      case '/apprentice-task-submission':
        return ApprenticeTaskSubmissionPage(task: arguments?['task']);
      case '/apprentice-detail':
        return ApprenticeDetailPage(
          apprenticeId: arguments?['apprenticeId'] ?? '',
          apprenticeshipId: arguments?['apprenticeshipId'] ?? '',
        );
      case '/curriculum-setup':
        return const CurriculumSetupPage();
      case '/module-create':
        return ModuleCreatePage(
          moduleId: arguments?['moduleId'],
          existingTitle: arguments?['existingTitle'],
          existingDescription: arguments?['existingDescription'],
          existingThumbnail: arguments?['existingThumbnail'],
        );
      case '/lesson-create':
        return LessonCreatePage(
          moduleId: arguments?['moduleId'] ?? '',
          moduleName: arguments?['moduleName'] ?? '',
          lessonId: arguments?['lessonId'],
          existingTitle: arguments?['existingTitle'],
          existingContent: arguments?['existingContent'],
          existingVideoUrl: arguments?['existingVideoUrl'],
          existingShortDescription: arguments?['existingShortDescription'],
          existingThumbnailUrl: arguments?['existingThumbnailUrl'],
          existingDurationMinutes: arguments?['existingDurationMinutes'],
          existingLessonType: arguments?['existingLessonType'],
          existingIsPublished: arguments?['existingIsPublished'],
          existingIsFreePreview: arguments?['existingIsFreePreview'],
          existingAttachments: arguments?['existingAttachments'],
        );
      case '/module-detail':
        return ModuleDetailPage(moduleId: arguments?['moduleId'] ?? '');
      case '/review-submit':
        return ReviewSubmitPage(
          orderId: arguments?['orderId'] ?? '',
          revieweeId: arguments?['revieweeId'] ?? '',
          reviewType: arguments?['reviewType'] ?? 'client_to_tailor',
        );
      case '/marketplace-cart':
        return const MarketplaceCartPage();
      case '/zoe-chat':
        return const ZoeChatPage();
      case '/badges':
        return const BadgesPage();
      case '/certificates':
        return const CertificatesPage();
      case '/portfolio':
        return const ApprenticePortfolioPage();
      case '/showcase':
        return const ShowcasePage();
      case '/masterclass':
        return const MasterclassPage();
      case '/referrals':
        return const ReferralsPage();
      case '/ai-pricing':
        return const AiPricingPage();
      case '/storefront':
        return const BrandedStorefrontPage();
      case '/low-stock':
        return const LowStockAlertsPage();
      default:
        return _buildNotFoundPage();
    }
  }

  Widget _buildNotFoundPage() {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: colors.textMuted, size: 64),
          const SizedBox(height: 16),
          Text(
            'Page Not Found',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The page you are looking for does not exist.',
            style: TextStyle(color: colors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.setShell('/main'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, dynamic user) {
    final colors = context.colors;
    final userId = user?.id ?? '';
    final userType = user?.userType ?? 'tailor';

    final profileAsync = userId.isNotEmpty
        ? ref.watch(userProfileProvider(userId))
        : null;

    Widget onboardingWidget;
    if (profileAsync != null) {
      onboardingWidget = profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return _buildOnboardingAlert(context, ref, userType);
          }
          return _checkProfileCompleteness(context, ref, profile, userType);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (e, st) => _buildOnboardingAlert(context, ref, userType),
      );
    } else {
      onboardingWidget = _buildOnboardingAlert(context, ref, userType);
    }

    return Drawer(
      backgroundColor: colors.sidebarBg,
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
                  _buildDrawerItem(
                    ref,
                    Icons.grid_view_rounded,
                    'Dashboard',
                    '/main',
                  ),
                  _buildDrawerItem(
                    ref,
                    Icons.person_outline_rounded,
                    'My Profile',
                    '/profile',
                    arguments: {'userId': user?.id},
                  ),
                  ...NavConfig.getDrawerItems(userType).map(
                    (item) => _buildDrawerItem(
                      ref,
                      item.icon,
                      item.label,
                      item.route,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: Icon(
              Icons.logout_rounded,
              color: colors.statusError,
              size: 22,
            ),
            title: Text(
              'Log Out',
              style: TextStyle(
                color: colors.statusError,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted)
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(dynamic user) {
    final colors = context.colors;
    final themeMode = ref.watch(themeModeProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(color: colors.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              UserAvatar(
                imageUrl: user?.profileImage,
                name: user?.name,
                radius: 35,
              ),
              IconButton(
                icon: Icon(
                  themeMode == ThemeMode.light
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  color: AppColors.amber,
                ),
                onPressed: () =>
                    ref.read(themeModeProvider.notifier).toggleTheme(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            user?.name ?? 'User',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            user?.email ?? '',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              user?.userType?.toUpperCase() ?? 'ACCESS',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingAlert(
    BuildContext context,
    WidgetRef ref,
    String type,
  ) {
    final colors = context.colors;
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
            Icon(Icons.warning_amber_rounded, color: colors.textOnAmber),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACTION REQUIRED',
                    style: TextStyle(
                      color: colors.textOnAmber,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Complete Mandatory Onboarding',
                    style: TextStyle(
                      color: colors.textOnAmber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: colors.textOnAmber,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkProfileCompleteness(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    String userType,
  ) {
    final bool isComplete = (userType == 'tailor')
        ? (profile.services != null && profile.services!.isNotEmpty) ||
              (profile.availableFabrics != null &&
                  profile.availableFabrics!.isNotEmpty)
        : profile.name.isNotEmpty && profile.name != 'New User';

    if (isComplete) {
      return _buildUpgradeCard(context, ref);
    } else {
      return _buildOnboardingAlert(context, ref, userType);
    }
  }

  Widget _buildUpgradeCard(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ref.pushShell('/subscription-plans');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 0,
            ),
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
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: AppColors.amber,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'UPGRADE PLAN',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Unlock premium features',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.amber,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    WidgetRef ref,
    IconData icon,
    String title,
    String route, {
    Object? arguments,
    Color? color,
  }) {
    final colors = context.colors;
    final itemColor = color ?? colors.textSecondary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: itemColor, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: itemColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        ref.pushShell(route, arguments as Map<String, dynamic>?);
      },
    );
  }
}

