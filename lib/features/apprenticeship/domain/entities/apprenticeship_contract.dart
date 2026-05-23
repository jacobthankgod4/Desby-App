import 'package:equatable/equatable.dart';

class ApprenticeshipContract extends Equatable {
  final String id;
  final String apprenticeshipId;
  final String terms;
  final double stipend;
  final String durationMonths;
  final DateTime signedDate;
  final String tailorSignature;
  final String apprenticeSignature;

  const ApprenticeshipContract({
    required this.id,
    required this.apprenticeshipId,
    required this.terms,
    required this.stipend,
    required this.durationMonths,
    required this.signedDate,
    required this.tailorSignature,
    required this.apprenticeSignature,
  });

  @override
  List<Object?> get props => [
        id,
        apprenticeshipId,
        terms,
        stipend,
        durationMonths,
        signedDate,
        tailorSignature,
        apprenticeSignature,
      ];
}
