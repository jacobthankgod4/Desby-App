import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/checkout_draft_repository.dart';
import '../../domain/entities/checkout_draft.dart';

final checkoutDraftRepositoryProvider =
    Provider<CheckoutDraftRepositoryContract>((ref) => CheckoutDraftRepository());

/// Loads a saved draft for the target the client is looking at, so a refresh or
/// a re-tap on the tailor resumes instead of starting over.
final savedDraftProvider = FutureProvider.autoDispose
    .family<CheckoutDraft?, CheckoutDraft>((ref, probe) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final repo = ref.watch(checkoutDraftRepositoryProvider);
  final result = await repo.loadFor(probe);
  return result.fold((_) => null, (draft) => draft);
});

/// The most recent in-progress request, used to offer "pick up where you left
/// off" instead of silently restarting.
final recentDraftProvider = FutureProvider.autoDispose<CheckoutDraft?>(
    (ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final repo = ref.watch(checkoutDraftRepositoryProvider);
  final result = await repo.loadMostRecent(user.id);
  return result.fold((_) => null, (draft) => draft);
});

/// Owns the draft for one journey. Single source of truth: every step reads and
/// writes this, so Back never loses anything and the state survives a reload.
class CheckoutDraftController extends StateNotifier<CheckoutDraft?> {
  CheckoutDraftController(this._repo, CheckoutDraft? initial)
      : super(initial);

  final CheckoutDraftRepositoryContract _repo;

  bool _saving = false;
  bool get isSaving => _saving;

  /// Start (or restart) a journey for this tailor/product pair.
  void begin({
    required String ownerId,
    CheckoutTailor? tailor,
    CheckoutProduct? product,
    CheckoutEntryMode? entryMode,
  }) {
    state = CheckoutDraft(
      ownerId: ownerId,
      tailor: tailor,
      product: product,
      entryMode: entryMode ??
          (product != null && product.isNotEmpty
              ? CheckoutEntryMode.fromProduct
              : CheckoutEntryMode.fromProfile),
      // A genuinely new target starts unanswered. Keeping a previous draft's
      // progress here would skip steps the client has not seen.
      furthestStep: -1,
    );
  }

  void _apply(CheckoutDraft Function(CheckoutDraft current) change) {
    final current = state;
    if (current == null) return;
    state = change(current);
  }

  void setEntryMode(CheckoutEntryMode mode) =>
      _apply((d) => d.copyWith(entryMode: mode));

  void setRequest(CheckoutRequest request) =>
      _apply((d) => d.copyWith(request: request));

  void setStyle(CheckoutStyle style) => _apply((d) => d.copyWith(style: style));

  void setFabric(CheckoutFabric fabric) =>
      _apply((d) => d.copyWith(fabric: fabric));

  /// The live fabric selection, for use inside event handlers.
  ///
  /// A widget's build-time snapshot of the draft goes stale as soon as anything
  /// is tapped, so a text field that copies from that snapshot can silently
  /// write back an older colour or ownership. Reading through this getter means
  /// handlers always start from what is actually stored right now.
  CheckoutFabric get currentFabric => state?.fabric ?? const CheckoutFabric();

  void setOccasions(List<String> occasions) =>
      _apply((d) => d.copyWith(occasions: occasions));

  void toggleOccasion(String occasion) =>
      _apply(
        (d) => d.copyWith(
          occasions: d.occasions.contains(occasion)
              ? d.occasions.where((o) => o != occasion).toList()
              : [...d.occasions, occasion],
        ),
      );

  void setMeasurements(CheckoutMeasurements measurements) =>
      _apply((d) => d.copyWith(measurements: measurements));

  void setAdditionalNotes(String? notes) =>
      _apply((d) => d.copyWith(additionalNotes: notes));

  void setDeliveryAddress(String? address) =>
      _apply((d) => d.copyWith(deliveryAddress: address));

  void setDueDate(DateTime? date) => _apply((d) => d.copyWith(dueDate: date));

  /// Append a reference image, keeping the first one as the primary so the
  /// tailor's card and `orders.material_asset_url` still resolve.
  void addMaterialAssetUrl(String url) => _apply((d) {
        if (d.materialAssetUrls.contains(url) ||
            d.materialAssetUrl == url) {
          return d;
        }
        final next = [...d.materialAssetUrls, url];
        return d.copyWith(
          materialAssetUrls: next,
          materialAssetUrl: d.materialAssetUrl ?? next.first,
        );
      });

  void removeMaterialAssetUrl(String url) => _apply((d) {
        final next = d.materialAssetUrls.where((u) => u != url).toList();
        return d.copyWith(
          materialAssetUrls: next,
          materialAssetUrl: next.contains(d.materialAssetUrl)
              ? d.materialAssetUrl
              : (next.isEmpty ? null : next.first),
          clearMaterialAssetUrl: next.isEmpty,
        );
      });

  void setMaterialAssetUrl(String? url) =>
      _apply((d) => d.copyWith(materialAssetUrl: url));

  /// Record that [step] is answered. Never moves backwards, so re-entering an
  /// earlier step to edit it does not discard later progress.
  void markStepAnswered(CheckoutStep step) {
    final current = state;
    if (current == null) return;
    _apply(
      (d) => d.copyWith(
        furthestStep: step.position > d.furthestStep ? step.position : d.furthestStep,
        // Record the acknowledgement too. `furthestStep` is the durable signal,
        // but keeping this accurate means completion survives even if the
        // furthest marker is ever reset.
        acknowledgedSteps: d.acknowledgedSteps.contains(step)
            ? d.acknowledgedSteps
            : {...d.acknowledgedSteps, step},
      ),
    );
  }

  /// Adopt a draft loaded from storage, preserving the journey's identity.
  ///
  /// The tailor/product links from the server win, because they are the
  /// authoritative record of what this draft is for.
  void restore(CheckoutDraft saved) {
    state = CheckoutDraft(
      ownerId: saved.ownerId,
      tailor: saved.tailor ?? state?.tailor,
      product: saved.product ?? state?.product,
      entryMode: saved.entryMode,
      request: saved.request,
      style: saved.style,
      fabric: saved.fabric,
      occasions: saved.occasions,
      measurements: saved.measurements,
      additionalNotes: saved.additionalNotes,
      furthestStep: saved.furthestStep,
      materialAssetUrl: saved.materialAssetUrl,
      deliveryAddress: saved.deliveryAddress,
      dueDate: saved.dueDate,
    );
  }

  /// Persist. Returns null on success, or a message to show the client.
  ///
  /// A save failure never discards what the client typed — the in-memory draft
  /// stays authoritative and they can retry.
  Future<String?> save() async {
    final current = state;
    if (current == null) return 'Nothing to save yet.';
    _saving = true;
    final result = await _repo.save(current);
    _saving = false;
    return result.fold(
      (failure) => failure.message,
      (saved) {
        // Adopt the row the database actually stored so the client and the
        // server agree about furthestStep and any server-side normalisation.
        state = saved;
        return null;
      },
    );
  }

  /// Save then advance. The step is only recorded once the write succeeded.
  Future<String?> advanceFrom(CheckoutStep step) async {
    markStepAnswered(step);
    return save();
  }

  Future<String?> discard() async {
    final current = state;
    if (current != null) {
      await _repo.discard(current);
    }
    state = null;
    return null;
  }
}

/// The one journey in progress.
///
/// Deliberately a single provider rather than a family: the client is only ever
/// inside one request at a time, and keying it per target would make the widget
/// tree unable to read the draft without threading the probe through every
/// step widget.
final checkoutDraftControllerProvider =
    StateNotifierProvider<CheckoutDraftController, CheckoutDraft?>((ref) {
  return CheckoutDraftController(
    ref.watch(checkoutDraftRepositoryProvider),
    null,
  );
});