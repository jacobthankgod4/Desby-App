import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/apprenticeship.dart';
import '../../../clients/domain/entities/client.dart' show InviteStatus;

part 'apprenticeship_model.freezed.dart';
part 'apprenticeship_model.g.dart';

@freezed
class ApprenticeshipModel with _$ApprenticeshipModel {
  const factory ApprenticeshipModel({
    required String id,
    required String tailorId,
    required String apprenticeId,
    required String status,
    required double progress,
    required DateTime startDate,
    DateTime? endDate,
    @Default([]) List<String> skillIds,
    String? inviteToken,
    String? inviteStatus,
    String? apprenticeName,
    String? apprenticePhone,
    String? level,
  }) = _ApprenticeshipModel;

  factory ApprenticeshipModel.fromJson(Map<String, dynamic> json) =>
      _$ApprenticeshipModelFromJson(json);

  factory ApprenticeshipModel.fromEntity(Apprenticeship entity) {
    return ApprenticeshipModel(
      id: entity.id,
      tailorId: entity.tailorId,
      apprenticeId: entity.apprenticeId,
      status: entity.status.name,
      progress: entity.progress,
      startDate: entity.startDate,
      endDate: entity.endDate,
      skillIds: entity.skillIds,
      inviteToken: entity.inviteToken,
      inviteStatus: entity.inviteStatus == InviteStatus.none
          ? null
          : entity.inviteStatus.name,
      apprenticeName: entity.apprenticeName,
      apprenticePhone: entity.apprenticePhone,
      level: entity.level,
    );
  }
}

extension ApprenticeshipModelX on ApprenticeshipModel {
  Apprenticeship toEntity() => Apprenticeship(
    id: id,
    tailorId: tailorId,
    apprenticeId: apprenticeId,
    status: ApprenticeshipStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => ApprenticeshipStatus.awaitingMasterApproval,
    ),
    progress: progress,
    startDate: startDate,
    endDate: endDate,
    skillIds: skillIds,
    inviteToken: inviteToken,
    inviteStatus: _parseInviteStatus(inviteStatus),
    apprenticeName: apprenticeName,
    apprenticePhone: apprenticePhone,
    level: level,
  );

  InviteStatus _parseInviteStatus(String? status) {
    if (status == null) return InviteStatus.none;
    return InviteStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => InviteStatus.none,
    );
  }
}
