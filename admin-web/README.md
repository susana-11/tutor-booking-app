# Tutor Booking Admin Panel

A comprehensive React-based admin panel for managing the Tutor Booking Platform. Built with Material-UI and modern React practices.

## Features

### 🎯 **Core Admin Functions**
- **Dashboard Overview** - Real-time statistics, charts, and system health monitoring
- **User Management** - Manage students, tutors, and admin accounts
- **Tutor Verification** - Review and approve tutor applications with document verification
- **Subject Management** - Create, edit, and organize subjects and categories
- **Booking Management** - Monitor and manage all tutoring sessions
- **Payment Management** - Track payments, payouts, and financial analytics
- **Analytics & Reports** - Comprehensive data visualization and reporting
- **Dispute Management** - Handle conflicts between students and tutors
- **System Settings** - Configure platform settings and preferences

### 🔐 **Security & Authentication**
- Role-based access control (Admin only)
- JWT token authentication
- Secure login with session management
- Protected routes and API calls

### 📊 **Data Visualization**
- Interactive charts and graphs using Recharts
- Real-time statistics and KPIs
- Revenue and booking trend analysis
- User growth and engagement metrics

### 🎨 **Modern UI/UX**
- Material-UI design system
- Responsive layout for all devices
- Dark/light theme support
- Intuitive navigation and user experience

## Tech Stack

- **Frontend**: React 18, Material-UI 5
- **Routing**: React Router DOM 6
- **Charts**: Recharts
- **HTTP Client**: Axios
- **Notifications**: React Hot Toast
- **Data Grid**: MUI X Data Grid
- **Icons**: Material Icons

## Getting Started

### Prerequisites
- Node.js 16+ and npm
- Backend API server running on port 5001

### Installation

1. **Clone and navigate to admin panel**
   ```bash
   cd admin-web
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Start development server**
   ```bash
   npm start
   ```

4. **Access the admin panel**
   - Open http://localhost:3000
   - Use demo credentials:
     - Email: admin@tutorbooking.com
     - Password: admin123

### Build for Production
```bash
npm run build
```

## Project Structure

```
admin-web/
├── public/
│   └── index.html
├── src/
│   ├── components/
│   │   └── Layout/
│   │       ├── Header.js
│   │       └── Sidebar.js
│   ├── contexts/
│   │   └── AuthContext.js
│   ├── pages/
│   │   ├── Dashboard.js
│   │   ├── UserManagement.js
│   │   ├── TutorVerification.js
│   │   ├── SubjectManagement.js
│   │   ├── BookingManagement.js
│   │   ├── PaymentManagement.js
│   │   ├── Analytics.js
│   │   ├── DisputeManagement.js
│   │   ├── SystemSettings.js
│   │   └── Login.js
│   ├── App.js
│   ├── index.js
│   └── theme.js
├── package.json
└── README.md
```

## Key Features Breakdown

### 📈 **Dashboard**
- Real-time statistics (users, bookings, revenue)
- Interactive charts for trends and analytics
- System health monitoring
- Recent activity feed
- Quick action items

### 👥 **User Management**
- View all users (students, tutors, admins)
- Advanced filtering and search
- User profile editing
- Account status management
- Bulk operations

### 🎓 **Tutor Verification**
- Review tutor applications
- Document verification system
- Approve/reject with reasons
- Performance tracking
- Communication history

### 📚 **Subject Management**
- Create and organize subjects
- Category management
- Grade level assignments
- Subject statistics
- Active/inactive status

### 📅 **Booking Management**
- View all bookings across platform
- Status tracking and updates
- Booking analytics
- Dispute resolution
- Refund processing

### 💰 **Payment Management**
- Transaction monitoring
- Revenue analytics
- Payout management
- Commission tracking
- Financial reporting

### 📊 **Analytics & Reports**
- Revenue trends and forecasting
- User growth analytics
- Popular subjects analysis
- Performance metrics
- Exportable reports

### ⚖️ **Dispute Management**
- Conflict resolution system
- Communication tracking
- Evidence review
- Resolution documentation
- Appeal process

### ⚙️ **System Settings**
- Platform configuration
- Payment settings
- Notification preferences
- Security settings
- Feature toggles

## API Integration

The admin panel integrates with the backend API for:
- Authentication and authorization
- User and tutor management
- Booking and payment processing
- Analytics data retrieval
- System configuration

## Security Considerations

- JWT token-based authentication
- Role-based access control
- Secure API communication
- Input validation and sanitization
- Session management

## Contributing

1. Follow React best practices
2. Use Material-UI components consistently
3. Implement proper error handling
4. Add loading states for async operations
5. Write clean, documented code

## License

This project is part of the Tutor Booking Platform and is proprietary software.