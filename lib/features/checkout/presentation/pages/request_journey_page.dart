import 'package:desby_app/core/providers/navigation_provider.dart';
import 'package:desby_app/core/widgets/shell_app_bar.dart';
import 'package:desby_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:desby_app/features/checkout/domain/entities/checkout_draft.dart';
import 'package:desby_app/features/checkout/domain/entities/journey_state.dart';
import 'package:desby_app/features/checkout/presentation/providers/checkout_draft_provider.dart';
import 'package:desby_app/features/checkout/presentation/widgets/fabric_and_fit_steps.dart';
import 'package:desby_app/features/designs/presentation/pages/ai_body_scan_page.dart';
import 'package:desby_app/features/checkout/presentation/widgets/progress_tracker.dart';
import 'package:desby_app/features/checkout/presentation/widgets/profile_address_prompt.dart';
import 'package:desby_app/features/checkout/presentation/widgets/request_journey_tour.dart';
import 'package:desby_app/features/checkout/presentation/widgets/request_steps.dart';
import 'package:desby_app/features/checkout/presentation/widgets/review_step.dart';
import 'package:desby_app/features/checkout/presentation/widgets/step_progression_widgets.dart';
import 'package:desby_app/features/orders/domain/entities/order.dart';
import 'package:desby_app/features/orders/domain/entities/order_ids.dart';
import 'package:desby_app/features/orders/presentation/providers/order_provider.dart';
import 'package:desby_app/theme/colors.dart';
import 'package:desby_app/theme/spacing.dart';
import 'package:desby_app/theme/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:uuid/uuid.dart';

/// The guided request journey — progressive disclosure, one step at a time.
///
/// The interaction model is a workflow, not a stack of cards:
///
/// ```
/// step 1 active  ->  complete  ->  collapse to a summary
///                                 ->  advance the tracker
///                                 ->  reveal + scroll to step 2
/// ```
///
/// Locked steps are **not built at all** — see [JourneyState.visibleSteps]. A
/// hidden-but-rendered form is still tab-reachable and still announced by a
/// screen reader, which would make the promise of "one thing at a time" a lie.
///
/// Desktop keeps the split screen from the earlier brief: the rail narrates
/// where the client is on the left, the single active step is the only
/// interactive region on the right. On mobile it collapses to
/// progress -> step -> CTA.
class RequestJourneyPage extends ConsumerStatefulWidget {
  const RequestJourneyPage({
    super.key,
    this.tailorId,
    this.tailorName,
    this.tailorAvatarUrl,
    this.designId,
    this.productId,
    this.productTitle,
    this.productCategory,
    this.productImageUrls = const [],
    this.productPrice,
    this.selectedSize,
    this.selectedColour,
    this.quantity = 1,
  });

  final String? tailorId;
  final String? tailorName;
  final String? tailorAvatarUrl;
  final String? designId;
  final String? productId;
  final String? productTitle;
  final String? productCategory;
  final List<String> productImageUrls;
  final double? productPrice;
  final String? selectedSize;
  final String? selectedColour;
  final int quantity;

  @override
  ConsumerState<RequestJourneyPage> createState() => _RequestJourneyPageState();
}

class _RequestJourneyPageState extends ConsumerState<RequestJourneyPage>
    with SingleTickerProviderStateMixin {
  /// The workflow state, kept as one object so "where am I and what may the
  /// client see" has exactly one answer.
  JourneyState _journey = const JourneyState();

  String? _validation;
  String? _submitError;

  /// Set when bootstrap could not get the app into a usable state. Without this
  /// the page sat on an endless spinner: `_bootstrap` returned silently while
  /// auth was still restoring, the draft stayed null, and nothing ever moved.
  bool _bootFailed = false;

  /// The scan is hosted *inside* the flow rather than pushed as a route, so the
  /// client keeps their place in the journey. `_scanExpanded` promotes the same
  /// widget to fullscreen — one instance, so the in-progress scan survives.
  bool _scanOpen = false;
  bool _scanExpanded = false;

  /// Drives the step reveal, shared with [StaggeredReveal] so the whole step
  /// assembles off one curve.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    value: 1,
  );

  RevealDirection _revealDirection = RevealDirection.forward;

  void _playReveal({required bool forward}) {
    _revealDirection =
        forward ? RevealDirection.forward : RevealDirection.back;
    _reveal
      ..value = 0
      ..forward();
  }
  String? _bootError;

  final ScrollController _scroll = ScrollController();
  final GlobalKey _activeStepKey = GlobalKey();
  final GlobalKey _trackerKey = GlobalKey();
  final GlobalKey _ctaKey = GlobalKey();
  final Map<CheckoutStep, GlobalKey> _stepKeys = {
    for (final s in CheckoutStep.values) s: GlobalKey(),
  };

  @override
  void dispose() {
    _reveal.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _bootstrap();
      await _maybeTour();
    });
  }

  Future<void> _bootstrap() async {
    final user = await _awaitUser();
    if (!mounted) return;
    if (user == null) {
      // Auth never produced a user. Say so and get them somewhere useful
      // rather than spinning forever.
      setState(() {
        _bootFailed = true;
        _bootError = 'We could not load your account. Please sign in again.';
      });
      return;
    }
    final notifier = ref.read(checkoutDraftControllerProvider.notifier);

    // Opened without a tailor or design — a resume, or a stale link. The client
    // is either picking their unfinished request back up or is simply lost, so
    // send them to whichever is true rather than to an empty form.
    if (widget.tailorId == null && widget.designId == null && widget.productId == null) {
      await _resumeOrRedirect();
      return;
    }

    final tailor = widget.tailorId == null
        ? null
        : CheckoutTailor(
            id: widget.tailorId!,
            name: widget.tailorName,
            avatarUrl: widget.tailorAvatarUrl,
          );
    final product = (widget.designId == null && widget.productId == null)
        ? null
        : CheckoutProduct(
            designId: widget.designId,
            productId: widget.productId,
            title: widget.productTitle,
            category: widget.productCategory,
            imageUrls: widget.productImageUrls,
            price: widget.productPrice,
            selectedSize: widget.selectedSize,
            selectedColour: widget.selectedColour,
            quantity: widget.quantity,
          );

    notifier.begin(
      ownerId: user.id,
      tailor: tailor,
      product: product,
      entryMode: product == null
          ? CheckoutEntryMode.fromProfile
          : CheckoutEntryMode.fromProduct,
    );

    final saved = await ref.read(
      savedDraftProvider(CheckoutDraft(ownerId: user.id, tailor: tailor, product: product))
          .future,
    );
    if (!mounted || saved == null || saved.ownerId != user.id) return;

    notifier.restore(saved);
    // Resume on the first step that has not been answered.
    final resume = CheckoutStep.fromIndex(saved.furthestStep + 1) ??
        CheckoutStep.defineRequest;
    setState(() {
      _journey = JourneyState(
        currentStep: resume,
        completedSteps: saved.completedSteps,
      );
    });
  }

  /// Resume the most recent unfinished request, or return to browsing.
  /// Waits for the signed-in user, bounded.
  ///
  /// `currentUserProvider` is briefly null while Supabase restores a session.
  /// Reading it once and giving up is what produced the permanent spinner.
  /// Shown when the page could not reach a usable state. Always offers a way
  /// out — a dead-end spinner is worse than an honest message.
  Widget _buildBootError(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 40, color: colors.textMuted),
              const SizedBox(height: AppSpacing.md),
              Text(
                'We could not start your request',
                textAlign: TextAlign.center,
                style: AppTypography.subtitle1.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _bootError ?? 'Something went wrong. Nothing you have entered is lost.',
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => ref.setShell('/main'),
                    child: const Text('Back to home'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _bootFailed = false;
                        _bootError = null;
                      });
                      _bootstrap();
                    },
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<dynamic> _awaitUser() async {
    final immediate = ref.read(currentUserProvider);
    if (immediate != null) return immediate;
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return null;
      final user = ref.read(currentUserProvider);
      if (user != null) return user;
    }
    return null;
  }

  Future<void> _resumeOrRedirect() async {
    try {
      final recent = await ref.read(recentDraftProvider.future);
      if (!mounted) return;
      if (recent != null && recent.tailor != null) {
        // Re-enter through the same arguments a tailor profile would supply, so
        // the draft is matched by (owner, tailor) and the saved answers return.
        final restored = recent!;
        ref.read(checkoutDraftControllerProvider.notifier).restore(restored);
        if (!mounted) return;
        setState(() {
          _journey = JourneyState(
            currentStep:
                CheckoutStep.fromIndex(restored.furthestStep + 1) ??
                    CheckoutStep.defineRequest,
            completedSteps: restored.completedSteps,
          );
        });
        await _revealAndFocus(_journey.currentStep);
        return;
      }
    } catch (e) {
      debugPrint('[REQUEST_JOURNEY] resume lookup failed: $e');
    }
    if (!mounted) return;
    ref.setShell('/main');
  }

  Future<void> _maybeTour() async {
    if (!mounted) return;
    if (!await RequestJourneyTour.shouldShow()) return;
    if (!mounted) return;
    // One frame later so the step keys have a context to point at.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    RequestJourneyTour.show(
      context,
      stops: [
        JourneyTourStop(
          keyTarget: _trackerKey,
          title: 'One step at a time',
          body: 'This is a short conversation with your tailor, not a form. '
              'We ask for one thing at a time and you can go back any time.',
        ),
        JourneyTourStop(
          keyTarget: _activeStepKey,
          title: 'Your request, step by step',
          body: 'Start with what you want made, then style, fabric, occasion '
              'and fit. Anything optional can be skipped.',
        ),
        JourneyTourStop(
          keyTarget: _ctaKey,
          align: ContentAlign.top,
          title: 'Nothing is sent until the end',
          body: 'Continue moves you forward. Only on the final review will you '
              'send the request to your tailor.',
        ),
      ],
      onFinish: RequestJourneyTour.markComplete,
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(checkoutDraftControllerProvider);
    if (draft == null) {
      return Scaffold(
        appBar: shellAppBar(context, title: 'Request'),
        body: _bootFailed
            ? _buildBootError(context)
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: shellAppBar(context, title: 'Request'),
      body: _scanOpen ? _buildInFlowScan() : _buildJourneyBody(draft, wide),
    );
  }

  Widget _buildJourneyBody(CheckoutDraft draft, bool wide) {
    return wide
        ? Row(
            children: [
              _rail(draft),
              Expanded(child: _progressiveBody(draft, wide: true)),
            ],
          )
        : _progressiveBody(draft, wide: false);
  }

  /// Why Continue is unavailable, in the client's words rather than a dead
  /// grey button.
  String _blockedHint(CheckoutStep step) => switch (step) {
        CheckoutStep.fabric => 'Add a cloth reference to continue',
        CheckoutStep.defineRequest => 'Tell us what you want made',
        _ => 'Answer this step to continue',
      };

  /// Take the scan's measurements into the draft, where they persist through
  /// Supabase with everything else and are written onto the order at submit.
  Future<void> _onScanMeasurementsReady(
    Map<String, dynamic> measurements,
    String gender,
    double heightCm,
  ) async {
    final values = <String, double>{};
    measurements.forEach((key, value) {
      if (value is num) values[key] = value.toDouble();
    });
    debugPrint('[CHECKOUT] scan measurements received: ${values.length}');

    ref
        .read(checkoutDraftControllerProvider.notifier)
        .setMeasurements(
          CheckoutMeasurements(
            source: MeasurementSource.bodyScan,
            values: values,
          ),
        );
    // Persist immediately. A scan costs the client two photos and several
    // minutes of processing; _apply only mutates memory and the next save would
    // otherwise not happen until they changed step. Losing 25 measurements to a
    // stray refresh is not acceptable.
    final error = await ref.read(checkoutDraftControllerProvider.notifier).save();
    if (!mounted) return;
    if (error != null) {
      debugPrint('[CHECKOUT] measurement save failed: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan added, but we could not save it: $error'),
          backgroundColor: context.colors.statusWarning,
        ),
      );
    }

    // Return to the journey so the client sees the measurements they just took.
    setState(() {
      _scanExpanded = false;
      _scanOpen = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${values.length} measurements added to your request',
        ),
        backgroundColor: context.colors.statusSuccess,
      ),
    );
  }

  /// The scan, hosted in the flow. Collapsed it keeps the flow header; expanded
  /// it takes the entire screen.
  Widget _buildInFlowScan() {
    final colors = context.colors;
    return Column(
      children: [
        if (!_scanExpanded)
          Container(
            color: colors.scaffoldBg,
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Icon(Icons.accessibility_new, size: 20, color: colors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Body scan',
                          style: AppTypography.subtitle1.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700)),
                      Text('Step 5 of 6 · measurements',
                          style: AppTypography.caption
                              .copyWith(color: colors.textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Expand',
                  icon: Icon(Icons.fullscreen, size: 20, color: colors.textSecondary),
                  onPressed: () => setState(() => _scanExpanded = true),
                ),
                IconButton(
                  tooltip: 'Close scan',
                  icon: Icon(Icons.close, size: 20, color: colors.textSecondary),
                  onPressed: () => setState(() {
                    _scanExpanded = false;
                    _scanOpen = false;
                  }),
                ),
              ],
            ),
          ),
        Expanded(
          child: AiBodyScanPage(
            inFlow: true,
            expanded: _scanExpanded,
            onToggleExpanded: () =>
                setState(() => _scanExpanded = !_scanExpanded),
            // Without this the scan finished successfully but its 25
            // measurements could never reach the booking: the page had no way
            // to hand them back, so the draft stayed empty and the tailor was
            // asked to work from a "Fit" step with nothing in it.
            onMeasurementsReady: _onScanMeasurementsReady,
          ),
        ),
      ],
    );
  }

  /// ── Left rail: context + the progress journey ──
  Widget _rail(CheckoutDraft draft) {
    final colors = context.colors;
    return Container(
      width: 340,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.sidebarBg,
        border: Border(right: BorderSide(color: colors.sidebarBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (draft.tailor != null) ...[
            Text(
              draft.tailor!.name ?? 'Your tailor',
              style: AppTypography.headline4.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'You are booking a request with '
              '${draft.tailor!.name ?? 'this tailor'}.',
              style: AppTypography.subtitle2.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          ProgressTracker(
            key: _trackerKey,
            state: _journey,
            draft: draft,
            onJump: _jumpTo,
          ),
          const Spacer(),
          Text(
            'Your progress is saved automatically. You can leave and come back.',
            style: AppTypography.captionSmall.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  /// ── The progressive column ──
  Widget _progressiveBody(CheckoutDraft draft, {required bool wide}) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: EdgeInsets.all(wide ? AppSpacing.lg : AppSpacing.md),
            children: [
              // Opening hero, shown only before the client has answered
              // anything. Once they start, the space belongs to the request.
              if (draft.completedSteps.isEmpty) ...[
                _JourneyHero(wide: wide),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (!wide) ...[
                ProgressTracker(
                  state: _journey,
                  draft: draft,
                  onJump: _jumpTo,
                  compact: true,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Completed steps collapse to one line each, above the active one.
              for (final step in _journey.visibleSteps)
                if (_journey.isCompleted(step)) ...[
                  CompletedStepSummary(
                    step: step,
                    draft: draft,
                    onEdit: () => _jumpTo(step),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

              // The one active step. Always exactly one.
              _activeSection(draft, wide: wide),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
        _actions(draft),
      ],
    );
  }

  Widget _activeSection(CheckoutDraft draft, {required bool wide}) {
    final step = _journey.currentStep;
    final dependents = _journey.dependentsOf(step);
    final warning = dependents.isEmpty
        ? null
        : 'Changing this may affect your selections in '
            '${dependents.length} later step${dependents.length == 1 ? '' : 's'}. '
            'Nothing is deleted — we will tell you what no longer applies.';

    return Container(
      key: _activeStepKey,
      margin: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActiveStepHeader(
            showCounter: !wide,
            state: _journey,
            title: step.title,
            purpose: step.purpose,
            warning: warning,
          ),
          const SizedBox(height: AppSpacing.lg),
          // The milestone banner only appears once every step is answered.
          if (_journey.isMilestone) ...[
            _milestoneBanner(),
            const SizedBox(height: AppSpacing.lg),
          ],
          RevealOnChange(
            key: ValueKey(step),
            step: step,
            controller: _reveal,
            direction: _revealDirection,
            child: KeyedSubtree(
              key: _stepKeys[step],
              // Cascades the step's own sections off the same curve. Without it
              // a step arrives as one flat block, which reads as a page load
              // rather than the interface responding.
              child: StaggeredReveal(
                animation: _reveal,
                child: _bodyFor(step),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bodyFor(CheckoutStep step) => switch (step) {
        CheckoutStep.defineRequest => const DefineRequestStep(),
        CheckoutStep.styleDirection => const StyleDirectionStep(),
        CheckoutStep.fabric => const FabricStep(),
        CheckoutStep.occasion => const OccasionStep(),
        CheckoutStep.measurements => MeasurementsStep(
          onStartScan: () => setState(() {
            _scanExpanded = false;
            _scanOpen = true;
          }),
        ),
        CheckoutStep.review => ReviewStep(
            onEdit: (s) => _jumpTo(s),
            onSubmit: _submit,
          ),
      };

  /// Opening image for the journey.
  ///
  /// Bundled rather than fetched: the file is 41 KB (re-encoded from a 917 KB
  /// webp), so it paints immediately on a slow connection and adds no network
  /// round trip before the first question.
  Widget _JourneyHero({required bool wide}) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.lg),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Image.asset(
            'assets/images/journey/hero_tailoring.webp',
            width: double.infinity,
            height: wide ? 240 : 170,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          // A scrim keeps the caption legible on any part of the photograph and
          // ties it into the surface colours.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.background.withValues(alpha: 0.15),
                    colors.background.withValues(alpha: 0.82),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Text(
              'Made by hand, for you.',
              style: AppTypography.headline5.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _milestoneBanner() {
    final colors = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.98 + 0.02 * t, child: child),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.statusSuccess.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(color: colors.statusSuccess.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: colors.statusSuccess),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your request is ready.',
                    style: AppTypography.subtitle1.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Check it over below, then send it to your tailor.',
                    style: AppTypography.caption.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ── Actions ──
  Widget _actions(CheckoutDraft draft) {
    final colors = context.colors;
    final step = _journey.currentStep;
    final isReview = step == CheckoutStep.review;
    // The submission CTA only exists on review, and only once every step is
    // answered. Never "Place Order" while work is outstanding.
    final canSubmit =
        _journey.isReadyToSubmit && draft.isSubmittable && draft.isBlockingComplete;
    final busy = _journey.isTransitioning || _journey.isSubmitting;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardBg,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_validation != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  _validation!,
                  style: AppTypography.caption.copyWith(color: colors.statusError),
                ),
              ),
            if (_submitError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  _submitError!,
                  style: AppTypography.caption.copyWith(color: colors.statusError),
                ),
              ),
            Row(
              children: [
                if (step != CheckoutStep.defineRequest)
                  TextButton.icon(
                    onPressed: busy ? null : _goBack,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back'),
                  ),
                const Spacer(),
                if (canSubmit)
                  FilledButton.icon(
                    key: _ctaKey,
                    onPressed: busy ? null : _submit,
                    icon: _journey.isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, size: 18),
                    label: const Text('Send request to tailor'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                    ),
                  )
                else if (!isReview)
                  FilledButton.icon(
                    key: _ctaKey,
                    // Blocking steps must actually be answered. Without this the
                    // button was live on the cloth step with no reference
                    // uploaded, so the client could walk past the one thing
                    // that stops "this is not what I asked for".
                    onPressed: busy || !draft.canContinueFrom(step)
                        ? null
                        : _completeStep,
                    icon: _journey.isTransitioning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward, size: 18),
                    label: Text(
                      draft.canContinueFrom(step) ? 'Continue' : _blockedHint(step),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── navigation ──

  CheckoutStep get _previous =>
      CheckoutStep.fromIndex(_journey.currentStep.position - 1) ??
      CheckoutStep.defineRequest;

  /// Back is non-destructive: it re-opens a step for editing and never deletes
  /// anything the client entered.
  void _goBack() {
    _playReveal(forward: false);
    _jumpTo(_previous);
  }

  void _jumpTo(CheckoutStep step) {
    if (_journey.isLocked(step)) return;
    setState(() {
      _journey = _journey.copyWith(
        currentStep: step,
        completedSteps: step == _journey.currentStep
            ? _journey.completedSteps
            : _journey.completedSteps,
      );
      _validation = null;
    });
    _revealAndFocus(step);
  }

  Future<void> _completeStep() async {
    _playReveal(forward: true);
    final draft = ref.read(checkoutDraftControllerProvider);
    if (draft == null) return;

    final problem = _validate(draft);
    if (problem != null) {
      setState(() => _validation = problem);
      return;
    }

    final completed = _journey.currentStep;

    // 1. validate, then record completion
    setState(() {
      _validation = null;
      _journey = _journey.copyWith(
        isTransitioning: true,
        completedSteps: {..._journey.completedSteps, completed},
      );
    });

    // 2. persist before unlocking the next step, so progress is never claimed
    //    that was not saved.
    final error = await ref
        .read(checkoutDraftControllerProvider.notifier)
        .advanceFrom(completed);

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _journey = _journey.copyWith(
          isTransitioning: false,
          // roll the completion back — we cannot claim what did not save
          completedSteps: _journey.completedSteps..remove(completed),
        );
        _submitError = 'Could not save your progress: $error';
      });
      return;
    }

    final draftAfter = ref.read(checkoutDraftControllerProvider)!;
    final next = CheckoutStep.fromIndex(completed.position + 1) ??
        CheckoutStep.review;

    setState(() {
      _journey = _journey.copyWith(
        currentStep: next,
        completedSteps: draftAfter.completedSteps,
        isTransitioning: false,
      );
    });

    // 3. scroll + focus the newly revealed step
    await _revealAndFocus(next);
  }

  /// Smoothly bring the active step into view, then move focus to its heading so
  /// a screen reader announces the change.
  Future<void> _revealAndFocus(CheckoutStep step) async {
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (!mounted) return;
    final ctx = _stepKeys[step]?.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.02,
      );
    }
    if (!mounted) return;
    final target = _stepKeys[step]?.currentContext;
    if (target != null) {
      // Announce without stealing focus from the CTA on the same screen.
      SemanticsService.announce(
        '${step.title}. ${step.purpose}',
        TextDirection.ltr,
      );
    }
  }

  /// Contextual validation. Never fires before the client interacts.
  String? _validate(CheckoutDraft draft) {
    if (_journey.currentStep != CheckoutStep.defineRequest) return null;
    if (!draft.entryMode.needsGarmentDefinition) return null;
    final garment = draft.request.garmentType;
    if (garment == null || garment.trim().isEmpty) {
      return 'Tell us what you would like ${draft.tailor?.name ?? 'your tailor'} '
          'to sew before continuing. Pick the closest garment above — you can '
          'change it later.';
    }
    return null;
  }

  Future<void> _submit() async {
    final draft = ref.read(checkoutDraftControllerProvider);
    final user = ref.read(currentUserProvider);
    if (draft == null || user == null) return;

    // Offer to remember a freshly typed delivery address — the one place the
    // client is guaranteed to have just written it down.
    final promptAddress = (draft.deliveryAddress ?? '').trim();
    if (promptAddress.isNotEmpty) {
      await ProfileAddressPrompt.askToSave(context, promptAddress);
      if (!mounted) return;
    }

    setState(() {
      _journey = _journey.copyWith(isSubmitting: true);
      _submitError = null;
    });

    final order = OrderEntity(
      id: const Uuid().v4(),
      reference: OrderIds.newReference(),
      requestingUserId: user.id,
      // `orders.client_id` is a foreign key to `clients(id)`, and a browsing
      // client has no record there — writing the auth uid failed every insert
      // with 23503 (verified against the live database). The requester is
      // attributed by `requesting_user_id`, which is what the client's own
      // orders list matches on (supabase_order_repository.dart).
      clientId: null,
      tailorId: draft.tailor?.id,
      clientName: user.name,
      status: OrderStatus.pending,
      // Not a guaranteed price: the tailor quotes. The review step says so.
      totalAmount: draft.product?.price ?? 0,
      dispatchFee: 0,
      dueDate: draft.dueDate,
      createdAt: DateTime.now(),
      fabricType: draft.fabric.name ?? 'To be advised',
      fabricColor: draft.fabric.colour,
      materialAssetUrl: draft.materialAssetUrl,
      deliveryAddress: draft.deliveryAddress,
      // This is the switch that activates the tailor-side Fez flow: when the
      // tailor marks the garment READY, `order_detail_page` summons a rider
      // only when requiresDispatch is true and no waybill exists yet. The client
      // never picks a courier — they only say where it goes.
      requiresDispatch: (draft.deliveryAddress ?? '').trim().isNotEmpty,
      metadata: draft.toSubmissionMap(),
      items: [
        OrderItem(
          id: const Uuid().v4(),
          garmentType:
              draft.request.garmentType ?? draft.product?.title ?? 'Custom garment',
          designId: draft.product?.designId,
          measurements: draft.measurements.values,
          price: draft.product?.price ?? 0,
        ),
      ],
    );

    final result = await ref.read(createOrderUsecaseProvider)(order);
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _journey = _journey.copyWith(isSubmitting: false);
        _submitError = 'We could not send your request: ${failure.message}. '
            'Nothing you entered was lost — try again.';
      }),
      (saved) async {
        setState(() => _journey = _journey.copyWith(isSubmitting: false));
        await ref.read(checkoutDraftControllerProvider.notifier).discard();
        ref.invalidate(ordersProvider);
        if (!mounted) return;
        _showSubmitted(context, saved);
      },
    );
  }

  void _showSubmitted(BuildContext context, OrderEntity saved) {
    final colors = context.colors;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.dialogBg,
        icon: Icon(Icons.check_circle, color: colors.statusSuccess, size: 40),
        title: Text('Request sent', style: AppTypography.headline5),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your tailor now has this request and will come back to you with '
              'a quote. Nothing was charged.',
              style: AppTypography.body2,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your reference',
              style: AppTypography.captionSmall
                  .copyWith(color: colors.textMuted),
            ),
            Text(
              saved.displayReference,
              style: AppTypography.subtitle1.copyWith(
                color: colors.borderFocused,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'What happens next: your tailor reviews the request and replies '
              'with a price and timeline. You can follow it from your requests.',
              style: AppTypography.caption.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.setShell('/orders');
            },
            child: const Text('View my requests'),
          ),
        ],
      ),
    );
  }
}
