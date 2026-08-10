import 'package:equatable/equatable.dart';

enum OrderStatus {
  pending,
  bookingAccepted, // NEW: Uber-style acceptance
  materialsInTransit, // NEW: Logistics tracking
  inProgress,
  ready,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending: return 'Booking Pending';
      case OrderStatus.bookingAccepted: return 'Accepted';
      case OrderStatus.materialsInTransit: return 'Materials in Transit';
      case OrderStatus.inProgress: return 'In Progress';
      case OrderStatus.ready: return 'Ready for Pickup';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.cancelled: return 'Cancelled';
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
  final String id;
  final String clientId;
  final String? tailorId; // NEW: Associate order with a tailor
  final String clientName;
  final List<OrderItem> items;
  final OrderStatus status;
  final double totalAmount;
  final double dispatchFee; // NEW: ₦4,900 calibrated fee
  final DateTime dueDate;
  final DateTime createdAt;
  
  // NEW ORDER ARCHITECTURE FIELDS
  final String? materialAssetUrl;
  final bool requiresDispatch;
  final String? fabricType;
  final String? fabricColor;
  final String? deliveryAddress;
  
  // FEZ LOGISTICS INTEGRATION
  final String? fezOrderNo;
  final String? trackingUrl;
  final String? deliveryEta;
  final List<Map<String, dynamic>>? trackingHistory;

  const OrderEntity({
    required this.id,
    required this.clientId,
    this.tailorId,
    required this.clientName,
    required this.items,
    required this.status,
    required this.totalAmount,
    this.dispatchFee = 4900.0,
    required this.dueDate,
    required this.createdAt,
    this.materialAssetUrl,
    this.requiresDispatch = false,
    this.fabricType,
    this.fabricColor,
    this.deliveryAddress,
    this.fezOrderNo,
    this.trackingUrl,
    this.deliveryEta,
    this.trackingHistory,
  });

  @override
  List<Object?> get props => [
    id, clientId, tailorId, clientName, items, status, totalAmount, dispatchFee, 
    dueDate, createdAt, materialAssetUrl, requiresDispatch, fabricType, 
    fabricColor, deliveryAddress, fezOrderNo, trackingUrl, deliveryEta, trackingHistory
  ];

  OrderEntity copyWith({
    String? id,
    String? clientId,
    String? tailorId,
    String? clientName,
    List<OrderItem>? items,
    OrderStatus? status,
    double? totalAmount,
    double? dispatchFee,
    DateTime? dueDate,
    DateTime? createdAt,
    String? materialAssetUrl,
    bool? requiresDispatch,
    String? fabricType,
    String? fabricColor,
    String? deliveryAddress,
    String? fezOrderNo,
    String? trackingUrl,
    String? deliveryEta,
    List<Map<String, dynamic>>? trackingHistory,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      tailorId: tailorId ?? this.tailorId,
      clientName: clientName ?? this.clientName,
      items: items ?? this.items,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      dispatchFee: dispatchFee ?? this.dispatchFee,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      materialAssetUrl: materialAssetUrl ?? this.materialAssetUrl,
      requiresDispatch: requiresDispatch ?? this.requiresDispatch,
      fabricType: fabricType ?? this.fabricType,
      fabricColor: fabricColor ?? this.fabricColor,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      fezOrderNo: fezOrderNo ?? this.fezOrderNo,
      trackingUrl: trackingUrl ?? this.trackingUrl,
      deliveryEta: deliveryEta ?? this.deliveryEta,
      trackingHistory: trackingHistory ?? this.trackingHistory,
    );
  }
}
