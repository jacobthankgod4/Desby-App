import 'package:desby_app/core/providers/user_preferences_provider.dart';
import 'package:desby_app/core/storage/local_storage.dart';
import 'package:desby_app/core/storage/storage_keys.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desby_app/theme/colors.dart';
import 'package:desby_app/theme/spacing.dart';
import 'package:desby_app/theme/typography.dart';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// One stop of the first-run tour.
///
/// The tour explains the *workflow*, not the buttons. A client who understands
/// "this is a conversation with the tailor, in five short steps" is better
/// served than one being told which rectangle to press.
class JourneyTourStop {
  const JourneyTourStop({
    required this.keyTarget,
    required this.title,
    required this.body,
    this.align = ContentAlign.bottom,
    this.alignSkip = Alignment.topLeft,
  });

  final GlobalKey? keyTarget;
  final String title;
  final String body;
  final ContentAlign align;
  final Alignment alignSkip;
}

/// The first-time tour for the guided request journey.
///
/// Persistence follows the pattern already proven in `checkout_page.dart`:
/// completion is written to `users.preferences` so it survives reinstalls and
/// follows the client across devices, and both Skip and Finish record it so the
/// tour never reappears once dismissed.
///
/// If the preference read fails the tour is *skipped*, not shown. A tour that
/// traps someone whose network blipped is worse than no tour.
class RequestJourneyTour {
  RequestJourneyTour._();

  static const String preferenceKey = 'requestJourneyTourCompleted';

  /// Whether to show the tour.
  ///
  /// Industry-standard ordering, and deliberately the opposite of the previous
  /// version:
  ///
  /// 1. **Local flag first.** "Has this person seen it" is a fact about the
  ///    device, not about the server. Reading it needs no network, so the
  ///    decision is available offline and on first paint.
  /// 2. **Server flag second**, purely to sync across devices. If it is
  ///    unreachable we carry on with the local answer.
  /// 3. **Unknown means show.** The previous code returned `false` on any error,
  ///    which silently and permanently denied the tour after a single flaky
  ///    request — the same user would see it on Wi-Fi and not on mobile data,
  ///    and nobody would ever report a feature that quietly stopped existing.
  ///    Showing once is cheap and recoverable; never showing is not.
  /// 4. **Skip is only ever a deliberate act** — the marker is written the
  ///    moment the tour is dismissed, locally first, so it cannot reappear even
  ///    if the server write fails.
  /// The decision, separated from the IO so it can be tested and reasoned about.
  ///
  /// Returns true when the tour should be shown.
  ///
  /// The asymmetry that matters: showing unnecessarily is mildly irritating and
  /// self-corrects (the client finishes it and it stops); failing to show when
  /// needed silently breaks a feature that nobody will ever report. So every
  /// ambiguous state resolves towards showing.
  static bool resolveShouldShow({
    required bool localSeen,
    required bool? serverSeen,
  }) {
    if (localSeen) return false;      // authoritative, and needs no network
    if (serverSeen == true) return false;  // dismissed on another device
    return true;                      // unknown -> show once
  }

  static Future<bool> shouldShow() async {
    bool localSeen = false;
    try {
      localSeen = localStorage.get(StorageKeys.requestJourneyTourSeen) == true;
    } catch (e) {
      debugPrint('[JOURNEY_TOUR] local read failed: $e');
    }

    bool? serverSeen;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final response = await Supabase.instance.client
            .from('users')
            .select('preferences')
            .eq('id', userId)
            .maybeSingle();
        final prefs = response?['preferences'];
        if (prefs is Map) serverSeen = prefs[preferenceKey] == true;
      }
    } catch (e) {
      debugPrint('[JOURNEY_TOUR] server sync unavailable (showing anyway): $e');
    }

    final show = resolveShouldShow(localSeen: localSeen, serverSeen: serverSeen);
    if (!show && !localSeen && serverSeen == true) {
      // Dismissed on another device — remember it here so we never ask again.
      await _rememberSeenLocally();
    }
    return show;
  }

  static Future<void> _rememberSeenLocally() async {
    try {
      await localStorage.save(StorageKeys.requestJourneyTourSeen, true);
    } catch (e) {
      debugPrint('[JOURNEY_TOUR] could not persist local flag: $e');
    }
  }

  /// Record the tour as seen. Local first and awaited, then the server.
  ///
  /// Order matters: the local write is what guarantees the tour never nags
  /// again even when the user is offline or the request 401s.
  static Future<void> markComplete() async {
    await _rememberSeenLocally();
    try {
      await updateUserPreferences({preferenceKey: true});
    } catch (e) {
      debugPrint('[JOURNEY_TOUR] server flag not saved (local flag stands): $e');
    }
  }

  /// Renders the tour against whatever of [stops] currently has a mounted
  /// context. Steps not yet revealed are skipped rather than showing an empty
  /// spotlight, which is what stops the tour pointing at nothing.
  static bool show(
    BuildContext context, {
    required List<JourneyTourStop> stops,
    required Future<void> Function() onFinish,
  }) {
    final targets = <TargetFocus>[];
    for (final stop in stops) {
      if (stop.keyTarget?.currentContext == null) continue;
      targets.add(
        TargetFocus(
          identify: stop.keyTarget.toString(),
          keyTarget: stop.keyTarget!,
          alignSkip: stop.alignSkip,
          contents: [
            TargetContent(
              align: stop.align,
              child: _TourCard(title: stop.title, body: stop.body),
            ),
          ],
        ),
      );
    }
    if (targets.isEmpty) return false;

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.85,
      paddingFocus: 14,
      // Keep the tour's own controls clear of the shell sidebar, which already
      // owns the left edge and has its own navigation there.
      useSafeArea: true,
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
      hideSkip: false,
      // Always leave the same way they came in.
      onFinish: onFinish,
      onSkip: () {
        onFinish();
        return true;
      },
    ).show(context: context);
    return true;
  }
}

/// Tour card, styled in Desby's brand rather than the library default.
class _TourCard extends StatelessWidget {
  const _TourCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        color: context.colors.dialogBg,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: context.colors.borderFocused, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  size: 16, color: context.colors.borderFocused),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.subtitle1.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: AppTypography.caption
                .copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
