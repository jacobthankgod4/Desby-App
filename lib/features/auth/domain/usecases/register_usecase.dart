import '../../../../core/error/failures.dart';
import '../entities/auth_response.dart';
import '../repositories/auth_repository.dart';

class RegisterUsecase {
  final AuthRepository repository;

  RegisterUsecase(this.repository);

  Future<Result<AuthResponse>> call(
    String email,
    String password,
    String name,
    String userType,
  ) {
    return repository.register(email, password, name, userType);
  }
}
