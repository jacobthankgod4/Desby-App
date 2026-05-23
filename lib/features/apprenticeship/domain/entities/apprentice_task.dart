import 'package:equatable/equatable.dart';

enum ApprenticeTaskStatus {
  todo,
  inProgress,
  underReview,
  completed,
  failed
}

class ApprenticeTask extends Equatable {
  final String id;
  final String apprenticeshipId;
  final String title;
  final String description;
  final ApprenticeTaskStatus status;
  final DateTime dueDate;
  final DateTime? completedAt;
  final String? feedback;
  final double? score; // 0.0 to 100.0
  final List<String>? proofImageUrls;
  final String? submissionNotes;

  const ApprenticeTask({
    required this.id,
    required this.apprenticeshipId,
    required this.title,
    required this.description,
    required this.status,
    required this.dueDate,
    this.completedAt,
    this.feedback,
    this.score,
    this.proofImageUrls,
    this.submissionNotes,
  });

  @override
  List<Object?> get props => [
        id,
        apprenticeshipId,
        title,
        description,
        status,
        dueDate,
        completedAt,
        feedback,
        score,
        proofImageUrls,
        submissionNotes,
      ];

  ApprenticeTask copyWith({
    String? id,
    String? apprenticeshipId,
    String? title,
    String? description,
    ApprenticeTaskStatus? status,
    DateTime? dueDate,
    DateTime? completedAt,
    String? feedback,
    double? score,
    List<String>? proofImageUrls,
    String? submissionNotes,
  }) {
    return ApprenticeTask(
      id: id ?? this.id,
      apprenticeshipId: apprenticeshipId ?? this.apprenticeshipId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      feedback: feedback ?? this.feedback,
      score: score ?? this.score,
      proofImageUrls: proofImageUrls ?? this.proofImageUrls,
      submissionNotes: submissionNotes ?? this.submissionNotes,
    );
  }
}
