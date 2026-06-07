import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/marketplace_filter.dart';

/// StateNotifier for managing marketplace filter state
class MarketplaceFilterNotifier extends StateNotifier<MarketplaceFilter> {
  MarketplaceFilterNotifier() : super(const MarketplaceFilter());

  // Debounce timer for search
  Timer? _debounceTimer;

  // Search history
  final List<String> _searchHistory = [];
  List<String> get searchHistory => List.unmodifiable(_searchHistory);

  /// Set category filter
  void setCategory(String category) {
    state = state.copyWith(category: category);
  }

  /// Toggle price range selection
  void togglePriceRange(String rangeLabel) {
    final currentList = List<String>.from(state.selectedPriceRanges);
    if (currentList.contains(rangeLabel)) {
      currentList.remove(rangeLabel);
    } else {
      currentList.add(rangeLabel);
    }
    state = state.copyWith(selectedPriceRanges: currentList);
  }

  /// Set price range (single select)
  void setPriceRange(String rangeLabel) {
    state = state.copyWith(selectedPriceRanges: [rangeLabel]);
  }

  /// Toggle origin selection
  void toggleOrigin(String origin) {
    final currentList = List<String>.from(state.selectedOrigins);
    if (currentList.contains(origin)) {
      currentList.remove(origin);
    } else {
      currentList.add(origin);
    }
    state = state.copyWith(selectedOrigins: currentList);
  }

  /// Set origins (multi-select)
  void setOrigins(List<String> origins) {
    state = state.copyWith(selectedOrigins: origins);
  }

  /// Toggle color selection
  void toggleColor(String colorLabel) {
    final currentList = List<String>.from(state.selectedColors);
    if (currentList.contains(colorLabel)) {
      currentList.remove(colorLabel);
    } else {
      currentList.add(colorLabel);
    }
    state = state.copyWith(selectedColors: currentList);
  }

  /// Set colors (multi-select)
  void setColors(List<String> colors) {
    state = state.copyWith(selectedColors: colors);
  }

  /// Toggle certification selection
  void toggleCertification(String certification) {
    final currentList = List<String>.from(state.selectedCertifications);
    if (currentList.contains(certification)) {
      currentList.remove(certification);
    } else {
      currentList.add(certification);
    }
    state = state.copyWith(selectedCertifications: currentList);
  }

  /// Set certifications (multi-select)
  void setCertifications(List<String> certifications) {
    state = state.copyWith(selectedCertifications: certifications);
  }

  /// Toggle filter chip selection
  void toggleFilterChip(String chipLabel) {
    final currentList = List<String>.from(state.selectedFilterChips);
    if (currentList.contains(chipLabel)) {
      currentList.remove(chipLabel);
    } else {
      currentList.add(chipLabel);
    }
    state = state.copyWith(selectedFilterChips: currentList);
  }

  /// Set filter chips (multi-select)
  void setFilterChips(List<String> chips) {
    state = state.copyWith(selectedFilterChips: chips);
  }

  /// Set search query with debouncing
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Set search query with immediate update
  void setSearchQueryImmediate(String query) {
    _debounceTimer?.cancel();
    state = state.copyWith(searchQuery: query);
    
    // Add to search history if non-empty
    if (query.isNotEmpty && !_searchHistory.contains(query)) {
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    }
  }

  /// Set search type (Fabrics or Sellers)
  void setSearchType(String type) {
    state = state.copyWith(searchType: type);
  }

  /// Set sort option
  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  /// Set Nigerian State filter
  void setSelectedState(String? stateName) {
    // When state changes, we must clear the LGA to prevent invalid hierarchy
    state = state.copyWith(selectedState: stateName, selectedLga: null);
  }

  /// Set Nigerian LGA filter
  void setSelectedLga(String? lgaName) {
    state = state.copyWith(selectedLga: lgaName);
  }

  /// Set price range (min/max)
  void setPriceRangeMinMax(int? min, int? max) {
    state = state.copyWith(minPrice: min, maxPrice: max);
  }

  /// Clear all filters
  void clearAllFilters() {
    state = const MarketplaceFilter();
  }

  /// Clear only category filter
  void clearCategory() {
    state = state.copyWith(category: 'All');
  }

  /// Clear search
  void clearSearch() {
    _debounceTimer?.cancel();
    state = state.copyWith(searchQuery: '');
  }

  /// Clear search history
  void clearSearchHistory() {
    _searchHistory.clear();
  }

  /// Remove single search history item
  void removeSearchHistoryItem(String query) {
    _searchHistory.remove(query);
  }

  /// Check if filter is active
  bool isPriceRangeSelected(String rangeLabel) {
    return state.selectedPriceRanges.contains(rangeLabel);
  }

  /// Check if origin is selected
  bool isOriginSelected(String origin) {
    return state.selectedOrigins.contains(origin);
  }

  /// Check if color is selected
  bool isColorSelected(String colorLabel) {
    return state.selectedColors.contains(colorLabel);
  }

  /// Check if certification is selected
  bool isCertificationSelected(String certification) {
    return state.selectedCertifications.contains(certification);
  }

  /// Check if filter chip is selected
  bool isFilterChipSelected(String chipLabel) {
    return state.selectedFilterChips.contains(chipLabel);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Provider for marketplace filter state
final marketplaceFilterProvider =
    StateNotifierProvider<MarketplaceFilterNotifier, MarketplaceFilter>((ref) {
  return MarketplaceFilterNotifier();
});

/// Convenience provider for filter count
final activeFilterCountProvider = Provider<int>((ref) {
  final filter = ref.watch(marketplaceFilterProvider);
  return filter.activeFilterCount;
});

/// Convenience provider for has active filters
final hasActiveFiltersProvider = Provider<bool>((ref) {
  final filter = ref.watch(marketplaceFilterProvider);
  return filter.hasActiveFilters;
});

/// Search history provider
final searchHistoryProvider = Provider<List<String>>((ref) {
  final notifier = ref.watch(marketplaceFilterProvider.notifier);
  return notifier.searchHistory;
});
