import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/uber_logistics.dart';

part 'uber_logistics_models.freezed.dart';
part 'uber_logistics_models.g.dart';

@freezed
class UberDeliveryQuoteModel with _$UberDeliveryQuoteModel {
  const factory UberDeliveryQuoteModel({
    required String id,
    required int fee,
    @JsonKey(name: 'currency_type') required String currencyType,
    @JsonKey(name: 'expires') required DateTime expiresAt,
    @JsonKey(name: 'pickup_duration') required int pickupDuration,
    @JsonKey(name: 'duration') required int totalDuration,
    @JsonKey(name: 'dropoff_eta') required DateTime dropoffEta,
  }) = _UberDeliveryQuoteModel;

  factory UberDeliveryQuoteModel.fromJson(Map<String, dynamic> json) =>
      _$UberDeliveryQuoteModelFromJson(json);
}

extension UberDeliveryQuoteModelX on UberDeliveryQuoteModel {
  UberDeliveryQuote toEntity() => UberDeliveryQuote(
        id: id,
        fee: fee,
        currencyType: currencyType,
        expiresAt: expiresAt,
        pickupDuration: pickupDuration,
        totalDuration: totalDuration,
        dropoffEta: dropoffEta,
      );
}

@freezed
class UberDeliveryStatusModel with _$UberDeliveryStatusModel {
  const factory UberDeliveryStatusModel({
    required String id,
    required String status,
    @JsonKey(name: 'courier_imminent') required bool courierImminent,
    @JsonKey(name: 'tracking_url') String? trackingUrl,
    @JsonKey(name: 'pickup_eta') DateTime? pickupEta,
    @JsonKey(name: 'dropoff_eta') DateTime? dropoffEta,
  }) = _UberDeliveryStatusModel;

  factory UberDeliveryStatusModel.fromJson(Map<String, dynamic> json) =>
      _$UberDeliveryStatusModelFromJson(json);
}
