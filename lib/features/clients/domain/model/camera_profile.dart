import 'package:equatable/equatable.dart';

/// Defines the framing and orientation for focusing on a specific measurement.
/// Part of Step 4.1: Camera Profile Engine.
class CameraProfile extends Equatable {
  final String id;
  final double targetX;
  final double targetY;
  final double targetZ;
  final double orbitTheta; // Yaw in degrees
  final double orbitPhi;   // Pitch in degrees
  final double radius;     // Distance in meters
  final double fov;        // Field of view
  final int transitionMs;  // Animation duration

  const CameraProfile({
    required this.id,
    required this.targetX,
    required this.targetY,
    required this.targetZ,
    required this.orbitTheta,
    required this.orbitPhi,
    required this.radius,
    this.fov = 30,
    this.transitionMs = 600,
  });

  @override
  List<Object?> get props => [
        id, targetX, targetY, targetZ, orbitTheta, orbitPhi, radius, fov, transitionMs,
      ];
}
