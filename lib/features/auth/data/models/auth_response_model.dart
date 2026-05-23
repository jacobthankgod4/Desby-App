import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_model.dart';
import '../../domain/entities/auth_response.dart';

part 'auth_response_model.freezed.dart';
part 'auth_response_model.g.dart';

@freezed
class AuthResponseModel with _$AuthResponseModel {
  const factory AuthResponseModel({
    required UserModel user,
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) = _AuthResponseModel;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseModelFromJson(json);
}

extension AuthResponseModelX on AuthResponseModel {
  AuthResponse toEntity() => AuthResponse(
        user: user.toEntity(),
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresIn: expiresIn,
      );
}
