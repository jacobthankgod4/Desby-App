import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user.dart';

enum ApprenticeshipStatus {
  invitedByMaster,      // Master pushed invite, student needs to accept
  onboarding,           // Student accepted invite, currently completing dossier
  awaitingMasterApproval, // Student self-applied, Master needs to confirm
  active,               // Fully linked and verified
  completed,
  terminated
}

class Apprenticeship extends Equatable {
  final String id;
  final String tailorId;
  final String apprenticeId;
  final ApprenticeshipStatus status;
  final double progress; // 0.0 to 1.0
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> skillIds;
  
  // UI Enrichment (optional, populated via joins)
  final User? apprenticeProfile;
  final User? tailorProfile;

  const Apprenticeship({
    required this.id,
    required this.tailorId,
    required this.apprenticeId,
    required this.status,
    required this.progress,
    required this.startDate,
    this.endDate,
    this.skillIds = const [],
    this.apprenticeProfile,
    this.tailorProfile,
  });

  @override
  List<Object?> get props => [
        id,
        tailorId,
        apprenticeId,
        status,
        progress,
        startDate,
        endDate,
        skillIds,
        apprenticeProfile,
        tailorProfile,
      ];

  Apprenticeship copyWith({
    String? id,
    String? tailorId,
    String? apprenticeId,
    ApprenticeshipStatus? status,
    double? progress,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? skillIds,
    User? apprenticeProfile,
    User? tailorProfile,
  }) {
    return Apprenticeship(
      id: id ?? this.id,
      tailorId: tailorId ?? this.tailorId,
      apprenticeId: apprenticeId ?? this.apprenticeId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      skillIds: skillIds ?? this.skillIds,
      apprenticeProfile: apprenticeProfile ?? this.apprenticeProfile,
      tailorProfile: tailorProfile ?? this.tailorProfile,
    );
  }
}
