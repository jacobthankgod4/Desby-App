import 'package:equatable/equatable.dart';
import '../../../payments/domain/platform_money_config.dart';

/// How the client entered the request. This is the single most important piece
/// of context in the whole flow, because it decides what we are allowed to ask.
///
/// * [fromProfile] — a tailor profile. No product is known, so Step 1 must
///   establish *what to sew*. Asking "which design?" would be nonsense.
/// * [fromProduct] — a design or shop product is already chosen. Everything the
///   system knows is shown back to the client and we ask only how they want it
///   made.
/// * [customDesign] — a design is chosen but they want something different.
///   Legitimate, and not the same state as [fromProduct].
enum CheckoutEntryMode {
  fromProfile('from_profile'),
  fromProduct('from_product'),
  customDesign('custom_design');

  const CheckoutEntryMode(this.storageValue);

  /// The exact string the database column accepts.
  ///
  /// Must not be [Enum.name]: Dart gives `fromProfile` (camelCase) while
  /// order_drafts_entry_mode_check allows `from_profile` (snake_case). Writing
  /// `name` here fails every insert with 23514.
  final String storageValue;

  static CheckoutEntryMode? fromName(String? value) {
    for (final mode in CheckoutEntryMode.values) {
      if (mode.storageValue == value) return mode;
    }
    return null;
  }

  /// True when the flow must ask what garment the client wants.
  bool get needsGarmentDefinition => this == CheckoutEntryMode.fromProfile;

  /// True when a product/design is part of the request.
  bool get hasProduct =>
      this == CheckoutEntryMode.fromProduct ||
      this == CheckoutEntryMode.customDesign;
}

/// Where the fit information came from. Recorded so an order can always be
/// traced back to the exact measurement set it was cut from.
enum MeasurementSource {
  bodyScan('body_scan'),
  manual('manual'),
  profile('profile'),
  none('none');

  const MeasurementSource(this.storageValue);

  /// Matches order_drafts_measurement_source_check. Dart's default `name`
  /// would give `bodyScan` and be rejected by the CHECK.
  final String storageValue;

  static MeasurementSource? fromName(String? value) {
    for (final s in MeasurementSource.values) {
      if (s.storageValue == value) return s;
    }
    return null;
  }
}

/// The six steps of the guided journey. Deliberately typed so a step index
/// cannot silently drift into a different step.
enum CheckoutStep {
  defineRequest,
  styleDirection,
  fabric,
  occasion,
  measurements,
  review;

  static CheckoutStep? fromIndex(int index) =>
      (index >= 0 && index < CheckoutStep.values.length)
          ? CheckoutStep.values[index]
          : null;

  /// Position in the journey. Named `position` because `index` collides
  /// with Enum.index.
  int get position => CheckoutStep.values.indexOf(this);

  String get title => switch (this) {
        CheckoutStep.defineRequest => 'Define the request',
        CheckoutStep.styleDirection => 'Style direction',
        CheckoutStep.fabric => 'Fabric',
        CheckoutStep.occasion => 'Occasion',
        CheckoutStep.measurements => 'Fit',
        CheckoutStep.review => 'Review',
      };

  /// One line explaining why this step exists. Shown under the title so the
  /// client always knows why we are asking.
  String get purpose => switch (this) {
        CheckoutStep.defineRequest =>
          'Tell the tailor what to make. This is the heart of the request.',
        CheckoutStep.styleDirection =>
          'The visual direction — cut, silhouette and how it should look.',
        CheckoutStep.fabric =>
          'What it is made from. Your tailor works with real stock, so this '
              'decides what they can actually cut.',
        CheckoutStep.occasion =>
          'Where it will be worn, so they can dress it appropriately.',
        CheckoutStep.measurements =>
          'Accurate measurements are how an outfit fits you rather than a size.',
        CheckoutStep.review =>
          'Check everything before it reaches the tailor.',
      };
}

/// The tailor being commissioned. Separate from the product and from the
/// request — the brief's "who is making the garment".
class CheckoutTailor extends Equatable {
  final String id;
  final String? name;
  final String? avatarUrl;
  final String? location;

  const CheckoutTailor({
    required this.id,
    this.name,
    this.avatarUrl,
    this.location,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'location': location,
      };

  @override
  List<Object?> get props => [id, name, avatarUrl, location];
}

/// The design or product already selected, if any. Separate from the request —
/// the brief's "existing Desby design/product selected by the client".
class CheckoutProduct extends Equatable {
  final String? designId;
  final String? productId;
  final String? title;
  final String? category;
  final List<String> imageUrls;
  final double? price;
  /// Size the client picked on the product page. Was previously dropped on the
  /// floor between the product page and checkout.
  final String? selectedSize;
  /// Colour index/name the client picked. Also previously dropped.
  final String? selectedColour;
  final int quantity;

  const CheckoutProduct({
    this.designId,
    this.productId,
    this.title,
    this.category,
    this.imageUrls = const [],
    this.price,
    this.selectedSize,
    this.selectedColour,
    this.quantity = 1,
  });

  bool get isNotEmpty =>
      designId != null || productId != null;

  CheckoutProduct copyWith({
    String? designId,
    String? productId,
    String? title,
    String? category,
    List<String>? imageUrls,
    double? price,
    String? selectedSize,
    String? selectedColour,
    int? quantity,
  }) =>
      CheckoutProduct(
        designId: designId ?? this.designId,
        productId: productId ?? this.productId,
        title: title ?? this.title,
        category: category ?? this.category,
        imageUrls: imageUrls ?? this.imageUrls,
        price: price ?? this.price,
        selectedSize: selectedSize ?? this.selectedSize,
        selectedColour: selectedColour ?? this.selectedColour,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toJson() => {
        'designId': designId,
        'productId': productId,
        'title': title,
        'category': category,
        'imageUrls': imageUrls,
        'price': price,
        'selectedSize': selectedSize,
        'selectedColour': selectedColour,
        'quantity': quantity,
      };

  @override
  List<Object?> get props => [
        designId,
        productId,
        title,
        category,
        imageUrls,
        price,
        selectedSize,
        selectedColour,
        quantity,
      ];
}

/// Step 1 — what the client wants made.
class CheckoutRequest extends Equatable {
  /// Garment or outfit. Required when entering from a tailor profile.
  final String? garmentType;

  /// A sentence in the client's own words. The single highest-value input in
  /// the whole form, and the one the legacy flow never asked for.
  final String? summary;

  /// Set when the client picked "something different" despite a design being
  /// preselected. Distinguishes "make this exact design" from "hire this
  /// tailor for something else" — the brief calls these different states.
  final bool wantsSomethingDifferent;

  const CheckoutRequest({
    this.garmentType,
    this.summary,
    this.wantsSomethingDifferent = false,
  });

  CheckoutRequest copyWith({
    String? garmentType,
    String? summary,
    bool? wantsSomethingDifferent,
  }) =>
      CheckoutRequest(
        garmentType: garmentType ?? this.garmentType,
        summary: summary ?? this.summary,
        wantsSomethingDifferent:
            wantsSomethingDifferent ?? this.wantsSomethingDifferent,
      );

  Map<String, dynamic> toJson() => {
        'garmentType': garmentType,
        'summary': summary,
        'wantsSomethingDifferent': wantsSomethingDifferent,
      };

  @override
  List<Object?> get props => [garmentType, summary, wantsSomethingDifferent];
}

/// Step 2 — order-level style direction.
///
/// Deliberately order-scoped, never written back to the client's global
/// preferences. A person who generally loves senator cuts may want something
/// entirely different for one wedding; overwriting their global taste because
/// of a single request would be a bug.
class CheckoutStyle extends Equatable {
  final List<String> tags;
  final String? fitPreference;
  final String? referenceImageUrl;
  final String? notes;

  const CheckoutStyle({
    this.tags = const [],
    this.fitPreference,
    this.referenceImageUrl,
    this.notes,
  });

  bool get isEmpty =>
      tags.isEmpty &&
      fitPreference == null &&
      referenceImageUrl == null &&
      (notes == null || notes!.trim().isEmpty);

  CheckoutStyle copyWith({
    List<String>? tags,
    String? fitPreference,
    String? referenceImageUrl,
    String? notes,
  }) =>
      CheckoutStyle(
        tags: tags ?? this.tags,
        fitPreference: fitPreference ?? this.fitPreference,
        referenceImageUrl: referenceImageUrl ?? this.referenceImageUrl,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'tags': tags,
        'fitPreference': fitPreference,
        'referenceImageUrl': referenceImageUrl,
        'notes': notes,
      };

  @override
  List<Object?> get props =>
      [tags, fitPreference, referenceImageUrl, notes];
}

/// Step 3 — fabric. Links to the real catalogue when one matches, and falls
/// back to free text when it does not.
class CheckoutFabric extends Equatable {
  final String? fabricId;
  final String? name;
  final String? colour;

  /// Whether the client already owns their cloth, or the tailor must source it.
  ///
  /// Without this the flow could only ever charge material, so a client who
  /// already had their fabric was quoted for cloth they did not need — the
  /// tailor's `material_cost` was baked into every order whether or not it
  /// applied.
  final FabricOwnership ownership;

  const CheckoutFabric({
    this.fabricId,
    this.name,
    this.colour,
    this.ownership = FabricOwnership.undecided,
  });

  bool get isEmpty =>
      (name == null || name!.trim().isEmpty) && fabricId == null;

  /// True when material should be added to the quote.
  bool get materialApplies => ownership == FabricOwnership.tailorSourced;

  /// Explicit `clear*` flags are required because `x ?? this.x` cannot express
  /// "set this back to null".
  ///
  /// Without them the only way to deselect a chip was to rebuild a whole new
  /// [CheckoutFabric], and that silently dropped [ownership] — so choosing a
  /// material after answering the ownership question wiped the answer. The
  /// order the two questions were asked in decided whether the answer survived,
  /// which is exactly the kind of bug that looks like the app is broken.
  CheckoutFabric copyWith({
    String? fabricId,
    String? name,
    String? colour,
    FabricOwnership? ownership,
    bool clearFabricId = false,
    bool clearName = false,
    bool clearColour = false,
  }) =>
      CheckoutFabric(
        fabricId: clearFabricId ? null : (fabricId ?? this.fabricId),
        name: clearName ? null : (name ?? this.name),
        colour: clearColour ? null : (colour ?? this.colour),
        ownership: ownership ?? this.ownership,
      );

  Map<String, dynamic> toJson() => {
        'fabricId': fabricId,
        'name': name,
        'colour': colour,
        'clientSuppliesMaterial': ownership.asBool,
      };

  @override
  List<Object?> get props => [fabricId, name, colour, ownership];
}

/// Step 5 — fit.
class CheckoutMeasurements extends Equatable {
  final MeasurementSource source;
  final Map<String, double>? values;
  final String? scanId;

  const CheckoutMeasurements({
    this.source = MeasurementSource.none,
    this.values,
    this.scanId,
  });

  bool get hasData =>
      source != MeasurementSource.none &&
      values != null &&
      values!.isNotEmpty;

  int get fieldCount => values?.length ?? 0;

  CheckoutMeasurements copyWith({
    MeasurementSource? source,
    Map<String, double>? values,
    String? scanId,
  }) =>
      CheckoutMeasurements(
        source: source ?? this.source,
        values: values ?? this.values,
        scanId: scanId ?? this.scanId,
      );

  Map<String, dynamic> toJson() => {
        'source': source.name,
        'values': values,
        'scanId': scanId,
      };

  @override
  List<Object?> get props => [source, values, scanId];
}

/// The single source of truth for the whole journey.
///
/// The legacy flow spread this across three widgets as `setState` fields plus
/// an untyped `Map<String, dynamic>` passed between routes, which is why a
/// refresh lost everything. One object, one owner, persisted per step.
class CheckoutDraft extends Equatable {
  final String ownerId;
  final CheckoutTailor? tailor;

  /// Null when entering from a tailor profile with no design chosen.
  final CheckoutProduct? product;

  final CheckoutEntryMode entryMode;
  final CheckoutRequest request;
  final CheckoutStyle style;
  final CheckoutFabric fabric;

  /// Multi-select on purpose: a request can genuinely be for more than one
  /// occasion, and the data model does not require exactly one.
  final List<String> occasions;

  final CheckoutMeasurements measurements;
  final String? additionalNotes;

  /// Index of the furthest step ANSWERED, or -1 when nothing has been answered.
  ///
  /// -1 rather than 0 matters: a brand-new draft has answered nothing, and
  /// resuming it at step 2 would skip the one question the client has not been
  /// asked yet.
  final int furthestStep;

  final String? materialAssetUrl;

  /// Every reference image the client sent. [materialAssetUrl] stays as the
  /// primary/first one so `orders.material_asset_url` keeps working unchanged.
  final List<String> materialAssetUrls;

  /// Whether the client has shown the tailor at least one reference.
  bool get hasMaterialReference =>
      materialAssetUrls.isNotEmpty ||
      (materialAssetUrl?.trim().isNotEmpty ?? false);
  final String? deliveryAddress;
  final DateTime? dueDate;

  const CheckoutDraft({
    required this.ownerId,
    this.tailor,
    this.product,
    this.entryMode = CheckoutEntryMode.fromProfile,
    this.request = const CheckoutRequest(),
    this.style = const CheckoutStyle(),
    this.fabric = const CheckoutFabric(),
    this.occasions = const [],
    this.measurements = const CheckoutMeasurements(),
    this.additionalNotes,
    this.furthestStep = -1,
    this.acknowledgedSteps = const {},
    this.materialAssetUrl,
    this.materialAssetUrls = const [],
    this.deliveryAddress,
    this.dueDate,
  });

  CheckoutDraft copyWith({
    CheckoutTailor? tailor,
    CheckoutProduct? product,
    CheckoutEntryMode? entryMode,
    CheckoutRequest? request,
    CheckoutStyle? style,
    CheckoutFabric? fabric,
    List<String>? occasions,
    CheckoutMeasurements? measurements,
    String? additionalNotes,
    int? furthestStep,
    Set<CheckoutStep>? acknowledgedSteps,
    String? materialAssetUrl,
    List<String>? materialAssetUrls,
    bool clearMaterialAssetUrl = false,
    String? deliveryAddress,
    DateTime? dueDate,
  }) =>
      CheckoutDraft(
        ownerId: ownerId,
        tailor: tailor ?? this.tailor,
        product: product ?? this.product,
        entryMode: entryMode ?? this.entryMode,
        request: request ?? this.request,
        style: style ?? this.style,
        fabric: fabric ?? this.fabric,
        occasions: occasions ?? this.occasions,
        measurements: measurements ?? this.measurements,
        additionalNotes: additionalNotes ?? this.additionalNotes,
        furthestStep: furthestStep ?? this.furthestStep,
        acknowledgedSteps: acknowledgedSteps ?? this.acknowledgedSteps,
        // `?? this.x` means passing null can never clear a field, so removing the
      // last reference image left the primary pointing at a deleted photo.
      materialAssetUrl: clearMaterialAssetUrl
          ? null
          : materialAssetUrl ?? this.materialAssetUrl,
      materialAssetUrls: materialAssetUrls ?? this.materialAssetUrls,
        deliveryAddress: deliveryAddress ?? this.deliveryAddress,
        dueDate: dueDate ?? this.dueDate,
      );

  /// A step is only complete if it has what it needs. Used to gate Continue
  /// and to decide where the review's Edit links should go.
  /// Whether this step carries an actual answer. Steps 2-5 are optional by
  /// design — an absent answer is a legitimate reply, not an incomplete step —
  /// so this asks "did they say anything", never "is it valid".
  bool _hasAnswerFor(CheckoutStep step) => switch (step) {
        CheckoutStep.defineRequest =>
          !entryMode.needsGarmentDefinition ||
              (request.garmentType?.trim().isNotEmpty ?? false) ||
              (request.summary?.trim().isNotEmpty ?? false),
        CheckoutStep.styleDirection =>
          style.tags.isNotEmpty ||
              style.fitPreference != null ||
              (style.referenceImageUrl?.trim().isNotEmpty ?? false) ||
              (style.notes?.trim().isNotEmpty ?? false),
        CheckoutStep.fabric =>
          (fabric.fabricId?.trim().isNotEmpty ?? false) ||
              (fabric.name?.trim().isNotEmpty ?? false) ||
              (fabric.colour?.trim().isNotEmpty ?? false) ||
              hasMaterialReference,
        CheckoutStep.occasion => occasions.isNotEmpty,
        CheckoutStep.measurements =>
          measurements.source != MeasurementSource.none ||
              (measurements.values?.isNotEmpty ?? false) ||
              (measurements.scanId?.trim().isNotEmpty ?? false),
        // Review is not "answered" in the data sense — its work is simply not
        // done until it is reached. Treating it as complete from the moment the
        // blocking answers existed is what made a client on Fit read 5/6.
        CheckoutStep.review => false,
      };

  bool isStepComplete(CheckoutStep step) => switch (step) {
        // From a profile there is nothing to confirm, so the tailor *is* the
        // answer. From a product the design is already chosen.
        CheckoutStep.defineRequest =>
          entryMode.needsGarmentDefinition
              ? (request.garmentType?.trim().isNotEmpty ?? false)
              : true,
        // Style direction is genuinely optional: the tailor can advise.
        CheckoutStep.styleDirection => true,
        // So is fabric — "you choose" is a legitimate answer.
        CheckoutStep.fabric => true,
        // Optional too, but strongly recommended, so not blocking.
        CheckoutStep.occasion => true,
        // Fit is the one thing worth pushing for, but a tailor can take
        // measurements at fitting, so it must not hard-block the journey.
        CheckoutStep.measurements => true,
        CheckoutStep.review => true,
      };

  /// Steps that genuinely cannot be skipped.
  List<CheckoutStep> get blockingSteps => [
        CheckoutStep.defineRequest,
        // A request with no picture of the cloth is the single biggest source
        // of "this is not what I asked for", so at least one reference is
        // required before the client may move on.
        CheckoutStep.fabric,
      ];

  /// Whether Continue should be enabled on [step].
  ///
  /// Blocking steps answer from their data; everything else stays optional and
  /// is answered by moving on.
  bool canContinueFrom(CheckoutStep step) =>
      blockingSteps.contains(step) ? _hasAnswerFor(step) : isStepComplete(step);

  CheckoutStep? get nextStep {
    final next = CheckoutStep.fromIndex(furthestStep + 1);
    return next;
  }

  /// Steps whose required information is actually present.
  ///
  /// This is what unlocks the next step. Deriving it from the draft — not from
  /// "the user clicked continue" — is the difference between a real workflow
  /// and a card that merely looks finished.
  Set<CheckoutStep> get completedSteps {
    final done = <CheckoutStep>{};

    // Progression is sequential, so every step up to the furthest answered one
    // has, by definition, been answered. This is the signal that actually
    // persists: `furthestStep` is a column on order_drafts, whereas
    // [acknowledgedSteps] lives only in memory and is lost on every save.
    //
    // Deriving completion from acknowledgedSteps alone meant a client who had
    // filled steps 1-4 still showed only step 1 complete — the tracker read 17%
    // and four finished steps carried no checkmark.
    for (final step in CheckoutStep.values) {
      if (step.position <= furthestStep) done.add(step);
    }

    // ── The authoritative signal: the answer is in the data ────────────────
    // furthestStep alone lies whenever a client reaches review another way
    // (resumed draft, deep link, back-button, a second device). The result was
    // a populated Style/Fabric rendered in Review while the tracker insisted
    // those steps were unanswered: 17%, no checkmarks, and — because
    // isReadyToSubmit demands every step — no way to send the request at all.
    // Their answers were on screen and unusable.
    for (final step in CheckoutStep.values) {
      if (_hasAnswerFor(step)) done.add(step);
    }

    // Steps 2-5 have no required fields by design — a client with no fabric, no
    // reference image and no scan can still reach review. Treat them as answered
    // once progressed past, so the tracker reflects the journey rather than
    // demanding data we deliberately never require.
    for (final step in [
      CheckoutStep.styleDirection,
      CheckoutStep.fabric,
      CheckoutStep.occasion,
      CheckoutStep.measurements,
    ]) {
      if (acknowledgedSteps.contains(step) || step.position < furthestStep) {
        done.add(step);
      }
    }

    // Review is the milestone: complete once every other step is.
    if (CheckoutStep.values
        .where((s) => s != CheckoutStep.review)
        .every((s) => done.contains(s))) {
      done.add(CheckoutStep.review);
    }
    return done;
  }

  /// Steps the client has explicitly continued past. Steps 2-5 are optional, so
  /// "visited and moved on" is the honest completion signal for them.
  final Set<CheckoutStep> acknowledgedSteps;

  /// True when there is enough here to actually submit a request.
  /// Whether the answers that genuinely block are present.
  ///
  /// Optional steps are answered by omission, so requiring all of them to be
  /// complete meant a client could read their entire request back off the review
  /// screen and still have no send button. Only [blockingSteps] can hold it.
  bool get isBlockingComplete => blockingSteps.every(_hasAnswerFor);

  bool get isSubmittable {
    if (tailor == null) return false;
    if (entryMode.needsGarmentDefinition &&
        (request.garmentType?.trim().isEmpty ?? true)) {
      return false;
    }
    return true;
  }

  /// Everything the tailor needs to act, in one flat map. This is what gets
  /// written to `orders.items[0]` and `orders.metadata` at submission.
  Map<String, dynamic> toSubmissionMap() => {
        'request_summary': request.summary,
        'garment_type': request.garmentType,
        'entry_mode': entryMode.storageValue,
        'wants_something_different': request.wantsSomethingDifferent,
        'design_id': product?.designId,
        'product_id': product?.productId,
        'selected_size': product?.selectedSize,
        'selected_colour': product?.selectedColour,
        'quantity': product?.quantity ?? 1,
        'style_tags': style.tags,
        'fit_preference': style.fitPreference,
        'reference_image_url': style.referenceImageUrl,
        'style_notes': style.notes,
        'fabric_id': fabric.fabricId,
        'fabric_name': fabric.name,
        'fabric_colour': fabric.colour,
        // Whether the client already owns their cloth. The tailor reads this
        // when quoting: if TRUE their material cost is excluded, if FALSE it
        // applies. Recorded on every request so a quote can never silently add
        // fabric the client said they already had.
        'client_supplies_material': fabric.ownership.asBool,
        'fabric_ownership': switch (fabric.ownership) {
          FabricOwnership.undecided => 'undecided',
          FabricOwnership.clientSupplied => 'clientSupplied',
          FabricOwnership.tailorSourced => 'tailorSourced',
        },
        'occasions': occasions,
        'measurement_source': measurements.source.storageValue,
        'measurement_scan_id': measurements.scanId,
        'additional_notes': additionalNotes,
      };

  @override
  List<Object?> get props => [
        ownerId,
        tailor,
        product,
        entryMode,
        request,
        style,
        fabric,
        occasions,
        measurements,
        additionalNotes,
        furthestStep,
        acknowledgedSteps,
        materialAssetUrl,
    materialAssetUrls,
        deliveryAddress,
        dueDate,
      ];
}