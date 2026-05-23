# Fez Delivery API Documentation

This document contains the comprehensive API reference for integrating Fez Delivery logistics into Desby OS.

**Base URL (Sandbox):** `https://apisandbox.fezdelivery.co/v1`  
**Base URL (Production):** `https://api.fezdelivery.co/v1`  
**Secret Key:** `kl6NxZuveIz_2sZGkKq2TvhXjCwwR2HmqsX4GtHNIlkZPx23ZvaGg94GTNuBMO9C`

---

## 1. Authentication

### Authenticate User
**Endpoint:** `POST /user/authenticate`

Used to obtain a Bearer Token for other API calls.

**Request Body:**
| Name | Type | Description |
| :--- | :--- | :--- |
| user_id | String | Required. User Id |
| password | String | Required. User Password |

**Response (200 Success):**
```json
{
  "status": "Success",
  "description": "Login Successfull",
  "authDetails": {
    "authToken": "PBKWY...",
    "expireToken": "2023-01-27 05:06:08"
  }
}
```

### Logout
**Endpoint:** `POST /user/logout`

**Headers:**
| Name | Description |
| :--- | :--- |
| secret-key | Required. Your Secret Key |
| Authorization | Required. Bearer Token |

### Change Password
**Endpoint:** `POST /user/changePassword`

---

## 2. Orders Management

### Create Local/Import Order
**Endpoint:** `POST /orders/import`

Used for creating delivery requests. Accepts single or multiple objects in an array.

**Request Body (Array of Objects):**
| Name | Type | Description |
| :--- | :--- | :--- |
| recipientAddress | String | Required. Delivery destination |
| recipientState | String | Required. 36 states or FCT |
| recipientName | String | Required. Recipient Name |
| recipientPhone | String | Required. Recipient Phone |
| uniqueID | String | Required. Unique identifier for request |
| BatchID | String | Required. Grouping ID for batch requests |
| valueOfItem | String | Required. Item value |
| weight | Integer | Required. Weight in Kg |
| itemDescription | String | Optional. Description |

### Get Order Details
**Endpoint:** `GET /orders/{order_id}`

### Update Order
**Endpoint:** `PUT /order`

### Delete Order
**Endpoint:** `DELETE /order`

### Search Orders
**Endpoint:** `POST /orders/search`

---

## 3. Logistics & Utilities

### Fetch Delivery Cost
**Endpoint:** `POST /order/cost`

Calculates delivery price including VAT.

**Request Body:**
| Name | Type | Description |
| :--- | :--- | :--- |
| state | String | Destination State |
| pickUpState | String | Origin State (Optional) |
| weight | Numeric | Weight (Optional) |

**Response:**
```json
{
    "status": "Success",
    "totalCost": 6450,
    "vat": { "vatAmount": 450 }
}
```

### Track Order
**Endpoint:** `GET /order/track/{orderNumber}`

Returns status, timeline history, and recipient details.

### Delivery Time Estimate
**Endpoint:** `POST /delivery-time-estimate`

### Get States
**Endpoint:** `GET /states`

### Pickup Hubs
**Endpoint:** `GET /hubs/{stateId}`

---

## 4. Webhooks

### Register Order Webhook
**Endpoint:** `POST /webhooks/store`

Registers a URL to receive POST requests when an order status changes.

**Payload sent to Webhook:**
```json
{
    "orderNumber": "UKOOIE001F35",
    "status": "Delivered"
}
```

---

## 5. Global Requirements
*   Include `secret-key` in all headers.
*   Include `Authorization: Bearer <token>` for all non-auth endpoints.
*   All amounts are usually in local currency (NGN) unless specified.
