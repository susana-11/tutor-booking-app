# Admin Panel Real Data Implementation

## Overview
Converted three admin pages from mock data to real database queries, providing live insights into the platform's operations.

---

## 1. Payment Management ✅

### Backend
- **Endpoint**: `GET /api/admin/transactions`
- **Controller**: `adminController.getAllTransactions()`
- **Features**:
  - Fetches all transactions from database
  - Filters by type (payment, withdrawal, refund)
  - Filters by status (completed, pending, failed)
  - Pagination support
  - Calculates totals (total amount, net amount)

### Frontend Updates
**File**: `admin-web/src/pages/PaymentManagement.js`

**Features**:
- Real-time transaction data from database
- Filter by transaction type and status
- Stats cards showing:
  - Total Revenue (ETB)
  - Net Revenue (ETB)
  - Pending Payouts (count)
  - Refund Requests (count)
- DataGrid with columns:
  - Reference number
  - Booking ID
  - User name
  - Amount, Platform Fee, Net Amount
  - Transaction type (payment/withdrawal/refund)
  - Status (completed/pending/failed)
  - Payment method
  - Date

---

## 2. Analytics & Reports ✅

### Backend
- **Endpoint**: `GET /api/admin/analytics`
- **Controller**: `adminController.getAnalytics()`
- **Query Parameter**: `period` (7, 30, 90, 365 days)

**Data Provided**:
1. **Bookings Over Time**: Daily booking counts and revenue
2. **Revenue by Status**: Bookings grouped by status
3. **Top Subjects**: Most popular subjects by booking count
4. **Top Tutors**: Best performing tutors by sessions and earnings
5. **User Growth**: Daily new user registrations (students/tutors)

### Frontend Updates
**File**: `admin-web/src/pages/Analytics.js`

**Charts Implemented**:
1. **Bookings & Revenue Trend** (Area Chart)
   - Dual Y-axis showing bookings count and revenue
   - Time-based visualization

2. **Popular Subjects** (Pie Chart)
   - Shows distribution of bookings by subject
   - Percentage labels

3. **Bookings by Status** (Bar Chart)
   - Visualizes booking counts by status
   - Completed, pending, cancelled, etc.

4. **User Growth** (Line Chart)
   - Tracks student and tutor registrations over time
   - Dual lines for comparison

5. **Top Performing Tutors** (Bar Chart)
   - Shows sessions count and earnings
   - Dual Y-axis for sessions and revenue

**Time Range Filters**:
- Last 7 Days
- Last 30 Days
- Last 90 Days
- Last Year

---

## 3. Dispute Management ✅

### New Backend Components

#### Model: `server/models/Dispute.js`
```javascript
{
  bookingId: ObjectId (ref: Booking),
  studentId: ObjectId (ref: User),
  tutorId: ObjectId (ref: User),
  raisedBy: 'student' | 'tutor',
  issue: String (max 200 chars),
  description: String (max 1000 chars),
  status: 'open' | 'in_progress' | 'resolved' | 'closed',
  priority: 'low' | 'medium' | 'high',
  amount: Number,
  messages: [{
    sender: ObjectId,
    senderRole: 'student' | 'tutor' | 'admin',
    message: String,
    timestamp: Date
  }],
  resolution: String,
  resolvedBy: ObjectId (ref: User),
  resolvedAt: Date
}
```

#### New Endpoints
1. `GET /api/admin/disputes` - Get all disputes with filters
2. `GET /api/admin/disputes/:disputeId` - Get single dispute
3. `PUT /api/admin/disputes/:disputeId/status` - Update status/priority
4. `POST /api/admin/disputes/:disputeId/resolve` - Resolve dispute
5. `POST /api/admin/disputes/:disputeId/messages` - Add admin message

### Frontend Updates
**File**: `admin-web/src/pages/DisputeManagement.js`

**Features**:
- Real-time dispute data from database
- Filter by status (open, in_progress, resolved, closed)
- Filter by priority (high, medium, low)
- DataGrid showing all disputes
- Detailed dispute view dialog with:
  - Student and tutor information
  - Issue and description
  - Message thread between parties
  - Admin can add messages
  - Resolution form
  - Resolve button

**Workflow**:
1. Admin views all disputes in table
2. Clicks "View" to see details
3. Can send messages to communicate with parties
4. Can enter resolution and click "Resolve"
5. Dispute status updates to "resolved"

---

## Database Collections Used

### Existing Collections
- `users` - User accounts (students, tutors, admins)
- `bookings` - Session bookings
- `transactions` - Payment transactions
- `tutorprofiles` - Tutor profile data
- `studentprofiles` - Student profile data
- `subjects` - Subject catalog

### New Collection
- `disputes` - Dispute records with messages

---

## API Authentication

All admin endpoints require:
```javascript
headers: {
  'Authorization': `Bearer ${adminToken}`
}
```

Token is stored in `localStorage.getItem('adminToken')` after admin login.

---

## Testing

### Payment Management
1. Login as admin
2. Navigate to "Payment Management"
3. View transaction list
4. Filter by type (payment/withdrawal/refund)
5. Filter by status (completed/pending/failed)
6. Check stats cards update

### Analytics
1. Navigate to "Analytics & Reports"
2. Change time range (7/30/90/365 days)
3. View all charts update with real data
4. Check if data makes sense with booking history

### Dispute Management
1. Navigate to "Dispute Management"
2. View disputes list (will be empty if no disputes exist)
3. Filter by status and priority
4. Click "View" on any dispute
5. Send a message
6. Enter resolution and click "Resolve"

---

## Creating Test Disputes

To test the dispute system, you can create disputes manually in MongoDB or add a dispute creation endpoint for students/tutors in the mobile app.

**Manual MongoDB Insert**:
```javascript
db.disputes.insertOne({
  bookingId: ObjectId("existing_booking_id"),
  studentId: ObjectId("student_user_id"),
  tutorId: ObjectId("tutor_user_id"),
  raisedBy: "student",
  issue: "Tutor did not show up",
  description: "The tutor was supposed to join at 10 AM but never showed up.",
  status: "open",
  priority: "high",
  amount: 45,
  messages: [],
  createdAt: new Date(),
  updatedAt: new Date()
});
```

---

## Next Steps

1. **Mobile App Integration**: Add dispute creation feature for students/tutors
2. **Email Notifications**: Send emails when disputes are resolved
3. **Refund Processing**: Integrate with Chapa for automated refunds
4. **Export Reports**: Add CSV/PDF export for analytics
5. **Real-time Updates**: Use Socket.IO for live dispute updates

---

## Files Modified

### Backend
- `server/controllers/adminController.js` - Added dispute management methods
- `server/routes/admin.js` - Added dispute routes
- `server/models/Dispute.js` - New dispute model

### Frontend
- `admin-web/src/pages/PaymentManagement.js` - Real data integration
- `admin-web/src/pages/Analytics.js` - Real data integration
- `admin-web/src/pages/DisputeManagement.js` - Real data integration

---

## Summary

All three admin pages now fetch real data from the database:
- ✅ Payment Management shows actual transactions
- ✅ Analytics displays real booking and user data
- ✅ Dispute Management handles real disputes with messaging

The admin panel is now fully functional with live data!
