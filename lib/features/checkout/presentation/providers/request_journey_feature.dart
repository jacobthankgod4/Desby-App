import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Feature gating for the guided request journey.
///
/// The journey is **additive**: it is a new route alongside the existing
/// booking chain, not a replacement. The legacy path
/// (booking_cart → price_estimation → checkout) is untouched and still
/// reachable, so turning this off is a pure rollback with no data implications —
/// both flows write to the same, now-correct `orders` schema.
///
/// Read once at startup from the environment so a rollout can be flipped
/// without a code change:
///
/// ```
/// DESBY_REQUEST_JOURNEY=1   # enable
/// DESBY_REQUEST_JOURNEY=0   # fall back to the legacy chain
/// ```
class RequestJourneyFeature {
  RequestJourneyFeature._();

  static bool _cached = false;
  static bool _loaded = false;

  static bool get enabled {
    if (!_loaded) _cached = _read();
    return _cached;
  }

  static bool _read() {
    // Default on: the legacy chain is still one variable away, and shipping the
    // fix but never exposing it would leave every client on the worse flow.
    final raw = _env('DESBY_REQUEST_JOURNEY');
    if (raw == null || raw.isEmpty) return true;
    const truthy = {'1', 'true', 'yes', 'on'};
    return truthy.contains(raw.toLowerCase());
  }

  static String? _env(String key) {
    try {
      return dotenv.env[key];
    } catch (_) {
      // dotenv not initialised (unit tests) — fall back to defaults.
      return null;
    }
  }

  /// Test seam: lets a test pin the flag without touching the process env.
  static void overrideForTesting(bool? value) {
    _cached = value ?? false;
    _loaded = value != null;
  }
}

/// Builds the journey route for a tailor profile — Scenario A.
///
/// No product is known, so the flow opens by asking what they want made.
Map<String, dynamic> tailorProfileJourneyArgs({
  required String tailorId,
  String? tailorName,
  String? tailorAvatarUrl,
}) =>
    {
      'tailorId': tailorId,
      'tailorName': tailorName,
      'tailorAvatarUrl': tailorAvatarUrl,
    };

/// Builds the journey route for a design — Scenario B.
///
/// Size, colour and quantity chosen on the product page are carried through.
/// The legacy flow received all of these and then discarded them.
Map<String, dynamic> designJourneyArgs({
  required String designId,
  required String tailorId,
  String? tailorName,
  String? tailorAvatarUrl,
  String? title,
  String? category,
  List<String> imageUrls = const [],
  double? price,
  String? selectedSize,
  String? selectedColour,
  int quantity = 1,
}) =>
    {
      'tailorId': tailorId,
      'tailorName': tailorName,
      'tailorAvatarUrl': tailorAvatarUrl,
      'designId': designId,
      'productTitle': title,
      'productCategory': category,
      'productImageUrls': imageUrls,
      'productPrice': price,
      'selectedSize': selectedSize,
      'selectedColour': selectedColour,
      'quantity': quantity,
    };

/// Route name. Kept distinct from `/booking-cart` so both can coexist.
const String requestJourneyRoute = '/request-journey';

/// Where a caller should open checkout for its scenario.
///
/// Scenario A (tailor profile, no product) and Scenario B (a design is already
/// chosen) both land on the journey when it is enabled. When it is not, they
/// fall back to the legacy booking chain, which still works after the order
/// persistence fixes.
String checkoutRouteFor({bool hasProduct = false}) =>
    RequestJourneyFeature.enabled ? requestJourneyRoute : '/booking-cart';

String checkoutRouteForTailorProfile() =>
    RequestJourneyFeature.enabled ? requestJourneyRoute : '/booking-cart';

String checkoutRouteForDesign() =>
    RequestJourneyFeature.enabled ? requestJourneyRoute : '/booking-cart';
