import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/session_manager.dart';

/// User Activity Tracker
/// Tracks user activity and resets session timeout
class UserActivityTracker extends ConsumerStatefulWidget {
  final Widget child;
  // Extended inactivity timeout to 2 hours for better UX
  // Users should not be logged out during typical app usage
  final Duration inactivityTimeout;

  const UserActivityTracker({
    super.key,
    required this.child,
    this.inactivityTimeout = const Duration(hours: 2),
  });

  @override
  ConsumerState<UserActivityTracker> createState() =>
      _UserActivityTrackerState();
}

class _UserActivityTrackerState extends ConsumerState<UserActivityTracker> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onUserActivity,
      onPanDown: (_) => _onUserActivity(),
      child: MouseRegion(
        onEnter: (_) => _onUserActivity(),
        onHover: (_) => _onUserActivity(),
        child: widget.child,
      ),
    );
  }

  void _onUserActivity() {
    final sessionManager = ref.read(sessionManagerProvider);
    sessionManager.resetSessionTimer();
  }
}
