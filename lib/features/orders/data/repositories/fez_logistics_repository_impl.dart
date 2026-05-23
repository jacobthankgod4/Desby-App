import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/fez_logistics_service.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/logistics_repository.dart';

class FezLogisticsRepositoryImpl implements LogisticsRepository {
  final FezLogisticsService _fezService;
  final FirebaseFirestore _firestore;

  FezLogisticsRepositoryImpl(this._fezService, this._firestore);

  @override
  Future<Result<String>> summonRider(OrderEntity order) async {
    try {
      // 1. Fetch Client Profile for accurate address/contact
      final clientDoc = await _firestore.collection('users').doc(order.clientId).get();
      if (!clientDoc.exists) return Failure(ServerFailure(message: 'Client Profile missing. Logistics aborted.'));
      
      final clientData = clientDoc.data()!;
      final String address = clientData['address'] ?? clientData['businessAddress'] ?? 'No Address';
      final String phone = clientData['phone'] ?? clientData['businessPhone'] ?? '08000000000';
      final String state = clientData['state'] ?? clientData['businessState'] ?? 'Lagos';

      // 2. Authenticate with Fez
      final authed = await _fezService.authenticate('G-4568-3493', 'KingOne123#');
      if (!authed) return Failure(ServerFailure(message: 'Fez Logistics Authentication Failed'));

      // 3. Prepare Order Data for Fez
      final fezOrderData = {
        "recipientAddress": address,
        "recipientState": state,
        "recipientName": order.clientName,
        "recipientPhone": phone,
        "uniqueID": order.id,
        "BatchID": "DESBY_${DateTime.now().day}${DateTime.now().month}",
        "valueOfItem": order.totalAmount.toString(),
        "weight": 2, 
        "itemDescription": "Fashion Masterpiece: ${order.items.isNotEmpty ? order.items.first.garmentType : 'Bespoke Item'}",
      };

      // 4. Create Fez Order
      final fezOrderNo = await _fezService.createOrder(fezOrderData);
      
      if (fezOrderNo != null) {
        // 5. Update internal order status to materialsInTransit
        await _firestore.collection('orders').doc(order.id).update({
          'status': OrderStatus.materialsInTransit.name,
          'fezOrderNo': fezOrderNo,
          'requiresDispatch': true,
        });
        
        return Success(fezOrderNo);
      }
      
      return Failure(ServerFailure(message: 'Fez Order Creation Failed'));
    } catch (e) {
      return Failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> trackDelivery(String fezOrderNo) async {
    try {
      final data = await _fezService.trackOrder(fezOrderNo);
      if (data != null) return Success(data);
      return Failure(ServerFailure(message: 'Tracking Info Unavailable'));
    } catch (e) {
      return Failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<double>> estimateCost(String destinationState) async {
    try {
      final data = await _fezService.getDeliveryCost(state: destinationState);
      if (data != null) {
        final baseCost = (data['totalCost'] as num).toDouble();
        // DESBY REVENUE ARCHITECTURE: Add ₦500 margin
        final totalWithMargin = baseCost + 500.0;
        return Success(totalWithMargin);
      }
      return Failure(ServerFailure(message: 'Cost Estimation Failed'));
    } catch (e) {
      return Failure(ServerFailure(message: e.toString()));
    }
  }
}
