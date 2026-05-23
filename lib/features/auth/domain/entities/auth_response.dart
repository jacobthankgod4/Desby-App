import 'user.dart';

class AuthResponse {
  final User user;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  AuthResponse copyWith({
    User? user,
    String? accessToken,
    String? refreshToken,
    int? expiresIn,
  }) {
    return AuthResponse(
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresIn: expiresIn ?? this.expiresIn,
    );
  }
}
