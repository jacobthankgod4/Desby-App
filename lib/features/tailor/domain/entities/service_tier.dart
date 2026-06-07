/// Service Tier Enum
/// Represents the different service categories offered by tailors
/// Adapted from Uber ride types (UberX, Select, Black, UberBAG)
enum ServiceTier {
  custom('Custom', 'Full bespoke tailoring service', 7),
  readyToWear('Ready-to-Wear', 'Alterations and adjustments', 3),
  bridal('Bridal', 'Wedding wear and events', 14),
  menswear('Menswear', "Men's uniforms and garments", 5),
  womenswear('Womenswear', "Women's garments and dresses", 5);

  final String displayName;
  final String description;
  final int defaultTurnaroundDays;

  const ServiceTier(
    this.displayName,
    this.description,
    this.defaultTurnaroundDays,
  );

  /// Get tier from string name
  static ServiceTier? fromString(String value) {
    return ServiceTier.values.cast<ServiceTier?>().firstWhere(
          (tier) => tier?.displayName.toLowerCase() == value.toLowerCase(),
          orElse: () => null,
        );
  }
}
