import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Single source of truth for text-to-speech across the app.
///
/// Previously each page configured its own [FlutterTts] instance:
///   - `ai_body_scan_page`      -> `setLanguage('en-US')`, rate 0.45
///   - `ai_camera_capture_page` -> rate 0.5, **no language set at all**
///
/// Neither selected a voice, so the OS default was used, which differs by
/// device and browser. This service pins the language, the rate and a
/// preferred voice so every surface sounds the same.
class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();

  bool _configured = false;
  bool _isSpeaking = false;
  String? _lastText;
  DateTime? _lastSpokenAt;

  /// Preferred voices, best-first. Matched case-insensitively against the
  /// voices the platform reports. Kept to widely available English voices so
  /// this degrades gracefully on devices that expose none of them.
  static const _preferredVoiceNames = <String>[
    'Samantha',
    'Google UK English Female',
    'Google US English',
    'Microsoft Aria',
    'Microsoft Zira',
    'Karen',
    'Daniel',
    'Serena',
  ];

  /// Whether the engine is currently voicing text.
  ///
  /// Tracked from the engine's completion handler rather than by awaiting
  /// speech to finish, so callers can skip a new prompt instead of queueing it
  /// on top of the utterance already playing.
  bool get isSpeaking => _isSpeaking;

  /// Configures the engine. Safe to call repeatedly; only the first call does
  /// work.
  Future<void> configure() async {
    if (_configured) return;
    _configured = true;

    try {
      await _tts.setLanguage('en-GB');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _applyPreferredVoice();

      // The engine has no isSpeaking getter we can trust across platforms, so
      // it is tracked here. Without this, rapid prompts during pose alignment
      // stack up and the user hears a stutter.
      _tts.setCompletionHandler(() => _isSpeaking = false);
      _tts.setCancelHandler(() => _isSpeaking = false);
      _tts.setErrorHandler((_) => _isSpeaking = false);
    } catch (e) {
      // A missing or restricted engine must not break the flow the speech is
      // supporting (for example the camera countdown).
      debugPrint('[TTS] configuration failed: $e');
    }
  }

  /// Picks the first preferred voice the platform actually offers.
  Future<void> _applyPreferredVoice() async {
    final voices = await _tts.getVoices;
    if (voices is! List || voices.isEmpty) return;

    final available = voices.whereType<Map>().toList();
    if (available.isEmpty) return;

    for (final wanted in _preferredVoiceNames) {
      final match = available.where((v) {
        final name = '${v['name'] ?? ''}';
        return name.toLowerCase().contains(wanted.toLowerCase());
      });
      if (match.isNotEmpty) {
        final voice = match.first;
        await _tts.setVoice({
          'name': voice['name'],
          'locale': voice['locale'],
        });
        debugPrint('[TTS] voice: ${voice['name']} (${voice['locale']})');
        return;
      }
    }

    debugPrint('[TTS] no preferred voice available; using platform default');
  }

  /// Speaks [text], configuring the engine first if needed.
  ///
  /// Skips the prompt when the engine is already speaking, unless [force] is
  /// set — that is what stops the capture screen from stacking cues while the
  /// user is still holding a pose. Repeats of [text] within [debounce] are
  /// also ignored, because the alignment loop re-emits the same message every
  /// frame it loses pose.
  Future<void> speak(
    String text, {
    bool force = false,
    Duration debounce = const Duration(seconds: 3),
  }) async {
    if (text.trim().isEmpty) return;
    await configure();

    if (!force) {
      if (_isSpeaking) return;

      final now = DateTime.now();
      if (text == _lastText &&
          _lastSpokenAt != null &&
          now.difference(_lastSpokenAt!) < debounce) {
        return;
      }
    }

    try {
      if (force) await _tts.stop();
      _isSpeaking = true;
      _lastText = text;
      _lastSpokenAt = DateTime.now();
      // awaitSpeakCompletion(false) returns immediately; completion is
      // signalled through the handler registered in configure().
      await _tts.awaitSpeakCompletion(false);
      await _tts.speak(text);
    } catch (e) {
      _isSpeaking = false;
      debugPrint('[TTS] speak failed: $e');
    }
  }

  Future<void> stop() async {
    _isSpeaking = false;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}