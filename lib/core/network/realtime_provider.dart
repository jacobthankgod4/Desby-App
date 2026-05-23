import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'realtime_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeServiceImpl();
  
  // Connect/Disconnect based on auth state
  ref.listen(isAuthenticatedProvider, (previous, next) {
    if (next) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        service.connect(user.id);
      }
    } else {
      service.disconnect();
    }
  });

  return service;
});

final realtimeEventStreamProvider = StreamProvider<RealtimeEvent>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  return service.eventStream;
});
