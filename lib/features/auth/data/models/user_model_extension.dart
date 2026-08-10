import '../../domain/entities/user.dart';
import 'user_model.dart';

// NOTE: This project uses a simplified UserModel (no Freezed). Extension is retained
// for convenience but should not reference generated Freezed copyWith members.


extension UserModelX on UserModel {
  User toEntity() => User(
    id: id,
    email: email,
    name: name,
    userType: userType,
    createdAt: createdAt,
    phone: phone,
    profileImage: profileImage,
    bio: bio,
    isVerified: isVerified,
  );
}
