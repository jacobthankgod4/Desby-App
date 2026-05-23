import '../../../../core/storage/storage_keys.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response_model_extension.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;
  final AuthLocalDatasource localDatasource;

  AuthRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
  });

  @override
  Future<Result<AuthResponse>> login(String email, String password) async {
    try {
      final model = await remoteDatasource.login(email, password);
      await localDatasource.saveTokens(model.accessToken, model.refreshToken);
      // Save current user for persistence
      final storage = (localDatasource as AuthLocalDatasourceImpl).storage;
      await storage.save(StorageKeys.currentUser, model.user.toJson());
      
      return Success(model.toEntity());
    } catch (e) {
      return Failure(ErrorHandler.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AuthResponse>> register(
    String email,
    String password,
    String name,
    String userType,
  ) async {
    try {
      final model = await remoteDatasource.register(
        email,
        password,
        name,
        userType,
      );
      await localDatasource.saveTokens(model.accessToken, model.refreshToken);
      // Save current user for persistence
      final storage = (localDatasource as AuthLocalDatasourceImpl).storage;
      await storage.save(StorageKeys.currentUser, model.user.toJson());

      return Success(model.toEntity());
    } catch (e) {
      return Failure(ErrorHandler.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await remoteDatasource.logout();
      await localDatasource.clearTokens();
      // Clear current user
      final storage = (localDatasource as AuthLocalDatasourceImpl).storage;
      await storage.delete(StorageKeys.currentUser);

      return const Success(null);
    } catch (e) {
      return Failure(ErrorHandler.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AuthResponse>> refreshToken(String refreshToken) async {
    try {
      final model = await remoteDatasource.refreshToken(refreshToken);
      await localDatasource.saveTokens(model.accessToken, model.refreshToken);
      return Success(model.toEntity());
    } catch (e) {
      return Failure(ErrorHandler.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> saveTokens(String accessToken, String refreshToken) async {
    try {
      await localDatasource.saveTokens(accessToken, refreshToken);
      return const Success(null);
    } catch (e) {
      return Failure(ErrorHandler.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<String?>> getAccessToken() async {
    try {
      final token = localDatasource.getAccessToken();
      return Success(token);
    } catch (e) {
      return Failure(ErrorHandler.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<String?>> getRefreshToken() async {
    try {
      final token = localDatasource.getRefreshToken();
      return Success(token);
    } catch (e) {
      return Failure(ErrorHandler.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> clearTokens() async {
    try {
      await localDatasource.clearTokens();
      return const Success(null);
    } catch (e) {
      return Failure(ErrorHandler.mapExceptionToFailure(e));
    }
  }
}
