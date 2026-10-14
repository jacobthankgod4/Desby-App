import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../clients/domain/entities/client.dart' show InviteStatus;

enum ApprenticeshipStatus {
  active,
  awaitingMasterApproval,
  completed,
  terminated,
  pendingInvite,
}

class Apprenticeship extends Equatable {
  final String id;
  final String tailorId;
  final String apprenticeId;
  final ApprenticeshipStatus status;
  final double progress;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> skillIds;
  final String? inviteToken;
  final InviteStatus inviteStatus;
  final String? apprenticeName;
  final String? apprenticePhone;
  final String? level;
  final DateTime? updatedAt;

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
    this.inviteToken,
    this.inviteStatus = InviteStatus.none,
    this.apprenticeName,
    this.apprenticePhone,
    this.level,
    this.updatedAt,
    this.apprenticeProfile,
    this.tailorProfile,
  });

  bool get hasInvite => inviteToken != null && inviteToken!.isNotEmpty;

  String? get inviteUrl => inviteToken != null
      ? 'https://desby.app/invite-apprentice?token=$inviteToken'
      : null;

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
    inviteToken,
    inviteStatus,
    apprenticeName,
    apprenticePhone,
    level,
    updatedAt,
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
    String? inviteToken,
    InviteStatus? inviteStatus,
    String? apprenticeName,
    String? apprenticePhone,
    String? level,
    DateTime? updatedAt,
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
      inviteToken: inviteToken ?? this.inviteToken,
      inviteStatus: inviteStatus ?? this.inviteStatus,
      apprenticeName: apprenticeName ?? this.apprenticeName,
      apprenticePhone: apprenticePhone ?? this.apprenticePhone,
      level: level ?? this.level,
      updatedAt: updatedAt ?? this.updatedAt,
      apprenticeProfile: apprenticeProfile ?? this.apprenticeProfile,
      tailorProfile: tailorProfile ?? this.tailorProfile,
    );
  }
}
