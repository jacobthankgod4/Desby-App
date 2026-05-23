import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/user_types.dart';

/// Provider for all available user types
final userTypesProvider = Provider<List<UserType>>((ref) {
  return UserType.getAll();
});

/// Provider for user type display names
final userTypeDisplayNamesProvider = Provider<List<String>>((ref) {
  return UserType.getDisplayNames();
});

/// Provider to convert string to UserType
final userTypeConverterProvider = Provider((ref) {
  return (String value) => UserType.fromString(value);
});
