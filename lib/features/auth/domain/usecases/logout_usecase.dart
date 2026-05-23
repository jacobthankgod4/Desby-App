import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class LogoutUsecase {
  final AuthRepository repository;

  LogoutUsecase(this.repository);

  Future<Result<void>> call() {
    return repository.logout();
  }
}
