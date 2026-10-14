import 'package:equatable/equatable.dart';

enum OrderStatus {
  pending,
  paid,
  bookingAccepted,
  materialsInTransit,
  inProgress,
  ready,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Booking Pending';
      case OrderStatus.paid:
        return 'Paid';
      case OrderStatus.bookingAccepted:
        return 'Accepted';
      case OrderStatus.materialsInTransit:
        return 'Materials in Transit';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class OrderItem extends Equatable {
  final String id;
  final String garmentType;
  final String? designId;
  final Map<String, dynamic>? measurements;
  final double price;

  const OrderItem({
    required this.id,
    required this.garmentType,
    this.designId,
    this.measurements,
    required this.price,
  });

  @override
  List<Object?> get props => [id, garmentType, designId, measurements, price];
}

class OrderEntity extends Equatable {
  /// Primary key: a UUID. The production `orders.id` column is `uuid`, so a
  /// readable `ORD_…` value here was rejected with 22P02 and every insert
  /// failed. The human-readable handle lives in [reference].
  final String id;

  /// Human-readable handle, e.g. `ORD_1757000000000`. Unique and indexed.
  /// This is what support reads and what the tailor quotes back. Nullable
  /// because legacy rows predate the column; read [displayReference].
  final String? reference;

  /// The authenticated Desby account that placed this request.
  ///
  /// Distinct from [clientId]: that column references `clients(id)`, the
  /// tailor's own customer record, which a browsing client does not have until
  /// the tailor creates one. Conflating the two made every insert fail the FK.
  final String? requestingUserId;

  /// The tailor's customer record for this buyer, once one exists.
  /// Nullable: null until fulfilment.
  final String? clientId;

  /// The tailor being commissioned. null for marketplace/fabric orders.
  final String? tailorId;
  final String clientName;
  final List<OrderItem> items;
  final OrderStatus status;
  final double totalAmount;

  /// Units ordered.
  ///
  /// Promoted out of `metadata` so fulfilment, reporting and returns can query
  /// and index it. Null only on legacy rows written before the column existed;
  /// new orders always set it.
  final int? quantity;
  final double dispatchFee; // Calculated by Fez Logistics
  /// Null when no timeline has been agreed — the tailor confirms it. The
  /// production column is nullable; Dart claimed NOT NULL and invented a value.
  final DateTime? dueDate;
  final DateTime createdAt;

  // NEW ORDER ARCHITECTURE FIELDS
  final String? materialAssetUrl;
  final bool requiresDispatch;
  final String? fabricType;
  final String? fabricColor;
  final String? deliveryAddress;

  // LOGISTICS
  /// Reference for the arranged shipment.
  ///
  /// This maps to the `fez_order_no` column, a name left over from before
  /// logistics moved to Terminal Africa. The column was kept so existing rows
  /// and older builds keep working, but it now holds a **Terminal** shipment
  /// id. See `terminal_shipping_repository_impl.dart` for the write and
  /// `TerminalShippingRepositoryImpl.trackDelivery` for the read.
  final String? shipmentId;
  final String? trackingUrl;
  final String? deliveryEta;
  final List<Map<String, dynamic>>? trackingHistory;
  final Map<String, dynamic>? metadata;

  // PAYMENT FIELDS
  final String? paymentStatus; // 'pending', 'paid', 'refunded'
  final String? paymentReference; // Flutterwave tx_ref
  final double? platformFee; // 10% Desby commission
  final double? tailorPayout; // 90% to tailor/seller
  final DateTime? paidAt;

  const OrderEntity({
    required this.id,
    this.reference,
    this.requestingUserId,
    this.clientId,
    this.tailorId,
    required this.clientName,
    required this.items,
    required this.status,
    required this.totalAmount,
    this.quantity,
    this.dispatchFee = 0.0,
    this.dueDate,
    required this.createdAt,
    this.materialAssetUrl,
    this.requiresDispatch = false,
    this.fabricType,
    this.fabricColor,
    this.deliveryAddress,
    this.shipmentId,
    this.trackingUrl,
    this.deliveryEta,
    this.trackingHistory,
    this.metadata,
    this.paymentStatus,
    this.paymentReference,
    this.platformFee,
    this.tailorPayout,
    this.paidAt,
  });

  /// Falls back to a legacy `ORD_`-style handle when the caller could not supply
  /// one, so existing code and old rows still read sensibly.
  String get displayReference =>
      (reference != null && reference!.isNotEmpty) ? reference! : id;

  @override
  List<Object?> get props => [
    id,
    reference,
    requestingUserId,
    clientId,
    tailorId,
    clientName,
    items,
    status,
    totalAmount,
    dispatchFee,
    dueDate,
    createdAt,
    materialAssetUrl,
    requiresDispatch,
    fabricType,
    fabricColor,
    deliveryAddress,
    shipmentId,
    trackingUrl,
    deliveryEta,
    trackingHistory,
    metadata,
    paymentStatus,
    paymentReference,
    platformFee,
    tailorPayout,
    paidAt,
  ];

  OrderEntity copyWith({
    String? id,
    String? reference,
    String? requestingUserId,
    String? clientId,
    String? tailorId,
    String? clientName,
    List<OrderItem>? items,
    OrderStatus? status,
    double? totalAmount,
    int? quantity,
    double? dispatchFee,
    DateTime? dueDate,
    DateTime? createdAt,
    bool clearClientId = false,
    bool clearDueDate = false,
    String? materialAssetUrl,
    bool? requiresDispatch,
    String? fabricType,
    String? fabricColor,
    String? deliveryAddress,
    String? shipmentId,
    String? trackingUrl,
    String? deliveryEta,
    List<Map<String, dynamic>>? trackingHistory,
    Map<String, dynamic>? metadata,
    String? paymentStatus,
    String? paymentReference,
    double? platformFee,
    double? tailorPayout,
    DateTime? paidAt,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      requestingUserId: requestingUserId ?? this.requestingUserId,
      clientId: clearClientId ? null : (clientId ?? this.clientId),
      tailorId: tailorId ?? this.tailorId,
      clientName: clientName ?? this.clientName,
      items: items ?? this.items,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      quantity: quantity ?? this.quantity,
      dispatchFee: dispatchFee ?? this.dispatchFee,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt ?? this.createdAt,
      materialAssetUrl: materialAssetUrl ?? this.materialAssetUrl,
      requiresDispatch: requiresDispatch ?? this.requiresDispatch,
      fabricType: fabricType ?? this.fabricType,
      fabricColor: fabricColor ?? this.fabricColor,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      shipmentId: shipmentId ?? this.shipmentId,
      trackingUrl: trackingUrl ?? this.trackingUrl,
      deliveryEta: deliveryEta ?? this.deliveryEta,
      trackingHistory: trackingHistory ?? this.trackingHistory,
      metadata: metadata ?? this.metadata,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentReference: paymentReference ?? this.paymentReference,
      platformFee: platformFee ?? this.platformFee,
      tailorPayout: tailorPayout ?? this.tailorPayout,
      paidAt: paidAt ?? this.paidAt,
    );
  }
}
