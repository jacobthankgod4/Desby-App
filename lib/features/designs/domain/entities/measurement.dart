import 'package:equatable/equatable.dart';

class MeasurementField extends Equatable {
  final String label;
  final double value;
  final String unit; // 'inch' or 'cm'

  const MeasurementField({
    required this.label,
    required this.value,
    this.unit = 'inch',
  });

  @override
  List<Object?> get props => [label, value, unit];
}

class ClientMeasurements extends Equatable {
  final String id;
  final String clientId;
  final List<MeasurementField> fields;
  final DateTime lastUpdated;

  const ClientMeasurements({
    required this.id,
    required this.clientId,
    required this.fields,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [id, clientId, fields, lastUpdated];
}
