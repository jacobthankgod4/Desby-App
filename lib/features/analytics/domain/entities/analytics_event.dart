import 'package:equatable/equatable.dart';

class AnalyticsEvent extends Equatable {
  final String name;
  final DateTime timestamp;
  final Map<String, dynamic> parameters;

  const AnalyticsEvent({
    required this.name,
    required this.timestamp,
    this.parameters = const {},
  });

  @override
  List<Object?> get props => [name, timestamp, parameters];
}

class BusinessMetric extends Equatable {
  final String label;
  final double value;
  final String trend; // 'up', 'down', 'stable'
  final double changePercentage;

  const BusinessMetric({
    required this.label,
    required this.value,
    required this.trend,
    required this.changePercentage,
  });

  @override
  List<Object?> get props => [label, value, trend, changePercentage];
}
