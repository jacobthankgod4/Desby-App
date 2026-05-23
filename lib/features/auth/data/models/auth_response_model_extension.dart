import '../../domain/entities/auth_response.dart';
import 'user_model_extension.dart';
import 'auth_response_model.dart';

extension AuthResponseModelX on AuthResponseModel {
  AuthResponse toEntity() => AuthResponse(
        user: user.toEntity(),
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresIn: expiresIn,
      );
}
