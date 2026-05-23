/// Centralized API Endpoints
class ApiEndpoints {
  ApiEndpoints._(); // Private constructor

  // Base paths
  static const String _authPath = '/auth';
  static const String _usersPath = '/users';
  static const String _clientsPath = '/clients';
  static const String _ordersPath = '/orders';
  static const String _designsPath = '/designs';
  static const String _fabricsPath = '/fabrics';
  static const String _suppliersPath = '/suppliers';
  static const String _apprenticeshipsPath = '/apprenticeships';
  static const String _conversationsPath = '/conversations';
  static const String _notificationsPath = '/notifications';
  static const String _analyticsPath = '/analytics';
  static const String _filesPath = '/files';
  static const String _paymentsPath = '/payments';
  static const String _subscriptionsPath = '/subscriptions';
  static const String _fabricOrdersPath = '/fabric-orders';
  static const String _measurementsPath = '/measurements';
  static const String _devicePath = '/device';

  // Authentication Endpoints
  static const String authRegister = '$_authPath/register';
  static const String authLogin = '$_authPath/login';
  static const String authRefreshToken = '$_authPath/refresh-token';
  static const String authLogout = '$_authPath/logout';
  static const String authPasswordReset = '$_authPath/password-reset';
  static const String authPasswordResetConfirm = '$_authPath/password-reset/confirm';
  static const String authTwoFactorSetup = '$_authPath/two-factor-setup';
  static const String authTwoFactorVerify = '$_authPath/two-factor-verify';

  // User Profile Endpoints
  static const String userProfile = '$_usersPath/profile';
  static const String userProfileAvatar = '$_usersPath/profile/avatar';
  static const String userPreferences = '$_usersPath/preferences';
  static const String userSettings = '$_usersPath/settings';

  static String userById(String userId) => '$_usersPath/$userId';

  // Client Management Endpoints
  static const String clientsList = _clientsPath;
  static const String clientsCreate = _clientsPath;

  static String clientDetail(String clientId) => '$_clientsPath/$clientId';
  static String clientUpdate(String clientId) => '$_clientsPath/$clientId';
  static String clientDelete(String clientId) => '$_clientsPath/$clientId';
  static String clientMeasurements(String clientId) =>
      '$_clientsPath/$clientId/measurements';
  static String clientMeasurementsAdd(String clientId) =>
      '$_clientsPath/$clientId/measurements';
  static String clientOrders(String clientId) =>
      '$_clientsPath/$clientId/orders';
  static String clientNotes(String clientId) => '$_clientsPath/$clientId/notes';
  static String clientNotesGet(String clientId) =>
      '$_clientsPath/$clientId/notes';

  // Order Management Endpoints
  static const String ordersList = _ordersPath;
  static const String ordersCreate = _ordersPath;

  static String orderDetail(String orderId) => '$_ordersPath/$orderId';
  static String orderUpdate(String orderId) => '$_ordersPath/$orderId';
  static String orderDelete(String orderId) => '$_ordersPath/$orderId';
  static String orderStatusUpdate(String orderId) =>
      '$_ordersPath/$orderId/status';
  static String orderPhotoUpload(String orderId) =>
      '$_ordersPath/$orderId/upload-photo';
  static String orderRating(String orderId) => '$_ordersPath/$orderId/rating';

  // Design & Measurements Endpoints
  static const String designsList = _designsPath;
  static const String designsCreate = _designsPath;

  static String designDetail(String designId) => '$_designsPath/$designId';
  static String designUpdate(String designId) => '$_designsPath/$designId';
  static String designDelete(String designId) => '$_designsPath/$designId';
  static const String measurementsStandard = '$_measurementsPath/standard';
  static const String measurementsValidate = '$_measurementsPath/validate';

  // Fabric Marketplace Endpoints
  static const String fabricsList = _fabricsPath;

  static String fabricDetail(String fabricId) => '$_fabricsPath/$fabricId';
  static const String suppliersList = _suppliersPath;

  static String supplierDetail(String supplierId) =>
      '$_suppliersPath/$supplierId';
  static const String fabricOrdersCreate = _fabricOrdersPath;
  static const String fabricOrdersList = _fabricOrdersPath;

  static String fabricOrderDetail(String orderId) =>
      '$_fabricOrdersPath/$orderId';

  // Apprenticeship Endpoints
  static const String apprenticeshipsList = _apprenticeshipsPath;
  static const String apprenticeshipsCreate = _apprenticeshipsPath;

  static String apprenticeshipDetail(String apprenticeId) =>
      '$_apprenticeshipsPath/$apprenticeId';
  static String apprenticeshipUpdate(String apprenticeId) =>
      '$_apprenticeshipsPath/$apprenticeId';
  static String apprenticeshipTasks(String apprenticeId) =>
      '$_apprenticeshipsPath/$apprenticeId/tasks';
  static String apprenticeshipTaskComplete(String apprenticeId, String taskId) =>
      '$_apprenticeshipsPath/$apprenticeId/tasks/$taskId/complete';
  static String apprenticeshipSkills(String apprenticeId) =>
      '$_apprenticeshipsPath/$apprenticeId/skills';
  static String apprenticeshipContract(String apprenticeId) =>
      '$_apprenticeshipsPath/$apprenticeId/contract';

  // Chat & Messaging Endpoints
  static const String conversationsList = _conversationsPath;
  static const String conversationsCreate = _conversationsPath;

  static String conversationMessages(String conversationId) =>
      '$_conversationsPath/$conversationId/messages';
  static String conversationMessageSend(String conversationId) =>
      '$_conversationsPath/$conversationId/messages';
  static String conversationMessageEdit(String conversationId, String messageId) =>
      '$_conversationsPath/$conversationId/messages/$messageId';
  static String conversationMessageDelete(String conversationId, String messageId) =>
      '$_conversationsPath/$conversationId/messages/$messageId';
  static String conversationTyping(String conversationId) =>
      '$_conversationsPath/$conversationId/typing';

  // Notifications Endpoints
  static const String notificationsList = _notificationsPath;

  static String notificationMarkRead(String notificationId) =>
      '$_notificationsPath/$notificationId';
  static const String notificationsMarkAllRead = '$_notificationsPath/read-all';
  static const String notificationsPreferences = '$_notificationsPath/preferences';
  static const String deviceRegisterToken = '$_devicePath/register-token';

  // Analytics & Reporting Endpoints
  static const String analyticsDashboard = '$_analyticsPath/dashboard';
  static const String dashboardStats = '$_analyticsPath/dashboard/stats';
  static const String orderList = '$_ordersPath/list';
  static const String clientList = _clientsPath;

  // File Upload Endpoints
  static const String filesUpload = '$_filesPath/upload';

  static String fileGet(String fileId) => '$_filesPath/$fileId';
  static String fileDelete(String fileId) => '$_filesPath/$fileId';

  // Payment Endpoints
  static const String paymentsStripeIntent = '$_paymentsPath/stripe/intent';
  static const String paymentsPaystackInitialize =
      '$_paymentsPath/paystack/initialize';
  static const String paymentsWebhook = '$_paymentsPath/webhook';
  static const String paymentsHistory = '$_paymentsPath/history';

  // Subscription Endpoints
  static const String subscriptionPlans = '$_subscriptionsPath/plans';
  static const String subscriptionsSubscribe = '$_subscriptionsPath/subscribe';
  static const String subscriptionsCurrent = '$_subscriptionsPath/current';
  static const String subscriptionsUpgrade = '$_subscriptionsPath/upgrade';
  static const String subscriptionsCancel = '$_subscriptionsPath/cancel';
}
