import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/apprentice_task.dart';

part 'apprentice_task_model.freezed.dart';
part 'apprentice_task_model.g.dart';

@freezed
class ApprenticeTaskModel with _$ApprenticeTaskModel {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ApprenticeTaskModel({
    required String id,
    required String apprenticeshipId,
    required String title,
    required String description,
    required String status,
    required DateTime dueDate,
    DateTime? completedAt,
    String? feedback,
    double? score,
    List<String>? proofImageUrls,
    String? submissionNotes,
  }) = _ApprenticeTaskModel;

  factory ApprenticeTaskModel.fromJson(Map<String, dynamic> json) =>
      _$ApprenticeTaskModelFromJson(json);

  factory ApprenticeTaskModel.fromEntity(ApprenticeTask entity) {
    return ApprenticeTaskModel(
      id: entity.id,
      apprenticeshipId: entity.apprenticeshipId,
      title: entity.title,
      description: entity.description,
      status: entity.status.name,
      dueDate: entity.dueDate,
      completedAt: entity.completedAt,
      feedback: entity.feedback,
      score: entity.score,
      proofImageUrls: entity.proofImageUrls,
      submissionNotes: entity.submissionNotes,
    );
  }
}

extension ApprenticeTaskModelX on ApprenticeTaskModel {
  ApprenticeTask toEntity() => ApprenticeTask(
        id: id,
        apprenticeshipId: apprenticeshipId,
        title: title,
        description: description,
        status: ApprenticeTaskStatus.values.byName(status),
        dueDate: dueDate,
        completedAt: completedAt,
        feedback: feedback,
        score: score,
        proofImageUrls: proofImageUrls,
        submissionNotes: submissionNotes,
      );
}
