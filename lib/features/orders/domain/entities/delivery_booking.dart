/// One carrier's offer for a parcel.
///
/// Terminal returns competing offers from every carrier it can reach, each with
/// its own price and speed. Collapsing that to a single number throws away the
/// main advantage of an aggregator, so the list is modelled explicitly and the
/// cheapest is selected by default.
class DeliveryQuote {
  const DeliveryQuote({
    required this.carrierId,
    required this.carrierName,
    required this.carrierSlug,
    required this.amount,
    required this.currency,
    required this.rateId,
    this.deliveryEtaMinutes,
    this.pickupEtaMinutes,
    this.deliveryTime = '',
    this.supportsCod = false,
  });

  final String carrierId;
  final String carrierName;
  final String carrierSlug;
  final double amount;
  final String currency;

  /// Rate reference required to arrange this specific offer.
  final String rateId;
  final int? deliveryEtaMinutes;
  final int? pickupEtaMinutes;

  /// Carrier's own wording, e.g. "Within 3 business days".
  final String deliveryTime;

  /// Whether the carrier collects cash on delivery for this rate.
  final bool supportsCod;

  String get etaLabel => deliveryEtaMinutes == null
      ? deliveryTime
      : _humanise(deliveryEtaMinutes!);

  static String _humanise(int minutes) {
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

/// A confirmed delivery arrangement.
class DeliveryBooking {
  const DeliveryBooking({
    required this.shipmentId,
    required this.status,
    required this.carrierName,
    required this.amount,
    required this.currency,
    this.trackingNumber,
    this.trackingUrl,
    this.events = const [],
  });

  final String shipmentId;

  /// `confirmed` once a rider is arranged; `draft` before that.
  final String status;
  final String carrierName;
  final double amount;
  final String currency;
  final String? trackingNumber;
  final String? trackingUrl;
  final List<DeliveryEvent> events;

  bool get isArranged => status.toUpperCase() != 'DRAFT';
}

/// A tracking event emitted by the carrier.
class DeliveryEvent {
  const DeliveryEvent({
    required this.status,
    required this.description,
    required this.location,
    required this.createdAt,
  });

  final String status;
  final String description;
  final String location;
  final String createdAt;
}