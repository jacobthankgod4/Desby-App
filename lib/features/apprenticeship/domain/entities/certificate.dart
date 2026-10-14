import 'package:equatable/equatable.dart';

class Certificate extends Equatable {
  final String id;
  final String apprenticeId;
  final String level;
  final String tailorName;
  final String apprenticeName;
  final DateTime completedAt;
  final String certificateNumber;

  const Certificate({
    required this.id,
    required this.apprenticeId,
    required this.level,
    required this.tailorName,
    required this.apprenticeName,
    required this.completedAt,
    required this.certificateNumber,
  });

  @override
  List<Object?> get props => [
    id,
    apprenticeId,
    level,
    tailorName,
    apprenticeName,
    completedAt,
    certificateNumber,
  ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'apprentice_id': apprenticeId,
      'level': level,
      'tailor_name': tailorName,
      'apprentice_name': apprenticeName,
      'completed_at': completedAt.toIso8601String(),
      'certificate_number': certificateNumber,
    };
  }

  factory Certificate.fromMap(Map<String, dynamic> map) {
    return Certificate(
      id: map['id'] ?? '',
      apprenticeId: map['apprentice_id'] ?? '',
      level: map['level'] ?? '',
      tailorName: map['tailor_name'] ?? '',
      apprenticeName: map['apprentice_name'] ?? '',
      completedAt:
          DateTime.tryParse(map['completed_at'] ?? '') ?? DateTime.now(),
      certificateNumber: map['certificate_number'] ?? '',
    );
  }
}
