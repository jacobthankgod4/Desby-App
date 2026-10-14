import 'package:equatable/equatable.dart';

class Referral extends Equatable {
  final String id;
  final String referrerId;
  final String? refereeId;
  final String code;
  final bool isUsed;
  final DateTime createdAt;
  final DateTime? usedAt;

  const Referral({
    required this.id,
    required this.referrerId,
    this.refereeId,
    required this.code,
    this.isUsed = false,
    required this.createdAt,
    this.usedAt,
  });

  @override
  List<Object?> get props => [
    id,
    referrerId,
    refereeId,
    code,
    isUsed,
    createdAt,
    usedAt,
  ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referrer_id': referrerId,
      'referee_id': refereeId,
      'code': code,
      'is_used': isUsed,
      'created_at': createdAt.toIso8601String(),
      'used_at': usedAt?.toIso8601String(),
    };
  }

  factory Referral.fromMap(Map<String, dynamic> map) {
    return Referral(
      id: map['id'] ?? '',
      referrerId: map['referrer_id'] ?? '',
      refereeId: map['referee_id'],
      code: map['code'] ?? '',
      isUsed: map['is_used'] ?? false,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      usedAt: map['used_at'] != null ? DateTime.tryParse(map['used_at']) : null,
    );
  }
}
