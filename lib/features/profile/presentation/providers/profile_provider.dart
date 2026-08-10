import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/profile_usecases.dart';
import '../../data/repositories/supabase_profile_repository.dart';
import '../../domain/entities/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository();
});

final getProfileUsecaseProvider = Provider((ref) {
  return GetProfileUsecase(ref.watch(profileRepositoryProvider));
});

final updateProfileUsecaseProvider = Provider((ref) {
  return UpdateProfileUsecase(ref.watch(profileRepositoryProvider));
});

final uploadProfileImageUsecaseProvider = Provider((ref) {
  return UploadProfileImageUsecase(ref.watch(profileRepositoryProvider));
});

/// User profile provider with graceful sync failure handling
/// 
/// Returns a UserProfile when found, or null if the user doesn't exist in Firestore yet.
/// This prevents sync failures from crashing the app - instead shows a "loading" state
/// that allows users to continue using the app even without synchronized data.
final userProfileProvider = FutureProvider.family<UserProfile?, String>((ref, String userId) async {
  // Handle empty or invalid userId
  if (userId.isEmpty) {
    return null;
  }

  try {
    final usecase = ref.watch(getProfileUsecaseProvider);
    final result = await usecase(userId);

    return result.fold<UserProfile?>(
      (failure) {
        // Log the failure for debugging
        print('Profile sync warning for user $userId: ${failure.message}');
        
        // Return null to indicate profile doesn't exist in Firestore yet
        // The UI can then show a loading state or prompt to complete onboarding
        return null;
      },
      (profile) => profile,
    );
  } catch (e) {
    // Handle any unexpected errors gracefully
    print('Profile sync error for user $userId: $e');
    return null;
  }
});

/// Required profile provider - throws if profile not found
/// Use this when you specifically need the profile to exist
final requiredUserProfileProvider = FutureProvider.family<UserProfile, String>((ref, String userId) async {
  final profile = await ref.watch(userProfileProvider(userId).future);
  if (profile == null) {
    throw Exception('Profile not found. Please complete your profile setup.');
  }
  return profile;
});
