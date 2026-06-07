import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../auth/data/repositories/firebase_auth_repository.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/service_tier.dart';
import '../../domain/entities/booking_quote.dart';

/// Provider to get tailors from Firestore - uses FirebaseAuthRepository directly
/// since getTailors is not in the AuthRepository interface
final tailorsFromFirestoreProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  // Support both FirebaseAuthRepository and the general AuthRepository interface
  // if it's implemented there.
  if (authRepo is FirebaseAuthRepository) {
    return authRepo.getTailors();
  }
  
// Fallback: try to get from user profile search if auth repo doesn't support it
  final profileRepo = ref.read(profileRepositoryProvider);
  final result = await profileRepo.searchMasters('');
  // Use fold() instead of when() for Result type
return result.fold(
    (f) => [],
    (profiles) => profiles.map((p) => {
      'id': p.id,
      'name': p.name,
      'email': p.email,
      'userType': p.userType,
      'phone': p.phone,
      'profileImage': p.profileImage,
      'bio': p.bio,
      'shopAddress': p.businessAddress ?? p.address,
      'latitude': p.latitude,
      'longitude': p.longitude,
      // Use -1 for new tailors without ratings
      'rating': -1.0,
      'reviewCount': 0,
      'services': p.services,
    }).toList(),
  );
});

/// Provider to check if user prefers the new Uber-style finder
/// Reads from current user's profile (preferredFinderStyle field) - defaults to 'uber'
/// FIX: Use .future to properly await profile load instead of valueOrNull cache
final prefersUberStyleFinderProvider = FutureProvider<bool>((ref) async {
  final authUser = ref.watch(currentUserProvider);
  if (authUser == null) return true; // Default to Uber style for logged out users
  
  try {
    // Use .future to properly await the AsyncValue instead of valueOrNull cache
    final profileAsync = ref.watch(userProfileProvider(authUser.id));
    
    // Wait for profile to load properly using .when/await
    final profile = await profileAsync.when(
      data: (profile) async => profile,
      loading: () async {
        // If still loading, wait for it
        await Future.delayed(const Duration(milliseconds: 500));
        final retryProfile = ref.read(userProfileProvider(authUser.id));
        return retryProfile.valueOrNull;
      },
      error: (err, stack) async => null,
    );
    
    // Explicit check: if profile is null or field is null/empty, default to 'uber' for new users
    if (profile == null) {
      // If profile doesn't exist yet, default to Uber style
      return true;
    }
    
    // Check the preferredFinderStyle field - default to 'uber' if null or empty
    final finderStyle = profile.preferredFinderStyle;
    if (finderStyle == null || finderStyle.isEmpty) {
      // No preference set yet - default to Uber for new users
      return true;
    }
    
    // Return true only if explicitly set to 'uber'
    return finderStyle == 'uber';
  } catch (e) {
    // On any error, default to Uber style for better UX
    return true;
  }
});

/// Tailor location marker for map display
/// Enhanced with all Firebase fields
/// AI Scan enabled status added for premium feature tier
class TailorMarker {
  final String id;
  final String name;
  final String? profileImage;
  final double rating;
  final int reviewCount;
  final LatLng location;
  final List<ServiceTier> availableServices;
  final double startingPrice;
  final bool isAvailable;
  final String? shopAddress;
  final int? distanceMinutes;
  final String? phoneNumber;
  final String? email;
  final String? bio;
  final List<String>? portfolioImages;
  final bool aiScanEnabled; // NEW: AI Scan premium feature flag

  const TailorMarker({
    required this.id,
    required this.name,
    this.profileImage,
    this.rating = -1.0, // -1 means no rating yet - sync with Firebase
    this.reviewCount = 0,
    required this.location,
    this.availableServices = const [],
    this.startingPrice = 5000,
    this.isAvailable = true,
    this.shopAddress,
    this.distanceMinutes,
    this.phoneNumber,
    this.email,
    this.bio,
    this.portfolioImages,
    this.aiScanEnabled = false, // Default to false (free tier)
  });

factory TailorMarker.fromMap(Map<String, dynamic> map, {int? calculatedDistance}) {
    // Extract services from Firebase field
    // FIX: Default to custom + readyToWear if no services defined
    final servicesList = map['services'] as List<dynamic>? ?? 
        map['availableServices'] as List<dynamic>? ?? [];
    final services = servicesList.isEmpty 
        ? <ServiceTier>[ServiceTier.custom, ServiceTier.readyToWear]
        : servicesList
            .map((s) => ServiceTier.fromString(s.toString()))
            .whereType<ServiceTier>()
            .toList();
    
    // Extract location - default to Lagos if not set
    // FIX: Handle both direct fields and nested location object
    final lat = (map['latitude'] as num?)?.toDouble() ?? 
             (map['location'] as Map?)?['latitude']?.toDouble() ?? 
             6.5244;
    final lng = (map['longitude'] as num?)?.toDouble() ?? 
             (map['location'] as Map?)?['longitude']?.toDouble() ?? 
             3.3792;
    
    // Extract price - default to 5000 if no pricing defined
    // FIX: Be more resilient - use 5000 as placeholder for new tailors
    final price = (map['startingPrice'] as num?)?.toDouble() ?? 
                (map['pricing'] as num?)?.toDouble() ?? 
                5000.0; // Use default 5000 instead of 0
    
    // Extract availability - default to true for new tailors
    final available = map['isAvailable'] as bool? ?? 
                    map['available'] as bool? ?? 
                    true;
    
// Extract rating/reviews - default to -1 (no rating) for new tailors
    // FIX: Sync with Firebase - use explicit rating or -1 if not set
    final rating = (map['rating'] as num?)?.toDouble() ?? -1.0;
    final reviews = map['reviewCount'] as int? ?? 
                  map['reviews'] as int? ?? 0;
    
// Extract portfolio images
    List<String>? portfolio;
    if (map['portfolioImages'] is List) {
      portfolio = (map['portfolioImages'] as List)
          .whereType<String>()
          .toList();
    } else if (map['portfolio'] is List) {
      portfolio = (map['portfolio'] as List)
          .whereType<String>()
          .toList();
    }
    
    // Extract AI Scan enabled status - derived from subscription tier
    // true only if tailor has BUSINESS tier subscription with AI Body Scan feature
    final subscriptionPlan = map['subscriptionPlan'] as String? ?? 
                       map['subscriptionTier'] as String? ?? '';
    final aiFeatures = map['subscriptionFeatures'] as List<dynamic>? ?? [];
    final aiScanEnabled = subscriptionPlan == 'tailor_elite' || 
                       subscriptionPlan == 'business' ||
                       subscriptionPlan == 'BUSINESS' ||
                       aiFeatures.contains('AI Body Scan') ||
                       aiFeatures.contains('ai_body_scan');
    
    return TailorMarker(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Tailor',
      profileImage: map['profileImageUrl'] as String? ?? 
                  map['profileImage'] as String? ?? 
                  map['photoUrl'] as String?,
      rating: rating,
      reviewCount: reviews,
      location: LatLng(lat, lng),
      availableServices: services,
      startingPrice: price,
      isAvailable: available,
      shopAddress: map['shopAddress'] as String? ?? 
                  map['address'] as String?,
      distanceMinutes: map['distanceMinutes'] as int? ?? calculatedDistance,
phoneNumber: map['phoneNumber'] as String? ?? 
                  map['phone'] as String?,
      email: map['email'] as String?,
      bio: map['bio'] as String? ?? 
          map['description'] as String?,
      portfolioImages: portfolio,
      aiScanEnabled: aiScanEnabled, // NEW: AI Scan premium feature flag
    );
  }
}

/// Tailor Finder Filters
class TailorFinderFilters {
  final String? state;
  final String? lga;
  final ServiceTier? serviceTier;
  final double? maxPrice;
  final double? minRating;
  final bool onlyAvailable;

  const TailorFinderFilters({
    this.state,
    this.lga,
    this.serviceTier,
    this.maxPrice,
    this.minRating,
    this.onlyAvailable = true,
  });

  /// Create a copy with optional field clearing support
  /// Use explicit null to clear a field, or omit to keep current value
  TailorFinderFilters copyWith({
    String? state,
    bool clearState = false,
    String? lga,
    bool clearLga = false,
    ServiceTier? serviceTier,
    bool clearServiceTier = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    double? minRating,
    bool clearMinRating = false,
    bool? onlyAvailable,
  }) {
    return TailorFinderFilters(
      state: clearState ? null : (state ?? this.state),
      lga: clearLga ? null : (lga ?? this.lga),
      serviceTier: clearServiceTier ? null : (serviceTier ?? this.serviceTier),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
    );
  }
}

/// Tailor Finder State
class TailorFinderState {
  final List<TailorMarker> tailors;
  final TailorMarker? selectedTailor;
  final ServiceTier? selectedServiceTier;
  final BookingQuote? currentQuote;
  final TailorFinderFilters filters;
  final bool isLoading;
  final String? error;
  final LatLng? userLocation;

  const TailorFinderState({
    this.tailors = const [],
    this.selectedTailor,
    this.selectedServiceTier,
    this.currentQuote,
    this.filters = const TailorFinderFilters(),
    this.isLoading = false,
    this.error,
    this.userLocation,
  });

  TailorFinderState copyWith({
    List<TailorMarker>? tailors,
    TailorMarker? selectedTailor,
    ServiceTier? selectedServiceTier,
    BookingQuote? currentQuote,
    TailorFinderFilters? filters,
    bool? isLoading,
    String? error,
    LatLng? userLocation,
  }) {
    return TailorFinderState(
      tailors: tailors ?? this.tailors,
      selectedTailor: selectedTailor ?? this.selectedTailor,
      selectedServiceTier: selectedServiceTier ?? this.selectedServiceTier,
      currentQuote: currentQuote ?? this.currentQuote,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userLocation: userLocation ?? this.userLocation,
    );
  }
}

/// Tailor Finder Notifier
class TailorFinderNotifier extends StateNotifier<TailorFinderState> {
  final Ref ref;
  
  TailorFinderNotifier(this.ref) : super(const TailorFinderState());

/// Load nearby tailors from Firestore
  Future<void> loadNearbyTailors() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // AUTO-DETECT: Get user's GPS location first
      final userLocation = await LocationService.getCurrentLocation();
      
// Fall back to user's state from profile if GPS unavailable
      LatLng? fallbackLocation;
      if (userLocation == null) {
        final authUser = ref.read(currentUserProvider);
        if (authUser != null) {
          final profileAsync = ref.read(userProfileProvider(authUser.id));
          final profile = profileAsync.valueOrNull;
          final profileState = profile?.state;
          if (profileState != null && profileState.isNotEmpty) {
            fallbackLocation = _getLocationForState(profileState);
          }
        }
      }
      
      // Set user location (GPS or fallback)
      final location = userLocation ?? fallbackLocation ?? LocationService.defaultLocation;
      state = state.copyWith(userLocation: location);
      
      // Get tailors from Firestore via provider
      final tailorsAsyncResult = await ref.read(tailorsFromFirestoreProvider.future);
      
// If we got no tailors from Firestore, show empty state
      // Firebase is the sole data provider - no fallback demo data
      if (tailorsAsyncResult.isEmpty) {
        state = state.copyWith(
          tailors: [],
          isLoading: false,
          userLocation: location,
          error: null, // No error - just empty
        );
        return;
      }

      // Convert Firestore data to TailorMarkers with distance calculation
      final allTailors = tailorsAsyncResult.map((data) {
        final tailorLat = (data['latitude'] as num?)?.toDouble();
        final tailorLng = (data['longitude'] as num?)?.toDouble();
        
        int? distance;
        if (tailorLat != null && tailorLng != null) {
          distance = LocationService.calculateDistanceMinutes(
            location, 
            LatLng(tailorLat, tailorLng),
          );
        }
        return TailorMarker.fromMap(data, calculatedDistance: distance);
      }).toList();
      
      // Sort by distance
      allTailors.sort((a, b) => (a.distanceMinutes ?? 999).compareTo(b.distanceMinutes ?? 999));
      
      // Apply local filters
      final filteredTailors = _applyFilters(allTailors);
      
      state = state.copyWith(
        tailors: filteredTailors,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        tailors: [],
        isLoading: false,
        userLocation: LocationService.defaultLocation,
        error: 'Sync error: $e',
      );
    }
  }
  
  /// Get approximate location for Nigerian states
  LatLng _getLocationForState(String state) {
    final stateLocations = {
      'Lagos': const LatLng(6.5244, 3.3792),
      'Abuja': const LatLng(9.0765, 7.3986),
      'Rivers': const LatLng(4.7774, 6.8333),
      'Delta': const LatLng(5.2040, 5.5900),
      'Oyo': const LatLng(7.3775, 3.9470),
      'Ogun': const LatLng(6.9025, 3.3475),
      'Kano': const LatLng(12.0022, 8.5919),
      'Enugu': const LatLng(6.4402, 7.4931),
      'Anambra': const LatLng(6.2194, 6.9362),
      'Imo': const LatLng(5.2828, 6.9887),
      'Kaduna': const LatLng(10.5105, 7.4165),
      'Plateau': const LatLng(9.9293, 8.8921),
      'Edo': const LatLng(6.3350, 5.6247),
      'Kwara': const LatLng(8.9850, 4.5419),
      'Ondo': const LatLng(7.1608, 5.2152),
      'Ekiti': const LatLng(7.6256, 5.0460),
      'Osun': const LatLng(7.5930, 4.1659),
      'Abia': const LatLng(5.5657, 6.2540),
      'Niger': const LatLng(9.7155, 6.5636),
      'Borno': const LatLng(11.8469, 13.1570),
    };
    return stateLocations[state] ?? LocationService.defaultLocation;
  }

/// Apply filters to tailor list
  /// FIX: Now allows tailors with missing/zero pricing to be displayed
  List<TailorMarker> _applyFilters(List<TailorMarker> tailors) {
    final filters = state.filters;
    final filtered = tailors.where((tailor) {
      // Filter by availability - always allow available tailors
      if (filters.onlyAvailable && !tailor.isAvailable) return false;
      
      // Filter by max price - apply only if both price AND maxPrice are set
      // FIX: Allow tailors with pricing = 0 (new tailors without pricing setup)
      if (filters.maxPrice != null && 
          tailor.startingPrice > 0 && 
          tailor.startingPrice > filters.maxPrice!) {
        return false;
      }
      
// Filter by min rating - skip if rating is -1 (no rating yet)
      // FIX: Only filter tailors who actually have ratings
      if (filters.minRating != null && tailor.rating > 0 && tailor.rating < filters.minRating!) {
        return false;
      }
      
      // Filter by service tier - only if tailor has services and filter is set
      if (filters.serviceTier != null && 
          tailor.availableServices.isNotEmpty &&
          !tailor.availableServices.contains(filters.serviceTier)) {
        return false;
      }
      
      return true;
    }).toList();

    return filtered;
  }

  /// Select a tailor
  void selectTailor(TailorMarker tailor) {
    state = state.copyWith(
      selectedTailor: tailor,
      currentQuote: null,
    );
  }

  /// Clear selection
  void clearSelection() {
    state = state.copyWith(
      selectedTailor: null,
      selectedServiceTier: null,
      currentQuote: null,
    );
  }

  /// Select service tier
  void selectServiceTier(ServiceTier tier) {
    state = state.copyWith(selectedServiceTier: tier);
    // Auto-generate quote when both tailor and tier selected
    if (state.selectedTailor != null) {
      _generateQuote(tier);
    }
  }

  /// Generate quote for selected options
  void _generateQuote(ServiceTier tier) {
    if (state.selectedTailor == null) return;

    final tailor = state.selectedTailor!;
    final quote = BookingQuote(
      id: 'quote_${DateTime.now().millisecondsSinceEpoch}',
      tailorId: tailor.id,
      tailorName: tailor.name,
      serviceTier: tier,
      price: _calculatePrice(tier, tailor.startingPrice),
      turnaroundDays: tier.defaultTurnaroundDays,
      garmentType: tier.displayName,
      inclusions: _getInclusions(tier),
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    );

    state = state.copyWith(currentQuote: quote);
  }

  double _calculatePrice(ServiceTier tier, double basePrice) {
    switch (tier) {
      case ServiceTier.custom:
        return basePrice * 2.5;
      case ServiceTier.readyToWear:
        return basePrice;
      case ServiceTier.bridal:
        return basePrice * 4.0;
      case ServiceTier.menswear:
        return basePrice * 1.5;
      case ServiceTier.womenswear:
        return basePrice * 1.5;
    }
  }

  List<String> _getInclusions(ServiceTier tier) {
    switch (tier) {
      case ServiceTier.custom:
        return ['Measurement', 'Fitting', 'Delivery'];
      case ServiceTier.readyToWear:
        return ['Alteration', 'Fitting'];
      case ServiceTier.bridal:
        return ['Multiple Fittings', 'Rush Order', 'Delivery'];
      case ServiceTier.menswear:
        return ['Measurement', 'Fitting'];
      case ServiceTier.womenswear:
        return ['Measurement', 'Fitting', 'Delivery'];
    }
  }

  /// Update filters
  void updateFilters(TailorFinderFilters filters) {
    state = state.copyWith(filters: filters);
    loadNearbyTailors(); // Reload with new filters
  }

/// Set user location
  void setUserLocation(LatLng location) {
    state = state.copyWith(userLocation: location);
  }
}

/// Main provider for tailor finder
final tailorFinderProvider =
    StateNotifierProvider<TailorFinderNotifier, TailorFinderState>((ref) {
  return TailorFinderNotifier(ref);
});

/// Convenience providers
final selectedTailorProvider = Provider<TailorMarker?>((ref) {
  return ref.watch(tailorFinderProvider).selectedTailor;
});

final selectedServiceTierProvider = Provider<ServiceTier?>((ref) {
  return ref.watch(tailorFinderProvider).selectedServiceTier;
});

final currentQuoteProvider = Provider<BookingQuote?>((ref) {
  return ref.watch(tailorFinderProvider).currentQuote;
});

final nearbyTailorsProvider = Provider<List<TailorMarker>>((ref) {
  return ref.watch(tailorFinderProvider).tailors;
});

final isLoadingTailorsProvider = Provider<bool>((ref) {
  return ref.watch(tailorFinderProvider).isLoading;
});
