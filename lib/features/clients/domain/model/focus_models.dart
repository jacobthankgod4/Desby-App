class FocusTarget {
  final double x;
  final double y;
  final double z;

  const FocusTarget(this.x, this.y, this.z);
}

class FocusOrbit {
  final double theta;
  final double phi;
  final double radius;

  const FocusOrbit(this.theta, this.phi, this.radius);
}

class FocusProfile {
  final FocusTarget target;
  final FocusOrbit orbit;
  final String bucket;

  const FocusProfile({
    required this.target,
    required this.orbit,
    required this.bucket,
  });
}

class FocusResolution {
  final String canonicalKey;
  final FocusProfile profile;
  final bool usedFallback;
  final double confidence;

  const FocusResolution({
    required this.canonicalKey,
    required this.profile,
    required this.usedFallback,
    required this.confidence,
  });
}
