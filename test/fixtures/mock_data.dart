/// Mock Data for Testing
class MockData {
  MockData._(); // Private constructor

  // Mock User Data
  static const mockUserId = 'user_123';
  static const mockUserEmail = 'test@desby.app';
  static const mockUserName = 'Test User';
  static const mockUserPhone = '+1-555-0123';

  static Map<String, dynamic> get mockUserJson => {
    'id': mockUserId,
    'email': mockUserEmail,
    'name': mockUserName,
    'phone': mockUserPhone,
    'createdAt': '2024-01-01T00:00:00Z',
    'updatedAt': '2024-01-01T00:00:00Z',
  };

  // Mock Client Data
  static const mockClientId = 'client_123';
  static const mockClientName = 'John Doe';
  static const mockClientEmail = 'client@example.com';
  static const mockClientPhone = '+1-555-0456';

  static Map<String, dynamic> get mockClientJson => {
    'id': mockClientId,
    'name': mockClientName,
    'email': mockClientEmail,
    'phone': mockClientPhone,
    'measurements': {
      'chest': 38,
      'waist': 32,
      'length': 30,
    },
    'createdAt': '2024-01-01T00:00:00Z',
  };

  static List<Map<String, dynamic>> get mockClientsList => [
    mockClientJson,
    {
      'id': 'client_124',
      'name': 'Jane Smith',
      'email': 'jane@example.com',
      'phone': '+1-555-0789',
      'measurements': {
        'chest': 34,
        'waist': 28,
        'length': 28,
      },
      'createdAt': '2024-01-02T00:00:00Z',
    },
  ];

  // Mock Order Data
  static const mockOrderId = 'order_123';
  static const mockOrderStatus = 'in_progress';
  static const mockOrderTotal = 150.00;

  static Map<String, dynamic> get mockOrderJson => {
    'id': mockOrderId,
    'clientId': mockClientId,
    'status': mockOrderStatus,
    'items': [
      {
        'id': 'item_1',
        'name': 'Shirt',
        'quantity': 1,
        'price': 50.00,
      },
      {
        'id': 'item_2',
        'name': 'Pants',
        'quantity': 1,
        'price': 100.00,
      },
    ],
    'total': mockOrderTotal,
    'createdAt': '2024-01-01T00:00:00Z',
    'dueDate': '2024-01-15T00:00:00Z',
  };

  static List<Map<String, dynamic>> get mockOrdersList => [
    mockOrderJson,
    {
      'id': 'order_124',
      'clientId': 'client_124',
      'status': 'completed',
      'items': [
        {
          'id': 'item_3',
          'name': 'Dress',
          'quantity': 1,
          'price': 120.00,
        },
      ],
      'total': 120.00,
      'createdAt': '2024-01-02T00:00:00Z',
      'dueDate': '2024-01-10T00:00:00Z',
    },
  ];

  // Mock Design Data
  static const mockDesignId = 'design_123';
  static const mockDesignName = 'Classic Shirt';

  static Map<String, dynamic> get mockDesignJson => {
    'id': mockDesignId,
    'name': mockDesignName,
    'description': 'A classic shirt design',
    'imageUrl': 'https://example.com/design.jpg',
    'category': 'shirts',
    'createdAt': '2024-01-01T00:00:00Z',
  };

  // Mock Fabric Data
  static const mockFabricId = 'fabric_123';
  static const mockFabricName = 'Cotton Blend';
  static const mockFabricPrice = 15.00;

  static Map<String, dynamic> get mockFabricJson => {
    'id': mockFabricId,
    'name': mockFabricName,
    'type': 'cotton',
    'color': 'blue',
    'price': mockFabricPrice,
    'stock': 100,
    'supplierId': 'supplier_123',
    'createdAt': '2024-01-01T00:00:00Z',
  };

  // Mock Authentication Data
  static const mockAccessToken = 'mock_access_token_123';
  static const mockRefreshToken = 'mock_refresh_token_123';

  static Map<String, dynamic> get mockAuthJson => {
    'accessToken': mockAccessToken,
    'refreshToken': mockRefreshToken,
    'expiresIn': 3600,
    'tokenType': 'Bearer',
  };

  // Mock Error Response
  static Map<String, dynamic> get mockErrorJson => {
    'success': false,
    'message': 'An error occurred',
    'code': 'ERROR_CODE',
    'errors': {
      'field': 'Field error message',
    },
  };

  // Mock Pagination Response
  static Map<String, dynamic> get mockPaginationJson => {
    'success': true,
    'data': {
      'items': mockClientsList,
      'pagination': {
        'page': 1,
        'pageSize': 20,
        'total': 2,
        'totalPages': 1,
      },
    },
  };

  // Mock Connectivity Status
  static const mockConnectivityOnline = 'wifi';
  static const mockConnectivityOffline = 'none';

  // Mock Device Info
  static Map<String, dynamic> get mockDeviceInfoJson => {
    'appName': 'Desby OS',
    'packageName': 'com.desby.app',
    'version': '1.0.0',
    'buildNumber': '1',
    'buildSignature': 'mock_signature',
  };

  // Mock Notification
  static const mockNotificationId = 'notification_123';
  static const mockNotificationTitle = 'Order Ready';
  static const mockNotificationBody = 'Your order is ready for pickup';

  static Map<String, dynamic> get mockNotificationJson => {
    'id': mockNotificationId,
    'title': mockNotificationTitle,
    'body': mockNotificationBody,
    'type': 'order_update',
    'data': {
      'orderId': mockOrderId,
    },
    'createdAt': '2024-01-01T00:00:00Z',
    'read': false,
  };
}
