import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/auth_response_model.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';

abstract class AuthRemoteDatasource {
  Future<AuthResponseModel> login(String email, String password);
  Future<AuthResponseModel> register(
    String email,
    String password,
    String name,
    String userType,
  );
  Future<void> logout();
  Future<AuthResponseModel> refreshToken(String refreshToken);
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final Dio dio;

  AuthRemoteDatasourceImpl(this.dio);

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final request = LoginRequestModel(email: email, password: password);
      final response = await dio.post(
        ApiEndpoints.authLogin,
        data: request.toJson(),
      );
      return AuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Login failed',
        code: e.response?.statusCode.toString(),
        originalException: e,
      );
    } catch (e) {
      throw ServerException(
        message: 'Login failed',
        originalException: e,
      );
    }
  }

  @override
  Future<AuthResponseModel> register(
    String email,
    String password,
    String name,
    String userType,
  ) async {
    try {
      final request = RegisterRequestModel(
        email: email,
        password: password,
        name: name,
        userType: userType,
      );
      final response = await dio.post(
        ApiEndpoints.authRegister,
        data: request.toJson(),
      );
      return AuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Registration failed',
        code: e.response?.statusCode.toString(),
        originalException: e,
      );
    } catch (e) {
      throw ServerException(
        message: 'Registration failed',
        originalException: e,
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post(ApiEndpoints.authLogout);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Logout failed',
        code: e.response?.statusCode.toString(),
        originalException: e,
      );
    } catch (e) {
      throw ServerException(
        message: 'Logout failed',
        originalException: e,
      );
    }
  }

  @override
  Future<AuthResponseModel> refreshToken(String refreshToken) async {
    try {
      final response = await dio.post(
        ApiEndpoints.authRefreshToken,
        data: {'refreshToken': refreshToken},
      );
      return AuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Token refresh failed',
        code: e.response?.statusCode.toString(),
        originalException: e,
      );
    } catch (e) {
      throw ServerException(
        message: 'Token refresh failed',
        originalException: e,
      );
    }
  }
}
