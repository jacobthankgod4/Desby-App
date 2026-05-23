import 'package:flutter_test/flutter_test.dart';
import 'package:desby_app/features/apprenticeship/domain/entities/apprenticeship.dart';

void main() {
  group('Apprenticeship Entity Tests', () {
    test('should support equality comparison', () {
      final now = DateTime.now();
      final a1 = Apprenticeship(
        id: '1',
        tailorId: 't1',
        apprenticeId: 'a1',
        status: ApprenticeshipStatus.active,
        progress: 0.5,
        startDate: now,
      );
      final a2 = Apprenticeship(
        id: '1',
        tailorId: 't1',
        apprenticeId: 'a1',
        status: ApprenticeshipStatus.active,
        progress: 0.5,
        startDate: now,
      );

      expect(a1, equals(a2));
    });

    test('copyWith should return a new object with updated values', () {
      final now = DateTime.now();
      final a1 = Apprenticeship(
        id: '1',
        tailorId: 't1',
        apprenticeId: 'a1',
        status: ApprenticeshipStatus.active,
        progress: 0.5,
        startDate: now,
      );
      
      final updated = a1.copyWith(progress: 0.8, status: ApprenticeshipStatus.completed);

      expect(updated.progress, 0.8);
      expect(updated.status, ApprenticeshipStatus.completed);
      expect(updated.id, a1.id);
    });
  });
}
