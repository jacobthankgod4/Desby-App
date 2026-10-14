import '../../../core/constants/nigeria_lga_data.dart';

/// Derives a Nigerian state from a free-text delivery address.
///
/// Dispatch surfaces need a state to price against; defaulting to Lagos meant
/// every non-Lagos order was quoted the wrong fee. Falls back to Lagos only when
/// the address genuinely names no known state, which is the same behaviour the
/// courier payload builder uses.
String deriveDeliveryState(String? address) {
  final normalized = (address ?? '').toLowerCase();
  for (final state in NigeriaLgaData.states) {
    if (normalized.contains(state.toLowerCase())) return state;
  }
  return 'Lagos';
}
