import React, { useState, useEffect } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { Box } from '@mui/material';
import Sidebar from './components/Layout/Sidebar';
import Header from './components/Layout/Header';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import UserManagement from './pages/UserManagement';
import TutorVerification from './pages/TutorVerification';
import SubjectManagement from './pages/SubjectManagement';
import BookingManagement from './pages/BookingManagement';
import PaymentManagement from './pages/PaymentManagement';
import Analytics from './pages/Analytics';
import DisputeManagement from './pages/DisputeManagement';
import SystemSettings from './pages/SystemSettings';
import { AuthProvider, useAuth } from './contexts/AuthContext';

const DRAWER_WIDTH = 280;

function AppContent() {
  const { isAuthenticated, loading } = useAuth();
  const [mobileOpen, setMobileOpen] = useState(false);

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  if (loading) {
    return <div>Loading...</div>;
  }

  if (!isAuthenticated) {
    return <Login />;
  }

  return (
    <Box sx={{ display: 'flex' }}>
      <Header onMenuClick={handleDrawerToggle} />
      <Sidebar 
        drawerWidth={DRAWER_WIDTH}
        mobileOpen={mobileOpen}
        onDrawerToggle={handleDrawerToggle}
      />
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          p: 3,
          width: { sm: `calc(100% - ${DRAWER_WIDTH}px)` },
          mt: 8,
          backgroundColor: 'background.default',
          minHeight: '100vh',
        }}
      >
        <Routes>
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/users" element={<UserManagement />} />
          <Route path="/tutors" element={<TutorVerification />} />
          <Route path="/subjects" element={<SubjectManagement />} />
          <Route path="/bookings" element={<BookingManagement />} />
          <Route path="/payments" element={<PaymentManagement />} />
          <Route path="/analytics" element={<Analytics />} />
          <Route path="/disputes" element={<DisputeManagement />} />
          <Route path="/settings" element={<SystemSettings />} />
        </Routes>
      </Box>
    </Box>
  );
}

function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}

export default App;