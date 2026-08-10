import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/service_tier.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/booking_quote.dart';

class TailorMarker {
  final String id;
  final LatLng location;
  final String name;
  final String? profileImage;
  final double startingPrice;
  final bool aiScanEnabled;
  final String? shopAddress;
  final double rating;
  final int reviewCount;
  final List<String> availableServices;
  final bool isAvailable;
  final int? distanceMinutes;

  TailorMarker({
    required this.id,
    required this.location,
    required this.name,
    this.profileImage,
    this.startingPrice = 0.0,
    this.aiScanEnabled = false,
    this.shopAddress,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.availableServices = const [],
    this.isAvailable = true,
    this.distanceMinutes,
  });

  factory TailorMarker.fromProfile(UserProfile profile) {
    return TailorMarker(
      id: profile.id,
      location: LatLng(profile.latitude ?? 0, profile.longitude ?? 0),
      name: profile.name,
      profileImage: profile.profileImage,
      startingPrice: profile.startingPrice ?? 0.0,
      aiScanEnabled: true,
      shopAddress: profile.address,
      rating: 4.5,
      reviewCount: 12,
      availableServices: profile.services ?? [],
      isAvailable: true,
      distanceMinutes: profile.distanceMinutes,
    );
  }
}

class TailorFinderFilters {
  final ServiceTier? serviceTier;
  final double maxDistance;
  final String? searchQuery;
  final double? maxPrice;
  final double? minRating;
  final bool onlyAvailable;

  const TailorFinderFilters({
    this.serviceTier,
    this.maxDistance = 50.0,
    this.searchQuery,
    this.maxPrice,
    this.minRating,
    this.onlyAvailable = false,
  });

  TailorFinderFilters copyWith({
    ServiceTier? serviceTier,
    double? maxDistance,
    String? searchQuery,
    double? maxPrice,
    double? minRating,
    bool? onlyAvailable,
    bool clearServiceTier = false,
    bool clearMaxPrice = false,
    bool clearMinRating = false,
  }) {
    return TailorFinderFilters(
      serviceTier: clearServiceTier ? null : (serviceTier ?? this.serviceTier),
      maxDistance: maxDistance ?? this.maxDistance,
      searchQuery: searchQuery ?? this.searchQuery,
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
    );
  }
}

class TailorFinderState {
  final List<UserProfile> tailors;
  final List<TailorMarker> markers;
  final UserProfile? selectedTailor;
  final ServiceTier? selectedServiceTier;
  final BookingQuote? currentQuote;
  final bool isLoading;
  final String? error;
  final TailorFinderFilters filters;
  final LatLng? userLocation;

  const TailorFinderState({
    this.tailors = const [],
    this.markers = const [],
    this.selectedTailor,
    this.selectedServiceTier,
    this.currentQuote,
    this.isLoading = false,
    this.error,
    this.filters = const TailorFinderFilters(),
    this.userLocation,
  });

  TailorFinderState copyWith({
    List<UserProfile>? tailors,
    List<TailorMarker>? markers,
    UserProfile? selectedTailor,
    ServiceTier? selectedServiceTier,
    BookingQuote? currentQuote,
    bool? isLoading,
    String? error,
    TailorFinderFilters? filters,
    LatLng? userLocation,
  }) {
    return TailorFinderState(
      tailors: tailors ?? this.tailors,
      markers: markers ?? this.markers,
      selectedTailor: selectedTailor ?? this.selectedTailor,
      selectedServiceTier: selectedServiceTier ?? this.selectedServiceTier,
      currentQuote: currentQuote ?? this.currentQuote,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      filters: filters ?? this.filters,
      userLocation: userLocation ?? this.userLocation,
    );
  }
}

class TailorFinderNotifier extends StateNotifier<TailorFinderState> {
  final Ref ref;

  TailorFinderNotifier(this.ref) : super(const TailorFinderState());

  Future<void> loadNearbyTailors() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final result = await repo.searchMasters(state.filters.searchQuery ?? '');
      
      result.fold(
        (failure) => state = state.copyWith(isLoading: false, error: failure.message),
        (tailors) {
          final markers = tailors.map((t) => TailorMarker.fromProfile(t)).toList();
          state = state.copyWith(isLoading: false, tailors: tailors, markers: markers);
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectTailor(dynamic tailor) {
    if (tailor is UserProfile) {
      state = state.copyWith(selectedTailor: tailor);
    } else if (tailor is TailorMarker) {
      final userProfile = state.tailors.firstWhere((t) => t.id == tailor.id);
      state = state.copyWith(selectedTailor: userProfile);
    }
  }

  void selectServiceTier(ServiceTier? tier) {
    state = state.copyWith(selectedServiceTier: tier);
  }

  void updateFilters(TailorFinderFilters filters) {
    state = state.copyWith(filters: filters);
    loadNearbyTailors();
  }

  void clearSelection() {
    state = state.copyWith(selectedTailor: null, selectedServiceTier: null, currentQuote: null);
  }

  void setUserLocation(LatLng location) {
    state = state.copyWith(userLocation: location);
  }
}

final tailorFinderProvider = StateNotifierProvider<TailorFinderNotifier, TailorFinderState>((ref) {
  return TailorFinderNotifier(ref);
});

// For compatibility
final tailorsProvider = FutureProvider.family<List<UserProfile>, String>((ref, query) async {
  final repo = ref.watch(profileRepositoryProvider);
  final result = await repo.searchMasters(query);
  return result.fold(
    (failure) => [],
    (tailors) => tailors,
  );
});
