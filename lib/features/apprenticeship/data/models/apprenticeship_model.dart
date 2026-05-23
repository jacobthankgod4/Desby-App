import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/apprenticeship.dart';

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
    );
  }
}

extension ApprenticeshipModelX on ApprenticeshipModel {
  Apprenticeship toEntity() => Apprenticeship(
        id: id,
        tailorId: tailorId,
        apprenticeId: apprenticeId,
        status: ApprenticeshipStatus.values.byName(status),
        progress: progress,
        startDate: startDate,
        endDate: endDate,
        skillIds: skillIds,
      );
}
