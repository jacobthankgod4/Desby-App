import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/order.dart';

part 'order_model.freezed.dart';
part 'order_model.g.dart';

@freezed
class OrderItemModel with _$OrderItemModel {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory OrderItemModel({
    required String id,
    required String garmentType,
    String? designId,
    Map<String, dynamic>? measurements,
    required double price,
  }) = _OrderItemModel;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemModelFromJson(json);

  factory OrderItemModel.fromEntity(OrderItem item) => OrderItemModel(
        id: item.id,
        garmentType: item.garmentType,
        designId: item.designId,
        measurements: item.measurements,
        price: item.price,
      );
}

@freezed
class OrderModel with _$OrderModel {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory OrderModel({
    required String id,
    required String clientId,
    String? tailorId, // NEW: Associate with tailor
    required String clientName,
    required List<OrderItemModel> items,
    @Default(OrderStatus.pending) OrderStatus status,
    required double totalAmount,
    @Default(4900.0) double dispatchFee,
    required DateTime dueDate,
    required DateTime createdAt,
    String? materialAssetUrl,
    @Default(false) bool requiresDispatch,
    String? fabricType,
    String? fabricColor,
    String? fezOrderNo,
    String? deliveryEta,
    List<Map<String, dynamic>>? trackingHistory,
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  factory OrderModel.fromEntity(OrderEntity order) => OrderModel(
        id: order.id,
        clientId: order.clientId,
        tailorId: order.tailorId,
        clientName: order.clientName,
        items: order.items.map((i) => OrderItemModel.fromEntity(i)).toList(),
        status: order.status,
        totalAmount: order.totalAmount,
        dispatchFee: order.dispatchFee,
        dueDate: order.dueDate,
        createdAt: order.createdAt,
        materialAssetUrl: order.materialAssetUrl,
        requiresDispatch: order.requiresDispatch,
        fabricType: order.fabricType,
        fabricColor: order.fabricColor,
        fezOrderNo: order.fezOrderNo,
        deliveryEta: order.deliveryEta,
        trackingHistory: order.trackingHistory,
      );
}

extension OrderItemModelX on OrderItemModel {
  OrderItem toEntity() => OrderItem(
        id: id,
        garmentType: garmentType,
        designId: designId,
        measurements: measurements,
        price: price,
      );
}

extension OrderModelX on OrderModel {
  OrderEntity toEntity() => OrderEntity(
    id: id,
    clientId: clientId,
    tailorId: tailorId,
    clientName: clientName,
    items: items.map((i) => i.toEntity()).toList(),
    status: status,
    totalAmount: totalAmount,
    dispatchFee: dispatchFee,
    dueDate: dueDate,
    createdAt: createdAt,
    materialAssetUrl: materialAssetUrl,
    requiresDispatch: requiresDispatch,
    fabricType: fabricType,
    fabricColor: fabricColor,
    fezOrderNo: fezOrderNo,
    deliveryEta: deliveryEta,
    trackingHistory: trackingHistory,
  );
}
