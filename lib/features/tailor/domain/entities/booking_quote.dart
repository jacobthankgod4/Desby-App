import 'service_tier.dart';

/// Booking Quote Entity
/// Represents the estimated price and turnaround for a tailoring service
/// Adapted from Uber fare estimation
class BookingQuote {
  final String id;
  final String tailorId;
  final String tailorName;
  final ServiceTier serviceTier;
  final double price;
  final int turnaroundDays;
  final String garmentType;
  final List<String> inclusions;
  final DateTime expiresAt;

  const BookingQuote({
    required this.id,
    required this.tailorId,
    required this.tailorName,
    required this.serviceTier,
    required this.price,
    required this.turnaroundDays,
    required this.garmentType,
    required this.inclusions,
    required this.expiresAt,
  });

  /// Create from Firestore map
  factory BookingQuote.fromMap(Map<String, dynamic> map) {
    return BookingQuote(
      id: map['id'] as String,
      tailorId: map['tailorId'] as String,
      tailorName: map['tailorName'] as String,
      serviceTier: ServiceTier.values.firstWhere(
        (t) => t.name == map['serviceTier'],
        orElse: () => ServiceTier.custom,
      ),
      price: (map['price'] as num).toDouble(),
      turnaroundDays: map['turnaroundDays'] as int,
      garmentType: map['garmentType'] as String,
      inclusions: List<String>.from(map['inclusions'] ?? []),
      expiresAt: DateTime.parse(map['expiresAt'] as String),
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tailorId': tailorId,
      'tailorName': tailorName,
      'serviceTier': serviceTier.name,
      'price': price,
      'turnaroundDays': turnaroundDays,
      'garmentType': garmentType,
      'inclusions': inclusions,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  /// Check if quote is still valid
  bool get isValid => DateTime.now().isBefore(expiresAt);

  /// Get formatted price
  String get formattedPrice => '₦${price.toStringAsFixed(0)}';

  /// Get formatted turnaround
  String get formattedTurnaround {
    if (turnaroundDays == 1) return '1 day';
    return '$turnaroundDays days';
  }

  /// Copy with new values
  BookingQuote copyWith({
    String? id,
    String? tailorId,
    String? tailorName,
    ServiceTier? serviceTier,
    double? price,
    int? turnaroundDays,
    String? garmentType,
    List<String>? inclusions,
    DateTime? expiresAt,
  }) {
    return BookingQuote(
      id: id ?? this.id,
      tailorId: tailorId ?? this.tailorId,
      tailorName: tailorName ?? this.tailorName,
      serviceTier: serviceTier ?? this.serviceTier,
      price: price ?? this.price,
      turnaroundDays: turnaroundDays ?? this.turnaroundDays,
      garmentType: garmentType ?? this.garmentType,
      inclusions: inclusions ?? this.inclusions,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
