/// User type enumeration
enum UserType {
  tailor('tailor', 'Tailor'),
  client('client', 'Client'),
  apprentice('apprentice', 'Apprentice'),
  fabricSeller('fabric_seller', 'Fabric Seller');

  final String value;
  final String displayName;

  const UserType(this.value, this.displayName);

  /// Convert string to UserType
  static UserType fromString(String value) {
    return UserType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => UserType.tailor,
    );
  }

  /// Get all user types as list
  static List<UserType> getAll() => UserType.values;

  /// Get display names for dropdown
  static List<String> getDisplayNames() =>
      UserType.values.map((type) => type.displayName).toList();
}
