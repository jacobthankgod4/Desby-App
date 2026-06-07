import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/uber_logistics.dart';
import '../../domain/repositories/uber_logistics_repository.dart' as domain;
import '../models/uber_logistics_models.dart';
import 'uber_auth_interceptor.dart';
import '../../domain/repositories/uber_auth_repository.dart';

class UberLogisticsRepositoryImpl implements domain.UberLogisticsRepository {
  final Dio _dio;
  final String _customerId;
  final FirebaseFirestore _firestore;

  UberLogisticsRepositoryImpl({
    required UberAuthRepository authRepository,
    required String customerId,
    required FirebaseFirestore firestore,
  })  : _customerId = customerId,
        _firestore = firestore,
        _dio = Dio(BaseOptions(baseUrl: 'https://api.uber.com/v1')) {
    _dio.interceptors.add(UberAuthInterceptor(authRepository));
  }

  @override
  Future<Either<Failure, UberDeliveryQuote>> getQuote({
    required UberStructuredAddress pickup,
    required UberStructuredAddress dropoff,
  }) async {
    try {
      final response = await _dio.post(
        '/customers/$_customerId/delivery_quotes',
        data: {
          'pickup_address': jsonEncode(pickup.toJson()),
          'dropoff_address': jsonEncode(dropoff.toJson()),
        },
      );
      
      final model = UberDeliveryQuoteModel.fromJson(response.data);
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: _parseUberError(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createDelivery({
    required String quoteId,
    required String pickupName,
    required UberStructuredAddress pickupAddress,
    required String pickupPhoneNumber,
    required String dropoffName,
    required UberStructuredAddress dropoffAddress,
    required String dropoffPhoneNumber,
    required List<UberManifestItem> items,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _dio.post(
        '/customers/$_customerId/deliveries',
        data: {
          'quote_id': quoteId,
          'pickup_name': pickupName,
          'pickup_address': jsonEncode(pickupAddress.toJson()),
          'pickup_phone_number': pickupPhoneNumber,
          'dropoff_name': dropoffName,
          'dropoff_address': jsonEncode(dropoffAddress.toJson()),
          'dropoff_phone_number': dropoffPhoneNumber,
          'manifest_items': items.map((i) => i.toJson()).toList(),
          'idempotency_key': idempotencyKey,
        },
      );

      final deliveryId = response.data['id'];
      
      // Log to Firestore for ledger tracking
      await _firestore.collection('logistics_transactions').doc(deliveryId).set({
        'uber_delivery_id': deliveryId,
        'quote_id': quoteId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'idempotency_key': idempotencyKey,
      });

      return Right(deliveryId);
    } on DioException catch (e) {
      return Left(ServerFailure(message: _parseUberError(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, domain.UberDeliveryStatus>> getStatus(String deliveryId) async {
    try {
      final response = await _dio.get('/customers/$_customerId/deliveries/$deliveryId');
      final model = UberDeliveryStatusModel.fromJson(response.data);
      
      final status = domain.UberDeliveryStatus(
        id: model.id,
        current: model.status,
        courierImminent: model.courierImminent,
        trackingUrl: model.trackingUrl,
      );

      // Async log status change to Firestore
      _logStatusUpdate(status);

      return Right(status);
    } on DioException catch (e) {
      return Left(ServerFailure(message: _parseUberError(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelDelivery(String deliveryId, String reason) async {
    try {
      await _dio.post(
        '/customers/$_customerId/deliveries/$deliveryId/cancel',
        data: {'cancelation_reason': reason},
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(message: _parseUberError(e)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  void _logStatusUpdate(domain.UberDeliveryStatus status) {
    _firestore.collection('logistics_transactions').doc(status.id).update({
      'status': status.current,
      'courierImminent': status.courierImminent,
      'last_updated': FieldValue.serverTimestamp(),
    }).catchError((e) => print('Firestore log error: $e'));
  }

  String _parseUberError(DioException e) {
    if (e.response?.data != null && e.response?.data is Map) {
      return e.response!.data['message'] ?? 'Uber API Error';
    }
    return e.message ?? 'Unknown Connection Error';
  }
}
