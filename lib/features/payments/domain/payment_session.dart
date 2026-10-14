import '../../../core/storage/local_storage.dart';

/// Tracks an in-flight payment so a page reload cannot start a second charge
/// for the same order.
///
/// Payment providers are keyed by a transaction reference the client supplies,
/// so recording that reference before the redirect and refusing to mint a new
/// one for the same order turns "reload mid-payment" from a double-charge risk
/// into a resumable state.
class PaymentSession {
  const PaymentSession({
    required this.orderId,
    required this.txRef,
    required this.startedAtMs,
  });

  final String orderId;
  final String txRef;
  final int startedAtMs;

  /// A session older than this is treated as abandoned so a customer who
  /// genuinely abandoned a payment weeks ago is not locked out forever.
  static const Duration maxAge = Duration(days: 1);

  static String _key(String orderId) => 'payment_session_$orderId';

  /// Returns the active session for [orderId], or null when there is none.
  static PaymentSession? activeFor(String orderId) {
    if (orderId.isEmpty) return null;
    final raw = localStorage.get(_key(orderId), defaultValue: null);
    if (raw is! String || raw.isEmpty) return null;

    final parts = raw.split('|');
    if (parts.length < 3) {
      clear(orderId);
      return null;
    }
    final session = PaymentSession(
      orderId: orderId,
      txRef: parts[0],
      startedAtMs: int.tryParse(parts[1]) ?? 0,
    );
    if (DateTime.now().millisecondsSinceEpoch - session.startedAtMs >
        maxAge.inMilliseconds) {
      clear(orderId);
      return null;
    }
    return session;
  }

  /// Records a started payment against [orderId]. The first reference wins so a
  /// second attempt cannot silently replace the one the provider already has.
  static void record(String orderId, String txRef) {
    if (orderId.isEmpty || txRef.isEmpty) return;
    if (activeFor(orderId) != null) return;
    localStorage.save(
      _key(orderId),
      '$txRef|${DateTime.now().millisecondsSinceEpoch}|1',
    );
  }

  static void clear(String orderId) {
    if (orderId.isEmpty) return;
    localStorage.delete(_key(orderId));
  }
}