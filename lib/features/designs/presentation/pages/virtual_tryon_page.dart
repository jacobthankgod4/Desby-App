import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/colors.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/layout_provider.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/services/ai_credit_service.dart';
import '../../../../core/network/magic_hour_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/shell_scope.dart';
import '../../../../core/widgets/app_network_image.dart';

class _HowStep {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final String title;
  final String desc;
  const _HowStep(
    this.icon,
    this.bgColor,
    this.iconColor,
    this.title,
    this.desc,
  );
}

class VirtualTryOnState {
  final int currentStep;
  final List<Map<String, dynamic>> tryOns;
  final List<Map<String, dynamic>> browseDesigns;
  final bool loading;
  final String? selectedGarmentUrl;
  final String? selectedDesignTitle;
  final String? selectedDesignId;
  final String? selectedTailorId;
  final String? selectedTailorName;
  final Uint8List? customerPhotoBytes;
  final String? customerPhotoName;
  final String? uploadedPhotoUrl;
  final String category;
  final String? resultUrl;

  const VirtualTryOnState({
    this.currentStep = 0,
    this.tryOns = const [],
    this.browseDesigns = const [],
    this.loading = true,
    this.selectedGarmentUrl,
    this.selectedDesignTitle,
    this.selectedDesignId,
    this.selectedTailorId,
    this.selectedTailorName,
    this.customerPhotoBytes,
    this.customerPhotoName,
    this.uploadedPhotoUrl,
    this.category = 'upper_body',
    this.resultUrl,
  });

  VirtualTryOnState copyWith({
    int? currentStep,
    List<Map<String, dynamic>>? tryOns,
    List<Map<String, dynamic>>? browseDesigns,
    bool? loading,
    String? selectedGarmentUrl,
    String? selectedDesignTitle,
    String? selectedDesignId,
    String? selectedTailorId,
    String? selectedTailorName,
    Uint8List? customerPhotoBytes,
    String? customerPhotoName,
    String? uploadedPhotoUrl,
    String? category,
    String? resultUrl,
    bool clearGarment = false,
    bool clearPhoto = false,
    bool clearResult = false,
  }) {
    return VirtualTryOnState(
      currentStep: currentStep ?? this.currentStep,
      tryOns: tryOns ?? this.tryOns,
      browseDesigns: browseDesigns ?? this.browseDesigns,
      loading: loading ?? this.loading,
      selectedGarmentUrl: clearGarment
          ? null
          : (selectedGarmentUrl ?? this.selectedGarmentUrl),
      selectedDesignTitle: clearGarment
          ? null
          : (selectedDesignTitle ?? this.selectedDesignTitle),
      selectedDesignId: clearGarment
          ? null
          : (selectedDesignId ?? this.selectedDesignId),
      selectedTailorId: clearGarment
          ? null
          : (selectedTailorId ?? this.selectedTailorId),
      selectedTailorName: clearGarment
          ? null
          : (selectedTailorName ?? this.selectedTailorName),
      customerPhotoBytes: clearPhoto
          ? null
          : (customerPhotoBytes ?? this.customerPhotoBytes),
      customerPhotoName: clearPhoto
          ? null
          : (customerPhotoName ?? this.customerPhotoName),
      uploadedPhotoUrl: clearPhoto
          ? null
          : (uploadedPhotoUrl ?? this.uploadedPhotoUrl),
      category: category ?? this.category,
      resultUrl: clearResult ? null : (resultUrl ?? this.resultUrl),
    );
  }
}

class VirtualTryOnNotifier extends StateNotifier<VirtualTryOnState> {
  final Ref ref;
  final _imageService = ImageUploadService();
  final _magicHourClient = MagicHourClient();

  VirtualTryOnNotifier(this.ref) : super(const VirtualTryOnState()) {
    loadTryOns();
    loadBrowseDesigns();
  }

  Future<void> loadTryOns() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final response = await Supabase.instance.client
          .from('virtual_tryons')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      state = state.copyWith(
        tryOns: List<Map<String, dynamic>>.from(response as List),
        loading: false,
      );
    } catch (e) {
      debugPrint('[VTO] loadTryOns failed: $e');
      state = state.copyWith(loading: false);
    }
  }

  Future<void> loadBrowseDesigns() async {
    try {
      final response = await Supabase.instance.client
          .from('designs')
          .select('id, title, image_urls, category, tailor_name, tailor_id')
          .eq('is_visible', true)
          .order('created_at', ascending: false)
          .limit(20);
      state = state.copyWith(
        browseDesigns: List<Map<String, dynamic>>.from(response as List),
      );
    } catch (e) {
      debugPrint('[ERROR] loadBrowseDesigns: $e');
    }
  }

  void selectDesignAsGarment(String url, String title) {
    final design = state.browseDesigns.firstWhere((d) {
      final imgs = d['image_urls'] as List<dynamic>?;
      final imgUrl = (imgs != null && imgs.isNotEmpty)
          ? imgs[0].toString()
          : '';
      return imgUrl == url;
    }, orElse: () => {});
    state = state.copyWith(
      selectedGarmentUrl: url,
      selectedDesignTitle: title,
      selectedDesignId: design['id'] as String?,
      selectedTailorId: design['tailor_id'] as String?,
      selectedTailorName: design['tailor_name'] as String?,
    );
  }

  void startTryOn({
    String? garmentUrl,
    String? designTitle,
    String? designId,
    String? tailorId,
    String? tailorName,
  }) {
    state = state.copyWith(
      selectedGarmentUrl: garmentUrl,
      selectedDesignTitle: designTitle,
      selectedDesignId: designId,
      selectedTailorId: tailorId,
      selectedTailorName: tailorName,
      currentStep: 1,
    );
  }

  void goToLanding() {
    state = const VirtualTryOnState();
    loadTryOns();
    loadBrowseDesigns();
  }

  void goToResult() {
    state = state.copyWith(currentStep: 3);
  }

  void goToUpload() {
    state = state.copyWith(currentStep: 1, clearPhoto: true);
  }

  void goToProcessing() {
    state = state.copyWith(currentStep: 2);
  }

  void setPhoto(Uint8List bytes, String name) {
    state = state.copyWith(customerPhotoBytes: bytes, customerPhotoName: name);
  }

  void deselectDesign() {
    state = state.copyWith(clearGarment: true);
  }

  Future<void> runTryOn() async {
    if (state.customerPhotoBytes == null) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Check AI credits
    final creditService = ref.read(aiCreditServiceProvider);
    final hasCredits = await creditService.canUseCredits();
    if (!hasCredits) {
      return;
    }
    final deducted = await creditService.deductCredit(feature: 'virtual_tryon');
    if (!deducted) {
      return;
    }

    goToProcessing();
    try {
      final fileName = state.customerPhotoName ?? 'photo.jpg';
      final xFile = XFile.fromData(
        state.customerPhotoBytes!,
        name: fileName,
        mimeType: 'image/jpeg',
      );
      final photoUrl = await _imageService.uploadImage(
        xFile,
        user.id,
        'tryon_photos',
      );
      if (photoUrl == null) {
        throw const ImageUploadException('Upload returned no URL');
      }
      state = state.copyWith(uploadedPhotoUrl: photoUrl);
      final garmentUrl = state.selectedGarmentUrl ?? '';
      final predictionId = await _magicHourClient.createPrediction(
        humanImg: photoUrl,
        garmImg: garmentUrl,
        category: state.category,
      );
      if (predictionId == null) {
        goToUpload();
        return;
      }
      final result = await _magicHourClient.waitForResult(predictionId);
      if (result.status == 'complete' && result.output != null) {
        // Mirror before persisting: the provider URL is a short-lived signed link
        // and would leave this row pointing at a dead image within a day.
        final durableOutput = await ImageUploadService().mirrorRemoteImage(
          result.output!,
          folder: 'tryon_outputs',
        );
        await Supabase.instance.client.from('virtual_tryons').insert({
          'user_id': user.id,
          'image_url': photoUrl,
          'output_url': durableOutput,
        });
        state = state.copyWith(
          resultUrl: durableOutput,
          currentStep: 3,
        );
        loadTryOns();
      } else {
        debugPrint(
          '[VTO] Magic Hour failed: ${result.status} - ${result.error}',
        );
        goToUpload();
      }
    } on ImageUploadException catch (e) {
      debugPrint('[VTO] Image upload failed: $e');
      if (mounted) goToUpload();
      rethrow;
    } catch (e) {
      debugPrint('[VTO] runTryOn failed: $e');
      if (mounted) goToUpload();
    }
  }
}

final virtualTryOnProvider =
    StateNotifierProvider<VirtualTryOnNotifier, VirtualTryOnState>((ref) {
      return VirtualTryOnNotifier(ref);
    });

class VirtualTryOnPage extends ConsumerStatefulWidget {
  const VirtualTryOnPage({super.key});
  @override
  ConsumerState<VirtualTryOnPage> createState() => _VirtualTryOnPageState();
}

class _VirtualTryOnPageState extends ConsumerState<VirtualTryOnPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _statusController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _statusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ref.watch(isDesktopProvider);
    final vtoState = ref.watch(virtualTryOnProvider);
    final notifier = ref.read(virtualTryOnProvider.notifier);

    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _buildCurrentStep(isDesktop, vtoState, notifier),
      ),
    );
  }

  Widget _buildCurrentStep(
    bool isDesktop,
    VirtualTryOnState vtoState,
    VirtualTryOnNotifier notifier,
  ) {
    switch (vtoState.currentStep) {
      case 0:
        return _LandingView(
          key: const ValueKey(0),
          tryOns: vtoState.tryOns,
          loading: vtoState.loading,
          isDesktop: isDesktop,
          onStartTryOn: notifier.startTryOn,
          onBrowseDesigns: () => ref.pushShell('/designs'),
          onPop: () => ref.popShell(),
        );
      case 1:
        return _UploadView(
          key: const ValueKey(1),
          garmentUrl: vtoState.selectedGarmentUrl,
          designTitle: vtoState.selectedDesignTitle,
          customerPhotoBytes: vtoState.customerPhotoBytes,
          browseDesigns: vtoState.browseDesigns,
          onBack: () => ref.popShell(),
          onPickPhoto: () async {
            final file = await ImageUploadService().pickImageFromGallery();
            if (file != null) {
              final bytes = await file.readAsBytes();
              notifier.setPhoto(bytes, file.name);
            }
          },
          onSelectDesign: notifier.selectDesignAsGarment,
          onDeselectDesign: notifier.deselectDesign,
          onGenerate: () async {
            final creditService = ref.read(aiCreditServiceProvider);
            final hasCredits = await creditService.canUseCredits();
            if (!hasCredits && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'No AI credits left. Upgrade to Premium for unlimited try-ons.',
                  ),
                  backgroundColor: Colors.orangeAccent,
                  action: SnackBarAction(
                    label: 'UPGRADE',
                    textColor: Colors.white,
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/subscription-plans'),
                  ),
                ),
              );
              return;
            }
            try {
              await notifier.runTryOn();
            } on ImageUploadException catch (e) {
              debugPrint('[VTO] Image upload failed: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Image upload failed — please try again'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }
          },
        );
      case 2:
        return _ProcessingView(
          key: const ValueKey(2),
          pulseAnimation: _pulseAnimation,
          statusController: _statusController,
        );
      case 3:
        return _ResultView(
          key: const ValueKey(3),
          resultUrl: vtoState.resultUrl,
          customerPhotoUrl: vtoState.uploadedPhotoUrl,
          designTitle: vtoState.selectedDesignTitle,
          tailorId: vtoState.selectedTailorId,
          tailorName: vtoState.selectedTailorName,
          onNewTryOn: () => ref.popShell(),
          onBrowseDesigns: () => ref.pushShell('/designs'),
          onGetMade: (tailorId, tailorName) => ref.pushShell('/booking-cart', {
            'id': tailorId,
            'name': tailorName,
          }),
        );
      default:
        return _LandingView(
          key: const ValueKey(0),
          tryOns: vtoState.tryOns,
          loading: vtoState.loading,
          isDesktop: isDesktop,
          onStartTryOn: notifier.startTryOn,
          onBrowseDesigns: () => ref.pushShell('/designs'),
          onPop: () => ref.popShell(),
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// STEP 0: LANDING
// ═══════════════════════════════════════════════════════════════

class _LandingView extends StatefulWidget {
  final List<Map<String, dynamic>> tryOns;
  final bool loading;
  final bool isDesktop;
  final void Function({String? garmentUrl, String? designTitle}) onStartTryOn;
  final VoidCallback onBrowseDesigns;
  final VoidCallback onPop;

  const _LandingView({
    super.key,
    required this.tryOns,
    required this.loading,
    required this.isDesktop,
    required this.onStartTryOn,
    required this.onBrowseDesigns,
    required this.onPop,
  });

  @override
  State<_LandingView> createState() => _LandingViewState();
}

class _LandingViewState extends State<_LandingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (!ShellScope.isInside(context))
          SliverAppBar(
            pinned: true,
            backgroundColor: context.colors.scaffoldBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 60,
            leading: MediaQuery.of(context).size.width > 1000
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.amber,
                      size: 20,
                    ),
                    onPressed: widget.onPop,
                  ),
            title: Text(
              'VIRTUAL TRY-ON',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.8,
              ),
            ),
          ),
        SliverToBoxAdapter(child: _buildHero()),
        SliverToBoxAdapter(child: _buildHowItWorks(context)),
        if (widget.tryOns.isNotEmpty)
          SliverToBoxAdapter(child: _buildHistory(context)),
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  Widget _buildHero() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1100),
        padding: EdgeInsets.symmetric(
          horizontal: widget.isDesktop ? 48 : 24,
          vertical: widget.isDesktop ? 10 : 16,
        ),
        child: widget.isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 35, child: _buildUploadCard(context)),
                  const SizedBox(width: 24),
                  Expanded(flex: 65, child: _buildShowcaseCard(context)),
                ],
              )
            : Column(
                children: [
                  _buildUploadCard(context),
                  const SizedBox(height: 20),
                  _buildShowcaseCard(context),
                ],
              ),
      ),
    );
  }

  Widget _buildUploadCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.borderSubtle),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, _) {
              return Text(
                'Change Clothes Online with AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: widget.isDesktop ? 28 : 24,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(
                      color: AppColors.amber.withValues(
                        alpha: 0.15 * _glowAnimation.value,
                      ),
                      blurRadius: 40 * _glowAnimation.value,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Experience AI virtual try on clothes with Desby',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => widget.onStartTryOn(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.amber,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_rounded,
                    color: context.colors.textPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Upload your clothes',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a garment from your shop or upload a photo',
            style: TextStyle(
              color: context.colors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 1,
            color: context.colors.surfaceHover,
          ),
          const SizedBox(height: 20),
          Text(
            'How it works',
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            Icons.camera_alt_rounded,
            'Snap or upload',
            'Take a front & side photo or pick from gallery',
            context,
          ),
          const SizedBox(height: 12),
          _buildFeatureRow(
            Icons.checkroom_rounded,
            'Pick a garment',
            'Choose any design from the marketplace or your shop',
            context,
          ),
          const SizedBox(height: 12),
          _buildFeatureRow(
            Icons.auto_awesome_rounded,
            'AI generates',
            'Our AI places the garment on your body realistically',
            context,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 1,
            color: context.colors.surfaceHover,
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: AppColors.amber, size: 14),
              SizedBox(width: 6),
              Text(
                'Upload tips',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    IconData icon,
    String title,
    String subtitle,
    BuildContext context,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.amber, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: context.colors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShowcaseCard(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: widget.isDesktop ? 480 : 320),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/tryon_result.png',
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (a, b, c) => Container(
          color: context.colors.surface,
          height: widget.isDesktop ? 480 : 320,
          child: Center(
            child: Icon(
              Icons.checkroom_rounded,
              color: context.colors.textMuted,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorks(BuildContext context) {
    final steps = [
      _HowStep(
        Icons.cloud_upload_rounded,
        AppColors.amber.withValues(alpha: 0.12),
        AppColors.amber,
        'Upload your outfit',
        'Upload a high-resolution image of the outfit you want to try on so the AI can recognize it.',
      ),
      _HowStep(
        Icons.person_add_rounded,
        AppColors.amber.withValues(alpha: 0.12),
        AppColors.amber,
        'Upload a photo of yourself',
        'Choose a portrait photo, standing alone, looking straight at the camera for best results.',
      ),
      _HowStep(
        Icons.auto_awesome_rounded,
        AppColors.amber.withValues(alpha: 0.12),
        AppColors.amber,
        'See the result',
        'In moments, the AI renders your chosen clothing fitted with incredible precision.',
      ),
    ];

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1100),
        padding: EdgeInsets.symmetric(
          horizontal: widget.isDesktop ? 48 : 24,
          vertical: 48,
        ),
        child: Column(
          children: [
            Text(
              'Online outfit fitting and styling is easy with Desby. Let\'s get started:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 40),
            if (widget.isDesktop)
              Row(
                children: steps
                    .map((s) => Expanded(child: _buildStepCard(s, context)))
                    .toList(),
              )
            else
              Column(
                children: steps.map((s) => _buildStepCard(s, context)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(_HowStep step, BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.surfaceHover),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: step.bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(step.icon, color: step.iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  step.desc,
                  style: TextStyle(
                    color: context.colors.textMuted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1100),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR TRY-ONS',
              style: TextStyle(
                color: AppColors.amber.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.tryOns.length,
                separatorBuilder: (_, a) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final t = widget.tryOns[i];
                  final url =
                      t['output_url'] as String? ??
                      t['image_url'] as String? ??
                      '';
                  return GestureDetector(
                    onTap: () => _showTryOnFullscreen(context, t),
                    child: Container(
                      width: 140,
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.colors.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                              child: url.isNotEmpty
                                  ? AppNetworkImage(
                                      url: url,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      filterQuality: FilterQuality.high,
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.checkroom_rounded,
                                        color: context.colors.textMuted,
                                        size: 24,
                                      ),
                                    ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.colors.surface,
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(15),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.open_in_full_rounded,
                                  color: context.colors.textMuted,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Try-On #${(t["id"] ?? "").toString().substring(0, 6)}',
                                  style: TextStyle(
                                    color: context.colors.textSecondary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTryOnFullscreen(BuildContext context, Map<String, dynamic> tryOn) {
    final outputUrl = tryOn['output_url'] as String? ?? '';
    final imageId = (tryOn["id"] ?? "").toString();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Try-On',
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (ctx, a1, a2, child) =>
          FadeTransition(opacity: a1, child: child),
      pageBuilder: (ctx, a1, a2) =>
          _TryOnFullscreenOverlay(imageUrl: outputUrl, tryOnId: imageId),
    );
  }
}

// Fullscreen try-on overlay with action buttons

class _TryOnFullscreenOverlay extends StatelessWidget {
  final String imageUrl;
  final String tryOnId;
  const _TryOnFullscreenOverlay({
    required this.imageUrl,
    required this.tryOnId,
  });

  void _downloadImage(BuildContext context) async {
    if (imageUrl.isEmpty) return;
    final uri = Uri.parse(imageUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  void _shareImage(BuildContext context) async {
    if (imageUrl.isEmpty) return;
    await Share.share('Check out my AI virtual try-on result! $imageUrl');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.scaffoldBg,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: imageUrl.isNotEmpty
                  ? AppNetworkImage(
                      url: imageUrl,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    )
                  : Center(
                      child: Icon(
                        Icons.checkroom_rounded,
                        color: context.colors.textMuted,
                        size: 60,
                      ),
                    ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [context.colors.overlayHeavy, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.divider,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: context.colors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Try-On #${tryOnId.substring(0, 6)}',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [context.colors.overlayHeavy, Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOverlayButton(
                    Icons.download_rounded,
                    'Save',
                    () => _downloadImage(context),
                    context,
                  ),
                  const SizedBox(width: 16),
                  _buildOverlayButton(
                    Icons.share_rounded,
                    'Share',
                    () => _shareImage(context),
                    context,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.divider,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: context.colors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: context.colors.textPrimary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// STEP 1: UPLOAD PAGE

class _UploadView extends StatefulWidget {
  final String? garmentUrl;
  final String? designTitle;
  final Uint8List? customerPhotoBytes;
  final List<Map<String, dynamic>> browseDesigns;
  final VoidCallback onBack;
  final VoidCallback onPickPhoto;
  final void Function(String url, String title) onSelectDesign;
  final VoidCallback onDeselectDesign;
  final VoidCallback onGenerate;

  const _UploadView({
    super.key,
    this.garmentUrl,
    this.designTitle,
    this.customerPhotoBytes,
    required this.browseDesigns,
    required this.onBack,
    required this.onPickPhoto,
    required this.onSelectDesign,
    required this.onDeselectDesign,
    required this.onGenerate,
  });

  @override
  State<_UploadView> createState() => _UploadViewState();
}

class _UploadViewState extends State<_UploadView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filteredDesigns {
    if (_searchQuery.isEmpty) return widget.browseDesigns;
    return widget.browseDesigns.where((d) {
      final title = (d['title'] as String? ?? '').toLowerCase();
      final category = (d['category'] as String? ?? '').toLowerCase();
      final tailor = (d['tailor_name'] as String? ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase();
      return title.contains(q) || category.contains(q) || tailor.contains(q);
    }).toList();
  }

  void _scrollLeft() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.offset - 300,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollRight() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.offset + 300,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1000;
    final hasGarment = widget.garmentUrl != null;

    return Container(
      color: context.colors.scaffoldBg,
      child: Column(
        children: [
          Container(
            height: 60,
            color: context.colors.scaffoldBg,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.amber,
                    size: 20,
                  ),
                  onPressed: widget.onBack,
                ),
                Text(
                  'UPLOAD & GENERATE',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.8,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 120 : 24,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasGarment) ...[
                    Row(
                      children: [
                        Text(
                          'SELECTED GARMENT',
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: widget.onDeselectDesign,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.close_rounded,
                                  color: context.colors.statusError,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Change',
                                  style: TextStyle(
                                    color: context.colors.statusError,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.amber.withValues(alpha: 0.3),
                        ),
                        color: context.colors.surface,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: AppNetworkImage(
                          url: widget.garmentUrl!,
                          fit: BoxFit.cover,
                          placeholderIcon: Icons.checkroom_rounded,
                        ),
                      ),
                    ),
                    if (widget.designTitle != null)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          widget.designTitle!,
                          style: TextStyle(
                            color: context.colors.textPrimary.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 28),
                  ],
                  if (!hasGarment) ...[
                    Row(
                      children: [
                        Text(
                          'SELECT GARMENT',
                          style: TextStyle(
                            color: context.colors.textPrimary.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: context.colors.surfaceHover,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search designs...',
                        hintStyle: TextStyle(
                          color: context.colors.textPrimary.withValues(
                            alpha: 0.25,
                          ),
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: context.colors.textPrimary.withValues(
                            alpha: 0.3,
                          ),
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: Icon(
                                  Icons.close_rounded,
                                  color: context.colors.textPrimary.withValues(
                                    alpha: 0.3,
                                  ),
                                  size: 18,
                                ),
                              )
                            : null,
                        filled: true,
                        fillColor: context.colors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: context.colors.surfaceHover,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.amber,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_filteredDesigns.isEmpty)
                      Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: context.colors.surfaceHover,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.checkroom_rounded,
                              color: context.colors.textPrimary.withValues(
                                alpha: 0.15,
                              ),
                              size: 28,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No designs match "$_searchQuery"'
                                  : 'No designs available yet',
                              style: TextStyle(
                                color: context.colors.textPrimary.withValues(
                                  alpha: 0.3,
                                ),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload a garment photo instead or browse the shop',
                              style: TextStyle(
                                color: context.colors.textPrimary.withValues(
                                  alpha: 0.2,
                                ),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 220,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _scrollLeft,
                              child: Container(
                                width: 36,
                                height: 36,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.colors.surfaceHover,
                                  border: Border.all(
                                    color: context.colors.surfaceHover,
                                  ),
                                ),
                                child: Icon(
                                  Icons.chevron_left_rounded,
                                  color: context.colors.textPrimary.withValues(
                                    alpha: 0.5,
                                  ),
                                  size: 22,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                controller: _scrollController,
                                scrollDirection: Axis.horizontal,
                                itemCount: _filteredDesigns.length,
                                separatorBuilder: (_, a) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, i) {
                                  final d = _filteredDesigns[i];
                                  final imgs =
                                      d['image_urls'] as List<dynamic>?;
                                  final imgUrl =
                                      (imgs != null && imgs.isNotEmpty)
                                      ? imgs[0].toString()
                                      : '';
                                  final title = d['title'] as String? ?? '';
                                  return GestureDetector(
                                    onTap: () =>
                                        widget.onSelectDesign(imgUrl, title),
                                    child: Container(
                                      width: 160,
                                      decoration: BoxDecoration(
                                        color: context.colors.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.amber.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(15),
                                                  ),
                                              child: imgUrl.isNotEmpty
                                                  ? AppNetworkImage(
                                                      url: imgUrl,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      placeholderIcon: Icons
                                                          .checkroom_rounded,
                                                    )
                                                  : Center(
                                                      child: Icon(
                                                        Icons.checkroom_rounded,
                                                        color: context
                                                            .colors
                                                            .textPrimary
                                                            .withValues(
                                                              alpha: 0.24,
                                                            ),
                                                        size: 28,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text(
                                              title,
                                              style: TextStyle(
                                                color: context
                                                    .colors
                                                    .textPrimary
                                                    .withValues(alpha: 0.7),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            GestureDetector(
                              onTap: _scrollRight,
                              child: Container(
                                width: 36,
                                height: 36,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.colors.surfaceHover,
                                  border: Border.all(
                                    color: context.colors.surfaceHover,
                                  ),
                                ),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  color: context.colors.textPrimary.withValues(
                                    alpha: 0.5,
                                  ),
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 28),
                  ],
                  Text(
                    'UPLOAD YOUR PHOTO',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: widget.onPickPhoto,
                    child: Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: widget.customerPhotoBytes != null
                              ? AppColors.accent.withValues(alpha: 0.4)
                              : context.colors.surfaceHover,
                        ),
                      ),
                      child: widget.customerPhotoBytes != null
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(23),
                                  child: Image.memory(
                                    widget.customerPhotoBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  bottom: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.colors.overlayHeavy,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.accent,
                                          size: 16,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Photo selected — tap to change',
                                          style: TextStyle(
                                            color: context.colors.textPrimary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accent.withValues(
                                      alpha: 0.1,
                                    ),
                                    border: Border.all(
                                      color: AppColors.accent.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: AppColors.accent,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tap to upload your photo',
                                  style: TextStyle(
                                    color: context.colors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'JPG, PNG up to 10MB',
                                  style: TextStyle(
                                    color: context.colors.textPrimary
                                        .withValues(alpha: 0.3),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          (widget.customerPhotoBytes != null &&
                              widget.garmentUrl != null)
                          ? widget.onGenerate
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: context.colors.textPrimary,
                        disabledBackgroundColor: AppColors.accent.withValues(
                          alpha: 0.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'GENERATE TRY-ON',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// STEP 2: PROCESSING

class _ProcessingView extends StatelessWidget {
  final Animation<double> pulseAnimation;
  final AnimationController statusController;
  const _ProcessingView({
    super.key,
    required this.pulseAnimation,
    required this.statusController,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = ['Uploading Assets...', 'AI Mapping...', 'Rendering...'];
    return Container(
      color: context.colors.scaffoldBg,
      child: Column(
        children: [
          Container(
            height: 60,
            color: context.colors.scaffoldBg,
            child: Center(
              child: Text(
                'PROCESSING',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.8,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: pulseAnimation,
                    builder: (context, _) {
                      return Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.amber.withValues(
                                alpha: 0.15 * pulseAnimation.value,
                              ),
                              blurRadius: 60 * pulseAnimation.value,
                              spreadRadius: 10 * pulseAnimation.value,
                            ),
                            BoxShadow(
                              color: AppColors.amber.withValues(
                                alpha: 0.08 * pulseAnimation.value,
                              ),
                              blurRadius: 120 * pulseAnimation.value,
                              spreadRadius: 30 * pulseAnimation.value,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.amber.withValues(alpha: 0.12),
                                  AppColors.amber.withValues(alpha: 0.02),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.amber.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.checkroom_rounded,
                              color: AppColors.amber,
                              size: 36,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'NEURAL FITTING IN PROGRESS',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: statusController,
                    builder: (context, _) {
                      final idx =
                          (statusController.value * statuses.length).floor() %
                          statuses.length;
                      return Text(
                        statuses[idx],
                        style: TextStyle(
                          color: AppColors.amber.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 200,
                    child: AnimatedBuilder(
                      animation: statusController,
                      builder: (context, _) {
                        return LinearProgressIndicator(
                          value: statusController.value,
                          backgroundColor: context.colors.borderSubtle,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.amber,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// STEP 3: RESULT - Full bleed images with overlay buttons

class _ResultView extends StatelessWidget {
  final String? resultUrl;
  final String? customerPhotoUrl;
  final String? designTitle;
  final String? tailorId;
  final String? tailorName;
  final VoidCallback onNewTryOn;
  final VoidCallback onBrowseDesigns;
  final void Function(String tailorId, String tailorName) onGetMade;

  const _ResultView({
    super.key,
    this.resultUrl,
    this.customerPhotoUrl,
    this.designTitle,
    this.tailorId,
    this.tailorName,
    required this.onNewTryOn,
    required this.onBrowseDesigns,
    required this.onGetMade,
  });

  void _downloadImage(BuildContext context) async {
    if (resultUrl == null) return;
    final uri = Uri.parse(resultUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  void _shareImage(BuildContext context) async {
    if (resultUrl == null) return;
    final uri = Uri.parse(resultUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1000;
    return Container(
      color: context.colors.scaffoldBg,
      child: Column(
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.amber,
                    size: 20,
                  ),
                  onPressed: onNewTryOn,
                ),
                Text(
                  'YOUR AI FITTING',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.8,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isDesktop
                ? Row(
                    children: [
                      Expanded(
                        child: _buildFullBleedCard(
                          'YOUR PHOTO',
                          customerPhotoUrl,
                          context,
                        ),
                      ),
                      Container(width: 1, color: context.colors.scaffoldBg),
                      Expanded(
                        child: _buildFullBleedCard(
                          'AI RESULT',
                          resultUrl,
                          context,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(
                        child: _buildFullBleedCard(
                          'YOUR PHOTO',
                          customerPhotoUrl,
                          context,
                        ),
                      ),
                      Container(height: 1, color: context.colors.scaffoldBg),
                      Expanded(
                        child: _buildFullBleedCard(
                          'AI RESULT',
                          resultUrl,
                          context,
                        ),
                      ),
                    ],
                  ),
          ),
          Container(
            padding: const EdgeInsets.only(
              bottom: 20,
              left: 20,
              right: 20,
              top: 16,
            ),
            decoration: BoxDecoration(
              color: context.colors.scaffoldBg,
              border: Border(top: BorderSide(color: context.colors.surface)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _downloadImage(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceHover,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: context.colors.surfaceHover,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.download_rounded,
                              color: context.colors.textPrimary.withValues(
                                alpha: 0.7,
                              ),
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Save',
                              style: TextStyle(
                                color: context.colors.textPrimary.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _shareImage(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceHover,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: context.colors.surfaceHover,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.share_rounded,
                              color: context.colors.textPrimary.withValues(
                                alpha: 0.7,
                              ),
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Share',
                              style: TextStyle(
                                color: context.colors.textPrimary.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (tailorId != null && tailorName != null)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onGetMade(tailorId!, tailorName!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.amber,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.storefront_rounded,
                                  color: context.colors.scaffoldBg,
                                  size: 15,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'GET THIS MADE',
                                  style: TextStyle(
                                    color: context.colors.scaffoldBg,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onNewTryOn,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'NEW TRY-ON',
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: onBrowseDesigns,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: context.colors.surfaceHover,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: context.colors.surfaceHover,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'BROWSE DESIGNS',
                            style: TextStyle(
                              color: context.colors.textPrimary.withValues(
                                alpha: 0.5,
                              ),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBleedCard(
    String label,
    String? imageUrl,
    BuildContext context,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: context.colors.scaffoldBg,
          child: imageUrl != null && imageUrl.isNotEmpty
              ? AppNetworkImage(
                  url: imageUrl,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  placeholderIcon: Icons.checkroom_rounded,
                )
              : Center(
                  child: Icon(
                    Icons.checkroom_rounded,
                    color: context.colors.textPrimary.withValues(alpha: 0.1),
                    size: 48,
                  ),
                ),
        ),
        Positioned(
          bottom: 12,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: context.colors.scaffoldBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: context.colors.textPrimary.withValues(alpha: 0.7),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
