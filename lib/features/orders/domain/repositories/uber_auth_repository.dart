abstract class UberAuthRepository {
  Future<String> getAccessToken();
  Future<void> refreshTokens();
}
