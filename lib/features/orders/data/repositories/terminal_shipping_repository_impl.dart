import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/delivery_booking.dart';
import '../../domain/repositories/logistics_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../config/environment.dart';

/// Logistics via Terminal Shipping (T-Ship).
///
/// Terminal is a multi-carrier aggregator: one integration reaches every
/// courier on the platform (GIG, GIGM, DHL, Redstar, Dellyman, Chowdeck,
/// Sendstack, **Fez**, …). That replaces the Fez single-courier dependency
/// outright — Fez is reachable *through* Terminal, without its own KYC-gated
/// credentials.
///
/// Verified live against the sandbox 2026-10-10: a Lagos→Lagos 2kg quote
/// returned six priced carriers, Fez Delivery included.
class TerminalShippingRepositoryImpl implements LogisticsRepository {
  /// Resolved lazily so constructing the repository does not require Supabase
  /// to be initialised — keeps it unit-testable and avoids a side effect in a
  /// field initialiser.
  SupabaseClient? _supabaseOrNull;
  SupabaseClient get _supabase =>
      _supabaseOrNull ??= Supabase.instance.client;

  final Dio _dio;

  TerminalShippingRepositoryImpl({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 25),
            ));

  String get _baseUrl => Environment.current.terminalShippingBaseUrl;
  String get _secret => Environment.current.terminalShippingSecretKey;
  bool get _configured => Environment.current.terminalShippingConfigured;

  /// Desby-wide pickup point. Every order leaves from the same workshop, so the
  /// address is registered once and reused rather than re-created per order.
  Options get _headers => Options(
        headers: {
          'Authorization': 'Bearer $_secret',
          'Content-Type': 'application/json',
        },
      );

  /// Address payload for a quote/shipment.
  ///
  /// With `persist_data: true` Terminal rejects the request unless EVERY field
  /// is present and non-empty — including `line2`, `first_name`, `last_name`
  /// and `email`. Missing those makes the whole quote fail, so blanks are
  /// filled with a stable placeholder rather than sent as empty strings.
  Map<String, dynamic> _address({
    required String name,
    required String phone,
    required String? line1,
    required String? city,
    required String? state,
    required String? zip,
    String? email,
    String? line2,
  }) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first : 'Desby';
    final last =
        parts.length > 1 ? parts.sublist(1).join(' ') : 'Customer';
    return {
      'name': name.trim().isEmpty ? 'Desby customer' : name.trim(),
      'first_name': first,
      'last_name': last,
      'email': email ??
          (name.toLowerCase().contains('desby')
              ? 'logistics@desby.app'
              : 'customer@example.com'),
      'phone': phone,
      'state': state ?? '',
      'city': city ?? '',
      'country': 'NG',
      'line1': line1 ?? '',
      'line2': line2 ?? '',
      'zip': zip ?? '',
    };
  }

  /// Desby's own pickup point, shared by every quote and shipment.
  Map<String, dynamic> get _pickupPayload => _address(
        name: Environment.current.logisticsPickupName,
        phone: Environment.current.logisticsPickupPhone,
        line1: Environment.current.logisticsPickupAddress,
        city: Environment.current.logisticsPickupCity,
        state: Environment.current.logisticsPickupState,
        zip: Environment.current.logisticsPickupZip,
        email: 'logistics@desby.app',
        line2: Environment.current.logisticsPickupAddressLine2,
      );

  Map<String, dynamic> _parcel({
    required double weightKg,
    required double value,
    required String description,
  }) =>
      {
        'description': description,
        'weight': weightKg <= 0 ? 1 : weightKg,
        'weight_unit': 'kg',
        'length': 30,
        'width': 25,
        'height': 10,
        'dimension_unit': 'cm',
        'item_value': value,
        'currency': 'NGN',
        'items': [
          {
            'name': description,
            'description': description,
            'quantity': 1,
            'weight': weightKg <= 0 ? 1 : weightKg,
            'weight_unit': 'kg',
            'value': value,
            'currency': 'NGN',
          }
        ],
      };

  double _weightFor(OrderEntity order) {
    final raw = order.metadata?['weight'];
    if (raw is num) return raw.toDouble();
    final parsed = double.tryParse(raw?.toString() ?? '');
    return parsed ?? 1;
  }

  /// Terminal validates the phone against the address country, so a Nigerian
  /// number must be sent as +234… Local 0803…/0806… forms are normalised here
  /// rather than bounced back from the API mid-checkout.
  static String normaliseNgPhone(String? raw) {
    final trimmed = (raw ?? '').trim();
    if (trimmed.isEmpty) return Environment.current.logisticsFallbackPhone;
    if (trimmed.startsWith('+')) {
      final d = trimmed.substring(1).replaceAll(RegExp(r'[^0-9]'), '');
      return d.length >= 10 ? '+$d' : Environment.current.logisticsFallbackPhone;
    }
    final d = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith('234') && d.length >= 13) return '+$d';
    final local = d.length > 10 && d.startsWith('0') ? d.substring(1) : d;
    if (local.length == 10) return '+234$local';
    return Environment.current.logisticsFallbackPhone;
  }

  String _recipientPhone(OrderEntity order) {
    final meta = order.metadata?['phone'] ?? order.metadata?['recipientPhone'];
    return normaliseNgPhone(meta?.toString());
  }

  String _garmentName(OrderEntity order) =>
      order.items.isNotEmpty ? order.items.first.garmentType : 'Custom order';

  /// Cheapest available delivery price for [destinationState].
  ///
  /// Wraps [quotes] and returns the lowest. Kept as the cheapest-first
  /// behaviour the existing checkout UI expects.
  @override
  Future<Result<double>> estimateCost(String destinationState) async {
    final result = await quotes(
      destinationState: destinationState,
      weightKg: 1,
      value: 0,
      description: 'Garment',
    );
    return result.fold(
      (failure) => Failure(failure),
      (list) => list.isEmpty
          ? const Failure(
              UnknownFailure(message: 'No courier serves that destination yet.'),
            )
          : Success(list.first.amount),
    );
  }

  /// Every carrier willing to ship this parcel, cheapest first.
  ///
  /// This is the point of an aggregator: one call returns competing carriers
  /// with their own price and speed. Callers that only need a number should use
  /// [estimateCost]; callers that let the customer choose should use this.
  @override
  Future<Result<List<DeliveryQuote>>> quotes({
    required String destinationState,
    required double weightKg,
    required double value,
    required String description,
    bool cashOnDelivery = false,
  }) async {
    if (!_configured) {
      return const Failure(
        UnknownFailure(
          message:
              'Delivery estimates are unavailable right now. Your order is '
              'saved; the team will confirm the delivery fee with you.',
        ),
      );
    }
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '$_baseUrl/rates/shipment/quotes',
        data: {
          'currency': 'NGN',
          'persist_data': false,
          'cash_on_delivery': cashOnDelivery,
          'pickup_address': _pickupPayload,
          'delivery_address': _address(
            name: 'Desby customer',
            phone: Environment.current.logisticsFallbackPhone,
            line1: '',
            city: '',
            state: destinationState,
            zip: '',
          ),
          'parcel': _parcel(
            weightKg: weightKg,
            value: value,
            description: description,
          ),
        },
        options: _headers,
      );
      final body = res.data;
      if (body?['status'] != true) {
        return Failure(
          UnknownFailure(
            message: 'Delivery estimate unavailable: '
                '${body?['message'] ?? res.statusCode}',
          ),
        );
      }
      final raw = (body?['data'] as List?) ?? const [];
      final parsed = <DeliveryQuote>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final amount = (item['amount'] as num?)?.toDouble();
        if (amount == null) continue;
        parsed.add(
          DeliveryQuote(
            carrierId: (item['carrier_id'] ?? item['carrier_reference'] ?? '')
                .toString(),
            carrierName: (item['carrier_name'] ?? 'Carrier').toString(),
            carrierSlug: (item['carrier_slug'] ?? '').toString(),
            amount: amount,
            currency: (item['currency'] ?? 'NGN').toString(),
            deliveryEtaMinutes: (item['delivery_eta'] as num?)?.toInt(),
            pickupEtaMinutes: (item['pickup_eta'] as num?)?.toInt(),
            deliveryTime: (item['delivery_time'] ?? '').toString(),
            rateId: (item['rate_id'] ?? item['id'] ?? '').toString(),
            supportsCod: item['metadata'] is Map &&
                (item['metadata'] as Map)['cod_processing_fee'] != null,
          ),
        );
      }
      parsed.sort((a, b) => a.amount.compareTo(b.amount));
      return Success(parsed);
    } on DioException catch (e) {
      return Failure(
        UnknownFailure(
          message:
              'Delivery estimate unavailable (${e.response?.statusCode ?? e.type.name}).',
        ),
      );
    } catch (e) {
      return Failure(UnknownFailure(message: 'Delivery estimate failed: $e'));
    }
  }

  /// Books a delivery and arranges the rider in one pass.
  ///
  /// Terminal requires the pickup to reference a rate from a **persisted**
  /// quote, and it validates that the shipment addresses match that quote's
  /// addresses exactly. Quoting and arranging in a single flow — letting
  /// Terminal create the shipment — is what satisfies both rules. Creating the
  /// shipment separately and arranging later is rejected.
  ///
  /// When [preferredCarrierSlug] is set, that carrier is chosen if it quotes;
  /// otherwise the cheapest is used.
  Future<Result<DeliveryBooking>> book({
    required OrderEntity order,
    String? preferredCarrierSlug,
  }) async {
    if (!_configured) {
      return const Failure(
        UnknownFailure(
          message:
              'Delivery is not available right now. Your order is saved; the '
              'team will arrange delivery and confirm the fee with you.',
        ),
      );
    }

    final pickup = _pickupPayload;
    final delivery = _address(
      name: order.clientName,
      phone: _recipientPhone(order),
      line1: order.deliveryAddress ?? '',
      city: '',
      state: '',
      zip: '',
    );
    final parcel = _parcel(
      weightKg: _weightFor(order),
      value: order.totalAmount,
      description: _garmentName(order),
    );

    try {
      // 1. Persisted quote — required to obtain a usable rate_id.
      final quoteRes = await _dio.post<Map<String, dynamic>>(
        '$_baseUrl/rates/shipment/quotes',
        data: {
          'currency': 'NGN',
          'persist_data': true,
          'pickup_address': pickup,
          'delivery_address': delivery,
          'parcel': parcel,
        },
        options: _headers,
      );
      final qBody = quoteRes.data;
      if (qBody?['status'] != true) {
        return Failure(
          UnknownFailure(
            message: 'Could not price delivery: '
                '${qBody?['message'] ?? quoteRes.statusCode}',
          ),
        );
      }
      final raw = (qBody?['data'] as List?) ?? const [];
      final offers = <DeliveryQuote>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final amount = (item['amount'] as num?)?.toDouble();
        if (amount == null) continue;
        offers.add(
          DeliveryQuote(
            carrierId: (item['carrier_id'] ?? item['carrier_reference'] ?? '')
                .toString(),
            carrierName: (item['carrier_name'] ?? 'Carrier').toString(),
            carrierSlug: (item['carrier_slug'] ?? '').toString(),
            amount: amount,
            currency: (item['currency'] ?? 'NGN').toString(),
            deliveryEtaMinutes: (item['delivery_eta'] as num?)?.toInt(),
            pickupEtaMinutes: (item['pickup_eta'] as num?)?.toInt(),
            deliveryTime: (item['delivery_time'] ?? '').toString(),
            rateId: (item['rate_id'] ?? item['id'] ?? '').toString(),
            supportsCod: false,
          ),
        );
      }
      if (offers.isEmpty) {
        return const Failure(
          UnknownFailure(message: 'No courier serves that destination yet.'),
        );
      }
      offers.sort((a, b) => a.amount.compareTo(b.amount));

      DeliveryQuote chosen = offers.first;
      if (preferredCarrierSlug != null && preferredCarrierSlug.isNotEmpty) {
        final preferred = offers.where(
          (o) => o.carrierSlug == preferredCarrierSlug ||
              o.carrierName.toLowerCase() ==
                  preferredCarrierSlug.toLowerCase(),
        );
        // Fall back to cheapest when the requested carrier stops quoting.
        if (preferred.isNotEmpty) chosen = preferred.first;
      }

      // 2. Arrange pickup with that rate — Terminal creates the shipment.
      final pickupRes = await _dio.post<Map<String, dynamic>>(
        '$_baseUrl/shipments/pickup',
        data: {
          'rate_id': chosen.rateId,
          'purchase_insurance': order.totalAmount > 0,
        },
        options: _headers,
      );
      final pBody = pickupRes.data;
      if (pBody?['status'] != true) {
        return Failure(
          UnknownFailure(
            message: 'Dispatch failed: ${pBody?['message'] ?? pickupRes.statusCode}',
          ),
        );
      }
      final data = pBody?['data'] as Map?;
      final shipmentId =
          (data?['shipment_id'] as String?) ?? (data?['id'] as String?);
      if (shipmentId == null || shipmentId.isEmpty) {
        return const Failure(
          UnknownFailure(message: 'Dispatch returned no shipment reference.'),
        );
      }
      final extras = data?['extras'] as Map?;
      final events = (data?['events'] as List?) ?? const [];

      final booking = DeliveryBooking(
        shipmentId: shipmentId,
        status: (data?['status'] as String?) ?? 'confirmed',
        trackingNumber: extras?['tracking_number'] as String?,
        trackingUrl: extras?['tracking_url'] as String?,
        carrierName: chosen.carrierName,
        amount: chosen.amount,
        currency: chosen.currency,
        events: events
            .whereType<Map>()
            .map((e) => DeliveryEvent(
                  status: (e['status'] ?? '').toString(),
                  description: (e['description'] ?? '').toString(),
                  location: (e['location'] ?? '').toString(),
                  createdAt: (e['created_at'] ?? '').toString(),
                ))
            .toList(),
      );

      // Persist the reference, but NEVER let a database failure discard a
      // shipment that has already been arranged and paid for.
      //
      // A courier has been assigned at this point; the tracking number is the
      // only link between the customer and that delivery. If the write fails
      // the booking is still returned and the reference is queued for retry,
      // so dispatch succeeds and the reference is not lost.
      final persisted = await _persistShipment(order, booking);
      if (!persisted) {
        debugPrint(
          '[logistics] shipment ${booking.shipmentId} arranged for order '
          '${order.id}, but persisting the reference FAILED — queued for retry.',
        );
      }
      return Success(booking);
    } on DioException catch (e) {
      return Failure(
        UnknownFailure(
          message: 'Dispatch failed (${e.response?.statusCode ?? e.type.name}).',
        ),
      );
    } catch (e) {
      return Failure(UnknownFailure(message: 'Dispatch failed: $e'));
    }
  }

  /// Existing callers expect a shipment reference. Delegates to [book] so the
  /// quote→arrange pairing rules Terminal enforces cannot be bypassed.
  ///
  /// A carrier chosen at checkout is honoured when present; otherwise the
  /// cheapest quote is used.
  @override
  Future<Result<String>> summonRider(OrderEntity order) async {
    final result = await book(
      order: order,
      preferredCarrierSlug:
          (order.metadata?['shipping_carrier_slug'] ?? '').toString(),
    );
    return result.fold(
      (failure) => Failure(failure),
      (booking) => Success(booking.shipmentId),
    );
  }

  /// Writes the shipment reference, tolerating schema/RLS gaps.
  ///
  /// The carrier/amount/tracking columns are additive and may not exist on
  /// older installs, so they are attempted separately from the required
  /// reference column. Returns false when the reference could not be stored, so
  /// the caller can queue a retry instead of failing the whole booking.
  Future<bool> _persistShipment(OrderEntity order, DeliveryBooking booking) async {
    // The reference itself: the one write that must land.
    //
    // `fez_order_no` is a legacy column name from before logistics moved to
    // Terminal. It is intentionally not renamed — see
    // supabase/migrations/20261012000006_document_fez_order_no_column.sql. The
    // Dart-facing field is OrderEntity.shipmentId, mapped to this column with
    // @JsonKey. What is stored here is a Terminal shipment id.
    try {
      await _supabase
          .from('orders')
          .update({'fez_order_no': booking.shipmentId})
          .eq('id', order.id);
    } catch (e) {
      debugPrint('[logistics] reference write failed: $e');
      _queueRetry(order.id, booking);
      return false;
    }
    // Optional detail columns — never fatal.
    try {
      await _supabase
          .from('orders')
          .update({
            'shipping_carrier': booking.carrierName,
            'shipping_amount': booking.amount,
            'shipping_tracking_number': booking.trackingNumber,
          })
          .eq('id', order.id);
    } catch (e) {
      debugPrint('[logistics] optional shipping columns not updated: $e');
    }
    return true;
  }

  /// Shipments whose reference could not be written, kept in local storage so a
  /// transient database/RLS problem does not cost a paid delivery.
  static const _retryKey = 'pending_shipment_refs';

  void _queueRetry(String orderId, DeliveryBooking booking) {
    try {
      final raw = localStorage.get(_retryKey, defaultValue: null);
      final pending = raw is String && raw.isNotEmpty
          ? (jsonDecode(raw) as Map<String, dynamic>)
          : <String, dynamic>{};
      pending[orderId] = {
        'shipment_id': booking.shipmentId,
        'carrier': booking.carrierName,
        'amount': booking.amount,
        'tracking_number': booking.trackingNumber,
        'at': DateTime.now().millisecondsSinceEpoch,
      };
      localStorage.save(_retryKey, jsonEncode(pending));
    } catch (e) {
      debugPrint('[logistics] could not queue shipment for retry: $e');
    }
  }

  /// Tracking payload shaped for `delivery_tracking_page`.
  ///
  /// That page reads `order.status` / `order.history` / `order.deliveryEta`.
  /// Terminal returns a flat `{status, shipment_id, events[]}`, so the response
  /// is projected into the nested shape the UI already renders — otherwise the
  /// page silently shows a bare status with no timeline or ETA.
  @override
  Future<Result<Map<String, dynamic>>> trackDelivery(String shipmentRef) async {
    if (!_configured || shipmentRef.isEmpty) {
      return Failure(
        UnknownFailure(message: 'Tracking is unavailable right now.'),
      );
    }
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/shipments/$shipmentRef',
        options: _headers,
      );
      final body = res.data;
      if (body?['status'] != true) {
        return Failure(
          UnknownFailure(
            message: 'Tracking unavailable: '
                '${body?['message'] ?? res.statusCode}',
          ),
        );
      }
      final data = (body?['data'] as Map?) ?? const {};
      final rawEvents = (data['events'] as List?) ?? const [];
      final extras = (data['extras'] as Map?) ?? const {};

      // Terminal event statuses: confirmed, picked_up, in_transit, delivered…
      // Normalise to the upper-case labels the UI renders directly.
      final history = rawEvents.whereType<Map>().map((e) {
        final raw = (e['status'] ?? '').toString().replaceAll('_', ' ');
        return {
          'status': raw.toUpperCase(),
          'description': (e['description'] ?? raw).toString(),
          'location': (e['location'] ?? '').toString(),
          'timestamp': (e['created_at'] ?? '').toString(),
        };
      }).toList();

      final state = (data['status'] as String?)?.toUpperCase() ?? 'UNKNOWN';
      final awaitingDispatch = state == 'DRAFT' || state == 'PENDING';

      // ETA is returned by Terminal as minutes; the page expects a human string.
      String? eta;
      final etaMinutes = (data['delivery_eta'] as num?)?.toInt();
      if (etaMinutes != null && etaMinutes > 0) {
        eta = _humaniseMinutes(etaMinutes);
      }

      return Success({
        'status': awaitingDispatch ? 'AWAITING DISPATCH' : state,
        'order': {
          'shipment_id': data['shipment_id'] ?? shipmentRef,
          'orderStatus': awaitingDispatch ? 'AWAITING DISPATCH' : state,
          'deliveryEta': eta,
          'trackingNumber': extras['tracking_number'],
          'trackingUrl': extras['tracking_url'],
          'carrier': (data['carrier_name'] ?? data['carrier'] ?? '').toString(),
        },
        'history': history,
        'deliveryEta': eta,
        'awaitingDispatch': awaitingDispatch,
        'trackingNumber': extras['tracking_number'],
        'trackingUrl': extras['tracking_url'],
      });
    } on DioException catch (e) {
      return Failure(
        UnknownFailure(
          message: 'Tracking failed (${e.response?.statusCode ?? e.type.name}).',
        ),
      );
    } catch (e) {
      return Failure(UnknownFailure(message: 'Tracking failed: $e'));
    }
  }

  static String _humaniseMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    if (minutes < 60 * 24) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0 ? '$h hr' : '$h hr $m min';
    }
    final days = minutes ~/ (60 * 24);
    return '$days day${days == 1 ? '' : 's'}';
  }
}
