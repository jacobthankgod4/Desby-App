import 'package:equatable/equatable.dart';

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
  });

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
      ];
}
