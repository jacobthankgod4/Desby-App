import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/checkout_draft.dart';

/// The storage contract for a draft.
///
/// Extracted so the journey's logic can be tested without a network: the
/// critical behaviour is "a failed save never discards what the client typed",
/// which is only provable against a repository that can fail on demand.
abstract class CheckoutDraftRepositoryContract {
  /// The draft for this exact target, or null when there isn't one.
  Future<Result<CheckoutDraft?>> loadFor(CheckoutDraft probe);

  /// The most recent in-progress request, for resuming.
  Future<Result<CheckoutDraft?>> loadMostRecent(String ownerId);

  Future<Result<CheckoutDraft>> save(CheckoutDraft draft);

  Future<Result<void>> discard(CheckoutDraft draft);
}

/// Persists a [CheckoutDraft] so a refresh, a deep link or a crash does not lose
/// the request. One live draft per (owner, tailor|design|product) — starting a
/// second request to the same tailor updates the existing row instead of
/// littering the table.
class CheckoutDraftRepository implements CheckoutDraftRepositoryContract {
  CheckoutDraftRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Generated column; the ON CONFLICT arbiter for the unique index.
  static const _conflictTarget = 'requesting_user_id,target_key';

  static const _columns = [
    'id',
    'requesting_user_id',
    'tailor_id',
    'design_id',
    'product_id',
    'tailor_name',
    'tailor_avatar_url',
    'product_title',
    'product_image_urls',
    'product_category',
    'product_price',
    'garment_type',
    'request_summary',
    'entry_mode',
    'style_tags',
    'fit_preference',
    'reference_image_url',
    'style_notes',
    'fabric_id',
    'fabric_name',
    'fabric_colour',
    'occasions',
    'measurement_source',
    'measurement_scan_id',
    'measurements',
    'additional_notes',
    'material_asset_url',
    'delivery_address',
    'due_date',
    'request_step',
    'updated_at',
  ];

  @override
  Future<Result<CheckoutDraft?>> loadFor(CheckoutDraft probe) async {
    try {
      var query = _supabase
          .from('order_drafts')
          .select(_columns.join(','))
          .eq('requesting_user_id', probe.ownerId);

      // A null id means "this draft has no such link", which must be matched as
      // SQL NULL. `eq(col, null)` is not the same thing — and in postgrest 2.9.1
      // eq() takes a non-nullable Object, so passing null would not compile and
      // dropping the filter would return somebody else's draft. `not(col,'is',
      // null)` is the supported way to express IS NULL.
      query = probe.tailor == null
          ? query.not('tailor_id', 'is', null)
          : query.eq('tailor_id', probe.tailor!.id);
      query = probe.product?.designId == null
          ? query.not('design_id', 'is', null)
          : query.eq('design_id', probe.product!.designId!);
      query = probe.product?.productId == null
          ? query.not('product_id', 'is', null)
          : query.eq('product_id', probe.product!.productId!);

      final rows = await query.limit(1);
      if (rows.isEmpty) return const Success(null);
      return Success(_fromRow(rows.first));
    } catch (e) {
      return Failure(AuthFailure(message: 'Could not load your draft: $e'));
    }
  }

  @override
  Future<Result<CheckoutDraft?>> loadMostRecent(String ownerId) async {
    try {
      final rows = await _supabase
          .from('order_drafts')
          .select(_columns.join(','))
          .eq('requesting_user_id', ownerId)
          .order('updated_at', ascending: false)
          .limit(1);
      if (rows.isEmpty) return const Success(null);
      return Success(_fromRow(rows.first));
    } catch (e) {
      return Failure(AuthFailure(message: 'Could not load your draft: $e'));
    }
  }

  @override
  Future<Result<CheckoutDraft>> save(CheckoutDraft draft) async {
    try {
      final rows = await _supabase
          .from('order_drafts')
          .upsert(_toRow(draft), onConflict: _conflictTarget)
          .select(_columns.join(','))
          .limit(1);
      if (rows.isEmpty) {
        return const Failure(
          AuthFailure(message: 'Your draft was not saved. Please try again.'),
        );
      }
      return Success(_fromRow(rows.first));
    } on PostgrestException catch (e) {
      return Failure(
        AuthFailure(message: 'Could not save your draft (${e.code}): ${e.message}'),
      );
    } catch (e) {
      return Failure(AuthFailure(message: 'Could not save your draft: $e'));
    }
  }

  @override
  Future<Result<void>> discard(CheckoutDraft draft) async {
    try {
      await _supabase
          .from('order_drafts')
          .delete()
          .eq('requesting_user_id', draft.ownerId);
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailure(message: 'Could not discard your draft: $e'));
    }
  }

  Map<String, dynamic> _toRow(CheckoutDraft d) => {
        'requesting_user_id': d.ownerId,
        'tailor_id': d.tailor?.id,
        'design_id': d.product?.designId,
        'product_id': d.product?.productId,
        'tailor_name': d.tailor?.name,
        'tailor_avatar_url': d.tailor?.avatarUrl,
        'product_title': d.product?.title,
        'product_image_urls': d.product?.imageUrls ?? const <String>[],
        'product_category': d.product?.category,
        'product_price': d.product?.price,
        'garment_type': d.request.garmentType,
        'request_summary': d.request.summary,
        'entry_mode': d.entryMode.storageValue,
        'style_tags': d.style.tags,
        'fit_preference': d.style.fitPreference,
        'reference_image_url': d.style.referenceImageUrl,
        'style_notes': d.style.notes,
        'fabric_id': d.fabric.fabricId,
        'fabric_name': d.fabric.name,
        'fabric_colour': d.fabric.colour,
        'occasions': d.occasions,
        'measurement_source': d.measurements.source.storageValue,
        'measurement_scan_id': d.measurements.scanId,
        'measurements': d.measurements.values,
        'additional_notes': d.additionalNotes,
        'material_asset_url': d.materialAssetUrl,
        'material_asset_urls': d.materialAssetUrls,
        'delivery_address': d.deliveryAddress,
        'due_date': d.dueDate?.toIso8601String(),
        'request_step': d.furthestStep,
      };

  CheckoutDraft _fromRow(Map<String, dynamic> row) {
    final owner = row['requesting_user_id'] as String;
    final tailorId = row['tailor_id'] as String?;
    final designId = row['design_id'] as String?;
    final productId = row['product_id'] as String?;
    final name = row['tailor_name'] as String?;
    final avatar = row['tailor_avatar_url'] as String?;

    final images = row['product_image_urls'];
    final measurements = row['measurements'];

    return CheckoutDraft(
      ownerId: owner,
      tailor: tailorId == null
          ? null
          : CheckoutTailor(id: tailorId, name: name, avatarUrl: avatar),
      product: (designId == null && productId == null)
          ? null
          : CheckoutProduct(
              designId: designId,
              productId: productId,
              title: row['product_title'] as String?,
              category: row['product_category'] as String?,
              imageUrls: images is List
                  ? images.map((e) => e.toString()).toList()
                  : const [],
              price: (row['product_price'] as num?)?.toDouble(),
            ),
      entryMode: CheckoutEntryMode.fromName(row['entry_mode'] as String?) ??
          CheckoutEntryMode.fromProfile,
      request: CheckoutRequest(
        garmentType: row['garment_type'] as String?,
        summary: row['request_summary'] as String?,
        wantsSomethingDifferent:
            (row['entry_mode'] ==
                CheckoutEntryMode.customDesign.storageValue),
      ),
      style: CheckoutStyle(
        tags: _stringList(row['style_tags']),
        fitPreference: row['fit_preference'] as String?,
        referenceImageUrl: row['reference_image_url'] as String?,
        notes: row['style_notes'] as String?,
      ),
      fabric: CheckoutFabric(
        fabricId: row['fabric_id'] as String?,
        name: row['fabric_name'] as String?,
        colour: row['fabric_colour'] as String?,
      ),
      occasions: _stringList(row['occasions']),
      measurements: CheckoutMeasurements(
        source: MeasurementSource.fromName(row['measurement_source'] as String?) ??
            MeasurementSource.none,
        values: measurements is Map
            ? measurements.map((k, v) => MapEntry(
                  k.toString(),
                  v is num ? v.toDouble() : double.tryParse('$v') ?? 0,
                ))
            : null,
        scanId: row['measurement_scan_id'] as String?,
      ),
      additionalNotes: row['additional_notes'] as String?,
      furthestStep: (row['request_step'] as num?)?.toInt() ?? -1,
      materialAssetUrl: row['material_asset_url'] as String?,
      materialAssetUrls: _stringList(row['material_asset_urls']),
      deliveryAddress: row['delivery_address'] as String?,
      dueDate: row['due_date'] == null
          ? null
          : DateTime.tryParse(row['due_date'].toString()),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList();
  }
}

/// Small helper so callers can log or diff a draft without importing json.
String describeDraft(CheckoutDraft draft) =>
    const JsonEncoder.withIndent('  ').convert(draft.toSubmissionMap());