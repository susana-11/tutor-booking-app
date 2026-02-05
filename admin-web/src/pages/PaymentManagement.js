import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Chip,
  Grid,
  CircularProgress,
  Alert,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import { AttachMoney, TrendingUp, Receipt, Undo } from '@mui/icons-material';
import axios from 'axios';
import toast from 'react-hot-toast';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'https://tutor-app-backend-wtru.onrender.com/api';

const PaymentManagement = () => {
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filter, setFilter] = useState({ type: 'all', status: 'all' });
  const [stats, setStats] = useState({
    totalRevenue: 0,
    monthlyRevenue: 0,
    pendingPayouts: 0,
    refundRequests: 0,
  });

  useEffect(() => {
    fetchTransactions();
  }, [filter]);

  const fetchTransactions = async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem('adminToken');
      const response = await axios.get(`${API_BASE_URL}/admin/transactions`, {
        headers: { 'Authorization': `Bearer ${token}` },
        params: filter
      });

      if (response.data.success) {
        const { transactions: txns, totals } = response.data.data;
        
        setTransactions(txns.map(tx => ({
          id: tx._id,
          bookingId: tx.bookingId?._id || 'N/A',
          student: tx.userId?.firstName + ' ' + tx.userId?.lastName || 'Unknown',
          tutor: tx.bookingId?.tutorId?.firstName + ' ' + tx.bookingId?.tutorId?.lastName || 'N/A',
          amount: tx.amount,
          platformFee: tx.platformFee || 0,
          netAmount: tx.netAmount,
          status: tx.status,
          type: tx.type,
          paymentMethod: tx.paymentMethod || 'Chapa',
          date: new Date(tx.createdAt).toLocaleDateString(),
          reference: tx.reference || 'N/A',
        })));

        // Update stats
        setStats({
          totalRevenue: totals.totalAmount,
          monthlyRevenue: totals.totalNet,
          pendingPayouts: txns.filter(t => t.status === 'pending' && t.type === 'withdrawal').length,
          refundRequests: txns.filter(t => t.type === 'refund').length,
        });
      }
    } catch (err) {
      console.error('Failed to fetch transactions:', err);
      setError(err.response?.data?.message || 'Failed to load transactions');
      toast.error('Failed to load transactions');
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'completed': return 'success';
      case 'pending': return 'warning';
      case 'failed': return 'error';
      case 'refunded': return 'info';
      default: return 'default';
    }
  };

  const getTypeColor = (type) => {
    switch (type) {
      case 'payment': return 'primary';
      case 'withdrawal': return 'secondary';
      case 'refund': return 'error';
      default: return 'default';
    }
  };

  const columns = [
    { field: 'reference', headerName: 'Reference', width: 150 },
    { field: 'bookingId', headerName: 'Booking ID', width: 120 },
    { field: 'student', headerName: 'User', width: 150 },
    {
      field: 'amount',
      headerName: 'Amount',
      width: 100,
      renderCell: (params) => `ETB ${params.value.toFixed(2)}`,
    },
    {
      field: 'platformFee',
      headerName: 'Platform Fee',
      width: 120,
      renderCell: (params) => `ETB ${params.value.toFixed(2)}`,
    },
    {
      field: 'netAmount',
      headerName: 'Net Amount',
      width: 130,
      renderCell: (params) => `ETB ${params.value.toFixed(2)}`,
    },
    {
      field: 'type',
      headerName: 'Type',
      width: 120,
      renderCell: (params) => (
        <Chip
          label={params.value}
          color={getTypeColor(params.value)}
          size="small"
          variant="outlined"
        />
      ),
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
    { field: 'paymentMethod', headerName: 'Method', width: 120 },
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
              {typeof value === 'number' ? `ETB ${value.toLocaleString()}` : value}
            </Typography>
          </Box>
          <Box sx={{ color, fontSize: 40 }}>
            {icon}
          </Box>
        </Box>
      </CardContent>
    </Card>
  );

  if (error) {
    return (
      <Box>
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      </Box>
    );
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" fontWeight="bold">
          Payment Management
        </Typography>
        <Box sx={{ display: 'flex', gap: 2 }}>
          <FormControl sx={{ minWidth: 120 }}>
            <InputLabel>Type</InputLabel>
            <Select
              value={filter.type}
              label="Type"
              onChange={(e) => setFilter({ ...filter, type: e.target.value })}
            >
              <MenuItem value="all">All Types</MenuItem>
              <MenuItem value="payment">Payment</MenuItem>
              <MenuItem value="withdrawal">Withdrawal</MenuItem>
              <MenuItem value="refund">Refund</MenuItem>
            </Select>
          </FormControl>
          <FormControl sx={{ minWidth: 120 }}>
            <InputLabel>Status</InputLabel>
            <Select
              value={filter.status}
              label="Status"
              onChange={(e) => setFilter({ ...filter, status: e.target.value })}
            >
              <MenuItem value="all">All Status</MenuItem>
              <MenuItem value="completed">Completed</MenuItem>
              <MenuItem value="pending">Pending</MenuItem>
              <MenuItem value="failed">Failed</MenuItem>
            </Select>
          </FormControl>
        </Box>
      </Box>

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
            title="Net Revenue"
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
            rows={transactions}
            columns={columns}
            pageSize={10}
            rowsPerPageOptions={[10, 25, 50]}
            disableSelectionOnClick
            loading={loading}
            sx={{
              border: 'none',
              '& .MuiDataGrid-cell': {
                borderBottom: '1px solid #f0f0f0',
              },
            }}
          />
        </Box>
      </Card>
    </Box>
  );
};

export default PaymentManagement;
