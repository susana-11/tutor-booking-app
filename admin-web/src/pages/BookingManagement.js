import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  Typography,
  Chip,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Grid,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  CircularProgress,
  Alert,
  Paper,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import { Visibility } from '@mui/icons-material';
import axios from 'axios';
import toast from 'react-hot-toast';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'https://tutor-app-backend-wtru.onrender.com/api';

const BookingManagement = () => {
  const [bookings, setBookings] = useState([]);
  const [selectedBooking, setSelectedBooking] = useState(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [filterStatus, setFilterStatus] = useState('all');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [pagination, setPagination] = useState({ page: 1, limit: 20, total: 0 });

  useEffect(() => {
    fetchBookings();
  }, [filterStatus, pagination.page]);

  const fetchBookings = async () => {
    try {
      setLoading(true);
      const params = {
        page: pagination.page,
        limit: pagination.limit,
      };
      if (filterStatus !== 'all') {
        params.status = filterStatus;
      }

      const response = await axios.get(`${API_BASE_URL}/admin/bookings`, { params });
      
      if (response.data.success) {
        setBookings(response.data.data.bookings.map(booking => ({
          id: booking._id,
          student: `${booking.studentId?.firstName || ''} ${booking.studentId?.lastName || ''}`.trim() || 'N/A',
          studentEmail: booking.studentId?.email || 'N/A',
          tutor: `${booking.tutorId?.firstName || ''} ${booking.tutorId?.lastName || ''}`.trim() || 'N/A',
          tutorEmail: booking.tutorId?.email || 'N/A',
          subject: booking.subject?.name || 'N/A',
          date: new Date(booking.sessionDate).toLocaleDateString(),
          time: `${booking.startTime} - ${booking.endTime}`,
          status: booking.status,
          amount: booking.totalAmount,
          mode: booking.sessionType,
          paymentStatus: booking.paymentStatus || booking.payment?.status || 'pending',
          createdAt: new Date(booking.createdAt).toLocaleDateString(),
          duration: booking.duration,
          bookingData: booking,
        })));
        setPagination(prev => ({
          ...prev,
          total: response.data.data.pagination.total,
        }));
      }
    } catch (err) {
      console.error('Failed to fetch bookings:', err);
      setError(err.response?.data?.message || 'Failed to load bookings');
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'confirmed': return 'success';
      case 'pending': return 'warning';
      case 'completed': return 'info';
      case 'cancelled': return 'error';
      case 'rejected': return 'error';
      default: return 'default';
    }
  };

  const columns = [
    { 
      field: 'id', 
      headerName: 'ID', 
      width: 100,
      renderCell: (params) => (
        <Typography variant="caption" sx={{ fontFamily: 'monospace' }}>
          {params.value.slice(-8)}
        </Typography>
      ),
    },
    { 
      field: 'student', 
      headerName: 'Student', 
      width: 150,
      renderCell: (params) => (
        <Box>
          <Typography variant="body2" fontWeight="medium">
            {params.value}
          </Typography>
          <Typography variant="caption" color="text.secondary">
            {params.row.studentEmail}
          </Typography>
        </Box>
      ),
    },
    { 
      field: 'tutor', 
      headerName: 'Tutor', 
      width: 150,
      renderCell: (params) => (
        <Box>
          <Typography variant="body2" fontWeight="medium">
            {params.value}
          </Typography>
          <Typography variant="caption" color="text.secondary">
            {params.row.tutorEmail}
          </Typography>
        </Box>
      ),
    },
    { field: 'subject', headerName: 'Subject', width: 120 },
    { field: 'date', headerName: 'Date', width: 120 },
    { field: 'time', headerName: 'Time', width: 150 },
    {
      field: 'status',
      headerName: 'Status',
      width: 120,
      renderCell: (params) => (
        <Chip
          label={params.value}
          color={getStatusColor(params.value)}
          size="small"
          sx={{ textTransform: 'capitalize' }}
        />
      ),
    },
    {
      field: 'amount',
      headerName: 'Amount',
      width: 100,
      renderCell: (params) => `ETB ${params.value}`,
    },
    {
      field: 'mode',
      headerName: 'Mode',
      width: 100,
      renderCell: (params) => (
        <Chip
          label={params.value === 'online' ? 'Online' : 'In-Person'}
          size="small"
          variant="outlined"
        />
      ),
    },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 120,
      renderCell: (params) => (
        <Button
          size="small"
          startIcon={<Visibility />}
          onClick={() => {
            setSelectedBooking(params.row);
            setDialogOpen(true);
          }}
        >
          View
        </Button>
      ),
      sortable: false,
      filterable: false,
    },
  ];

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
      <Typography variant="h4" fontWeight="bold" sx={{ mb: 3 }}>
        Booking Management
      </Typography>

      <Card sx={{ mb: 3, p: 2 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} md={3}>
            <FormControl fullWidth>
              <InputLabel>Filter by Status</InputLabel>
              <Select
                value={filterStatus}
                label="Filter by Status"
                onChange={(e) => setFilterStatus(e.target.value)}
              >
                <MenuItem value="all">All Status</MenuItem>
                <MenuItem value="pending">Pending</MenuItem>
                <MenuItem value="confirmed">Confirmed</MenuItem>
                <MenuItem value="completed">Completed</MenuItem>
                <MenuItem value="cancelled">Cancelled</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} md={9}>
            <Box sx={{ display: 'flex', gap: 2 }}>
              <Paper sx={{ p: 2, flex: 1 }}>
                <Typography variant="caption" color="text.secondary">Total Bookings</Typography>
                <Typography variant="h6">{pagination.total}</Typography>
              </Paper>
              <Paper sx={{ p: 2, flex: 1 }}>
                <Typography variant="caption" color="text.secondary">Showing</Typography>
                <Typography variant="h6">{bookings.length}</Typography>
              </Paper>
            </Box>
          </Grid>
        </Grid>
      </Card>

      <Card>
        <Box sx={{ height: 600, width: '100%' }}>
          <DataGrid
            rows={bookings}
            columns={columns}
            pageSize={pagination.limit}
            rowsPerPageOptions={[10, 20, 50]}
            disableSelectionOnClick
            loading={loading}
            rowCount={pagination.total}
            paginationMode="server"
            onPageChange={(newPage) => setPagination(prev => ({ ...prev, page: newPage + 1 }))}
            sx={{
              border: 'none',
              '& .MuiDataGrid-cell': {
                borderBottom: '1px solid #f0f0f0',
              },
            }}
          />
        </Box>
      </Card>

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Booking Details</DialogTitle>
        <DialogContent>
          {selectedBooking && (
            <Grid container spacing={2} sx={{ mt: 1 }}>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Student"
                  value={selectedBooking.student}
                  InputProps={{ readOnly: true }}
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Tutor"
                  value={selectedBooking.tutor}
                  InputProps={{ readOnly: true }}
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Subject"
                  value={selectedBooking.subject}
                  InputProps={{ readOnly: true }}
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Amount"
                  value={`ETB ${selectedBooking.amount}`}
                  InputProps={{ readOnly: true }}
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Date"
                  value={selectedBooking.date}
                  InputProps={{ readOnly: true }}
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Time"
                  value={selectedBooking.time}
                  InputProps={{ readOnly: true }}
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Duration"
                  value={`${selectedBooking.duration} minutes`}
                  InputProps={{ readOnly: true }}
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Mode"
                  value={selectedBooking.mode === 'online' ? 'Online' : 'In-Person'}
                  InputProps={{ readOnly: true }}
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Booking Status"
                  value={selectedBooking.status}
                  InputProps={{ readOnly: true }}
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Payment Status"
                  value={selectedBooking.paymentStatus}
                  InputProps={{ readOnly: true }}
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Created At"
                  value={selectedBooking.createdAt}
                  InputProps={{ readOnly: true }}
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
            </Grid>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default BookingManagement;
