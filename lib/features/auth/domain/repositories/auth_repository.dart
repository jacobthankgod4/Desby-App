import '../../../../core/error/failures.dart';
import '../entities/auth_response.dart';

abstract class AuthRepository {
  Future<Result<AuthResponse>> login(String email, String password);
  Future<Result<AuthResponse>> register(
    String email,
    String password,
    String name,
    String userType,
  );
  Future<Result<void>> logout();
  Future<Result<AuthResponse>> refreshToken(String refreshToken);
  Future<Result<void>> saveTokens(String accessToken, String refreshToken);
  Future<Result<String?>> getAccessToken();
  Future<Result<String?>> getRefreshToken();
  Future<Result<void>> clearTokens();
}
