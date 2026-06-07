import 'package:equatable/equatable.dart';

/// Filter state model for marketplace filters
class MarketplaceFilter extends Equatable {
  final String? category;
  final List<String> selectedPriceRanges;
  final List<String> selectedOrigins;
  final List<String> selectedColors;
  final List<String> selectedCertifications;
  final List<String> selectedFilterChips;
  final String searchQuery;
  final String searchType;
  final String sortBy;
  final int? minPrice;
  final int? maxPrice;
  final String? selectedState;
  final String? selectedLga;

  const MarketplaceFilter({
    this.category = 'All',
    this.selectedPriceRanges = const [],
    this.selectedOrigins = const [],
    this.selectedColors = const [],
    this.selectedCertifications = const [],
    this.selectedFilterChips = const ['All'],
    this.searchQuery = '',
    this.searchType = 'All',
    this.sortBy = 'Newest',
    this.minPrice,
    this.maxPrice,
    this.selectedState,
    this.selectedLga,
  });

  MarketplaceFilter copyWith({
    String? category,
    List<String>? selectedPriceRanges,
    List<String>? selectedOrigins,
    List<String>? selectedColors,
    List<String>? selectedCertifications,
    List<String>? selectedFilterChips,
    String? searchQuery,
    String? searchType,
    String? sortBy,
    int? minPrice,
    int? maxPrice,
    String? selectedState,
    String? selectedLga,
  }) {
    return MarketplaceFilter(
      category: category ?? this.category,
      selectedPriceRanges: selectedPriceRanges ?? this.selectedPriceRanges,
      selectedOrigins: selectedOrigins ?? this.selectedOrigins,
      selectedColors: selectedColors ?? this.selectedColors,
      selectedCertifications: selectedCertifications ?? this.selectedCertifications,
      selectedFilterChips: selectedFilterChips ?? this.selectedFilterChips,
      searchQuery: searchQuery ?? this.searchQuery,
      searchType: searchType ?? this.searchType,
      sortBy: sortBy ?? this.sortBy,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedState: selectedState ?? this.selectedState,
      selectedLga: selectedLga ?? this.selectedLga,
    );
  }

  bool get hasActiveFilters {
    return category != 'All' ||
        selectedPriceRanges.isNotEmpty ||
        selectedOrigins.isNotEmpty ||
        selectedColors.isNotEmpty ||
        selectedCertifications.isNotEmpty ||
        selectedFilterChips.isNotEmpty ||
        searchQuery.isNotEmpty ||
        selectedState != null ||
        selectedLga != null;
  }

  int get activeFilterCount {
    int count = 0;
    if (category != 'All') count++;
    count += selectedPriceRanges.length;
    count += selectedOrigins.length;
    count += selectedColors.length;
    count += selectedCertifications.length;
    count += selectedFilterChips.where((c) => c != 'All').length;
    if (selectedState != null) count++;
    if (selectedLga != null) count++;
    return count;
  }

  @override
  List<Object?> get props => [
        category,
        selectedPriceRanges,
        selectedOrigins,
        selectedColors,
        selectedCertifications,
        selectedFilterChips,
        searchQuery,
        searchType,
        sortBy,
        minPrice,
        maxPrice,
        selectedState,
        selectedLga,
      ];
}

/// Price range options for filtering
class PriceRange {
  final String label;
  final int? minPrice;
  final int? maxPrice;

  const PriceRange({
    required this.label,
    this.minPrice,
    this.maxPrice,
  });

  static const List<PriceRange> options = [
    PriceRange(label: 'Under ₦5,000', maxPrice: 5000),
    PriceRange(label: '₦5,000 - ₦15,000', minPrice: 5000, maxPrice: 15000),
    PriceRange(label: '₦15,000 - ₦30,000', minPrice: 15000, maxPrice: 30000),
    PriceRange(label: '₦30,000 - ₦50,000', minPrice: 30000, maxPrice: 50000),
    PriceRange(label: 'Above ₦50,000', minPrice: 50000),
  ];
}

/// Origin countries for filtering
class FabricOrigin {
  final String label;
  final String value;

  const FabricOrigin({required this.label, required this.value});

  static const List<FabricOrigin> options = [
    FabricOrigin(label: 'Nigeria', value: 'Nigeria'),
    FabricOrigin(label: 'India', value: 'India'),
    FabricOrigin(label: 'China', value: 'China'),
    FabricOrigin(label: 'Turkey', value: 'Turkey'),
    FabricOrigin(label: 'Italy', value: 'Italy'),
  ];
}

/// Color options for filtering
class FabricColorOption {
  final String label;
  final int colorValue;

  const FabricColorOption({required this.label, required this.colorValue});

  int get color => colorValue;

  static const List<FabricColorOption> options = [
    FabricColorOption(label: 'Black', colorValue: 0xFF000000),
    FabricColorOption(label: 'White', colorValue: 0xFFFFFFFF),
    FabricColorOption(label: 'Navy', colorValue: 0xFF000080),
    FabricColorOption(label: 'Red', colorValue: 0xFFFF0000),
    FabricColorOption(label: 'Blue', colorValue: 0xFF0000FF),
    FabricColorOption(label: 'Green', colorValue: 0xFF008000),
    FabricColorOption(label: 'Brown', colorValue: 0xFF8B4513),
    FabricColorOption(label: 'Beige', colorValue: 0xFFF5F5DC),
    FabricColorOption(label: 'Grey', colorValue: 0xFF808080),
    FabricColorOption(label: 'Pink', colorValue: 0xFFFFC0CB),
    FabricColorOption(label: 'Purple', colorValue: 0xFF800080),
    FabricColorOption(label: 'Gold', colorValue: 0xFFFFD700),
  ];
}

/// Certification options for filtering
class CertificationOption {
  final String label;
  final String value;

  const CertificationOption({required this.label, required this.value});

  static const List<CertificationOption> options = [
    CertificationOption(label: 'Verified Sellers', value: 'verified'),
    CertificationOption(label: 'Organic', value: 'organic'),
    CertificationOption(label: 'Sustainable', value: 'sustainable'),
  ];
}

/// Filter chip options
class FilterChipOption {
  final String label;
  final String value;

  const FilterChipOption({required this.label, required this.value});

  static const List<FilterChipOption> options = [
    FilterChipOption(label: 'All', value: 'All'),
    FilterChipOption(label: 'Premium', value: 'premium'),
    FilterChipOption(label: 'Local Sourcing', value: 'local'),
    FilterChipOption(label: 'Imported', value: 'imported'),
    FilterChipOption(label: 'Organic', value: 'organic'),
    FilterChipOption(label: 'Sustainable', value: 'sustainable'),
  ];
}

/// Sort options
class SortOption {
  final String label;
  final String value;

  const SortOption({required this.label, required this.value});

  static const List<SortOption> options = [
    SortOption(label: 'Newest', value: 'newest'),
    SortOption(label: 'Price: Low to High', value: 'price_asc'),
    SortOption(label: 'Price: High to Low', value: 'price_desc'),
    SortOption(label: 'Best Sellers', value: 'popular'),
  ];
}
