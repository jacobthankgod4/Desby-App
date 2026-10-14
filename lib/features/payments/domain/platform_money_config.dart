import 'package:supabase_flutter/supabase_flutter.dart';

/// Who owns the fabric for a job.
enum FabricOwnership {
  /// Not answered yet.
  undecided,

  /// The client already owns their cloth. Material is never charged.
  clientSupplied,

  /// The tailor must source fabric. The tailor's `material_cost` applies.
  tailorSourced;

  static FabricOwnership fromBool(bool? value) => value == null
      ? FabricOwnership.undecided
      : (value ? FabricOwnership.clientSupplied : FabricOwnership.tailorSourced);

  bool? get asBool => switch (this) {
        FabricOwnership.undecided => null,
        FabricOwnership.clientSupplied => true,
        FabricOwnership.tailorSourced => false,
      };
}

/// The itemised money for one order.
///
/// Commission is charged on the *service* only. Material is pass-through (the
/// client may already own their cloth, and where they do not, the tailor is
/// simply reselling fabric rather than acting as the platform's agent for it),
/// and delivery belongs to the courier. Charging commission on either would tax
/// the two parts of the bill that are not tailoring work.
class OrderBreakdown {
  final double stitching;
  final double alteration;
  final double custom;
  final double express;
  final double material;
  final double delivery;

  const OrderBreakdown({
    this.stitching = 0,
    this.alteration = 0,
    this.custom = 0,
    this.express = 0,
    this.material = 0,
    this.delivery = 0,
  });

  /// The part the tailor actually charges for their time and skill.
  double get serviceSubtotal =>
      stitching + alteration + custom + express;

  /// What the client is billed.
  double get gross => serviceSubtotal + material + delivery;

  bool get isEmpty => gross <= 0;

  Map<String, dynamic> toJson() => {
        'stitching': stitching,
        'alteration': alteration,
        'custom': custom,
        'express': express,
        'material': material,
        'delivery': delivery,
      };
}

/// The outcome of splitting a gross amount.
class MoneySplit {
  final double gross;
  final double commission;
  final double paymentFee;
  final double tailorPayout;
  final double delivery;

  const MoneySplit({
    required this.gross,
    required this.commission,
    required this.paymentFee,
    required this.tailorPayout,
    required this.delivery,
  });
}

/// Single source of truth for platform money rules on the client.
///
/// The commission rate used to be a bare `0.10` literal repeated across the
/// checkout flow, so changing it meant finding every site and hoping none were
/// missed. It now lives in `platform_config`, which is also what the server uses
/// once payment computation moves into Edge Functions.
///
/// The fallback matters: checkout must still be able to record an order if the
/// config row cannot be read. Falling back to the current rate keeps behaviour
/// identical to before rather than charging a different amount at random.
class PlatformMoneyConfig {
  PlatformMoneyConfig._();

  static const double _fallbackCommissionRate = 0.015;
  static const double _fallbackPaymentFeePct = 0.014;
  static const double _fallbackDepositPct = 0.40;

  static double _commissionRate = _fallbackCommissionRate;
  static double _paymentFeePct = _fallbackPaymentFeePct;
  static double _depositPct = _fallbackDepositPct;
  static bool _materialChargesCommission = false;

  static double get commissionRate => _commissionRate;
  static double get paymentFeePct => _paymentFeePct;
  static double get depositPct => _depositPct;
  static double get balancePct => 1 - _depositPct;

  /// The share a Flutterwave subaccount should be configured with.
  ///
  /// Equals `1 - commission - payment_fee` of the GROSS. Flutterwave takes its
  /// transaction fee off the settlement before distributing the split, so if the
  /// subaccount were set to `1 - commission` the platform would quietly end up
  /// paying the 1.4% that is meant to come from the tailor's share.
  ///
  /// Rounded to 6dp, NOT to 2dp: this is a rate, not an amount of money, and
  /// cent-rounding would turn 97.1% into 97% and quietly overcharge the
  /// platform's take.
  static double get subaccountSplitValue {
    final value = 1 - _commissionRate - _paymentFeePct;
    return (value.clamp(0.0, 1.0) * 1000000).round() / 1000000;
  }

  /// Splits a gross amount into what each party receives.
  ///
  /// `delivery` is passed through to the courier and is not part of the
  /// tailor's payout. Commission is taken from the service subtotal only. The
  /// payment fee is charged to the tailor and is taken from the gross.
  static MoneySplit split(OrderBreakdown b) {
    final gross = round2(b.gross);
    final service = round2(b.serviceSubtotal);

    // Material is pass-through unless policy says otherwise.
    final commissionBase =
        _materialChargesCommission ? round2(service + b.material) : service;
    final commission = round2(commissionBase * _commissionRate);
    final paymentFee = round2(gross * _paymentFeePct);

    // The courier is paid the delivery fee directly, out of the gross.
    final tailorPool = round2(gross - b.delivery);
    final tailorPayout = round2(tailorPool - commission - paymentFee);

    return MoneySplit(
      gross: gross,
      commission: commission,
      paymentFee: paymentFee,
      tailorPayout: tailorPayout < 0 ? 0 : tailorPayout,
      delivery: round2(b.delivery),
    );
  }

  /// Convenience for callers that only have a gross amount and no breakdown.
  /// Treats the whole gross as service, which matches the pre-breakdown
  /// behaviour.
  static MoneySplit splitGross(double gross) =>
      split(OrderBreakdown(stitching: gross));

  /// The portion released to the tailor so work can begin, and the portion held
  /// until delivery. Only meaningful once staged payments are enabled.
  static ({double deposit, double balance}) stageSplit(double gross) {
    final deposit = round2(gross * _depositPct);
    return (deposit: deposit, balance: round2(gross - deposit));
  }

  static double round2(double value) => (value * 100).roundToDouble() / 100;

  /// Loads the current rules. Safe to call repeatedly; failures are non-fatal.
  static Future<void> load() async {
    try {
      final rows = await Supabase.instance.client
          .from('platform_config')
          .select('key, value')
          .inFilter('key', ['commission', 'deposit_split', 'material_policy']);

      for (final row in rows) {
        final value = row['value'];
        if (value is! Map) continue;
        final key = row['key'];

        if (key == 'commission') {
          final rate = value['rate'];
          if (rate is num && rate >= 0 && rate <= 0.5) {
            _commissionRate = rate.toDouble();
          }
          final fee = value['payment_fee_pct'];
          if (fee is num && fee >= 0 && fee <= 0.2) {
            _paymentFeePct = fee.toDouble();
          }
        } else if (key == 'deposit_split') {
          final pct = value['deposit_pct'];
          if (pct is num && pct > 0 && pct < 1) {
            _depositPct = pct.toDouble();
          }
        } else if (key == 'material_policy') {
          _materialChargesCommission = value['charges_commission'] == true;
        }
      }
    } catch (_) {
      // Keep the fallback. Recording an order at the previous rate is better
      // than failing the customer's checkout.
    }
  }
}