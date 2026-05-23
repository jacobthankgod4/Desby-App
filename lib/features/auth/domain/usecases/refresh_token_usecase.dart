import '../../../../core/error/failures.dart';
import '../entities/auth_response.dart';
import '../repositories/auth_repository.dart';

class RefreshTokenUsecase {
  final AuthRepository repository;

  RefreshTokenUsecase(this.repository);

  Future<Result<AuthResponse>> call(String refreshToken) {
    return repository.refreshToken(refreshToken);
  }
}
