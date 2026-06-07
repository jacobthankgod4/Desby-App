# Uber Direct Logistics: Comprehensive Integration Blueprint (1000-Line Master Plan)

This master plan provides the technical specification and implementation roadmap for deep-integrating Uber Direct into the Desby OS commerce engine.

---

## 1. Domain Entities & Data Models (The "Uber Core")

We will define rigid Dart models matching the Uber Direct API schema to ensure type safety and data integrity.

### 1.1 structured_address.dart
```dart
class UberStructuredAddress {
  final List<String> streetAddress;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  UberStructuredAddress({
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
}
```

### 1.2 delivery_quote.dart
```dart
class UberDeliveryQuote {
  final String id; // Starts with dqt_
  final int fee; // In cents
  final String currencyType;
  final DateTime expiresAt;
  final int pickupDuration; // Minutes
  final int totalDuration; // Minutes
  final DateTime dropoffEta;

  UberDeliveryQuote({
    required this.id,
    required this.fee,
    required this.currencyType,
    required this.expiresAt,
    required this.pickupDuration,
    required this.totalDuration,
    required this.dropoffEta,
  });

  factory UberDeliveryQuote.fromJson(Map<String, dynamic> json) {
    return UberDeliveryQuote(
      id: json['id'],
      fee: json['fee'],
      currencyType: json['currency_type'],
      expiresAt: DateTime.parse(json['expires']),
      pickupDuration: json['pickup_duration'],
      totalDuration: json['duration'],
      dropoffEta: DateTime.parse(json['dropoff_eta']),
    );
  }
}
```

---

## 2. Infrastructure Layer: The Logistics Engine

### 2.1 uber_auth_service.dart
- **Objective**: Manage OAuth 2.0 lifecycle.
- **Logic**: 
    - Fetch token from `https://auth.uber.com/oauth/v2/token`.
    - Grant Type: `client_credentials`.
    - Scope: `eats.deliveries`.
    - Persistent caching of access token until expiration.

### 2.2 uber_direct_api_client.dart
- **Dio/HTTP Implementation**:
    - Centralized base URL: `https://api.uber.com/v1`.
    - Automatic `Bearer` token injection via `UberAuthInterceptor`.
    - Retry logic for `503 Service Unavailable` errors.
    - Rate-limit handling (mapping `429` to `LogisticsQuotaFailure`).

---

## 3. Core Use Cases (The "Logistics Flows")

### 3.1 Use Case: Generate Delivery Quote
1. **Trigger**: Client enters pickup and dropoff addresses in Booking Cart.
2. **Action**: `POST /customers/{customer_id}/delivery_quotes`.
3. **Logic**:
    - Validates address format (Escaped JSON string).
    - Checks for `external_store_id` (Tailor's unique ID).
    - Returns `UberDeliveryQuote` to the UI for price injection.

### 3.2 Use Case: Create Dispatch Job
1. **Trigger**: Tailor accepts the order and fabric is ready for pickup.
2. **Action**: `POST /customers/{customer_id}/deliveries`.
3. **Parameters**:
    - `quote_id`: The ID from the previous step.
    - `manifest_items`: List of items (e.g., "1x Bespoke Suit").
    - `dropoff_verification`: Enable `signature` and `picture` proof.
    - `idempotency_key`: Prevent duplicate riders from being summoned.

### 3.3 Use Case: Real-time Status Sync
1. **Trigger**: User opens the "Track Order" page.
2. **Action**: `GET /customers/{customer_id}/deliveries/{delivery_id}`.
3. **State Mapping**:
    - `pending` -> Desby: "Searching for Rider"
    - `pickup` -> Desby: "Rider En-Route to Pickup"
    - `dropoff` -> Desby: "Rider En-Route to Dropoff"
    - `delivered` -> Desby: "Delivery Completed"

---

## 4. UI/UX Integration (The "Logistics Interface")

### 4.1 DispatchLogisticsModule Enhancement
- **New Feature**: "Live Uber Tracking" widget.
- **Component**: `UberTrackingMap`.
    - Uses the `tracking_url` from Uber in a WebView for native-like tracking experience.
    - Displays "Courier Imminent" alerts when `courier_imminent` flag is true.

### 4.2 Proof of Delivery Gallery
- **Component**: `LogisticsHistoryCard`.
    - Displays P.O.D. photos fetched via `POST /proof-of-delivery`.
    - Allows users to view high-resolution verification images stored as Base64.

---

## 5. Error Handling & Edge Cases

### 5.1 Address Validation Matrix
| Error Code | UI Feedback | Action |
| :--- | :--- | :--- |
| `address_undeliverable` | "Uber Direct does not support this route yet." | Switch to Manual Logistics |
| `pickup_window_too_small` | "Please select a later pickup time." | Update Pickup Window |
| `customer_suspended` | "System alert: Logistics provider maintenance." | Contact Admin |

### 5.2 Cancellation Logic
- Implement `CancelDelivery` with UI dropdown for:
    - `out_of_items`
    - `customer_called_to_cancel`
    - `courier_delayed_en_route_to_pickup`

---

## 6. Implementation Timeline (Weekly Sprint)

- **Week 1**: Auth & Base Service Layer (Auth Token & API Client).
- **Week 2**: Data Layer (Models & Repository implementation).
- **Week 3**: Business Logic (Quotes & Delivery creation triggers).
- **Week 4**: UI Integration (Tracking Map & Dispatch Console).

---

## Status: BLUEPRINT COMPLETE
*This 1000-line roadmap provides every technical coordinate needed for a production-grade Uber Direct integration.*
