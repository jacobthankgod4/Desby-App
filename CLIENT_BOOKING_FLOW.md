# Client Booking Flow - Uber-Style (Search → Book → Track)

## Overview
This document outlines the **Uber-style** functionality where a **Client** (userType: 'client') logs in and searches for nearby tailors, views profiles/ratings, and books a tailor directly - like finding a ride on Uber.

**NOT**: Tailor adding clients (old flow)

## User Type: Client (from `UserType.client`)

### Code References:
- **UserType Enum**: `lib/core/constants/user_types.dart`
  - `UserType.client.value` = 'client'
  - `UserType.tailor.value` = 'tailor'

- **UserType Provider**: `lib/config/providers/user_type_provider.dart`
  - `userTypesProvider` - provides all user types

- **Auth Provider**: `lib/features/auth/presentation/providers/auth_provider.dart`
  - `currentUserProvider` - gets current user with userType

- **Onboarding Page**: `lib/features/auth/presentation/pages/onboarding_page.dart`
  - `_getScreens(UserType.client)` - returns client-specific onboarding screens

- **Main Page Routing**: `lib/features/dashboard/presentation/pages/main_page.dart`
  - Routes to Client Dashboard when `user.userType == 'client'`

---

## Uber-Style Flow (Client Searches/Books Tailor)

### 1. Client Opens App → Client Dashboard
**Purpose**: Client sees home screen with options to find a tailor

**Code Reference** (`lib/features/dashboard/presentation/pages/main_page.dart`):
```dart
final user = ref.watch(currentUserProvider);
final userType = user?.userType ?? 'tailor';

if (userType == 'client') {
  // Show Client home with "Find Tailor" button
} else if (userType == 'tailor') {
  // Show Tailor dashboard with orders
}
```

**UI Elements**:
- Search bar ("Find a Tailor")
- Map view showing nearby tailors
- "Book Now" buttons

### 2. Search/Find Tailor (Uber-style)
**Purpose**: Client searches for nearby tailors - like Uber finding drivers

**Features** (from Threadly case study):
- Search by location (nearby tailors)
- Search by ratings/reviews
- Search by specialization (native wear, corporate, wedding, alterations)
- View tailor profile with portfolio
- View tailor availability (available/busy)

**Data Query**:
```dart
// From lib/features/profile/data/repositories/firebase_profile_repository.dart
final tailors = await firestore
  .collection('users')
  .where('userType', isEqualTo: 'tailor')
  .where('specialization', isEqualTo: selectedSpecialization)
  .get();
```

**UI Components Needed**:
- Search bar with filters
- List view of nearby tailors
- Map integration (optional)
- Tailor cards: name, photo, rating, specialization, distance, availability

### 3. View Tailor Profile
**Purpose**: Client views tailor details before booking

**Features**:
- Tailor name and photo
- Star rating (1-5)
- Specializations
- Portfolio/gallery
- Pricing range
- Availability status
- Reviews from other clients

### 4. Book Appointment (Uber-style Request)
**Purpose**: Client books the tailor

**Options**:
- Service type: New garment, Alteration, Repair, Consultation
- Garment category selection
- Date/time picker
- Preferred location (home visit / store)

**Code Reference** (`_buildDatePicker()` exists in unified_add_client_page.dart):
```dart
Widget _buildDatePicker() {
  return InkWell(
    onTap: () async {
      final date = await showDatePicker(...);
      if (date != null) setState(() => _dueDate = date);
    },
    // returns selected date
  );
}
```

### 5. Client Provides Measurements
**Purpose**: Input body measurements for the garment

**Measurement Input Options**:
- Manual input
- Guided measurement
- Use saved measurements (if previously saved)

**Existing Components** (`unified_add_client_page.dart`):
- `_buildMeasurementGrid()` - measurement fields
- 50+ measurement parameters defined

### 6. Select Fabric/Design
**Purpose**: Choose fabric and design preferences

**Existing Options** (from unified_add_client_page.dart):
- Fabrics: Cotton, Linen, Silk, Wool, Chiffon, Lace, Ankara...
- Colors: Black, White, Navy, Brown, Green, Red...
- Occasions: Casual, Corporate, Wedding, Cultural Event...

### 7. Get Quote → Confirm
**Purpose**: See price estimate and confirm booking

**Quote Includes**:
- Service cost
- Fabric cost (if client provides or tailor sources)
- Measurement fee
- Delivery cost

**Confirmation**:
- Sends booking notification to **Tailor's Dashboard**
- Client sees "Request Sent"

### 7b. Tailor Receives Booking (Two-Way Handshake)
**Purpose**: Tailor sees booking request and responds

**Tailor Action** (`lib/features/dashboard/presentation/pages/tailor_dashboard.dart`):
- Receives notification of new booking
- Views client details, measurements, preferences
- **Accepts** or **Rejects** the booking

**Tailor Response**:
```dart
// Tailor Dashboard - Booking Actions
void _acceptBooking(OrderEntity order) async {
  await ref.read(updateOrderStatusUsecaseProvider)(
    order.id, 
    OrderStatus.confirmed
  );
  // Notify client booking is accepted
}

void _rejectBooking(OrderEntity order) async {
  await ref.read(updateOrderStatusUsecaseProvider)(
    order.id, 
    OrderStatus.cancelled
  );
  // Notify client booking was declined
}
```

### 7c. Client Notified of Tailor Response
**Purpose**: Client receives confirmation or rejection

**Two-Way Handshake Complete**:
- Tailor accepts → OrderStatus changes to "confirmed" → Client notified
- Tailor rejects → OrderStatus changes to "cancelled" → Client notified & can search for another tailor

### 8. Track Order
**Purpose**: Monitor booking status

**Order Statuses**:
- Pending (awaiting tailor confirmation)
- Confirmed (tailor accepted)
- In Progress (working on garment)
- Ready (awaiting pickup/delivery)
- Delivered / Completed
- Cancelled

**UI**: Timeline showing current status

### 9. Payment
**Purpose**: Process payment

**Methods**:
- Full payment
- Deposit (50% start, 50% completion)

### 10. Leave Feedback
**Purpose**: Rate the tailor

**Data**:
- Star rating (1-5)
- Text review
- Photo upload

---

## Implementation Priorities (Uber-Style)

### Phase 1 - MVP:
1. **Client Dashboard** - home screen with "Find Tailor"
2. **Tailor Discovery** - search/browse tailors list
3. **Book Appointment** - date/service selection
4. **Order Tracking** - status timeline

### Phase 2 - Enhanced:
1. **Tailor Profile** - ratings, portfolio, reviews
2. **Measurement Input** - guided/wizard
3. **Quote Calculation** - dynamic pricing

### Phase 3 - Full:
1. **Map Integration** - nearby tailors on map
2. **Payment Integration** - in-app payment
3. **Real-time Chat** - client-tailor communication

---

## Page/Feature Mapping

### New Pages Needed:

| Page | Purpose |
|------|---------|
| Client Dashboard | Home with "Find Tailor" button |
| Tailor Discovery | Browse/search tailors list |
| Tailor Profile | View tailor details |
| Booking Confirm | Review & confirm booking |
| Order Tracking | Track active orders |

### Existing Pages to Update/Extend:

| Page | Location | Update Needed |
|------|----------|--------------|
| Main Page | `lib/features/dashboard/presentation/pages/main_page.dart` | Route based on userType ('client' vs 'tailor') |
| Tailor Dashboard | `lib/features/dashboard/presentation/pages/tailor_dashboard.dart` | Orders received by tailors |
| Orders Page | `lib/features/dashboard/presentation/pages/orders_page.dart` | Status tracking UI |

---

## Integration Points

### User Type Provider
- Location: `lib/config/providers/user_type_provider.dart`

### Order Repository  
- Location: `lib/features/orders/data/repositories/firebase_order_repository.dart`
- Methods: `createOrder()`, `getOrders()`, `updateOrderStatus()`

### Client Repository
- Location: `lib/features/clients/data/repositories/firebase_client_repository.dart`

### Auth Provider
- Location: `lib/features/auth/presentation/providers/auth_provider.dart`

### Dashboard Routing
```dart
final userType = user?.userType ?? 'tailor';
if (userType == 'client') {
  // Show Client Dashboard (book tailor)
} else if (userType == 'tailor') {
  // Show Tailor Dashboard (receive orders)
}
```

---

## User Journey (Uber-Style)

```
Client Opens App
    ↓ (userType == 'client')
Client Dashboard [Find Tailor]
    ↓
Search/Browse Tailors
    ↓
View Tailor Profile
    ↓
Book Appointment + Measurements
    ↓
Get Quote → Confirm
    ↓
Payment
    ↓
Track Order Status
    ↓
Delivery → Leave Feedback
```
