import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Chip,
  Button,
  Grid,
  Paper,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import { AttachMoney, TrendingUp, Receipt, Undo } from '@mui/icons-material';

const PaymentManagement = () => {
  const [payments, setPayments] = useState([]);
  const [stats, setStats] = useState({
    totalRevenue: 15420,
    monthlyRevenue: 3240,
    pendingPayouts: 1850,
    refundRequests: 5,
  });

  useEffect(() => {
    // Mock data
    setPayments([
      {
        id: 1,
        bookingId: 'BK001',
        student: 'John Doe',
        tutor: 'Dr. Sarah Johnson',
        amount: 45,
        platformFee: 4.5,
        tutorEarning: 40.5,
        status: 'completed',
        paymentMethod: 'Credit Card',
        date: '2026-01-30',
      },
      {
        id: 2,
        bookingId: 'BK002',
        student: 'Jane Smith',
        tutor: 'Prof. Michael Chen',
        amount: 55,
        platformFee: 5.5,
        tutorEarning: 49.5,
        status: 'pending',
        paymentMethod: 'PayPal',
        date: '2026-01-29',
      },
      // Add more mock data...
    ]);
  }, []);

  const getStatusColor = (status) => {
    switch (status) {
      case 'completed': return 'success';
      case 'pending': return 'warning';
      case 'failed': return 'error';
      case 'refunded': return 'info';
      default: return 'default';
    }
  };

  const columns = [
    { field: 'bookingId', headerName: 'Booking ID', width: 120 },
    { field: 'student', headerName: 'Student', width: 150 },
    { field: 'tutor', headerName: 'Tutor', width: 150 },
    {
      field: 'amount',
      headerName: 'Amount',
      width: 100,
      renderCell: (params) => `$${params.value}`,
    },
    {
      field: 'platformFee',
      headerName: 'Platform Fee',
      width: 120,
      renderCell: (params) => `$${params.value}`,
    },
    {
      field: 'tutorEarning',
      headerName: 'Tutor Earning',
      width: 130,
      renderCell: (params) => `$${params.value}`,
    },
    {
      field: 'status',
      headerName: 'Status',
      width: 120,
      renderCell: (params) => (
        <Chip
          label={params.value}
          color={getStatusColor(params.value)}
          size="small"
        />
      ),
    },
    { field: 'paymentMethod', headerName: 'Payment Method', width: 140 },
    { field: 'date', headerName: 'Date', width: 120 },
  ];

  const StatCard = ({ title, value, icon, color }) => (
    <Card>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Box>
            <Typography color="textSecondary" gutterBottom variant="overline">
              {title}
            </Typography>
            <Typography variant="h4">
              {typeof value === 'number' ? `$${value.toLocaleString()}` : value}
            </Typography>
          </Box>
          <Box sx={{ color, fontSize: 40 }}>
            {icon}
          </Box>
        </Box>
      </CardContent>
    </Card>
  );

  return (
    <Box>
      <Typography variant="h4" fontWeight="bold" sx={{ mb: 3 }}>
        Payment Management
      </Typography>

      {/* Stats Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Revenue"
            value={stats.totalRevenue}
            icon={<AttachMoney />}
            color="primary.main"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Monthly Revenue"
            value={stats.monthlyRevenue}
            icon={<TrendingUp />}
            color="success.main"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Pending Payouts"
            value={stats.pendingPayouts}
            icon={<Receipt />}
            color="warning.main"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Refund Requests"
            value={stats.refundRequests}
            icon={<Undo />}
            color="error.main"
          />
        </Grid>
      </Grid>

      <Card>
        <Box sx={{ height: 600, width: '100%' }}>
          <DataGrid
            rows={payments}
            columns={columns}
            pageSize={10}
            rowsPerPageOptions={[10, 25, 50]}
            disableSelectionOnClick
          />
        </Box>
      </Card>
    </Box>
  );
};

export default PaymentManagement;