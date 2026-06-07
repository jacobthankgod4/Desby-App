import 'package:equatable/equatable.dart';

class UberStructuredAddress extends Equatable {
  final List<String> streetAddress;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  const UberStructuredAddress({
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
  });

  Map<String, dynamic> toJson() => {
        'street_address': streetAddress,
        'city': city,
        'state': state,
        'zip_code': zipCode,
        'country': country,
      };

  @override
  List<Object?> get props => [streetAddress, city, state, zipCode, country];
}

class UberDimensions extends Equatable {
  final int length; // cm
  final int height; // cm
  final int depth; // cm

  const UberDimensions({
    required this.length,
    required this.height,
    required this.depth,
  });

  Map<String, dynamic> toJson() => {
        'length': length,
        'height': height,
        'depth': depth,
      };

  @override
  List<Object?> get props => [length, height, depth];
}

class UberManifestItem extends Equatable {
  final String name;
  final int quantity;
  final String size; // small, medium, large, xlarge
  final UberDimensions dimensions;
  final int price; // In cents
  final int weight; // In grams

  const UberManifestItem({
    required this.name,
    required this.quantity,
    this.size = 'small',
    required this.dimensions,
    required this.price,
    required this.weight,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'size': size,
        'dimensions': dimensions.toJson(),
        'price': price,
        'weight': weight,
      };

  @override
  List<Object?> get props => [name, quantity, size, dimensions, price, weight];
}

class UberVerificationRequirement extends Equatable {
  final bool signature;
  final bool picture;
  final bool identification; // min_age check
  final bool barcodes;

  const UberVerificationRequirement({
    this.signature = false,
    this.picture = true, // Default to true for Desby safety
    this.identification = false,
    this.barcodes = false,
  });

  Map<String, dynamic> toJson() => {
        'signature': signature,
        'picture': picture,
        'identification': identification,
        'barcodes': barcodes,
      };

  @override
  List<Object?> get props => [signature, picture, identification, barcodes];
}

class UberDeliveryQuote extends Equatable {
  final String id; // Starts with dqt_
  final int fee; // In cents
  final String currencyType;
  final DateTime expiresAt;
  final int pickupDuration; // Minutes
  final int totalDuration; // Minutes
  final DateTime dropoffEta;

  const UberDeliveryQuote({
    required this.id,
    required this.fee,
    required this.currencyType,
    required this.expiresAt,
    required this.pickupDuration,
    required this.totalDuration,
    required this.dropoffEta,
  });

  @override
  List<Object?> get props => [
        id,
        fee,
        currencyType,
        expiresAt,
        pickupDuration,
        totalDuration,
        dropoffEta,
      ];
}
