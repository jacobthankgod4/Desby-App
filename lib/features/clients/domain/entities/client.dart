import 'package:equatable/equatable.dart';

enum InviteStatus { none, pending, accepted, expired }

class Client extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final String address;
  final String gender; // MALE, FEMALE, UNISEX
  final Map<String, String>? measurements;
  final List<String> tags;
  final DateTime createdAt;
  final String? tailorId;
  final String? inviteToken;
  final InviteStatus inviteStatus;
  final Map<String, dynamic>? completedFields;
  final Map<String, dynamic>? stylePreferences;
  final Map<String, dynamic>? orderDetails;
  final DateTime? updatedAt;
  final DateTime? inviteSentAt;

  const Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    required this.address,
    required this.gender,
    this.measurements,
    this.tags = const [],
    required this.createdAt,
    this.tailorId,
    this.inviteToken,
    this.inviteStatus = InviteStatus.none,
    this.completedFields,
    this.stylePreferences,
    this.orderDetails,
    this.updatedAt,
    this.inviteSentAt,
  });

  bool get hasMeasurements => measurements != null && measurements!.isNotEmpty;

  bool get isInvitePending => inviteStatus == InviteStatus.pending;

  bool get isInviteAccepted => inviteStatus == InviteStatus.accepted;

  bool get hasInvite => inviteToken != null && inviteToken!.isNotEmpty;

  String? get inviteUrl => inviteToken != null
      ? 'https://desby.app/invite?token=$inviteToken'
      : null;

  Client copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? address,
    String? gender,
    Map<String, String>? measurements,
    List<String>? tags,
    DateTime? createdAt,
    String? tailorId,
    String? inviteToken,
    InviteStatus? inviteStatus,
    Map<String, dynamic>? completedFields,
    Map<String, dynamic>? stylePreferences,
    Map<String, dynamic>? orderDetails,
    DateTime? updatedAt,
    DateTime? inviteSentAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      measurements: measurements ?? this.measurements,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      tailorId: tailorId ?? this.tailorId,
      inviteToken: inviteToken ?? this.inviteToken,
      inviteStatus: inviteStatus ?? this.inviteStatus,
      completedFields: completedFields ?? this.completedFields,
      stylePreferences: stylePreferences ?? this.stylePreferences,
      orderDetails: orderDetails ?? this.orderDetails,
      updatedAt: updatedAt ?? this.updatedAt,
      inviteSentAt: inviteSentAt ?? this.inviteSentAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    profileImage,
    address,
    gender,
    measurements,
    tags,
    createdAt,
    tailorId,
    inviteToken,
    inviteStatus,
    completedFields,
    stylePreferences,
    orderDetails,
    updatedAt,
    inviteSentAt,
  ];
}
